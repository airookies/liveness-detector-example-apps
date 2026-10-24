package mn.ekyc.example.liveness

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import android.net.Uri
import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts.PickVisualMedia
import androidx.compose.foundation.Image
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import java.io.ByteArrayOutputStream
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import mn.ekyc.livenessdetector.LivenessOptions
import mn.ekyc.livenessdetector.LivenessResult
import mn.ekyc.livenessdetector.LivenessStatus

class MainActivity : ComponentActivity() {
  override fun onCreate(savedInstanceState: Bundle?) {
    super.onCreate(savedInstanceState)
    enableEdgeToEdge()
    setContent {
      MaterialTheme(colorScheme = if (isSystemInDarkTheme()) darkColorScheme() else lightColorScheme()) {
        var tab by rememberSaveable { mutableStateOf(0) }
        Scaffold { insets ->
          Column(Modifier.padding(insets).fillMaxSize()) {
            TabRow(selectedTabIndex = tab) {
              Tab(tab == 0, onClick = { tab = 0 }, text = { Text("Quick start") })
              Tab(tab == 1, onClick = { tab = 1 }, text = { Text("Backend flow") })
            }
            Column(
              Modifier.verticalScroll(rememberScrollState()).padding(16.dp),
              verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
              if (tab == 0) QuickStartScreen(this@MainActivity) else BackendScreen(this@MainActivity)
            }
          }
        }
      }
    }
  }
}

@Composable
private fun QuickStartScreen(activity: ComponentActivity) {
  val scope = rememberCoroutineScope()
  var result by remember { mutableStateOf<LivenessResult?>(null) }
  Text("Runs the check with a challenge the SDK picks: one head turn and four colours. No backend needed.")
  Button(onClick = { scope.launch { result = activity.runLiveness(quickStartOptions()) } }, Modifier.fillMaxWidth()) {
    Text("Start liveness check")
  }
  result?.let { ResultCard(it) }
}

@Composable
private fun ResultCard(r: LivenessResult) {
  val selfie = remember(r) { r.selfie?.file?.let { BitmapFactory.decodeFile(it.path) } }
  Card(Modifier.fillMaxWidth()) {
    Column(Modifier.padding(16.dp), verticalArrangement = Arrangement.spacedBy(6.dp)) {
      Text(
        if (r.status == LivenessStatus.PASSED) "Passed" else "${r.status}: ${r.reason.message()}",
        style = MaterialTheme.typography.titleMedium,
      )
      Text("reason ${r.reason}, integrity ${r.integrity}, challenge ${r.challengeId}", fontFamily = FontFamily.Monospace)
      r.steps.forEach { Text("  ${it.step}: ${if (it.passed) "passed" else "failed"} in ${it.durationMs} ms", fontFamily = FontFamily.Monospace) }
      Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
        selfie?.let { Image(it.asImageBitmap(), "Selfie", Modifier.height(160.dp)) }
        Column {
          r.selfie?.let { Text("selfie ${it.width}x${it.height}, ${it.file.length() / 1024} KB") }
          Text("color frames ${r.colorFrames.size}")
          r.archive?.let { Text("evidence zip ${it.file.length() / 1024} KB") }
        }
      }
    }
  }
}

@Composable
private fun BackendScreen(activity: ComponentActivity) {
  val context = LocalContext.current
  val prefs = remember { context.getSharedPreferences("backend", Context.MODE_PRIVATE) }
  val scope = rememberCoroutineScope()
  var baseUrl by remember { mutableStateOf(prefs.getString("baseUrl", "https://")!!) }
  var apiKey by remember { mutableStateOf(prefs.getString("apiKey", "")!!) }
  // With `adb reverse tcp:4000 tcp:4000`, a phone reaches a session server on your computer here.
  var sessionUrl by remember { mutableStateOf(prefs.getString("sessionUrl", "http://localhost:4000/ekyc/session")!!) }
  var idPhoto by remember { mutableStateOf<ByteArray?>(null) }
  var running by remember { mutableStateOf(false) }
  val log = remember { mutableStateListOf<String>() }

  val pickPhoto = rememberLauncherForActivityResult(PickVisualMedia()) { uri ->
    if (uri != null) scope.launch { idPhoto = withContext(Dispatchers.IO) { loadJpeg(context, uri) } }
  }

  Text(
    "For testing only: in production your backend keeps the API key and calls Face Match; the app only gets the challenge and sends the evidence.",
    color = MaterialTheme.colorScheme.error,
  )
  OutlinedTextField(baseUrl, { baseUrl = it }, Modifier.fillMaxWidth(), label = { Text("Face Match base URL") }, singleLine = true)
  OutlinedTextField(
    apiKey, { apiKey = it }, Modifier.fillMaxWidth(), label = { Text("API key (X-API-KEY)") }, singleLine = true,
    visualTransformation = PasswordVisualTransformation(), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
  )
  OutlinedTextField(sessionUrl, { sessionUrl = it }, Modifier.fillMaxWidth(), label = { Text("Session URL") }, singleLine = true)
  OutlinedButton(onClick = { pickPhoto.launch(PickVisualMediaRequest(PickVisualMedia.ImageOnly)) }, Modifier.fillMaxWidth()) {
    Text(idPhoto?.let { "ID photo: ${it.size / 1024} KB (change)" } ?: "Pick ID photo")
  }
  Button(
    enabled = !running && idPhoto != null,
    modifier = Modifier.fillMaxWidth(),
    onClick = {
      prefs.edit().putString("baseUrl", baseUrl).putString("apiKey", apiKey).putString("sessionUrl", sessionUrl).apply()
      log.clear()
      running = true
      scope.launch {
        try {
          runBackendFlow(activity, FaceMatchApi(baseUrl, apiKey.trim()), sessionUrl, idPhoto!!) { log += it }
        } catch (e: Exception) {
          log += "error: $e"
        } finally {
          running = false
        }
      }
    },
  ) { Text(if (running) "Running…" else "Run") }
  if (log.isNotEmpty()) {
    Card(Modifier.fillMaxWidth()) {
      Text(log.joinToString("\n"), Modifier.padding(16.dp), fontFamily = FontFamily.Monospace)
    }
  }
}

/** session -> challenge -> check -> face-match, logging each step. */
private suspend fun runBackendFlow(
  activity: ComponentActivity, api: FaceMatchApi, sessionUrl: String, idPhoto: ByteArray, log: (String) -> Unit,
) {
  val session = api.createSession(sessionUrl)
  log("session: request ${session.requestId}, row ${session.rowId}")

  val (response, challenge) = api.challenge(session)
  log("challenge: HTTP ${response.status}, code ${response.body.optInt("code", -1)} ${response.body.optString("message")}")
  if (challenge == null) return
  log("colors ${challenge.colors}, actions ${challenge.actions ?: "(SDK picks a turn)"}")

  val result = activity.runLiveness(LivenessOptions(challenge))
  log("check: ${result.status} ${result.reason}, integrity ${result.integrity}")
  if (result.status != LivenessStatus.PASSED) {
    log(result.reason.message())
    return
  }

  val match = api.faceMatch(session, result, idPhoto)
  log("face-match: HTTP ${match.status}" + (match.retryAfter?.let { ", retry after $it s" } ?: ""))
  for (field in listOf("code", "message", "liveness_score", "similarity_score", "verification_token")) {
    if (match.body.has(field)) log("  $field: ${match.body.get(field)}")
  }
}

/** The picked photo as a JPEG of at most 1280 px, so the request stays small. */
private fun loadJpeg(context: Context, uri: Uri): ByteArray? {
  val bytes = context.contentResolver.openInputStream(uri)?.use { it.readBytes() } ?: return null
  val bounds = BitmapFactory.Options().apply { inJustDecodeBounds = true }
  BitmapFactory.decodeByteArray(bytes, 0, bytes.size, bounds)
  var sample = 1
  while (maxOf(bounds.outWidth, bounds.outHeight) / sample > 1280) sample *= 2
  val bitmap = BitmapFactory.decodeByteArray(bytes, 0, bytes.size, BitmapFactory.Options().apply { inSampleSize = sample })
  return ByteArrayOutputStream().also { bitmap.compress(Bitmap.CompressFormat.JPEG, 90, it) }.toByteArray()
}
