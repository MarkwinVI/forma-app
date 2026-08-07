import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../home/home_dashboard_metrics.dart';
import 'skill_wheel.dart';
import 'skill_wheel_panels.dart';

/// The whole Progress-tab wheel screen: header, the radial wheel, and the
/// panel below it — MY PERFORMANCE on the overview (draggable up to cover
/// the wheel), the focused exercise card otherwise.
class SkillWheelScreen extends StatefulWidget {
  final List<WheelFamily> families;
  final Map<String, JourneySkillProgressData> journeyByCategory;
  final void Function(WheelNode node) onOpenExercise;

  const SkillWheelScreen({
    super.key,
    required this.families,
    this.journeyByCategory = const {},
    required this.onOpenExercise,
  });

  @override
  State<SkillWheelScreen> createState() => _SkillWheelScreenState();
}

class _SkillWheelScreenState extends State<SkillWheelScreen> {
  final _wheelController = SkillWheelController();

  int? _sel;
  int _focus = 0;
  double _edgeDragDx = 0;

  @override
  void didUpdateWidget(covariant SkillWheelScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_sel != null && _sel! >= widget.families.length) {
      _sel = null;
      _focus = 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final family = _sel == null ? null : widget.families[_sel!];
    final bottomInset = MediaQuery.of(context).padding.bottom + 78;

    return LayoutBuilder(
      builder: (context, constraints) {
        // Where the performance sheet rests: just under the wheel band. The
        // header height mirrors the compact header row below; the band
        // height is the wheel's overview framing scaled to width.
        const headerHeight = 51.0;
        final bandHeight =
            SkillWheel.overviewBandHeight * constraints.maxWidth / 400;
        final minFraction =
            (1 - (headerHeight + bandHeight) / constraints.maxHeight)
                .clamp(0.15, 0.9);

        return Stack(
          fit: StackFit.expand,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Compact header: one row pinned at the very top, so the
                // wheel below gets the vertical room. The focused view takes
                // extra breathing room under the title.
                Padding(
                  padding:
                      EdgeInsets.fromLTRB(22, 10, 22, _sel == null ? 6 : 18),
                  child: SizedBox(
                    height: 35,
                    child: Row(
                      children: [
                        if (_sel != null)
                          GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _wheelController.back,
                            child: const Padding(
                              padding: EdgeInsets.only(right: 10),
                              child: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 22,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        Expanded(
                          child: Text(
                            family?.title ?? 'Skill Trees',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 30,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.9,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Natural height where there is room, shrunk to fit where
                // there is not — the panel below always keeps a share.
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: constraints.maxHeight * 0.62,
                  ),
                  child: SkillWheel(
                    families: widget.families,
                    controller: _wheelController,
                    onChanged: (sel, focus) => setState(() {
                      _sel = sel;
                      _focus = focus;
                    }),
                  ),
                ),
                Expanded(
                  child: family == null
                      ? const SizedBox.shrink()
                      : DecoratedBox(
                          decoration: const BoxDecoration(
                            border: Border(
                              top: BorderSide(color: AppColors.divider),
                            ),
                          ),
                          child: WheelExerciseCard(
                            family: family,
                            focus: _focus,
                            journey:
                                widget.journeyByCategory[family.categoryId],
                            bottomInset: bottomInset,
                            onOpenExercise: widget.onOpenExercise,
                            onPickStep: (flatIndex) =>
                                _wheelController.goTo(_sel!, flatIndex),
                            onDismiss: _wheelController.back,
                          ),
                        ),
                ),
              ],
            ),
            // The system-style back swipe: a rightward drag starting at the
            // screen's left edge pulls out of the focused tree. Taps pass
            // through, so the back arrow underneath keeps working.
            if (family != null)
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                width: 28,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onHorizontalDragStart: (_) => _edgeDragDx = 0,
                  onHorizontalDragUpdate: (d) => _edgeDragDx += d.delta.dx,
                  onHorizontalDragEnd: (_) {
                    if (_edgeDragDx > 50) _wheelController.back();
                  },
                ),
              ),
            // MY PERFORMANCE rides in a sheet: resting just under the wheel,
            // draggable up to snap over it at the top of the page, and back
            // down to the resting view.
            if (family == null)
              DraggableScrollableSheet(
                initialChildSize: minFraction,
                minChildSize: minFraction,
                maxChildSize: 1.0,
                snap: true,
                builder: (context, scrollController) => DecoratedBox(
                  decoration: const BoxDecoration(
                    color: AppColors.bg,
                    border: Border(
                      top: BorderSide(color: AppColors.divider),
                    ),
                  ),
                  child: PerformancePanel(
                    controller: scrollController,
                    bottomInset: bottomInset,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
