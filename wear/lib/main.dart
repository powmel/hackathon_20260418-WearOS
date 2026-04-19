import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_models/shared_models.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vibration/vibration.dart';

import 'wear_sync_service.dart';

final FlutterLocalNotificationsPlugin _notifications =
    FlutterLocalNotificationsPlugin();

final WearSyncReceiver _syncReceiver = WearSyncReceiver();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
  await _notifications.initialize(
    const InitializationSettings(android: androidInit),
  );

  try {
    await _syncReceiver.init();
  } catch (_) {}

  final prefs = await SharedPreferences.getInstance();
  runApp(SaiPetWearApp(store: RhinoStore(prefs)));
}

Future<void> _vibrate({int duration = 150}) async {
  final hasVibrator = await Vibration.hasVibrator();
  if (hasVibrator == true) {
    Vibration.vibrate(duration: duration);
  } else {
    HapticFeedback.mediumImpact();
  }
}

Future<void> _showNotification({
  required String title,
  required String body,
}) async {
  const androidDetails = AndroidNotificationDetails(
    'sai_pet_channel',
    'Sai Pet',
    channelDescription: 'サイペットからのお知らせ',
    importance: Importance.high,
    priority: Priority.high,
    enableVibration: true,
    playSound: true,
  );
  await _notifications.show(
    0,
    title,
    body,
    const NotificationDetails(android: androidDetails),
  );
}

Future<void> _schedulePeriodicCheck(RhinoStore store) async {
  final state = store.load();
  if (state.fullness < 30) {
    await _showNotification(
      title: 'サイが お腹すいてるよ！🦏',
      body: 'げんきゲージが${state.fullness}%… エサをあげよう！',
    );
    await _vibrate(duration: 300);
  }
  if (state.mood == RhinoMood.sad) {
    await _showNotification(
      title: 'サイが 泣きそうだよ…😢',
      body: 'スマホ使いすぎかも。サイを見にきて！',
    );
    await _vibrate(duration: 500);
  }
}

// ─── Colors: Bright Tamagotchi + Tinder warm gradients ───

class TamaColors {
  static const peach = Color(0xFFFF6B6B);
  static const coral = Color(0xFFFF8E53);
  static const hotPink = Color(0xFFFF5864);
  static const warmOrange = Color(0xFFFD9644);
  static const sunYellow = Color(0xFFFFD93D);
  static const mintGreen = Color(0xFF6BCB77);
  static const skyBlue = Color(0xFF4D96FF);
  static const lavender = Color(0xFFB983FF);
  static const cream = Color(0xFFFFF5E4);
  static const softWhite = Color(0xFFFFFBF5);
  static const warmGray = Color(0xFF8D7B68);
  static const darkBrown = Color(0xFF4A3728);

  static const tinderGradient = [Color(0xFFFF5864), Color(0xFFFF6B6B), Color(0xFFFF8E53)];
  static const happyGradient = [Color(0xFFFFE985), Color(0xFFFA742B)];
  static const calmGradient = [Color(0xFF89F7FE), Color(0xFF66A6FF)];
  static const sadGradient = [Color(0xFFD4A5FF), Color(0xFF9B59B6)];
}

// ─── App ───

class SaiPetWearApp extends StatelessWidget {
  const SaiPetWearApp({super.key, required this.store});

  final RhinoStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Sai Pet Wear',
      theme: ThemeData(useMaterial3: true),
      home: WearHome(store: store),
    );
  }
}

// ─── Home ───

class WearHome extends StatefulWidget {
  const WearHome({super.key, required this.store});

  final RhinoStore store;

  @override
  State<WearHome> createState() => _WearHomeState();
}

class _WearHomeState extends State<WearHome> with TickerProviderStateMixin {
  late RhinoState _state;
  late AnimationController _bounceCtrl;
  late Animation<double> _bounce;
  late AnimationController _heartCtrl;
  late Animation<double> _heart;
  bool _showHeart = false;

  @override
  void initState() {
    super.initState();
    _state = widget.store.load();

    _bounceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _bounce = Tween<double>(begin: 0, end: -3.5).animate(
      CurvedAnimation(parent: _bounceCtrl, curve: Curves.easeInOut),
    );

    _heartCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _heart = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _heartCtrl, curve: Curves.easeOut),
    );
    _heartCtrl.addStatusListener((s) {
      if (s == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _heartCtrl.reset();
      }
    });

    _schedulePeriodicCheck(widget.store);
    _listenForSync();
  }

  void _listenForSync() {
    _syncReceiver.messages.listen((msg) {
      switch (msg.type) {
        case SyncType.scoreUpdate:
        case SyncType.petStateUpdate:
          final p = msg.payload;
          final score = p['focusScore'] as int? ?? _state.focusScore;
          final usage = p['usageMinutes'] as int? ?? _state.usageMinutes;
          final fullness = p['fullness'] as int? ?? _state.fullness;
          setState(() {
            _state = widget.store.updateFromPhone(
              _state,
              focusScore: score,
              usageMinutes: usage,
              fullness: fullness,
            );
          });
          _vibrate(duration: 100);
        case SyncType.notificationTrigger:
          final title = msg.payload['title'] as String? ?? 'サイペット';
          final body = msg.payload['body'] as String? ?? '';
          _showNotification(title: title, body: body);
          _vibrate(duration: 300);
        case SyncType.feedCommand:
          _feed();
        case SyncType.outfitCommand:
          _cycleOutfit();
        case SyncType.usageUpdate:
          break;
      }
    });
  }

  @override
  void dispose() {
    _bounceCtrl.dispose();
    _heartCtrl.dispose();
    super.dispose();
  }

  Future<void> _feed() async {
    if (_state.focusScore < RhinoStore.feedCost) return;
    await _vibrate(duration: 100);
    setState(() {
      _state = widget.store.feed(_state);
      _showHeart = true;
    });
    _heartCtrl.forward();
  }

  void _cycleOutfit() {
    _vibrate(duration: 50);
    final next = (_state.outfit.index + 1) % RhinoOutfit.values.length;
    setState(() {
      _state = widget.store.applyOutfit(_state, RhinoOutfit.values[next]);
    });
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final w = box.maxWidth;
        final h = box.maxHeight;
        final s = math.min(w, h);

        return Stack(
          children: [
            // Background: warm tamagotchi room
            Positioned.fill(child: _TamaRoom(mood: _state.mood, size: s)),

            // Score badge (top)
            Positioned(
              top: s * 0.06,
              left: 0,
              right: 0,
              child: _ScoreBadge(score: _state.focusScore, size: s),
            ),

            // Pet
            Positioned(
              left: 0,
              right: 0,
              top: s * 0.24,
              child: AnimatedBuilder(
                animation: _bounce,
                builder: (_, child) => Transform.translate(
                  offset: Offset(0, _bounce.value),
                  child: child,
                ),
                child: _Pet(
                  state: _state,
                  size: s,
                  showHeart: _showHeart,
                  heartAnimation: _heart,
                ),
              ),
            ),

            // Mood text
            Positioned(
              left: 0,
              right: 0,
              bottom: s * 0.28,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.08),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    _state.mood.label,
                    style: TextStyle(
                      fontSize: s <= 200 ? 9 : 10,
                      fontWeight: FontWeight.w700,
                      color: TamaColors.darkBrown,
                    ),
                  ),
                ),
              ),
            ),

            // Fullness bar
            Positioned(
              bottom: s * 0.19,
              left: s * 0.2,
              right: s * 0.2,
              child: _FullnessBar(fullness: _state.fullness, size: s),
            ),

            // Action buttons
            Positioned(
              bottom: s * 0.06,
              left: s * 0.12,
              right: s * 0.12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ActionBtn(
                    icon: Icons.restaurant_rounded,
                    label: 'エサ',
                    gradient: TamaColors.tinderGradient,
                    enabled: _state.focusScore >= RhinoStore.feedCost,
                    onTap: _feed,
                    size: s,
                  ),
                  _ActionBtn(
                    icon: Icons.checkroom_rounded,
                    label: _state.outfit.label,
                    gradient: [
                      _state.outfit.color,
                      _state.outfit.color.withValues(alpha: 0.7),
                    ],
                    enabled: true,
                    onTap: _cycleOutfit,
                    size: s,
                  ),
                  _ActionBtn(
                    icon: Icons.notifications_rounded,
                    label: 'お知らせ',
                    gradient: TamaColors.calmGradient,
                    enabled: true,
                    onTap: () async {
                      await _vibrate(duration: 200);
                      await _showNotification(
                        title: 'サイペットからのお知らせ 🦏',
                        body: 'スコア: ${_state.focusScore}pt / げんき: ${_state.fullness}%',
                      );
                    },
                    size: s,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ─── Tamagotchi Room Background ───

class _TamaRoom extends StatelessWidget {
  const _TamaRoom({required this.mood, required this.size});

  final RhinoMood mood;
  final double size;

  @override
  Widget build(BuildContext context) {
    final wallGradient = switch (mood) {
      RhinoMood.happy => [const Color(0xFFFFF1D0), const Color(0xFFFFE4B5)],
      RhinoMood.calm  => [const Color(0xFFE0F4FF), const Color(0xFFBBDEFB)],
      RhinoMood.sad   => [const Color(0xFFF3E5F5), const Color(0xFFE1BEE7)],
    };
    final floorColor = switch (mood) {
      RhinoMood.happy => const Color(0xFFDEB887),
      RhinoMood.calm  => const Color(0xFFB0C4DE),
      RhinoMood.sad   => const Color(0xFFD7BDE2),
    };

    return Stack(
      children: [
        // Wall
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: wallGradient,
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),

        // Wallpaper pattern (dots)
        ...List.generate(12, (i) {
          final rng = math.Random(i * 7);
          return Positioned(
            left: rng.nextDouble() * size,
            top: rng.nextDouble() * size * 0.65,
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.4),
                shape: BoxShape.circle,
              ),
            ),
          );
        }),

        // Floor
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          height: size * 0.35,
          child: Container(
            decoration: BoxDecoration(
              color: floorColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: CustomPaint(painter: _FloorPatternPainter()),
          ),
        ),

        // Window
        Positioned(
          top: size * 0.08,
          right: size * 0.15,
          child: _CuteWindow(
            size: size * 0.16,
            mood: mood,
          ),
        ),

        // Little plant
        Positioned(
          bottom: size * 0.32,
          left: size * 0.12,
          child: _TinyPlant(size: size * 0.08),
        ),
      ],
    );
  }
}

class _FloorPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 8; y < size.height; y += 12) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _CuteWindow extends StatelessWidget {
  const _CuteWindow({required this.size, required this.mood});

  final double size;
  final RhinoMood mood;

  @override
  Widget build(BuildContext context) {
    final skyColor = switch (mood) {
      RhinoMood.happy => const Color(0xFF87CEEB),
      RhinoMood.calm  => const Color(0xFFA8D8EA),
      RhinoMood.sad   => const Color(0xFFC5A3CF),
    };

    return Container(
      width: size,
      height: size * 1.2,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [skyColor, skyColor.withValues(alpha: 0.6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: TamaColors.warmGray, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: skyColor.withValues(alpha: 0.2),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Stack(
        children: [
          Center(
            child: Container(width: 1.5, height: size * 1.2, color: TamaColors.warmGray),
          ),
          Center(
            child: Container(width: size, height: 1.5, color: TamaColors.warmGray),
          ),
          // Sun / moon
          Positioned(
            top: 3,
            left: 3,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: mood == RhinoMood.sad
                    ? Colors.white.withValues(alpha: 0.8)
                    : TamaColors.sunYellow,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TinyPlant extends StatelessWidget {
  const _TinyPlant({required this.size});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size * 1.4,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Pot
          Positioned(
            bottom: 0,
            child: Container(
              width: size * 0.7,
              height: size * 0.5,
              decoration: BoxDecoration(
                color: const Color(0xFFD4845A),
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Leaves
          Positioned(
            bottom: size * 0.35,
            child: Container(
              width: size * 0.5,
              height: size * 0.6,
              decoration: BoxDecoration(
                color: TamaColors.mintGreen,
                borderRadius: BorderRadius.circular(size * 0.25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Score Badge ───

class _ScoreBadge extends StatelessWidget {
  const _ScoreBadge({required this.score, required this.size});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isSmall = size <= 200;
    return Center(
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 8 : 10,
          vertical: isSmall ? 3 : 4,
        ),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: TamaColors.tinderGradient),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: TamaColors.hotPink.withValues(alpha: 0.35),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star_rounded,
              size: isSmall ? 12 : 14,
              color: TamaColors.sunYellow,
            ),
            const SizedBox(width: 2),
            Text(
              '$score',
              style: TextStyle(
                fontSize: isSmall ? 13 : 15,
                fontWeight: FontWeight.w900,
                color: Colors.white,
              ),
            ),
            Text(
              'pt',
              style: TextStyle(
                fontSize: isSmall ? 8 : 9,
                color: Colors.white.withValues(alpha: 0.85),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Pet ───

class _Pet extends StatelessWidget {
  const _Pet({
    required this.state,
    required this.size,
    required this.showHeart,
    required this.heartAnimation,
  });

  final RhinoState state;
  final double size;
  final bool showHeart;
  final Animation<double> heartAnimation;

  @override
  Widget build(BuildContext context) {
    final petSize = size * 0.34;
    return Center(
      child: SizedBox(
        width: petSize,
        height: petSize,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // Outfit glow ring
            if (state.outfit != RhinoOutfit.none)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: state.outfit.color.withValues(alpha: 0.35),
                        blurRadius: 20,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            // Shadow
            Positioned(
              bottom: -3,
              left: petSize * 0.2,
              right: petSize * 0.2,
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            // Image
            Positioned.fill(
              child: Image.asset(
                state.mood == RhinoMood.sad
                    ? 'assets/images/sai_baby_short.png'
                    : 'assets/images/sai_baby_middle.png',
                fit: BoxFit.contain,
              ),
            ),
            // Heart pop
            if (showHeart)
              Positioned(
                top: -14,
                right: -6,
                child: AnimatedBuilder(
                  animation: heartAnimation,
                  builder: (_, _) => Opacity(
                    opacity: (1 - heartAnimation.value).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -24 * heartAnimation.value),
                      child: const Text('❤️', style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─── Fullness Bar ───

class _FullnessBar extends StatelessWidget {
  const _FullnessBar({required this.fullness, required this.size});

  final int fullness;
  final double size;

  @override
  Widget build(BuildContext context) {
    final isSmall = size <= 200;
    final barGradient = fullness > 50
        ? [TamaColors.mintGreen, const Color(0xFF2ECC71)]
        : fullness > 25
            ? [TamaColors.sunYellow, TamaColors.warmOrange]
            : [TamaColors.peach, TamaColors.hotPink];

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'げんき',
              style: TextStyle(
                fontSize: isSmall ? 7 : 8,
                color: TamaColors.darkBrown.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              '$fullness%',
              style: TextStyle(
                fontSize: isSmall ? 7 : 8,
                color: TamaColors.darkBrown.withValues(alpha: 0.7),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Container(
          height: isSmall ? 6 : 7,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 0.5,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fullness / 100,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: barGradient),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Action Button (Tinder-style rounded gradient) ───

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.gradient,
    required this.enabled,
    required this.onTap,
    required this.size,
  });

  final IconData icon;
  final String label;
  final List<Color> gradient;
  final bool enabled;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final btnSize = size <= 200 ? 26.0 : 30.0;
    final fontSize = size <= 200 ? 6.5 : 7.5;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.35,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: btnSize,
              height: btnSize,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: gradient.first.withValues(alpha: 0.4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(icon, size: btnSize * 0.48, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.w700,
                color: TamaColors.darkBrown.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Data models (unchanged logic) ───

enum RhinoMood {
  happy('楽しそう', '集中できていて上機嫌'),
  calm('ふつう', '落ち着いて見守り中'),
  sad('泣きそう', '使いすぎでしょんぼり');

  const RhinoMood(this.label, this.detail);
  final String label;
  final String detail;
}

enum RhinoOutfit {
  none('そのまま', Colors.blueGrey),
  cape('ケープ', Color(0xFF8F87F1)),
  bow('リボン', Color(0xFFEF7AA1)),
  raincoat('レイン', Color(0xFF6BCBFF));

  const RhinoOutfit(this.label, this.color);
  final String label;
  final Color color;
}

class RhinoState {
  const RhinoState({
    required this.focusScore,
    required this.usageMinutes,
    required this.fullness,
    required this.mood,
    required this.outfit,
    required this.lastSyncLabel,
  });

  final int focusScore;
  final int usageMinutes;
  final int fullness;
  final RhinoMood mood;
  final RhinoOutfit outfit;
  final String lastSyncLabel;

  RhinoState copyWith({
    int? focusScore,
    int? usageMinutes,
    int? fullness,
    RhinoMood? mood,
    RhinoOutfit? outfit,
    String? lastSyncLabel,
  }) {
    return RhinoState(
      focusScore: focusScore ?? this.focusScore,
      usageMinutes: usageMinutes ?? this.usageMinutes,
      fullness: fullness ?? this.fullness,
      mood: mood ?? this.mood,
      outfit: outfit ?? this.outfit,
      lastSyncLabel: lastSyncLabel ?? this.lastSyncLabel,
    );
  }
}

class RhinoStore {
  RhinoStore(this._prefs);
  final SharedPreferences _prefs;

  static const _scoreKey = 'score';
  static const _usageKey = 'usage_minutes';
  static const _fullnessKey = 'fullness';
  static const _outfitKey = 'outfit';
  static const _syncKey = 'sync';
  static const feedCost = 12;

  RhinoState load() {
    final score = _prefs.getInt(_scoreKey) ?? 72;
    final usage = _prefs.getInt(_usageKey) ?? 94;
    final fullness = _prefs.getInt(_fullnessKey) ?? 66;
    final outfit = RhinoOutfit.values.byName(
      _prefs.getString(_outfitKey) ?? RhinoOutfit.cape.name,
    );
    final sync = _prefs.getString(_syncKey) ?? 'phone sync 17:00';

    return RhinoState(
      focusScore: score,
      usageMinutes: usage,
      fullness: fullness,
      mood: _deriveMood(score: score, usageMinutes: usage, fullness: fullness),
      outfit: outfit,
      lastSyncLabel: sync,
    );
  }

  RhinoState feed(RhinoState current) {
    if (current.focusScore < feedCost) return current;
    final nextScore = (current.focusScore - feedCost).clamp(0, 100);
    final nextFullness = (current.fullness + 18).clamp(0, 100);
    final updated = current.copyWith(
      focusScore: nextScore,
      fullness: nextFullness,
      mood: _deriveMood(
        score: nextScore,
        usageMinutes: current.usageMinutes,
        fullness: nextFullness,
      ),
      lastSyncLabel: 'watch feed now',
    );
    _save(updated);
    return updated;
  }

  RhinoState applyOutfit(RhinoState current, RhinoOutfit outfit) {
    final updated = current.copyWith(
      outfit: outfit,
      lastSyncLabel: 'watch outfit now',
    );
    _save(updated);
    return updated;
  }

  RhinoState updateFromPhone(
    RhinoState current, {
    required int focusScore,
    required int usageMinutes,
    required int fullness,
  }) {
    final updated = current.copyWith(
      focusScore: focusScore,
      usageMinutes: usageMinutes,
      fullness: fullness,
      mood: _deriveMood(
        score: focusScore,
        usageMinutes: usageMinutes,
        fullness: fullness,
      ),
      lastSyncLabel: 'phone sync now',
    );
    _save(updated);
    return updated;
  }

  void _save(RhinoState state) {
    _prefs
      ..setInt(_scoreKey, state.focusScore)
      ..setInt(_usageKey, state.usageMinutes)
      ..setInt(_fullnessKey, state.fullness)
      ..setString(_outfitKey, state.outfit.name)
      ..setString(_syncKey, state.lastSyncLabel);
  }

  RhinoMood _deriveMood({
    required int score,
    required int usageMinutes,
    required int fullness,
  }) {
    final balance = score + fullness - (usageMinutes ~/ 3);
    if (balance >= 85) return RhinoMood.happy;
    if (balance >= 45) return RhinoMood.calm;
    return RhinoMood.sad;
  }
}
