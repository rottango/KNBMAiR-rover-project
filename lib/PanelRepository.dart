// lib/comm_repository.dart
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

enum LogSide { panel, python }

class LogEntry {
  final LogSide side;
  final String text;
  final DateTime ts;
  LogEntry(this.side, this.text) : ts = DateTime.now();
}

/// Repo łączy TCP (komendy/dane) i UDP (wideo) zgodnie z Twoim serwerem Pythona.
class PanelRepository {
  Socket? _tcp;
  StreamSubscription<List<int>>? _tcpSub;

  RawDatagramSocket? _udp;
  InternetAddress? _serverAddr;
  int? _udpPort;

  final _logCtrl = StreamController<LogEntry>.broadcast();
  final _videoCtrl = StreamController<Uint8List>.broadcast();

  Stream<LogEntry> get logs => _logCtrl.stream;
  Stream<Uint8List> get videoFrames => _videoCtrl.stream;

  bool get isConnected => _tcp != null;

  /// Połącz: TCP (portData) + przygotuj UDP (portVideo) i wyślij „HELLO”.
  Future<void> connect({
    required String ipAddress,
    required int tcpPort,
    required int udpPort,
    Duration connectTimeout = const Duration(seconds: 5),
  }) async {
    await close(); // wyczyść poprzednie połączenia

    _serverAddr = InternetAddress(ipAddress);
    _udpPort = udpPort;

    // — TCP client (data) —
    _tcp = await Socket.connect(ipAddress, tcpPort, timeout: connectTimeout);
    _logCtrl.add(LogEntry(LogSide.python, 'TCP connected to $ipAddress:$tcpPort'));

    // nasłuch odpowiedzi/JSON-ów z Pythona (SendStart, itp.)
    _tcpSub = _tcp!.listen(
          (bytes) {
        final s = utf8.decode(bytes, allowMalformed: true);
        // serwer nie używa delimiterów – zwykle wyśle pojedynczy JSON/ciąg
        _logCtrl.add(LogEntry(LogSide.python, s));
      },
      onDone: () => _logCtrl.add(LogEntry(LogSide.python, 'TCP closed by server')),
      onError: (e, _) => _logCtrl.add(LogEntry(LogSide.python, 'TCP error: $e')),
      cancelOnError: true,
    );

    // — UDP client (video) —
    // 1) bindowanie na losowy lokalny port
    _udp = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
    _udp!.readEventsEnabled = true;

    // 2) nasłuch ramek z JPEG (base64)
    _udp!.listen((event) {
      if (event == RawSocketEvent.read) {
        Datagram? dg = _udp!.receive();
        while (dg != null) {
          try {
            // Python wysyła bytes(base64) – zdekoduj do JPEG
            final b64 = ascii.decode(dg.data);
            final jpg = base64.decode(b64);
            _videoCtrl.add(Uint8List.fromList(jpg));
          } catch (e) {
            // ciche zignorowanie uszkodzonej ramki
          }
          dg = _udp!.receive();
        }
      }
    });

    // 3) „HELLO” – serwer zapamięta nasz adres/port i zacznie nadawać
    _udp!.send(utf8.encode('HELLO'), _serverAddr!, udpPort);
    _logCtrl.add(LogEntry(LogSide.panel, 'UDP HELLO → $ipAddress:$udpPort'));
  }

  /// Wyślij komendę *bez* znaku nowej linii (serwer porównuje literalnie).
  Future<void> sendCommand(String cmd) async {
    if (_tcp == null) {
      _logCtrl.add(LogEntry(LogSide.panel, 'Niepołączony: $cmd (pominięte)'));
      return;
    }
    _tcp!.add(utf8.encode(cmd));
    await _tcp!.flush();
    _logCtrl.add(LogEntry(LogSide.panel, cmd));
  }

  /// Zamknij zasoby. (Wyślij 'close' jeśli chcesz ładnie zakończyć serwer.)
  Future<void> close({bool sendClose = false}) async {
    if (sendClose && _tcp != null) {
      try {
        _tcp!.add(utf8.encode('close'));
        await _tcp!.flush();
      } catch (_) {}
    }
    await _tcpSub?.cancel();
    _tcpSub = null;
    await _tcp?.close();
    _tcp = null;

    _udp?.close();
    _udp = null;
  }

  Future<void> dispose() async {
    await close();
    await _logCtrl.close();
    await _videoCtrl.close();
  }
}
