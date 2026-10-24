// Everything an app needs to integrate LivenessDetector, in one file to copy from:
//   1. run the check (callback API wrapped as a suspend function),
//   2. the backend calls around it (session -> challenge -> check -> face-match),
//   3. user-facing messages for each failure reason.
// The UI in MainActivity.kt only calls these.
package mn.ekyc.example.liveness

import android.util.Base64
import androidx.activity.ComponentActivity
import java.net.HttpURLConnection
import java.net.URL
import java.util.Locale
import kotlin.coroutines.resume
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.suspendCancellableCoroutine
import kotlinx.coroutines.withContext
import mn.ekyc.livenessdetector.Challenge
import mn.ekyc.livenessdetector.LivenessAction
import mn.ekyc.livenessdetector.LivenessDetector
import mn.ekyc.livenessdetector.LivenessOptions
import mn.ekyc.livenessdetector.LivenessReason
import mn.ekyc.livenessdetector.LivenessResult
import mn.ekyc.livenessdetector.LivenessStatus
import org.json.JSONArray
import org.json.JSONObject

// ---- 1. Run the check ----------------------------------------------------------------

/**
 * Shows the SDK's full-screen check and returns when it closes. Resumes for every outcome
 * (passed, failed, cancelled, error); call it from the main thread.
 */
suspend fun ComponentActivity.runLiveness(options: LivenessOptions): LivenessResult =
  suspendCancellableCoroutine { cont ->
    LivenessDetector.start(this, options) { result -> if (cont.isActive) cont.resume(result) }
  }

/** Quick start: no backend, the SDK picks the colours and one head turn. */
fun quickStartOptions() = LivenessOptions(Challenge(id = "demo-${System.currentTimeMillis()}"))

// ---- 2. Backend calls ------------------------------------------------------------------
// In production, your own backend should hold the API key and make these calls; the app
// only receives the challenge and sends the evidence. The example calls Face Match
// directly so it runs without a backend of your own.

/** What your session endpoint returns: identifies this verification on Face Match. */
data class FaceMatchSession(val requestId: String, val rowId: Long, val sessionToken: String)

/** A response's HTTP status and its (unwrapped) JSON body. */
data class ApiResponse(val status: Int, val body: JSONObject, val retryAfter: String?)

class FaceMatchApi(baseUrl: String, private val apiKey: String) {
  private val base = baseUrl.trim().replace(Regex("/api/client/.*$|/+$"), "")

  /** Your backend creates the session; here it is any URL that returns the three fields. */
  suspend fun createSession(sessionUrl: String): FaceMatchSession {
    val s = post(sessionUrl.trim(), JSONObject(), apiKey = null).body
    return FaceMatchSession(s.getString("request_id"), s.getLong("row_id"), s.getString("session_token"))
  }

  /** POST /api/client/challenge. Single-use and valid for 90 s: fetch one per attempt. */
  suspend fun challenge(session: FaceMatchSession, colorCount: Int = 4): Pair<ApiResponse, Challenge?> {
    val body = JSONObject()
      .put("request_id", session.requestId).put("row_id", session.rowId)
      .put("sequence_length", colorCount).put("session_token", session.sessionToken)
    val r = post("$base/api/client/challenge", body)
    if (r.body.optInt("code", -1) != 0) return r to null
    val challenge = Challenge(
      id = r.body.getString("challenge_id"),
      colors = r.body.getJSONArray("colors").strings(),       // as the backend sent them
      actions = r.body.optJSONArray("actions")?.strings()?.map(::action), // null: the SDK picks a turn
      colorCount = colorCount,
    )
    return r to challenge
  }

  /** POST /api/client/face-match with the evidence of a passed check and the ID photo (JPEG bytes). */
  suspend fun faceMatch(session: FaceMatchSession, result: LivenessResult, idPhotoJpeg: ByteArray): ApiResponse {
    require(result.status == LivenessStatus.PASSED) { "only a passed check has evidence" }
    val selfie = withContext(Dispatchers.IO) { result.selfie!!.file.readBytes() }
    val zip = withContext(Dispatchers.IO) { result.archive!!.file.readBytes() }
    val image1 = JSONObject().put("base64", b64(selfie)).put("border", false)
      .put("liveness_check", true).put("sequence", b64(zip))
    val image2 = JSONObject().put("base64", b64(idPhotoJpeg)).put("border", true)
      .put("liveness_check", false).put("sequence", "")
    val body = JSONObject()
      .put("request_id", session.requestId).put("row_id", session.rowId)
      .put("challenge_id", result.challengeId).put("integrity", result.integrity)
      .put("data", JSONObject().put("image1", image1).put("image2", image2))
    return post("$base/api/client/face-match", body)
  }

  private suspend fun post(url: String, body: JSONObject, apiKey: String? = this.apiKey): ApiResponse =
    withContext(Dispatchers.IO) {
      val c = URL(url).openConnection() as HttpURLConnection
      try {
        c.requestMethod = "POST"
        c.doOutput = true
        c.connectTimeout = 15_000
        c.readTimeout = 60_000
        c.setRequestProperty("Content-Type", "application/json")
        if (!apiKey.isNullOrEmpty()) c.setRequestProperty("X-API-KEY", apiKey)
        c.outputStream.use { it.write(body.toString().toByteArray()) }
        val status = c.responseCode
        val text = (if (status < 400) c.inputStream else c.errorStream)?.use { it.readBytes().decodeToString() }.orEmpty()
        ApiResponse(status, unwrap(text), c.getHeaderField("Retry-After"))
      } finally {
        c.disconnect()
      }
    }

  /** Face Match wraps responses as data.response, response, or neither. */
  private fun unwrap(text: String): JSONObject {
    val o = try { JSONObject(text) } catch (e: Exception) { return JSONObject().put("message", text.take(200)) }
    return o.optJSONObject("data")?.optJSONObject("response") ?: o.optJSONObject("response") ?: o
  }

  private fun JSONArray.strings() = (0 until length()).map { getString(it) }

  /** "turn_left" / "TURN_LEFT" / "turnLeft" -> LivenessAction.TURN_LEFT */
  private fun action(name: String): LivenessAction =
    LivenessAction.entries.first { it.name.replace("_", "").equals(name.replace("_", ""), ignoreCase = true) }

  private fun b64(bytes: ByteArray) = Base64.encodeToString(bytes, Base64.NO_WRAP)
}

// ---- 3. Messages -----------------------------------------------------------------------

/** Suggested text for each reason (docs/integration/README.md). */
fun LivenessReason.message(locale: Locale = Locale.getDefault()): String {
  val mn = locale.language == "mn"
  return when (this) {
    LivenessReason.NONE -> if (mn) "Амжилттай" else "Passed"
    LivenessReason.STEP_TIMEOUT, LivenessReason.SESSION_TIMEOUT ->
      if (mn) "Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу." else "Time ran out. Try again and follow the prompts."
    LivenessReason.FACE_LOST -> if (mn) "Нүүрээ зууван хүрээнд байлгана уу." else "Keep your face in the oval."
    LivenessReason.MULTIPLE_FACES -> if (mn) "Зөвхөн нэг хүн байх ёстой." else "Only one person, please."
    LivenessReason.FLASH_FAILED -> if (mn) "Гэрэл анивчих үед хөдлөхгүй байна уу." else "Hold still during the flash."
    LivenessReason.CANCELLED -> if (mn) "Цуцлагдлаа." else "Cancelled."
    LivenessReason.CAMERA_PERMISSION_DENIED ->
      if (mn) "Тохиргооноос камерын зөвшөөрөл олгоно уу." else "Allow camera access in Settings."
    LivenessReason.CAMERA_UNAVAILABLE -> if (mn) "Камер ажиллахгүй байна. Дараа дахин оролдоно уу." else "The camera couldn't start. Try again later."
    LivenessReason.INTEGRITY_FAILED -> if (mn) "Энэ төхөөрөмж дээр шалгалт ажиллахгүй." else "The check can't run on this device."
    LivenessReason.UNSUPPORTED_DEVICE -> if (mn) "Бодит утас ашиглана уу." else "Use a real device."
    LivenessReason.INTERNAL_ERROR -> if (mn) "Алдаа гарлаа. Дахин оролдоно уу." else "Something went wrong. Try again."
  }
}
