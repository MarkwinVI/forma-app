import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';
import '../../core/widgets/type_led.dart';
import '../../data/services/analytics_service.dart';
import 'quick_sessions.dart';
import 'widgets/session_photo.dart';

/// Opens a session's intro over the whole screen, above the tab bar.
Future<void> showQuickSessionIntro(
  BuildContext context, {
  required QuickSession session,
  String? plannedToday,
  required String source,
}) {
  AnalyticsService.screen('quick_session_intro');
  AnalyticsService.capture('quick_session_opened', properties: {
    'session': session.id,
    'source': source,
  });
  return Navigator.of(context, rootNavigator: true).push(
    MaterialPageRoute(
      builder: (_) => QuickSessionIntroView(
        session: session,
        plannedToday: plannedToday,
      ),
    ),
  );
}

/// What a quick session is before it is started: how long, how many moves,
/// what it needs, what it does — and a line that says the day's program is
/// untouched by it.
///
/// Starting one is not built yet; the button says so rather than opening
/// something that is not there.
class QuickSessionIntroView extends StatelessWidget {
  final QuickSession session;

  /// The program session still planned for today ("Full Body"), or null on
  /// a rest day or once today's workout is done.
  final String? plannedToday;

  const QuickSessionIntroView({
    super.key,
    required this.session,
    this.plannedToday,
  });

  void _start(BuildContext context) {
    AnalyticsService.capture('quick_session_start_tapped', properties: {
      'session': session.id,
    });
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('Quick sessions are coming soon.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.of(context).padding.top;
    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                SizedBox(
                  height: 278 + topInset,
                  child: SessionPhoto(
                    image: session.image,
                    focusY: session.imageFocusY,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(16, topInset + 12, 16, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Pressable(
                            onTap: () => Navigator.of(context).pop(),
                            semanticLabel: 'Back',
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0x8C0C0D12),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.14),
                                ),
                              ),
                              alignment: Alignment.center,
                              child: const Icon(
                                Icons.chevron_left_rounded,
                                size: 22,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const Spacer(),
                          const Padding(
                            padding: EdgeInsets.only(left: 4),
                            child: PhotoPill('QUICK SESSION'),
                          ),
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
                            child: Text(
                              session.name,
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -1.08,
                                height: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _Stat(
                              value: '${session.minutes} min',
                              label: 'DURATION',
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Stat(
                              value: '${session.moves.length} moves',
                              label: session.pacing,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _Stat(
                              value: session.equipment,
                              label: 'EQUIPMENT',
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: Text(
                          session.description,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: Color(0xFFC9CAD2),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 18, bottom: 2),
                        child: Text(
                          'WHAT YOU’LL DO',
                          style: monoStyle(size: 11, letterSpacing: 1.76),
                        ),
                      ),
                      for (var i = 0; i < session.moves.length; i++)
                        _MoveRow(
                          index: i + 1,
                          move: session.moves[i],
                          last: i == session.moves.length - 1,
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.accentSoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 1),
                  child: Icon(
                    Icons.info_outline_rounded,
                    size: 16,
                    color: Color(0xFF7FA0FF),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      children: [
                        const TextSpan(text: 'An extra, not a replacement. '),
                        TextSpan(
                          text: plannedToday == null
                              ? 'Your program stays as planned.'
                              : '$plannedToday stays planned for today.',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    style: const TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFFC9D6FF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottomInset),
            child: Pressable(
              onTap: () => _start(context),
              semanticLabel: 'Start session, ${session.minutes} minutes',
              child: Container(
                constraints: const BoxConstraints(minHeight: 54),
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  // White, not blue: blue is the program's.
                  color: const Color(0xFFF4F5F8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'Start session · ${session.minutes} min',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF08090C),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;

  const _Stat({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 11),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
              letterSpacing: -0.17,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: monoStyle(
                size: 10, weight: FontWeight.w600, letterSpacing: 1.2),
          ),
        ],
      ),
    );
  }
}

class _MoveRow extends StatelessWidget {
  final int index;
  final QuickSessionMove move;
  final bool last;

  const _MoveRow({required this.index, required this.move, required this.last});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$index', style: monoStyle(size: 11, letterSpacing: 0)),
          ),
          Expanded(
            child: Text(
              move.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            move.amount,
            style: monoStyle(
              size: 11.5,
              weight: FontWeight.w600,
              letterSpacing: 0.7,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
