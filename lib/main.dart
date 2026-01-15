// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';
import 'PanelViewModel.dart';
import 'ControlScreen.dart';

// dostosuj ścieżkę do swojego pliku:

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  const Size initialSize = Size(1200, 800);   // domyślny rozmiar okna
  const Size minSize     = Size(980, 680);    // poniżej tego UI robi się niewygodny
  // Jeśli chcesz dodatkowo ograniczyć maksymalny rozmiar, np. do 1400x900, ustaw:
  // const Size maxSize  = Size(1400, 900);

  const windowOptions = WindowOptions(
    size: initialSize,
    minimumSize: minSize,
    center: true,
    backgroundColor: Colors.transparent,
    titleBarStyle: TitleBarStyle.normal,
  );

  await windowManager.waitUntilReadyToShow(windowOptions, () async {
    // blokada maksymalizacji (przycisk „Maximize” nieaktywny)
    await windowManager.setMaximizable(false);

    // Możesz całkiem zablokować zmianę rozmiaru (wtedy brak „ciągnięcia” krawędziami):
    // await windowManager.setResizable(false);

    // Jeśli zamiast wyłączać maksymalizację wolisz ograniczyć rozmiar do np. 1400x900:
    // await windowManager.setMaximumSize(maxSize);

    await windowManager.show();
    await windowManager.focus();
  });

  runApp(const App());
}

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<PanelViewModel>(create: (_) => PanelViewModel()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blueGrey),
        home: const ControlScreen(),
      ),
    );
  }
}
