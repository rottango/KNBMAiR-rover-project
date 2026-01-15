// lib/ControlScreen.dart
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'PanelViewModel.dart';
import 'PanelRepository.dart'; // dla LogEntry/LogSide (kolorowanie logów)

class ControlScreen extends StatefulWidget {
  const ControlScreen({super.key});

  @override
  State<ControlScreen> createState() => _ControlScreenState();
}

class _ControlScreenState extends State<ControlScreen> {
  final _ipCtrl = TextEditingController(text: '192.168.0.10');
  final _tcpCtrl = TextEditingController(text: '8885'); // przykładowy port TCP (data)
  final _udpCtrl = TextEditingController(text: '8884'); // przykładowy port UDP (video)
  final _logScroll = ScrollController();

  int _lastMsgCount = 0;

  @override
  void dispose() {
    _ipCtrl.dispose();
    _tcpCtrl.dispose();
    _udpCtrl.dispose();
    _logScroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<PanelViewModel>();

    // autoscroll logów na dół, gdy pojawi się nowy wpis
    if (vm.entries.length != _lastMsgCount) {
      _lastMsgCount = vm.entries.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_logScroll.hasClients) {
          _logScroll.animateTo(
            _logScroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool isWide = constraints.maxWidth >= 1100; // breakpoint
              final bool isCompactRight = (constraints.maxWidth * 0.30) < 520;
              final double controlsHeight = isCompactRight ? 104 : 72;

              return Column(
                children: [
                  // GÓRA ~80%
                  Expanded(
                    flex: 8,
                    child: isWide
                        ? Row(
                      children: [
                        // lewo 70% – obraz
                        Expanded(
                          flex: 7,
                          child: _ImagePane(bytes: vm.lastFrame),
                        ),
                        const SizedBox(width: 12),
                        // prawo 30% – pasek + log
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              SizedBox(
                                height: controlsHeight,
                                child: _ControlsBar(
                                  ipCtrl: _ipCtrl,
                                  tcpCtrl: _tcpCtrl,
                                  udpCtrl: _udpCtrl,
                                  isCompact: isCompactRight,
                                  isBusy: vm.isBusy,
                                  onListen: () => _handleListen(vm),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Expanded(
                                child: _LogPane(
                                  entries: vm.entries,
                                  controller: _logScroll,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                        : Column(
                      children: [
                        // na wąskim – obraz u góry
                        SizedBox(
                          height: constraints.maxHeight * 0.40,
                          child: _ImagePane(bytes: vm.lastFrame),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: controlsHeight,
                          child: _ControlsBar(
                            ipCtrl: _ipCtrl,
                            tcpCtrl: _tcpCtrl,
                            udpCtrl: _udpCtrl,
                            isCompact: true,
                            isBusy: vm.isBusy,
                            onListen: () => _handleListen(vm),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Expanded(
                          child: _LogPane(
                            entries: vm.entries,
                            controller: _logScroll,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  // DÓŁ – komendy
                  SizedBox(
                    height: 72,
                    child: Row(
                      children: [
                        Expanded(
                          child: _CmdButton(
                            label: 'Komenda 1',
                            onTap: vm.isBusy ? null : () => vm.sendCmd1(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CmdButton(
                            label: 'Komenda 2',
                            onTap: vm.isBusy ? null : () => vm.sendCmd2(),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CmdButton(
                            label: 'Komenda 3',
                            onTap: vm.isBusy ? null : () => vm.sendCmd3(),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _handleListen(PanelViewModel vm) async {
    final host = _ipCtrl.text.trim();
    final tcp = int.tryParse(_tcpCtrl.text.trim());
    final udp = int.tryParse(_udpCtrl.text.trim());

    if (host.isEmpty || tcp == null || udp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Podaj poprawne: IP, TCP Port i UDP Port.')),
      );
      return;
    }
    await vm.startListening(ipAddress: host, tcpPort: tcp, udpPort: udp);
  }
}

// —————————————————— widgets pomocnicze ——————————————————

class _ImagePane extends StatelessWidget {
  const _ImagePane({required this.bytes});
  final Uint8List? bytes;

  @override
  Widget build(BuildContext context) {
    final Widget child = (bytes == null)
        ? const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.image, size: 64),
        SizedBox(height: 8),
        Text('Podgląd obrazu / strumienia'),
      ],
    )
        : Image.memory(bytes!, fit: BoxFit.contain);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceVariant,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Center(child: child),
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.ipCtrl,
    required this.tcpCtrl,
    required this.udpCtrl,
    required this.isCompact,
    required this.isBusy,
    required this.onListen,
  });

  final TextEditingController ipCtrl;
  final TextEditingController tcpCtrl;
  final TextEditingController udpCtrl;
  final bool isCompact;
  final bool isBusy;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    final btnStyle = ElevatedButton.styleFrom(minimumSize: const Size(140, 48));

    if (isCompact) {
      // zawijany pasek (Wrap) – 1–2 rzędy
      return LayoutBuilder(builder: (context, c) {
        final full = c.maxWidth;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            ConstrainedBox(
              constraints:
              BoxConstraints(minWidth: full > 360 ? 260 : full, maxWidth: full),
              child: TextField(
                controller: ipCtrl,
                decoration: const InputDecoration(
                  labelText: 'IP Address',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 70, maxWidth: 80),
              child: TextField(
                controller: tcpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'TCP Port',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 70, maxWidth: 80),
              child: TextField(
                controller: udpCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'UDP Port',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ),
            ConstrainedBox(
              constraints: const BoxConstraints(minWidth: 140),
              child: ElevatedButton(
                style: btnStyle,
                onPressed: isBusy ? null : onListen,
                child: const Text('Listen...'),
              ),
            ),
          ],
        );
      });
    }

    // szeroki pasek – klasyczny rząd
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: ipCtrl,
            decoration: const InputDecoration(
              labelText: 'IP Address',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: tcpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'TCP Port',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: TextField(
            controller: udpCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'UDP Port',
              border: OutlineInputBorder(),
              isDense: true,
            ),
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 140,
          child: ElevatedButton(
            style: btnStyle,
            onPressed: isBusy ? null : onListen,
            child: const Text('Listen...'),
          ),
        ),
      ],
    );
  }
}

class _LogPane extends StatelessWidget {
  const _LogPane({required this.entries, required this.controller});

  final List<LogEntry> entries;
  final ScrollController controller;

  @override
  Widget build(BuildContext context) {
    final greenBg = Colors.green.withOpacity(0.10);
    final blueBg = Colors.blue.withOpacity(0.10);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(11),
        child: Scrollbar(
          controller: controller,
          thumbVisibility: true,
          child: ListView.builder(
            controller: controller,
            padding: const EdgeInsets.all(8),
            itemCount: entries.length,
            itemBuilder: (_, i) {
              final e = entries[i];
              final isPanel = e.side == LogSide.panel;
              final prefix = isPanel ? 'panel>' : 'python>';
              return Container(
                margin: const EdgeInsets.symmetric(vertical: 2),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: isPanel ? greenBg : blueBg,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    children: [
                      TextSpan(
                        text: '$prefix ',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isPanel ? Colors.green[900] : Colors.blue[900],
                        ),
                      ),
                      TextSpan(text: e.text),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _CmdButton extends StatelessWidget {
  const _CmdButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(minimumSize: const Size(0, 48)),
      child: Text(label),
    );
  }
}
