import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/app_constants.dart';
import '../providers/app_providers.dart';
import '../main.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _goalController = TextEditingController();
  int _selectedGoalMinutes = 30;

  @override
  void dispose() {
    _nameController.dispose();
    _goalController.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;

    ref.read(userNameProvider.notifier).setName(_nameController.text.trim());
    ref.read(userGoalProvider.notifier).setGoal(
      _goalController.text.trim().isEmpty
          ? '1日のSNS使用を${_selectedGoalMinutes}分以内に抑える'
          : _goalController.text.trim(),
    );
    ref.read(timeLimitProvider.notifier).setLimit(_selectedGoalMinutes);

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainNavigation()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ヘッダー
                  const Text('🦏', style: TextStyle(fontSize: 56), textAlign: TextAlign.center),
                  const SizedBox(height: 12),
                  Text(
                    'プロフィール設定',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? accentColor : primaryColor,
                        ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'あなたについて教えてください',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white60 : Colors.black54,
                        ),
                  ),
                  const SizedBox(height: 36),

                  // ユーザー名
                  Text(
                    'ユーザー名',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: '例：サイ太郎',
                      filled: true,
                      fillColor: isDark ? darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor.withAlpha(100)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor.withAlpha(80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Icon(Icons.person_outline, color: primaryColor),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'ユーザー名を入力してください' : null,
                  ),
                  const SizedBox(height: 28),

                  // 目標時間
                  Text(
                    'SNS使用時間の目標',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? darkCard : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: accentColor.withAlpha(80)),
                    ),
                    child: Column(
                      children: [
                        Text(
                          '1日 $_selectedGoalMinutes 分以内',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Slider(
                          value: _selectedGoalMinutes.toDouble(),
                          min: 10,
                          max: 180,
                          divisions: 17,
                          label: '$_selectedGoalMinutes分',
                          activeColor: primaryColor,
                          inactiveColor: accentColor.withAlpha(60),
                          onChanged: (v) =>
                              setState(() => _selectedGoalMinutes = v.round()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('10分', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                            Text('180分', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : Colors.black45)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // 自由目標入力
                  Text(
                    '目標メモ（任意）',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _goalController,
                    maxLines: 2,
                    decoration: InputDecoration(
                      hintText: '例：寝る前のSNSをやめる！',
                      filled: true,
                      fillColor: isDark ? darkCard : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor.withAlpha(100)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: accentColor.withAlpha(80)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: primaryColor, width: 2),
                      ),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Icon(Icons.flag_outlined, color: primaryColor),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // 開始ボタン
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 2,
                      ),
                      child: const Text(
                        'はじめる 🦏',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
