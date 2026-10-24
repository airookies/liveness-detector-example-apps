import React, { useState } from 'react';
import { Button, Image, Platform, Pressable, ScrollView, StatusBar, StyleSheet, Text, TextInput, View, useColorScheme } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import { launchImageLibrary } from 'react-native-image-picker';
import type { LivenessResult } from '@airookies/react-native-liveness-detector';
import { FaceMatchApi, quickStartOptions, reasonMessage, runLiveness } from './src/liveness';

export default function App() {
  const dark = useColorScheme() === 'dark';
  const c = dark ? DARK : LIGHT;
  const [tab, setTab] = useState<'quick' | 'backend'>('quick');
  return (
    <SafeAreaProvider>
      <StatusBar barStyle={dark ? 'light-content' : 'dark-content'} />
      <SafeAreaView style={[styles.fill, { backgroundColor: c.bg }]}>
        <View style={styles.tabs}>
          {(['quick', 'backend'] as const).map((t) => (
            <Pressable key={t} onPress={() => setTab(t)} style={[styles.tab, tab === t && { borderBottomColor: c.accent }]}>
              <Text style={[styles.tabLabel, { color: tab === t ? c.accent : c.muted }]}>{t === 'quick' ? 'Quick start' : 'Backend flow'}</Text>
            </Pressable>
          ))}
        </View>
        <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
          {tab === 'quick' ? <QuickStart c={c} /> : <BackendFlow c={c} />}
        </ScrollView>
      </SafeAreaView>
    </SafeAreaProvider>
  );
}

function QuickStart({ c }: { c: Colors }) {
  const [result, setResult] = useState<LivenessResult>();
  const [error, setError] = useState('');
  const run = () =>
    runLiveness(quickStartOptions()).then(
      (r) => { setResult(r); setError(''); },
      (e) => setError(String(e)),
    );
  return (
    <>
      <Text style={{ color: c.text }}>Runs the check with a challenge the SDK picks: one head turn and four colours. No backend needed.</Text>
      <Button title="Start liveness check" color={c.accent} onPress={run} />
      {error ? <Text style={{ color: c.error }}>{error}</Text> : null}
      {result ? <ResultCard r={result} c={c} /> : null}
    </>
  );
}

function ResultCard({ r, c }: { r: LivenessResult; c: Colors }) {
  return (
    <View style={[styles.card, { backgroundColor: c.card }]}>
      <Text style={[styles.title, { color: c.text }]}>{r.status === 'passed' ? 'Passed' : `${r.status}: ${reasonMessage(r.reason)}`}</Text>
      <Text style={[styles.mono, { color: c.text }]}>
        {`reason ${r.reason}, integrity ${r.integrity}\nchallenge ${r.challengeId}\n`}
        {r.steps.map((s) => `  ${s.step}: ${s.passed ? 'passed' : 'failed'} in ${s.durationMs} ms`).join('\n')}
      </Text>
      {r.selfie ? (
        <View style={styles.row}>
          <Image source={{ uri: r.selfie.uri }} style={styles.selfie} />
          <Text style={[styles.fill, { color: c.text }]}>
            {`selfie ${r.selfie.width}x${r.selfie.height}\ncolor frames ${r.colorFrames.length}\nevidence zip ${r.archive?.name}`}
          </Text>
        </View>
      ) : null}
    </View>
  );
}

function BackendFlow({ c }: { c: Colors }) {
  const [baseUrl, setBaseUrl] = useState('https://');
  const [apiKey, setApiKey] = useState('');
  // Android: `adb reverse tcp:4000 tcp:4000` makes localhost reach your computer.
  // iOS device: use your computer's LAN address instead of localhost.
  const [sessionUrl, setSessionUrl] = useState('http://localhost:4000/ekyc/session');
  const [idPhoto, setIdPhoto] = useState<string>(); // base64 JPEG
  const [running, setRunning] = useState(false);
  const [log, setLog] = useState<string[]>([]);

  const pickPhoto = async () => {
    const r = await launchImageLibrary({ mediaType: 'photo', includeBase64: true, maxWidth: 1280, maxHeight: 1280, quality: 0.9 });
    if (r.assets?.[0]?.base64) setIdPhoto(r.assets[0].base64);
  };

  /** session -> challenge -> check -> face-match, logging each step. */
  const run = async () => {
    if (!idPhoto) return;
    const lines: string[] = [];
    const out = (line: string) => { lines.push(line); setLog([...lines]); };
    setRunning(true);
    try {
      const api = new FaceMatchApi(baseUrl, apiKey);
      const session = await api.createSession(sessionUrl);
      out(`session: request ${session.request_id}, row ${session.row_id}`);

      const [response, challenge] = await api.challenge(session);
      out(`challenge: HTTP ${response.status}, code ${response.body.code} ${response.body.message ?? ''}`);
      if (!challenge) return;
      out(`colors ${JSON.stringify(challenge.colors)}, actions ${challenge.actions ? JSON.stringify(challenge.actions) : '(SDK picks a turn)'}`);

      const result = await runLiveness({ challenge });
      out(`check: ${result.status} ${result.reason}, integrity ${result.integrity}`);
      if (result.status !== 'passed') return out(reasonMessage(result.reason));

      const match = await api.faceMatch(session, result, idPhoto);
      out(`face-match: HTTP ${match.status}${match.retryAfter ? `, retry after ${match.retryAfter} s` : ''}`);
      for (const f of ['code', 'message', 'liveness_score', 'similarity_score', 'verification_token']) {
        if (match.body[f] !== undefined) out(`  ${f}: ${match.body[f]}`);
      }
    } catch (e) {
      out(`error: ${e}`);
    } finally {
      setRunning(false);
    }
  };

  const input = [styles.input, { color: c.text, borderColor: c.muted }];
  return (
    <>
      <Text style={{ color: c.error }}>
        For testing only: in production your backend keeps the API key and calls Face Match; the app only gets the challenge and sends the evidence.
      </Text>
      <Text style={{ color: c.muted }}>Face Match base URL</Text>
      <TextInput style={input} value={baseUrl} onChangeText={setBaseUrl} autoCapitalize="none" autoCorrect={false} keyboardType="url" />
      <Text style={{ color: c.muted }}>API key (X-API-KEY)</Text>
      <TextInput style={input} value={apiKey} onChangeText={setApiKey} autoCapitalize="none" secureTextEntry />
      <Text style={{ color: c.muted }}>Session URL</Text>
      <TextInput style={input} value={sessionUrl} onChangeText={setSessionUrl} autoCapitalize="none" autoCorrect={false} keyboardType="url" />
      <Button title={idPhoto ? `ID photo: ${Math.round((idPhoto.length * 0.75) / 1024)} KB (change)` : 'Pick ID photo'} color={c.accent} onPress={pickPhoto} />
      <Button title={running ? 'Running…' : 'Run'} color={c.accent} disabled={running || !idPhoto} onPress={run} />
      {log.length ? (
        <View style={[styles.card, { backgroundColor: c.card }]}>
          <Text selectable style={[styles.mono, { color: c.text }]}>{log.join('\n')}</Text>
        </View>
      ) : null}
    </>
  );
}

type Colors = typeof LIGHT;
const LIGHT = { bg: '#FFFFFF', card: '#F2F2F5', text: '#111111', muted: '#6B6B76', accent: '#1E88E5', error: '#C62828' };
const DARK: Colors = { bg: '#000000', card: '#1C1C1E', text: '#F2F2F2', muted: '#9A9AA2', accent: '#64B5F6', error: '#EF9A9A' };

const styles = StyleSheet.create({
  fill: { flex: 1 },
  tabs: { flexDirection: 'row' },
  tabLabel: { fontWeight: '600' },
  tab: { flex: 1, alignItems: 'center', paddingVertical: 12, borderBottomWidth: 2, borderBottomColor: 'transparent' },
  content: { padding: 16, gap: 12 },
  card: { borderRadius: 12, padding: 16, gap: 8 },
  title: { fontSize: 17, fontWeight: '600' },
  mono: { fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace', fontSize: 12 },
  row: { flexDirection: 'row', gap: 12, alignItems: 'flex-start' },
  selfie: { width: 90, height: 160, borderRadius: 8 },
  input: { borderWidth: StyleSheet.hairlineWidth, borderRadius: 8, padding: 10 },
});
