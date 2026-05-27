import 'package:flutter_tts/flutter_tts.dart';

class VoiceNavigationService {
  static final VoiceNavigationService _instance = VoiceNavigationService._();
  factory VoiceNavigationService() => _instance;
  VoiceNavigationService._();

  final FlutterTts _tts = FlutterTts();
  bool _enabled = true;
  bool _initialized = false;
  String? _lastInstruction;

  Future<void> init() async {
    if (_initialized) return;
    await _tts.setLanguage('id-ID');
    await _tts.setSpeechRate(0.85);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    _initialized = true;
  }

  bool get isEnabled => _enabled;

  void setEnabled(bool value) {
    _enabled = value;
  }

  Future<void> speak(String text) async {
    if (!_enabled) return;
    if (_lastInstruction == text) return; // avoid repeating same instruction
    _lastInstruction = text;
    await _tts.stop();
    await _tts.speak(text);
  }

  Future<void> speakInstruction(String instruction, double distanceMeters) async {
    if (!_enabled) return;
    String text;
    if (distanceMeters > 500) {
      text = 'Dalam ${(distanceMeters / 1000).toStringAsFixed(1)} kilometer, $instruction';
    } else if (distanceMeters > 100) {
      text = 'Dalam ${distanceMeters.round()} meter, $instruction';
    } else {
      text = instruction;
    }
    await speak(text);
  }

  Future<void> speakArrival() async {
    await speak('Anda telah tiba di tujuan');
  }

  Future<void> speakPrayerReminder(String prayerName, String time) async {
    await speak('Perhatian, waktu $prayerName pukul $time. Cari masjid terdekat untuk sholat.');
  }

  Future<void> speakRerouting() async {
    await speak('Menghitung ulang rute');
  }

  Future<void> stop() async {
    await _tts.stop();
  }

  Future<void> dispose() async {
    await _tts.stop();
  }
}
