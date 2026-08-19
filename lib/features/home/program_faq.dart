import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/polished.dart';

/// One block of a FAQ answer: a paragraph, or a bulleted list.
class FaqBlock {
  final String? paragraph;
  final List<String> bullets;

  const FaqBlock(this.paragraph) : bullets = const [];
  const FaqBlock.bullets(this.bullets) : paragraph = null;
}

class FaqItem {
  final String question;
  final List<FaqBlock> answer;

  const FaqItem({required this.question, required this.answer});
}

/// "About the program" — the questions the program raises, answered in full
/// only when one is opened.
const List<FaqItem> kProgramFaq = [
  FaqItem(
    question: 'Which workout split should I choose?',
    answer: [
      FaqBlock(
        'Full Body is the best default for most beginners. It lets you train '
        'each movement frequently while still leaving enough time to recover.',
      ),
      FaqBlock(
        'Push/Pull and Upper/Lower can also work well if you prefer shorter '
        'workouts or want to train 4 or more days per week.',
      ),
    ],
  ),
  FaqItem(
    question: 'How many days per week should I train?',
    answer: [
      FaqBlock('3 days per week is a strong default for Full Body.'),
      FaqBlock(
        'For Push/Pull or Upper/Lower, 4 days per week usually creates a more '
        'balanced schedule, with each part of the split trained twice per '
        'week.',
      ),
    ],
  ),
  kHowTargetsAreSetFaq,
  FaqItem(
    question: 'What are accessory exercises?',
    answer: [
      FaqBlock(
        'Accessories are exercises that sit outside your skill trees and '
        'supplement your main calisthenics progressions.',
      ),
      FaqBlock(
        'They can be added automatically by Forma or added manually to your '
        'workouts.',
      ),
      FaqBlock(
        'Accessories don’t progress to a different exercise, but you can '
        'enable Auto progression to automatically increase reps and weight '
        'over time.',
      ),
    ],
  ),
  FaqItem(
    question: 'How does Auto progression work for accessories?',
    answer: [
      FaqBlock(
        'With Auto progression enabled, Forma gradually increases your target '
        'from 3×6 to 3×8.',
      ),
      FaqBlock(
        'Once you complete 3×8, Forma increases the weight to the next load '
        'your equipment can make and starts again at 3×6.',
      ),
      FaqBlock(
        'The weight you type in a workout becomes the new starting point, so '
        'you can set an appropriate weight the first time you train an '
        'exercise. Auto progression stays on.',
      ),
    ],
  ),
  FaqItem(
    question: 'Can I skip ahead in a skill tree?',
    answer: [
      FaqBlock(
        'Yes. You can start a harder exercise even if you haven’t reached it '
        'normally.',
      ),
      FaqBlock(
        'Only jump ahead if you’re confident you can perform the exercise '
        'with good form.',
      ),
    ],
  ),
];

/// How a target moves — the rule the change feed links to when it reports a
/// raise.
const FaqItem kHowTargetsAreSetFaq = FaqItem(
  question: 'How does progression work?',
  answer: [
    FaqBlock('Exercises in your skill trees progress automatically.'),
    FaqBlock(
      'As you meet the target for your current exercise, Forma gradually '
      'increases the difficulty and eventually moves you to the next exercise '
      'in the progression.',
    ),
    FaqBlock(
      'Accessories can also use Auto progression. When enabled, Forma '
      'increases your reps from 3×6 to 3×8, then increases the weight and '
      'starts again at 3×6.',
    ),
  ],
);

/// Opens one FAQ answer in a bottom sheet.
Future<void> showFaqSheet(BuildContext context, FaqItem item) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.55),
    builder: (_) => FaqSheet(item: item),
  );
}

class FaqSheet extends StatelessWidget {
  final FaqItem item;

  const FaqSheet({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    return SheetShell(
      title: item.question,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final block in item.answer)
              if (block.paragraph != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    block.paragraph!,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.6,
                    ),
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (final bullet in block.bullets)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 6),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 4,
                                height: 4,
                                margin: const EdgeInsets.only(
                                  top: 9,
                                  right: 10,
                                ),
                                decoration: const BoxDecoration(
                                  color: AppColors.surface3,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Color(0xFFC9CAD1),
                                    height: 1.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
