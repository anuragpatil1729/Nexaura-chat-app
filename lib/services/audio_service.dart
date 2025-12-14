
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:path_provider/path_provider.dart';

class AudioService {
  FlutterSoundRecorder? _recorder;
  FlutterSoundPlayer? _player;
  bool _isRecorderInitialized = false;
  bool _isPlayerInitialized = false;
  String? _recorderPath;

  Future<void> initialize() async {
    _recorder = FlutterSoundRecorder();
    _player = FlutterSoundPlayer();

    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw RecordingPermissionException('Microphone permission not granted');
    }

    await _recorder!.openRecorder();
    await _player!.openPlayer();
    _isRecorderInitialized = true;
    _isPlayerInitialized = true;
  }

  void dispose() {
    if (_recorder != null) {
      _recorder!.closeRecorder();
      _recorder = null;
    }
    if (_player != null) {
      _player!.closePlayer();
      _player = null;
    }
  }

  Future<void> startRecording() async {
    if (!_isRecorderInitialized) return;
    final tempDir = await getTemporaryDirectory();
    _recorderPath = '${tempDir.path}/flutter_sound.aac';
    await _recorder!.startRecorder(toFile: _recorderPath);
  }

  Future<String?> stopRecording() async {
    if (!_isRecorderInitialized) return null;
    await _recorder!.stopRecorder();
    return _recorderPath;
  }

  Future<void> startPlaying(String path) async {
    if (!_isPlayerInitialized) return;
    await _player!.startPlayer(fromURI: path);
  }

  Future<void> stopPlaying() async {
    if (!_isPlayerInitialized) return;
    await _player!.stopPlayer();
  }

  bool get isRecording => _recorder?.isRecording ?? false;
}
