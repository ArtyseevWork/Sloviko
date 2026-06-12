import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../core/di/providers.dart';
import '../../../core/icons/detto_icon.dart';
import '../../../core/locale/app_locale.dart';
import '../../../core/locale/native_lang.dart';
import '../../../core/router/go.dart';
import '../../../core/settings/cefr_levels.dart';
import '../../../core/settings/daily_goal.dart';
import '../../../core/theme/theme_provider.dart';
import '../../quiz/provider/quiz_notifier.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(8.w, 6.h, 16.w, 6.h),
              child: Row(
                children: [
                  _IconBtn(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Go.back(context),
                  ),
                  SizedBox(width: 8.w),
                  Expanded(
                    child: Text(
                      AppLocale.text('settings_title'),
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: c.text,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: EdgeInsets.fromLTRB(14.w, 8.h, 14.w, 24.h),
                children: const [
                  _SectionLanguage(),
                  SizedBox(height: 10),
                  _SectionTheme(),
                  SizedBox(height: 10),
                  _SectionLevels(),
                  SizedBox(height: 10),
                  _SectionGoal(),
                  SizedBox(height: 10),
                  _SectionUpdate(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLanguage extends ConsumerWidget {
  const _SectionLanguage();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final lang = ref.watch(nativeLangProvider);
    return _Card(
      title: AppLocale.text('settings_native_lang'),
      child: Row(
        children: [
          for (final code in NativeLangNotifier.supported) ...[
            Expanded(
              child: _PillButton(
                label: AppLocale.text('lang_$code'),
                active: lang.code == code,
                onTap: () => lang.set(code),
              ),
            ),
            if (code != NativeLangNotifier.supported.last) SizedBox(width: 8.w),
          ],
        ],
      ),
      footer: Text(
        AppLocale.text('settings_native_lang_hint'),
        style: TextStyle(fontSize: 12.sp, color: c.textSub),
      ),
    );
  }
}

class _SectionTheme extends ConsumerWidget {
  const _SectionTheme();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(dettoThemeProvider);
    return _Card(
      title: AppLocale.text('settings_theme'),
      child: Row(
        children: [
          Expanded(
            child: _PillButton(
              label: AppLocale.text('theme_light'),
              active: theme.themeMode == ThemeMode.light,
              onTap: () => theme.setMode(ThemeMode.light),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _PillButton(
              label: AppLocale.text('theme_system'),
              active: theme.themeMode == ThemeMode.system,
              onTap: () => theme.setMode(ThemeMode.system),
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: _PillButton(
              label: AppLocale.text('theme_dark'),
              active: theme.themeMode == ThemeMode.dark,
              onTap: () => theme.setMode(ThemeMode.dark),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLevels extends ConsumerWidget {
  const _SectionLevels();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final levels = ref.watch(cefrLevelsProvider);
    return _Card(
      title: AppLocale.text('settings_levels'),
      child: Wrap(
        spacing: 8.w,
        runSpacing: 8.h,
        children: [
          for (final lvl in CefrLevelsNotifier.all)
            _PillButton(
              label: lvl,
              active: levels.isActive(lvl),
              onTap: () => levels.toggle(lvl),
              compact: true,
            ),
        ],
      ),
      footer: Text(
        AppLocale.text('settings_levels_hint'),
        style: TextStyle(fontSize: 12.sp, color: c.textSub),
      ),
    );
  }
}

class _SectionGoal extends ConsumerWidget {
  const _SectionGoal();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final goal = ref.watch(dailyGoalProvider);
    return _Card(
      title: AppLocale.text('settings_goal'),
      child: Row(
        children: [
          _StepperBtn(
            icon: Icons.remove_rounded,
            onTap: goal.goal > DailyGoalNotifier.min ? goal.decrement : null,
          ),
          Expanded(
            child: Center(
              child: Text(
                '${goal.goal}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: c.text,
                ),
              ),
            ),
          ),
          _StepperBtn(
            icon: Icons.add_rounded,
            onTap: goal.goal < DailyGoalNotifier.max ? goal.increment : null,
          ),
        ],
      ),
      footer: Text(
        AppLocale.text('settings_goal_hint'),
        style: TextStyle(fontSize: 12.sp, color: c.textSub),
      ),
    );
  }
}

class _StepperBtn extends ConsumerWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _StepperBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: enabled ? 1.0 : 0.4,
        child: Container(
          width: 44.w,
          height: 44.w,
          decoration: BoxDecoration(
            color: c.bg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: c.border),
          ),
          child: Center(
            child: DettoIcon(icon, size: 20.sp, color: c.text),
          ),
        ),
      ),
    );
  }
}

enum _LoadResult { idle, loading, success, nothing }

class _SectionUpdate extends ConsumerStatefulWidget {
  const _SectionUpdate();

  @override
  ConsumerState<_SectionUpdate> createState() => _SectionUpdateState();
}

class _SectionUpdateState extends ConsumerState<_SectionUpdate> {
  _LoadResult _state = _LoadResult.idle;

  Future<void> _loadMore() async {
    if (_state == _LoadResult.loading) return;
    setState(() => _state = _LoadResult.loading);
    final levels = ref.read(cefrLevelsProvider).levels;
    final ok = await ref.read(loadNextBatchProvider).call(levels, force: true);
    if (!mounted) return;
    setState(() => _state = ok ? _LoadResult.success : _LoadResult.nothing);
    if (ok) {
      // Refresh the quiz so freshly loaded words are mixed into rotation.
      await ref.read(quizNotifierProvider).reload();
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    String labelKey;
    switch (_state) {
      case _LoadResult.idle:
        labelKey = 'settings_load_more';
        break;
      case _LoadResult.loading:
        labelKey = 'settings_load_in_progress';
        break;
      case _LoadResult.success:
        labelKey = 'settings_load_done';
        break;
      case _LoadResult.nothing:
        labelKey = 'settings_load_nothing';
        break;
    }
    return _Card(
      title: AppLocale.text('settings_update'),
      child: GestureDetector(
        onTap: _state == _LoadResult.loading ? null : _loadMore,
        child: Container(
          height: 48.h,
          decoration: BoxDecoration(
            color: c.accentBg,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(color: c.accent, width: 1.5),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_state == _LoadResult.loading) ...[
                SizedBox(
                  width: 16.w,
                  height: 16.w,
                  child: CircularProgressIndicator(strokeWidth: 2, color: c.accentTxt),
                ),
                SizedBox(width: 10.w),
              ] else ...[
                DettoIcon(Icons.cloud_download_outlined, size: 16.sp, color: c.accentTxt),
                SizedBox(width: 8.w),
              ],
              Text(
                AppLocale.text(labelKey),
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: c.accentTxt,
                ),
              ),
            ],
          ),
        ),
      ),
      footer: Text(
        AppLocale.text('settings_update_hint'),
        style: TextStyle(fontSize: 12.sp, color: c.textSub),
      ),
    );
  }
}

class _Card extends ConsumerWidget {
  final String title;
  final Widget child;
  final Widget? footer;
  const _Card({required this.title, required this.child, this.footer});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: c.surface,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.5,
              color: c.textSub,
            ),
          ),
          SizedBox(height: 12.h),
          child,
          if (footer != null) ...[
            SizedBox(height: 10.h),
            footer!,
          ],
        ],
      ),
    );
  }
}

class _PillButton extends ConsumerWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  final bool compact;
  const _PillButton({
    required this.label,
    required this.active,
    required this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40.h,
        padding: EdgeInsets.symmetric(horizontal: compact ? 18.w : 12.w),
        decoration: BoxDecoration(
          color: active ? c.accentBg : c.bg,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: active ? c.accent : c.border,
            width: active ? 1.5 : 1,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: active ? c.accentTxt : c.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _IconBtn extends ConsumerWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _IconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = ref.watch(dettoThemeProvider).palette(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36.w,
        height: 36.w,
        decoration: BoxDecoration(
          color: c.surface,
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: c.border),
        ),
        child: Center(child: DettoIcon(icon, size: 18.sp, color: c.textSub)),
      ),
    );
  }
}
