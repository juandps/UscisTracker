import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_state.dart';
import 'tracker/ui/tracker_app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final appState = FFAppState();
  await appState.initializePersistedState();

  runApp(
    ChangeNotifierProvider<FFAppState>.value(
      value: appState,
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  static _MyAppState of(BuildContext context) =>
      context.findAncestorStateOfType<_MyAppState>()!;

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  String getRoute([Object? routeMatch]) => '/';

  List<String> getRouteStack() => const ['/'];

  void setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  @override
  Widget build(BuildContext context) {
    return TrackerApp(
      themeMode: _themeMode,
      onThemeModeChanged: setThemeMode,
    );
  }
}

class NavBarPage extends StatelessWidget {
  const NavBarPage({
    super.key,
    this.initialPage,
    this.page,
    this.disableResizeToAvoidBottomInset = false,
  });

  final String? initialPage;
  final Widget? page;
  final bool disableResizeToAvoidBottomInset;

  @override
  Widget build(BuildContext context) {
    return page ??
        TrackerHomePage(
          currentThemeMode: ThemeMode.system,
          onThemeModeChanged: MyApp.of(context).setThemeMode,
        );
  }
}
