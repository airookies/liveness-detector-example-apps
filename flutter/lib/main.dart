import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:liveness_detector/liveness_detector.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'liveness.dart';

void main() => runApp(const ExampleApp());

class ExampleApp extends StatelessWidget {
  const ExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Liveness Example',
      theme: ThemeData(colorSchemeSeed: Colors.blue),
      darkTheme: ThemeData(colorSchemeSeed: Colors.blue, brightness: Brightness.dark),
      home: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Liveness Example'),
            bottom: const TabBar(tabs: [Tab(text: 'Quick start'), Tab(text: 'Backend flow')]),
          ),
          body: const TabBarView(children: [QuickStartTab(), BackendFlowTab()]),
        ),
      ),
    );
  }
}

const _mono = TextStyle(fontFamily: 'monospace', fontSize: 12);

class QuickStartTab extends StatefulWidget {
  const QuickStartTab({super.key});

  @override
  State<QuickStartTab> createState() => _QuickStartTabState();
}

class _QuickStartTabState extends State<QuickStartTab> {
  LivenessResult? _result;
  String? _error;

  Future<void> _run() async {
    try {
      final r = await runLiveness(quickStartOptions());
      setState(() {
        _result = r;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = '$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text('Runs the check with a challenge the SDK picks: one head turn and four colours. No backend needed.'),
        const SizedBox(height: 12),
        FilledButton(onPressed: _run, child: const Text('Start liveness check')),
        if (_error != null) Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
        if (_result != null) ResultCard(_result!),
      ],
    );
  }
}

class ResultCard extends StatelessWidget {
  const ResultCard(this.r, {super.key});

  final LivenessResult r;

  @override
  Widget build(BuildContext context) {
    final selfie = r.selfie;
    return Card(
      margin: const EdgeInsets.only(top: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          spacing: 6,
          children: [
            Text(
              r.status == LivenessStatus.passed ? 'Passed' : '${r.status.name}: ${reasonMessage(r.reason)}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Text('reason ${r.reason.name}, integrity ${r.integrity}\nchallenge ${r.challengeId}', style: _mono),
            for (final s in r.steps)
              Text('  ${s.step.name}: ${s.passed ? 'passed' : 'failed'} in ${s.durationMs} ms', style: _mono),
            if (selfie != null)
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 12,
                children: [
                  Image.file(selfie.file, height: 160),
                  Expanded(
                    child: Text(
                      'selfie ${selfie.width}x${selfie.height}, ${selfie.file.lengthSync() ~/ 1024} KB\n'
                      'color frames ${r.colorFrames.length}\n'
                      'evidence zip ${(r.archive?.file.lengthSync() ?? 0) ~/ 1024} KB',
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}

class BackendFlowTab extends StatefulWidget {
  const BackendFlowTab({super.key});

  @override
  State<BackendFlowTab> createState() => _BackendFlowTabState();
}

class _BackendFlowTabState extends State<BackendFlowTab> with AutomaticKeepAliveClientMixin {
  final _baseUrl = TextEditingController(text: 'https://');
  final _apiKey = TextEditingController();
  // Android: `adb reverse tcp:4000 tcp:4000` makes localhost reach your computer.
  // iOS device: use your computer's LAN address instead of localhost.
  final _sessionUrl = TextEditingController(text: 'http://localhost:4000/ekyc/session');
  Uint8List? _idPhoto;
  bool _running = false;
  final _log = <String>[];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      _baseUrl.text = p.getString('baseUrl') ?? _baseUrl.text;
      _apiKey.text = p.getString('apiKey') ?? '';
      _sessionUrl.text = p.getString('sessionUrl') ?? _sessionUrl.text;
    });
  }

  Future<void> _pickPhoto() async {
    final x =
        await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1280, maxHeight: 1280, imageQuality: 90);
    if (x != null) {
      final bytes = await x.readAsBytes();
      setState(() => _idPhoto = bytes);
    }
  }

  void _out(String line) => setState(() => _log.add(line));

  /// session -> challenge -> check -> face-match, logging each step.
  Future<void> _run() async {
    final idPhoto = _idPhoto;
    if (idPhoto == null) return;
    final p = await SharedPreferences.getInstance();
    await p.setString('baseUrl', _baseUrl.text);
    await p.setString('apiKey', _apiKey.text);
    await p.setString('sessionUrl', _sessionUrl.text);
    setState(() {
      _running = true;
      _log.clear();
    });
    try {
      final api = FaceMatchApi(_baseUrl.text, _apiKey.text);
      final session = await api.createSession(_sessionUrl.text);
      _out('session: request ${session.requestId}, row ${session.rowId}');

      final (response, challenge) = await api.challenge(session);
      _out('challenge: HTTP ${response.status}, code ${response.code} ${response.body['message'] ?? ''}');
      if (challenge == null) return;
      _out(
          'colors ${challenge.colors}, actions ${challenge.actions?.map((a) => a.name).toList() ?? '(SDK picks a turn)'}');

      final result = await runLiveness(LivenessOptions(challenge: challenge));
      _out('check: ${result.status.name} ${result.reason.name}, integrity ${result.integrity}');
      if (result.status != LivenessStatus.passed) return _out(reasonMessage(result.reason));

      final match = await api.faceMatch(session, result, idPhoto);
      _out('face-match: HTTP ${match.status}${match.retryAfter != null ? ', retry after ${match.retryAfter} s' : ''}');
      for (final f in ['code', 'message', 'liveness_score', 'similarity_score', 'verification_token']) {
        if (match.body.containsKey(f)) _out('  $f: ${match.body[f]}');
      }
    } catch (e) {
      _out('error: $e');
    } finally {
      setState(() => _running = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'For testing only: in production your backend keeps the API key and calls Face Match; '
          'the app only gets the challenge and sends the evidence.',
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        TextField(
            controller: _baseUrl,
            decoration: const InputDecoration(labelText: 'Face Match base URL'),
            keyboardType: TextInputType.url,
            autocorrect: false),
        TextField(
            controller: _apiKey,
            decoration: const InputDecoration(labelText: 'API key (X-API-KEY)'),
            obscureText: true),
        TextField(
            controller: _sessionUrl,
            decoration: const InputDecoration(labelText: 'Session URL'),
            keyboardType: TextInputType.url,
            autocorrect: false),
        const SizedBox(height: 12),
        OutlinedButton(
          onPressed: _pickPhoto,
          child: Text(_idPhoto == null ? 'Pick ID photo' : 'ID photo: ${_idPhoto!.length ~/ 1024} KB (change)'),
        ),
        FilledButton(onPressed: _running || _idPhoto == null ? null : _run, child: Text(_running ? 'Running…' : 'Run')),
        if (_log.isNotEmpty)
          Card(
            margin: const EdgeInsets.only(top: 12),
            child: Padding(padding: const EdgeInsets.all(16), child: SelectableText(_log.join('\n'), style: _mono)),
          ),
      ],
    );
  }
}
