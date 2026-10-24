// Everything an app needs to integrate LivenessDetector, in one file to copy from:
//   1. run the check (completion API wrapped as async, presented from SwiftUI),
//   2. the backend calls around it (session -> challenge -> check -> face-match),
//   3. user-facing messages for each failure reason.
// The UI in ContentView.swift only calls these.
import LivenessDetector
import UIKit

// MARK: - 1. Run the check

enum LivenessError: Error { case noPresenter }

/// Shows the SDK's full-screen check and returns when it closes, for every outcome
/// (passed, failed, cancelled, error). SwiftUI has no view controller of its own to present
/// from, so this uses the top one of the active window.
@MainActor
func runLiveness(_ options: LivenessOptions) async throws -> LivenessResult {
  guard let presenter = topViewController() else { throw LivenessError.noPresenter }
  return await withCheckedContinuation { cont in
    LivenessDetector.start(from: presenter, options: options) { cont.resume(returning: $0) }
  }
}

/// Quick start: no backend, the SDK picks the colours and one head turn.
func quickStartOptions() -> LivenessOptions {
  LivenessOptions(challenge: Challenge(id: "demo-\(Int(Date().timeIntervalSince1970 * 1000))"))
}

@MainActor
private func topViewController() -> UIViewController? {
  let scene = UIApplication.shared.connectedScenes.compactMap { $0 as? UIWindowScene }
    .first { $0.activationState == .foregroundActive }
  var vc = scene?.windows.first(where: \.isKeyWindow)?.rootViewController
  while let presented = vc?.presentedViewController { vc = presented }
  return vc
}

// MARK: - 2. Backend calls
// In production, your own backend should hold the API key and make these calls; the app
// only receives the challenge and sends the evidence. The example calls Face Match
// directly so it runs without a backend of your own.

/// What your session endpoint returns: identifies this verification on Face Match.
struct FaceMatchSession {
  let requestId: String
  let rowId: Int
  let sessionToken: String
}

/// A response's HTTP status and its (unwrapped) JSON body.
struct ApiResponse {
  let status: Int
  let body: [String: Any]
  let retryAfter: String?
  var code: Int { body["code"] as? Int ?? -1 }
}

struct ApiError: LocalizedError {
  let errorDescription: String?
}

struct FaceMatchApi {
  let base: String
  let apiKey: String

  init(baseUrl: String, apiKey: String) {
    base = baseUrl.trimmingCharacters(in: .whitespaces)
      .replacingOccurrences(of: "/api/client/.*$|/+$", with: "", options: .regularExpression)
    self.apiKey = apiKey.trimmingCharacters(in: .whitespaces)
  }

  /// Your backend creates the session; here it is any URL that returns the three fields.
  func createSession(url: String) async throws -> FaceMatchSession {
    let s = try await post(url.trimmingCharacters(in: .whitespaces), [:]).body
    guard let requestId = s["request_id"] as? String, let rowId = s["row_id"] as? Int,
          let token = s["session_token"] as? String
    else { throw ApiError(errorDescription: "session response is missing request_id, row_id or session_token") }
    return FaceMatchSession(requestId: requestId, rowId: rowId, sessionToken: token)
  }

  /// POST /api/client/challenge. Single-use and valid for 90 s: fetch one per attempt.
  func challenge(_ session: FaceMatchSession, colorCount: Int = 4) async throws -> (ApiResponse, Challenge?) {
    let r = try await post("\(base)/api/client/challenge", [
      "request_id": session.requestId, "row_id": session.rowId,
      "sequence_length": colorCount, "session_token": session.sessionToken,
    ])
    guard r.code == 0, let id = r.body["challenge_id"] as? String else { return (r, nil) }
    let actions = (r.body["actions"] as? [String])?.compactMap(Self.action)  // nil: the SDK picks a turn
    return (r, Challenge(id: id, colors: r.body["colors"] as? [String], actions: actions, colorCount: colorCount))
  }

  /// POST /api/client/face-match with the evidence of a passed check and the ID photo (JPEG).
  func faceMatch(_ session: FaceMatchSession, result: LivenessResult, idPhotoJpeg: Data) async throws -> ApiResponse {
    guard result.status == .passed, let selfieUrl = result.selfie?.url, let zipUrl = result.archive?.url
    else { throw ApiError(errorDescription: "only a passed check has evidence") }
    let selfie = try Data(contentsOf: selfieUrl), zip = try Data(contentsOf: zipUrl)
    return try await post("\(base)/api/client/face-match", [
      "request_id": session.requestId, "row_id": session.rowId,
      "challenge_id": result.challengeId ?? "", "integrity": result.integrity,
      "data": [
        "image1": ["base64": selfie.base64EncodedString(), "border": false, "liveness_check": true,
                   "sequence": zip.base64EncodedString()],
        "image2": ["base64": idPhotoJpeg.base64EncodedString(), "border": true, "liveness_check": false,
                   "sequence": ""],
      ],
    ])
  }

  private func post(_ url: String, _ body: [String: Any]) async throws -> ApiResponse {
    guard let u = URL(string: url) else { throw ApiError(errorDescription: "invalid URL: \(url)") }
    var request = URLRequest(url: u, timeoutInterval: 60)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    // The API key is for Face Match only, never for the session server.
    if !apiKey.isEmpty, url.hasPrefix(base) { request.setValue(apiKey, forHTTPHeaderField: "X-API-KEY") }
    request.httpBody = try JSONSerialization.data(withJSONObject: body)
    let (data, response) = try await URLSession.shared.data(for: request)
    let http = response as? HTTPURLResponse
    return ApiResponse(status: http?.statusCode ?? 0, body: Self.unwrap(data),
                       retryAfter: http?.value(forHTTPHeaderField: "Retry-After"))
  }

  /// Face Match wraps responses as data.response, response, or neither.
  private static func unwrap(_ data: Data) -> [String: Any] {
    guard let o = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any] else {
      return ["message": String(decoding: data.prefix(200), as: UTF8.self)]
    }
    return ((o["data"] as? [String: Any])?["response"] as? [String: Any]) ?? (o["response"] as? [String: Any]) ?? o
  }

  /// "turn_left" / "TURN_LEFT" / "turnLeft" -> .turnLeft
  private static func action(_ name: String) -> LivenessAction? {
    switch name.replacingOccurrences(of: "_", with: "").lowercased() {
    case "turnleft": return .turnLeft
    case "turnright": return .turnRight
    case "blink": return .blink
    case "mouthopen": return .mouthOpen
    case "smile": return .smile
    default: return nil
    }
  }
}

// MARK: - 3. Messages

extension LivenessStatus {
  var name: String { ["passed", "failed", "cancelled", "error"][rawValue] }
}

extension LivenessReason {
  /// The contract name, e.g. "step_timeout".
  var name: String {
    ["none", "session_timeout", "step_timeout", "face_lost", "multiple_faces", "flash_failed", "cancelled",
     "camera_permission_denied", "camera_unavailable", "integrity_failed", "unsupported_device",
     "internal_error"][rawValue]
  }

  /// Suggested text for each reason (docs/integration/README.md).
  var message: String {
    let mn = Locale.preferredLanguages.first?.hasPrefix("mn") == true
    switch self {
    case .none: return mn ? "Амжилттай" : "Passed"
    case .stepTimeout, .sessionTimeout:
      return mn ? "Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу." : "Time ran out. Try again and follow the prompts."
    case .faceLost: return mn ? "Нүүрээ зууван хүрээнд байлгана уу." : "Keep your face in the oval."
    case .multipleFaces: return mn ? "Зөвхөн нэг хүн байх ёстой." : "Only one person, please."
    case .flashFailed: return mn ? "Гэрэл анивчих үед хөдлөхгүй байна уу." : "Hold still during the flash."
    case .cancelled: return mn ? "Цуцлагдлаа." : "Cancelled."
    case .cameraPermissionDenied: return mn ? "Тохиргооноос камерын зөвшөөрөл олгоно уу." : "Allow camera access in Settings."
    case .cameraUnavailable:
      return mn ? "Камер ажиллахгүй байна. Дараа дахин оролдоно уу." : "The camera couldn't start. Try again later."
    case .integrityFailed: return mn ? "Энэ төхөөрөмж дээр шалгалт ажиллахгүй." : "The check can't run on this device."
    case .unsupportedDevice: return mn ? "Бодит утас ашиглана уу." : "Use a real device."
    case .internalError: return mn ? "Алдаа гарлаа. Дахин оролдоно уу." : "Something went wrong. Try again."
    @unknown default: return name
    }
  }
}

extension LivenessStep {
  var name: String {
    ["none", "position", "turn_left", "turn_right", "blink", "mouth_open", "smile", "flash_position", "flash"][rawValue]
  }
}
