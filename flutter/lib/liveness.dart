// Everything an app needs to integrate LivenessDetector, in one file to copy from:
//   1. run the check,
//   2. the backend calls around it (session -> challenge -> check -> face-match),
//   3. user-facing messages for each failure reason.
// The UI in main.dart only calls these.
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' show PlatformDispatcher;

import 'package:http/http.dart' as http;
import 'package:liveness_detector/liveness_detector.dart';

// ---- 1. Run the check ----------------------------------------------------------------

/// Shows the SDK's full-screen check. Completes for every outcome (passed, failed,
/// cancelled, error); throws a PlatformException only if the screen can't be shown.
Future<LivenessResult> runLiveness(LivenessOptions options) => LivenessDetector.start(options);

/// Quick start: no backend, the SDK picks the colours and one head turn.
LivenessOptions quickStartOptions() =>
    LivenessOptions(challenge: Challenge(id: 'demo-${DateTime.now().millisecondsSinceEpoch}'));

// ---- 2. Backend calls ------------------------------------------------------------------
// In production, your own backend should hold the API key and make these calls; the app
// only receives the challenge and sends the evidence. The example calls Face Match
// directly so it runs without a backend of your own.

/// What your session endpoint returns: identifies this verification on Face Match.
class FaceMatchSession {
  FaceMatchSession(this.requestId, this.rowId, this.sessionToken);
  final String requestId;
  final int rowId;
  final String sessionToken;
}

/// A response's HTTP status and its (unwrapped) JSON body.
class ApiResponse {
  ApiResponse(this.status, this.body, this.retryAfter);
  final int status;
  final Map<String, dynamic> body;
  final String? retryAfter;
  int get code => body['code'] is int ? body['code'] as int : -1;
}

class FaceMatchApi {
  FaceMatchApi(String baseUrl, String apiKey)
      : _base = baseUrl.trim().replaceAll(RegExp(r'/api/client/.*$|/+$'), ''),
        _apiKey = apiKey.trim();

  final String _base;
  final String _apiKey;

  /// Your backend creates the session; here it is any URL that returns the three fields.
  Future<FaceMatchSession> createSession(String sessionUrl) async {
    final s = (await _post(sessionUrl.trim(), {}, withKey: false)).body;
    final requestId = s['request_id'], rowId = s['row_id'], token = s['session_token'];
    if (requestId is! String || rowId is! int || token is! String) {
      throw const FormatException('session response is missing request_id, row_id or session_token');
    }
    return FaceMatchSession(requestId, rowId, token);
  }

  /// POST /api/client/challenge. Single-use and valid for 90 s: fetch one per attempt.
  Future<(ApiResponse, Challenge?)> challenge(FaceMatchSession s, {int colorCount = 4}) async {
    final r = await _post('$_base/api/client/challenge', {
      'request_id': s.requestId,
      'row_id': s.rowId,
      'sequence_length': colorCount,
      'session_token': s.sessionToken,
    });
    if (r.code != 0) return (r, null);
    final actions = r.body['actions'] is List
        ? (r.body['actions'] as List).map((a) => _action(a as String)).whereType<LivenessAction>().toList()
        : null; // null: the SDK picks a turn
    return (
      r,
      Challenge(
        id: r.body['challenge_id'] as String,
        colors: List<String>.from(r.body['colors'] as List), // as the backend sent them
        actions: actions,
        colorCount: colorCount,
      ),
    );
  }

  /// POST /api/client/face-match with the evidence of a passed check and the ID photo (JPEG).
  Future<ApiResponse> faceMatch(FaceMatchSession s, LivenessResult result, Uint8List idPhotoJpeg) async {
    final selfie = result.selfie, zip = result.archive;
    if (result.status != LivenessStatus.passed || selfie == null || zip == null) {
      throw StateError('only a passed check has evidence');
    }
    return _post('$_base/api/client/face-match', {
      'request_id': s.requestId,
      'row_id': s.rowId,
      'challenge_id': result.challengeId,
      'integrity': result.integrity,
      'data': {
        'image1': {
          'base64': base64Encode(await selfie.file.readAsBytes()),
          'border': false,
          'liveness_check': true,
          'sequence': base64Encode(await zip.file.readAsBytes()),
        },
        'image2': {'base64': base64Encode(idPhotoJpeg), 'border': true, 'liveness_check': false, 'sequence': ''},
      },
    });
  }

  Future<ApiResponse> _post(String url, Map<String, dynamic> body, {bool withKey = true}) async {
    final res = await http
        .post(
          Uri.parse(url),
          headers: {
            'Content-Type': 'application/json',
            if (withKey && _apiKey.isNotEmpty) 'X-API-KEY': _apiKey,
          },
          body: jsonEncode(body),
        )
        .timeout(const Duration(seconds: 60));
    Map<String, dynamic> json;
    try {
      json = jsonDecode(res.body) as Map<String, dynamic>;
    } catch (_) {
      json = {'message': res.body.length > 200 ? res.body.substring(0, 200) : res.body};
    }
    // Face Match wraps responses as data.response, response, or neither.
    final data = json['data'];
    final unwrapped = (data is Map && data['response'] is Map ? data['response'] : json['response']) ?? json;
    return ApiResponse(res.statusCode, Map<String, dynamic>.from(unwrapped as Map), res.headers['retry-after']);
  }

  /// "turn_left" / "TURN_LEFT" / "turnLeft" -> LivenessAction.turnLeft
  static LivenessAction? _action(String name) {
    final key = name.replaceAll('_', '').toLowerCase();
    for (final a in LivenessAction.values) {
      if (a.name.toLowerCase() == key) return a;
    }
    return null;
  }
}

// ---- 3. Messages -----------------------------------------------------------------------

/// Suggested text for each reason (docs/integration/README.md): (English, Mongolian).
const _messages = <LivenessReason, (String, String)>{
  LivenessReason.none: ('Passed', 'Амжилттай'),
  LivenessReason.stepTimeout: (
    'Time ran out. Try again and follow the prompts.',
    'Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу.'
  ),
  LivenessReason.sessionTimeout: (
    'Time ran out. Try again and follow the prompts.',
    'Хугацаа дууслаа. Зааврыг дагаад дахин оролдоно уу.'
  ),
  LivenessReason.faceLost: ('Keep your face in the oval.', 'Нүүрээ зууван хүрээнд байлгана уу.'),
  LivenessReason.multipleFaces: ('Only one person, please.', 'Зөвхөн нэг хүн байх ёстой.'),
  LivenessReason.flashFailed: ('Hold still during the flash.', 'Гэрэл анивчих үед хөдлөхгүй байна уу.'),
  LivenessReason.cancelled: ('Cancelled.', 'Цуцлагдлаа.'),
  LivenessReason.cameraPermissionDenied: (
    'Allow camera access in Settings.',
    'Тохиргооноос камерын зөвшөөрөл олгоно уу.'
  ),
  LivenessReason.cameraUnavailable: (
    "The camera couldn't start. Try again later.",
    'Камер ажиллахгүй байна. Дараа дахин оролдоно уу.'
  ),
  LivenessReason.integrityFailed: ("The check can't run on this device.", 'Энэ төхөөрөмж дээр шалгалт ажиллахгүй.'),
  LivenessReason.unsupportedDevice: ('Use a real device.', 'Бодит утас ашиглана уу.'),
  LivenessReason.internalError: ('Something went wrong. Try again.', 'Алдаа гарлаа. Дахин оролдоно уу.'),
};

String reasonMessage(LivenessReason reason) {
  final (en, mn) = _messages[reason]!;
  return PlatformDispatcher.instance.locale.languageCode == 'mn' ? mn : en;
}
