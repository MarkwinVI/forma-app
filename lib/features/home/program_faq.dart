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
    question: 'Why does my program include different movement categories?',
    answer: [
      FaqBlock(
        'Forma builds balanced strength programs around five primary '
        'categories:',
      ),
      FaqBlock.bullets([
        'Horizontal push',
        'Vertical push',
        'Horizontal pull',
        'Vertical pull',
        'Legs',
      ]),
      FaqBlock(
        'Training every category helps you develop balanced strength and '
        'avoids overemphasising one movement pattern.',
      ),
    ],
  ),
  FaqItem(
    question: 'Why doesn’t every workout train every category?',
    answer: [
      FaqBlock(
        'Your program is evaluated across the complete repeating training '
        'cycle, not just one workout. A full-body session usually includes '
        'one exercise from each category, while split programs distribute '
        'the categories across different days.',
      ),
      FaqBlock(
        'The important thing is that every primary category is covered '
        'regularly across the full program.',
      ),
    ],
  ),
  FaqItem(
    question: 'How much should I train each category?',
    answer: [
      FaqBlock('Forma generally recommends:'),
      FaqBlock.bullets([
        'At least two sessions per week involving each category',
        'At least four blocks per category each week',
        'Around six blocks per category in a standard three-day full-body '
            'program',
      ]),
      FaqBlock(
        'These are guidelines rather than strict requirements. Your program '
        'may differ based on your schedule, goals and current ability.',
      ),
    ],
  ),
  FaqItem(
    question: 'How do I progress to a harder exercise?',
    answer: [
      FaqBlock('For repetition-based exercises, the standard progression is:'),
      FaqBlock('3×5 → 3×6 → 3×7 → 3×8'),
      FaqBlock(
        'Once you complete 3×8 with the required quality, Forma moves you to '
        'the next exercise progression, usually starting again at 3×5.',
      ),
      FaqBlock(
        'For timed holds, you normally progress from 3×10 seconds towards '
        '3×30 seconds before moving to the next progression.',
      ),
    ],
  ),
];

/// Opens one FAQ answer in a bottom sheet.
Future<void> showFaqSheet(BuildContext context, FaqItem item) {
  return showModalBottomSheet<void>(
    context: context,
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
