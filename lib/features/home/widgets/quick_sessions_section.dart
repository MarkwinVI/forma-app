import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/polished.dart';
import '../quick_sessions.dart';
import 'session_photo.dart';

/// "Quick sessions" under the program card: a quiet header and a row of photo tiles a fraction of the card's height,
/// so the program stays the main thing on the tab.
class QuickSessionsSection extends StatelessWidget {
  final List<QuickSession> sessions;
  final ValueChanged<QuickSession> onOpen;
  final VoidCallback onSeeAll;

  const QuickSessionsSection({
    super.key,
    required this.sessions,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Text(
                  'Quick sessions',
                  style: TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.28,
                  ),
                ),
              ),
              Pressable(
                onTap: onSeeAll,
                semanticLabel: 'See all sessions',
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.accentPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 150,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: sessions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) => _SessionTile(
              session: sessions[index],
              onTap: () => onOpen(sessions[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _SessionTile extends StatelessWidget {
  final QuickSession session;
  final VoidCallback onTap;

  const _SessionTile({required this.session, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: '${session.name}, ${session.minutes} minutes',
      child: SizedBox(
        width: 132,
        child: SessionPhoto(
          image: session.image,
          focusY: session.imageFocusY,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(9),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PhotoPill(session.durationLabel),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(2, 0, 2, 2),
                  child: Text(
                    session.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.15,
                      height: 1.12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
