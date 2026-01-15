// lib/PanelViewModel.dart
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'PanelRepository.dart';

class PanelViewModel extends ChangeNotifier {
  final PanelRepository _repo;

  PanelViewModel({PanelRepository? repository}) : _repo = repository ?? PanelRepository();

  // Stan UI
  bool _isBusy = false;
  bool get isBusy => _isBusy;

  final List<LogEntry> _entries = [];
  List<LogEntry> get entries => List.unmodifiable(_entries);

  Uint8List? _lastFrame;
  Uint8List? get lastFrame => _lastFrame;

  // subskrypcje
  StreamSubscription<LogEntry>? _logSub;
  StreamSubscription<Uint8List>? _vidSub;

  Future<void> startListening({
    required String ipAddress,
    required int tcpPort,
    required int udpPort,
  }) async {
    _isBusy = true;
    notifyListeners();

    // sprzątanie starych subów
    await _logSub?.cancel();
    await _vidSub?.cancel();
    _entries.clear();

    try {
      await _repo.connect(ipAddress: ipAddress, tcpPort: tcpPort, udpPort: udpPort);

      _logSub = _repo.logs.listen((e) {
        _entries.add(e);
        notifyListeners();
      });

      _vidSub = _repo.videoFrames.listen((frame) {
        _lastFrame = frame;
        notifyListeners();
      });
    } catch (e) {
      _entries.add(LogEntry(LogSide.python, 'Błąd połączenia: $e'));
    } finally {
      _isBusy = false;
      notifyListeners();
    }
  }

  // mapowanie przycisków KomendaX
  Future<void> sendCmd1() => _repo.sendCommand('start');     // zaczyna wideo w Pythonie
  Future<void> sendCmd2() => _repo.sendCommand('stop');      // zatrzymuje wideo
  Future<void> sendCmd3() => _repo.sendCommand('option=A');  // dowolna opcja / przykład

  // jeśli chcesz „surową” komendę:
  Future<void> sendRaw(String cmd) => _repo.sendCommand(cmd);

  @override
  void dispose() {
    _logSub?.cancel();
    _vidSub?.cancel();
    _repo.dispose();
    super.dispose();
  }
}
