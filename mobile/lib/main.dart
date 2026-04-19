import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'amplifyconfiguration.dart';
import 'firebase_options.dart';
import 'constants/app_constants.dart';
import 'providers/app_providers.dart';
import 'services/notification_service.dart';
import 'screens/home_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/analysis_screen.dart';
import 'screens/ranking_screen.dart';
import 'screens/login_screen.dart';

// バックグラウンドメッセージハンドラ（トップレベル関数にする必要あり）
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('バックグラウンドメッセージ受信: ${message.messageId}');
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase初期化
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // バックグラウンドハンドラを登録
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Amplify初期化
  await _configureAmplify();

  // 通知初期化の失敗でアプリ全体を止めない。
  try {
    await NotificationService.initialize();
    await NotificationService.requestPermission();
    await NotificationService.registerToken();
    await NotificationService.setupFCMListeners();
  } catch (e) {
    print('通知初期化に失敗しました: $e');
  }

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
      child: const SaboriApp(),
    ),
  );
}

Future<void> _configureAmplify() async {
  final authPlugin = AmplifyAuthCognito();
  await Amplify.addPlugin(authPlugin);
  await Amplify.configure(amplifyconfig);
}

class SaboriApp extends ConsumerWidget {
  const SaboriApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider);

    return MaterialApp(
      title: 'サボり防止 🦏',
      debugShowCheckedModeBanner: false,
      theme: _buildLightTheme(),
      darkTheme: _buildDarkTheme(),
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: const AuthWrapper(),
    );
  }

  ThemeData _buildLightTheme() {
    const headingColor = Color(0xFF061B31);
    const bodyColor = Color(0xFF64748D);
    const borderColor = Color(0xFFE5EDF5);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
        primary: primaryColor,
        secondary: const Color(0xFF4434D4),
        tertiary: const Color(0xFFEA2261),
        surface: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.white,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: headingColor,
        titleTextStyle: TextStyle(
          fontWeight: FontWeight.w300,
          fontSize: 20,
          letterSpacing: -0.4,
          color: headingColor,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: const BorderSide(color: borderColor, width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: const BorderSide(color: Color(0xFFB9B9F9), width: 1),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: headingColor, letterSpacing: -0.64),
        headlineMedium: TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: headingColor, letterSpacing: -0.26),
        headlineSmall: TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: headingColor, letterSpacing: -0.22),
        titleLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: headingColor),
        titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: headingColor),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: bodyColor),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: bodyColor),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: bodyColor),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF273951)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: primaryColor.withAlpha(25),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primaryColor, size: 26);
          }
          return const IconThemeData(color: bodyColor, size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            );
          }
          return const TextStyle(color: bodyColor, fontSize: 11);
        }),
      ),
      dividerColor: borderColor,
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: const TextStyle(color: Color(0xFF273951), fontSize: 14),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    const darkSurface = Color(0xFF0D253D);
    const darkCardColor = Color(0xFF1C1E54);
    const purpleLight = Color(0xFFB9B9F9);

    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
        surface: darkSurface,
        primary: primaryColor,
        secondary: const Color(0xFF665EFD),
        tertiary: const Color(0xFFEA2261),
      ),
      scaffoldBackgroundColor: darkSurface,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: darkCardColor,
        foregroundColor: Colors.white,
        titleTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w300,
          fontSize: 20,
          letterSpacing: -0.4,
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: darkCardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
          side: BorderSide(color: Colors.white.withAlpha(25), width: 1),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          elevation: 0,
          textStyle: const TextStyle(
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: purpleLight,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
          side: BorderSide(color: purpleLight.withAlpha(100), width: 1),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: const TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -0.64),
        headlineMedium: const TextStyle(fontSize: 26, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -0.26),
        headlineSmall: const TextStyle(fontSize: 22, fontWeight: FontWeight.w300, color: Colors.white, letterSpacing: -0.22),
        titleLarge: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white),
        titleMedium: const TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Colors.white.withAlpha(180)),
        bodyMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: Colors.white.withAlpha(180)),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Colors.white.withAlpha(150)),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: Colors.white.withAlpha(200)),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkCardColor,
        elevation: 0,
        indicatorColor: primaryColor.withAlpha(50),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: purpleLight, size: 26);
          }
          return IconThemeData(color: Colors.white.withAlpha(150), size: 24);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const TextStyle(
              color: purpleLight,
              fontWeight: FontWeight.w400,
              fontSize: 12,
            );
          }
          return TextStyle(color: Colors.white.withAlpha(130), fontSize: 11);
        }),
      ),
      dividerColor: Colors.white.withAlpha(25),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: BorderSide(color: Colors.white.withAlpha(25)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(4),
          borderSide: const BorderSide(color: primaryColor),
        ),
        labelStyle: TextStyle(color: Colors.white.withAlpha(200), fontSize: 14),
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool _isLoading = true;
  bool _isSignedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    try {
      await Amplify.Auth.getCurrentUser();
      setState(() { _isSignedIn = true; _isLoading = false; });
    } catch (_) {
      setState(() { _isSignedIn = false; _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isSignedIn ? const MainNavigation() : const LoginScreen();
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final _screens = const [
    HomeScreen(),
    AnalysisScreen(),
    RankingScreen(),
    SettingsScreen(),
  ];

  final _titles = const [
    'ホーム',
    '分析',
    'ランキング',
    '設定',
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _titles[_currentIndex],
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: isDark ? Colors.white70 : Colors.grey.shade600,
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        scrolledUnderElevation: 0.5,
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.analytics_outlined),
            selectedIcon: Icon(Icons.analytics),
            label: '分析',
          ),
          NavigationDestination(
            icon: Icon(Icons.leaderboard_outlined),
            selectedIcon: Icon(Icons.leaderboard),
            label: 'ランキング',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}
