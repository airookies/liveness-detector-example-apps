import LivenessDetector
import SwiftUI

struct QuickStartView: View {
  @State private var result: LivenessResult?
  @State private var error: String?

  var body: some View {
    Form {
      Section {
        Text("Runs the check with a challenge the SDK picks: one head turn and four colours. No backend needed.")
        Button("Start liveness check") {
          Task {
            do { result = try await runLiveness(quickStartOptions()) } catch { self.error = "\(error)" }
          }
        }
      }
      if let error { Text(error).foregroundColor(.red) }
      if let result { ResultSection(result: result) }
    }
    .navigationTitle("Quick start")
  }
}

struct ResultSection: View {
  let result: LivenessResult

  var body: some View {
    Section("Result") {
      Text(result.status == .passed ? "Passed" : "\(result.status.name): \(result.reason.message)").font(.headline)
      Group {
        Text("reason \(result.reason.name), integrity \(result.integrity)")
        Text("challenge \(result.challengeId ?? "-")")
        ForEach(Array(result.steps.enumerated()), id: \.offset) { _, step in
          Text("\(step.step.name): \(step.passed ? "passed" : "failed") in \(step.durationMs) ms")
        }
      }
      .font(.system(.footnote, design: .monospaced))
      if let selfie = result.selfie, let image = UIImage(contentsOfFile: selfie.url.path) {
        HStack(alignment: .top, spacing: 12) {
          Image(uiImage: image).resizable().scaledToFit().frame(height: 160)
          VStack(alignment: .leading) {
            Text("selfie \(selfie.width)x\(selfie.height), \(kb(selfie.url))")
            Text("color frames \(result.colorFrames.count)")
            if let zip = result.archive { Text("evidence zip \(kb(zip.url))") }
          }
          .font(.footnote)
        }
      }
    }
  }

  private func kb(_ url: URL) -> String {
    let size = (try? url.resourceValues(forKeys: [.fileSizeKey]).fileSize) ?? 0
    return "\(size / 1024) KB"
  }
}

struct BackendFlowView: View {
  @AppStorage("baseUrl") private var baseUrl = "https://"
  @AppStorage("apiKey") private var apiKey = ""
  // A phone can't reach your computer's localhost: use its LAN address, e.g. http://192.168.1.10:4000/ekyc/session
  @AppStorage("sessionUrl") private var sessionUrl = "http://localhost:4000/ekyc/session"
  @State private var idPhoto: Data?
  @State private var picking = false
  @State private var running = false
  @State private var log: [String] = []

  var body: some View {
    Form {
      Section {
        Text("For testing only: in production your backend keeps the API key and calls Face Match; the app only gets the challenge and sends the evidence.")
          .foregroundColor(.red).font(.footnote)
      }
      Section("Face Match") {
        TextField("Base URL", text: $baseUrl).keyboardType(.URL).textInputAutocapitalization(.never).disableAutocorrection(true)
        SecureField("API key (X-API-KEY)", text: $apiKey)
        TextField("Session URL", text: $sessionUrl).keyboardType(.URL).textInputAutocapitalization(.never).disableAutocorrection(true)
        Button(idPhoto.map { "ID photo: \($0.count / 1024) KB (change)" } ?? "Pick ID photo") { picking = true }
      }
      Section {
        Button(running ? "Running…" : "Run") { Task { await run() } }
          .disabled(running || idPhoto == nil)
      }
      if !log.isEmpty {
        Section("Log") {
          Text(log.joined(separator: "\n")).font(.system(.footnote, design: .monospaced)).textSelection(.enabled)
        }
      }
    }
    .navigationTitle("Backend flow")
    .sheet(isPresented: $picking) { PhotoPicker { idPhoto = $0 } }
  }

  /// session -> challenge -> check -> face-match, logging each step.
  @MainActor
  private func run() async {
    guard let idPhoto else { return }
    running = true
    log = []
    defer { running = false }
    let api = FaceMatchApi(baseUrl: baseUrl, apiKey: apiKey)
    do {
      let session = try await api.createSession(url: sessionUrl)
      log.append("session: request \(session.requestId), row \(session.rowId)")

      let (response, challenge) = try await api.challenge(session)
      log.append("challenge: HTTP \(response.status), code \(response.code) \(response.body["message"] ?? "")")
      guard let challenge else { return }
      log.append("colors \(challenge.colors ?? []), actions \(response.body["actions"] ?? "(SDK picks a turn)")")

      let result = try await runLiveness(LivenessOptions(challenge: challenge))
      log.append("check: \(result.status.name) \(result.reason.name), integrity \(result.integrity)")
      guard result.status == .passed else { log.append(result.reason.message); return }

      let match = try await api.faceMatch(session, result: result, idPhotoJpeg: idPhoto)
      log.append("face-match: HTTP \(match.status)" + (match.retryAfter.map { ", retry after \($0) s" } ?? ""))
      for field in ["code", "message", "liveness_score", "similarity_score", "verification_token"] {
        if let v = match.body[field] { log.append("  \(field): \(v)") }
      }
    } catch {
      log.append("error: \(error.localizedDescription)")
    }
  }
}
