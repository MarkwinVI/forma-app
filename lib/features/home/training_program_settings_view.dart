import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/loading_indicator.dart';
import '../../data/models/training_program_model.dart';

class TrainingProgramSettingsView extends StatefulWidget {
  final TrainingProgramType initialProgramType;
  final Future<void> Function(TrainingProgramType) onSave;

  const TrainingProgramSettingsView({
    super.key,
    required this.initialProgramType,
    required this.onSave,
  });

  @override
  State<TrainingProgramSettingsView> createState() =>
      _TrainingProgramSettingsViewState();
}

class _TrainingProgramSettingsViewState
    extends State<TrainingProgramSettingsView> {
  late TrainingProgramType _selectedProgramType;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProgramType = widget.initialProgramType;
  }

  Future<void> _save() async {
    if (_saving) return;

    setState(() => _saving = true);

    try {
      await widget.onSave(_selectedProgramType);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save program: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSecondary,
      appBar: AppBar(
        backgroundColor: AppColors.bgSecondary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Text(
          'Edit Program',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                children: [
                  Text(
                    'Training Program Type',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProgramTypeOptionCard(
                    title: 'Full Body',
                    description:
                        'Train your main progressions in the same session.',
                    isSelected:
                        _selectedProgramType == TrainingProgramType.fullBody,
                    onTap: () {
                      setState(
                        () =>
                            _selectedProgramType = TrainingProgramType.fullBody,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProgramTypeOptionCard(
                    title: 'Push / Pull',
                    description:
                        'Alternate between push-focused and pull-focused days.',
                    isSelected:
                        _selectedProgramType == TrainingProgramType.pushPull,
                    onTap: () {
                      setState(
                        () =>
                            _selectedProgramType = TrainingProgramType.pushPull,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _ProgramTypeOptionCard(
                    title: 'Upper / Lower',
                    description:
                        'Alternate upper-body sessions with lower-body sessions.',
                    isSelected:
                        _selectedProgramType == TrainingProgramType.upperLower,
                    onTap: () {
                      setState(
                        () => _selectedProgramType =
                            TrainingProgramType.upperLower,
                      );
                    },
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    minimumSize: const Size.fromHeight(56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(25),
                    ),
                  ),
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: LoadingIndicator(),
                        )
                      : Text(
                          'Save',
                          style: GoogleFonts.inter(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                            letterSpacing: -0.425,
                          ),
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

class _ProgramTypeOptionCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;

  const _ProgramTypeOptionCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.bgTertiary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color:
                isSelected ? AppColors.accentPrimary : AppColors.borderPrimary,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected
                      ? AppColors.accentPrimary
                      : AppColors.textMuted,
                  width: 2,
                ),
                color:
                    isSelected ? AppColors.accentPrimary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
