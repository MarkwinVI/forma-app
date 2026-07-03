import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/widgets/loading_indicator.dart';
import '../../data/catalog/exercise_catalog.dart';
import '../../data/catalog/skill_category_catalog.dart';
import '../../data/models/exercise_model.dart';
import '../../data/models/skill_category_model.dart';
import '../../data/models/training_program_model.dart';
import '../../data/services/training_program_service.dart';
import '../exercises/exercise_detail_view.dart';
import 'exercise_switch_selector.dart';

const _bg = Color(0xFF000000);
const _group = Color(0xFF1C1C1E);
const _sep = Color(0x14FFFFFF);
const _text = Color(0xFFF2F2F7);
const _text2 = Color(0xFF8E8E93);
const _text3 = Color(0xFF636366);
const _accent = Color(0xFFD4FF3A);
const _accentDim = Color(0x2ED4FF3A);
const _blue = Color(0xFF0A84FF);
const _red = Color(0xFFFF453A);
const _warm = Color(0xFF64D2FF);
const _skill = Color(0xFFBF5AF2);

class TrainingProgramLogicView extends StatefulWidget {
  final TrainingProgramLogicSnapshot initialLogic;
  final Map<String, ExerciseStatus> progressMap;
  final Future<void> Function({
    required TrainingProgramType programType,
    required Map<TrainingTrack, String> branchSelections,
    required RepGoalProfile repGoalProfile,
    required Map<String, dynamic> sessionItemsConfig,
  }) onSave;

  const TrainingProgramLogicView({
    super.key,
    required this.initialLogic,
    required this.progressMap,
    required this.onSave,
  });

  @override
  State<TrainingProgramLogicView> createState() =>
      _TrainingProgramLogicViewState();
}

class _TrainingProgramLogicViewState extends State<TrainingProgramLogicView> {
  final _programService = TrainingProgramService();

  late TrainingProgramType _selectedProgramType;
  late Map<TrainingTrack, String> _selectedBranches;
  late RepGoalProfile _repGoalProfile;
  late Map<TrainingSessionType, _SessionComponent?> _expandedSessionComponents;
  late Map<TrainingSessionType,
      Map<_SessionComponent, List<_EditableSessionItem>>> _sessionItems;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedProgramType = widget.initialLogic.program.programType;
    _selectedBranches = {
      ..._programService.defaultBranchSelections(),
      ...widget.initialLogic.branchSelections,
    };
    _repGoalProfile = widget.initialLogic.repGoalProfile;
    _expandedSessionComponents = _defaultExpandedSessionComponents(
      _selectedProgramType,
    );
    _sessionItems = _buildInitialSessionItems(_selectedProgramType);
  }

  Map<TrainingTrack, TrainingBranchOption> get _resolvedBranches =>
      _programService.resolveSelectedBranches(_selectedBranches);

  List<TrainingTrack> get _strengthTracks => _programService
      .editableTracksForProgramType(_selectedProgramType)
      .where((track) => track != TrainingTrack.skillWork)
      .toList();

  Future<void> _save() async {
    if (_saving) return;
    setState(() => _saving = true);

    try {
      await widget.onSave(
        programType: _selectedProgramType,
        branchSelections: _selectedBranches,
        repGoalProfile: _repGoalProfile,
        sessionItemsConfig: _serializeSessionItems(),
      );
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save program logic: $error')),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final split = _selectedProgramType;
    final repGoal = _repGoalProfile;
    final sessionBlocks = _buildSessionBlocks();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: _accent,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: LoadingIndicator(),
                  )
                : const Text(
                    'Save',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: _accent,
                    ),
                  ),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Program',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -1.1,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _programTitle(split),
                      style: const TextStyle(
                        fontSize: 15,
                        color: _text2,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const _SectionLabel(text: 'Program'),
                    _SettingsGroup(
                      footer:
                          'Picks the rhythm of your week and the rep range each track is built around.',
                      children: [
                        _SettingsRow(
                          first: true,
                          icon: Icons.calendar_month_outlined,
                          iconColor: _blue,
                          title: 'Split',
                          value: _splitShort(split),
                          onTap: () => _openSplitScreen(context),
                        ),
                        _SettingsRow(
                          last: true,
                          icon: Icons.adjust_outlined,
                          iconColor: _accent,
                          title: 'Rep Target',
                          value: repGoal.label,
                          onTap: () => _openRepGoalScreen(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    for (var i = 0; i < sessionBlocks.length; i++) ...[
                      if (i > 0) const SizedBox(height: 22),
                      _SectionLabel(text: sessionBlocks[i].title),
                      _SettingsGroup(
                        footer: sessionBlocks[i].footer,
                        children: [
                          _ComponentAccordionRow(
                            title: 'Warm-up',
                            count: '${sessionBlocks[i].warmupItems.length}',
                            expanded: _expandedSessionComponents[
                                    sessionBlocks[i].sessionType] ==
                                _SessionComponent.warmup,
                            accentColor: _warm,
                            onToggle: () => _toggleSessionComponent(
                              sessionBlocks[i].sessionType,
                              _SessionComponent.warmup,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildSessionItemsSection(
                                context: context,
                                items: sessionBlocks[i].warmupItems,
                                sessionType: sessionBlocks[i].sessionType,
                                component: _SessionComponent.warmup,
                                defaultTone: _warm,
                                onItemTap: (item) =>
                                    _exerciseDetailTapHandler(item) ??
                                    () => _openInfoScreen(
                                          context,
                                          title: 'Warm-up',
                                          footer:
                                              'Joint-by-joint prep so the work surfaces are ready. Keep it short and specific.',
                                          rows: [
                                            _StaticRowData(
                                              title: 'Block',
                                              value: sessionBlocks[i].title,
                                            ),
                                            const _StaticRowData(
                                              title: 'Type',
                                              value: 'Built in',
                                            ),
                                            const _StaticRowData(
                                              title: 'Purpose',
                                              value:
                                                  'Prepare shoulders, wrists, hips',
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                          _ComponentAccordionRow(
                            title: 'Skill Work',
                            count: '${sessionBlocks[i].skillItems.length}',
                            expanded: _expandedSessionComponents[
                                    sessionBlocks[i].sessionType] ==
                                _SessionComponent.skill,
                            accentColor: _skill,
                            onToggle: () => _toggleSessionComponent(
                              sessionBlocks[i].sessionType,
                              _SessionComponent.skill,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildSessionItemsSection(
                                context: context,
                                items: sessionBlocks[i].skillItems,
                                sessionType: sessionBlocks[i].sessionType,
                                component: _SessionComponent.skill,
                                defaultTone: _skill,
                                onItemTap: _exerciseDetailTapHandler,
                              ),
                            ),
                          ),
                          _ComponentAccordionRow(
                            title: 'Strength',
                            count: '${sessionBlocks[i].strengthItems.length}',
                            expanded: _expandedSessionComponents[
                                    sessionBlocks[i].sessionType] ==
                                _SessionComponent.strength,
                            accentColor: _accent,
                            onToggle: () => _toggleSessionComponent(
                              sessionBlocks[i].sessionType,
                              _SessionComponent.strength,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildSessionItemsSection(
                                context: context,
                                items: sessionBlocks[i].strengthItems,
                                sessionType: sessionBlocks[i].sessionType,
                                component: _SessionComponent.strength,
                                defaultTone: _accent,
                                onItemTap: (item) =>
                                    _exerciseDetailTapHandler(item) ??
                                    () => _openStrengthScreen(context),
                              ),
                            ),
                          ),
                          _ComponentAccordionRow(
                            title: 'Cool-down',
                            count: '${sessionBlocks[i].cooldownItems.length}',
                            expanded: _expandedSessionComponents[
                                    sessionBlocks[i].sessionType] ==
                                _SessionComponent.cooldown,
                            accentColor: _warm,
                            onToggle: () => _toggleSessionComponent(
                              sessionBlocks[i].sessionType,
                              _SessionComponent.cooldown,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                              child: _buildSessionItemsSection(
                                context: context,
                                items: sessionBlocks[i].cooldownItems,
                                sessionType: sessionBlocks[i].sessionType,
                                component: _SessionComponent.cooldown,
                                defaultTone: _warm,
                                onItemTap: (item) =>
                                    _exerciseDetailTapHandler(item) ??
                                    () => _openInfoScreen(
                                          context,
                                          title: 'Cool-down',
                                          footer:
                                              'Down-regulate and lock in whatever mobility the session earned while the tissue is warm.',
                                          rows: [
                                            _StaticRowData(
                                              title: 'Block',
                                              value: sessionBlocks[i].title,
                                            ),
                                            const _StaticRowData(
                                              title: 'Type',
                                              value: 'Built in',
                                            ),
                                            const _StaticRowData(
                                              title: 'Purpose',
                                              value: 'Breathing · Mobility',
                                            ),
                                          ],
                                        ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 22),
                    _SettingsGroup(
                      children: [
                        _SettingsRow(
                          first: true,
                          title: 'Reset to defaults',
                          titleColor: _red,
                          accessory: _RowAccessory.none,
                          onTap: _resetToDefaults,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _programTitle(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full body schedule with one active branch per slot';
      case TrainingProgramType.pushPull:
        return 'Push / pull split with one active branch per slot';
      case TrainingProgramType.upperLower:
        return 'Upper / lower split with one active branch per slot';
    }
  }

  String _splitShort(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full Body';
      case TrainingProgramType.pushPull:
        return 'Push · Pull';
      case TrainingProgramType.upperLower:
        return 'Upper · Lower';
    }
  }

  String _repSub(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return '3–5 sets · 3–8 reps · 2:30–3:30 rest';
      case RepGoalProfile.balanced:
        return '3–4 sets · 6–12 reps · 1:30–2:30 rest';
      case RepGoalProfile.volume:
        return '2–4 sets · 10–20 reps · 0:45–1:30 rest';
    }
  }

  Map<TrainingSessionType, _SessionComponent?>
      _defaultExpandedSessionComponents(
    TrainingProgramType programType,
  ) {
    return {
      for (final sessionType
          in _programService.trainingDaysForProgramType(programType))
        sessionType: null,
    };
  }

  void _toggleSessionComponent(
    TrainingSessionType sessionType,
    _SessionComponent component,
  ) {
    setState(() {
      final current = _expandedSessionComponents[sessionType];
      _expandedSessionComponents[sessionType] =
          current == component ? null : component;
    });
  }

  List<_ProgramSessionBlock> _buildSessionBlocks() {
    final blocks = <_ProgramSessionBlock>[];

    for (final sessionType
        in _programService.trainingDaysForProgramType(_selectedProgramType)) {
      final itemsForSession = _sessionItems[sessionType] ??
          const <_SessionComponent, List<_EditableSessionItem>>{};

      blocks.add(
        _ProgramSessionBlock(
          sessionType: sessionType,
          title: _sessionBlockTitle(sessionType),
          warmupItems: List<_EditableSessionItem>.from(
            itemsForSession[_SessionComponent.warmup] ?? const [],
          ),
          skillItems: List<_EditableSessionItem>.from(
            itemsForSession[_SessionComponent.skill] ?? const [],
          ),
          strengthItems: List<_EditableSessionItem>.from(
            itemsForSession[_SessionComponent.strength] ?? const [],
          ),
          cooldownItems: List<_EditableSessionItem>.from(
            itemsForSession[_SessionComponent.cooldown] ?? const [],
          ),
          footer: _sessionBlockFooter(sessionType),
        ),
      );
    }

    return blocks;
  }

  Map<TrainingSessionType, Map<_SessionComponent, List<_EditableSessionItem>>>
      _buildInitialSessionItems(TrainingProgramType programType) {
    final savedConfig = _savedSessionItemsConfig();
    if (savedConfig.isEmpty) {
      return _buildDefaultSessionItems(programType);
    }

    final sessionItems = <TrainingSessionType,
        Map<_SessionComponent, List<_EditableSessionItem>>>{};
    final defaultItems = _buildDefaultSessionItems(programType);

    for (final sessionType
        in _programService.trainingDaysForProgramType(programType)) {
      final rawSession = savedConfig[sessionType.dbValue];
      if (rawSession is! Map) {
        sessionItems[sessionType] = defaultItems[sessionType]!;
        continue;
      }

      final sessionMap = Map<String, dynamic>.from(rawSession);
      sessionItems[sessionType] = {
        for (final component in _SessionComponent.values)
          component: _deserializeSessionItemsForComponent(
            sessionMap[_sessionComponentKey(component)],
          ),
      };
    }

    return sessionItems;
  }

  Map<TrainingSessionType, Map<_SessionComponent, List<_EditableSessionItem>>>
      _buildDefaultSessionItems(TrainingProgramType programType) {
    final items = <TrainingSessionType,
        Map<_SessionComponent, List<_EditableSessionItem>>>{};
    final skillOption = _resolvedBranches[TrainingTrack.skillWork]!;
    final skillExercise = _programService.currentExerciseForOption(
      skillOption,
      widget.progressMap,
    );

    for (final sessionType
        in _programService.trainingDaysForProgramType(programType)) {
      final recommendation = _programService.buildToday(
        progressMap: widget.progressMap,
        programType: programType,
        sessionType: sessionType,
        branchSelections: _selectedBranches,
      );

      final strengthItems = <_EditableSessionItem>[];
      for (final item in recommendation.items) {
        if (item.track == TrainingTrack.skillWork) continue;
        strengthItems.add(_editableItemFromRecommendation(item));
      }

      items[sessionType] = {
        _SessionComponent.warmup: [],
        _SessionComponent.skill: [
          _EditableSessionItem.progression(
            id: 'skill-${sessionType.dbValue}',
            name: skillExercise?.name ?? skillOption.title,
            skillCategoryId: skillOption.sourceSkillCategoryId,
            branchId: skillOption.trainingPathId,
            exerciseId: skillExercise?.id,
          ),
        ],
        _SessionComponent.strength: strengthItems,
        _SessionComponent.cooldown: [],
      };
    }

    return items;
  }

  Map<String, dynamic> _savedSessionItemsConfig() {
    final raw = widget.initialLogic.program.variationRules['session_items_v1'];
    if (raw is Map) {
      return Map<String, dynamic>.from(raw);
    }
    return const {};
  }

  Map<String, dynamic> _serializeSessionItems() {
    final serialized = <String, dynamic>{};

    for (final sessionEntry in _sessionItems.entries) {
      final sessionMap = <String, dynamic>{};

      for (final componentEntry in sessionEntry.value.entries) {
        sessionMap[_sessionComponentKey(componentEntry.key)] = [
          for (final item in componentEntry.value) _serializeSessionItem(item),
        ];
      }

      serialized[sessionEntry.key.dbValue] = sessionMap;
    }

    return serialized;
  }

  Map<String, dynamic> _serializeSessionItem(_EditableSessionItem item) {
    return {
      'id': item.id,
      'kind': item.kind.name,
      'name': item.name,
      if (item.skillCategoryId != null)
        'skill_category_id': item.skillCategoryId,
      if (item.branchId != null) 'branch_id': item.branchId,
      if (item.exerciseId != null) 'exercise_id': item.exerciseId,
      if (item.subtitle != null) 'subtitle': item.subtitle,
      if (item.isSystem) 'is_system': true,
    };
  }

  List<_EditableSessionItem> _deserializeSessionItemsForComponent(dynamic raw) {
    if (raw is! List) return const [];

    return raw
        .whereType<Map>()
        .map((item) => Map<String, dynamic>.from(item))
        .map(_deserializeSessionItem)
        .toList();
  }

  _EditableSessionItem _deserializeSessionItem(Map<String, dynamic> item) {
    final kind = item['kind'] as String? ?? 'exercise';
    final name = item['name'] as String? ??
        (item['exercise_id'] as String? ?? 'Exercise');

    if (kind == _EditableSessionItemKind.progression.name) {
      return _EditableSessionItem.progression(
        id: item['id'] as String? ?? _newSessionItemId(),
        name: name,
        skillCategoryId: item['skill_category_id'] as String? ?? '',
        branchId: item['branch_id'] as String? ?? 'main',
        exerciseId: item['exercise_id'] as String?,
      );
    }

    return _EditableSessionItem.exercise(
      id: item['id'] as String? ?? _newSessionItemId(),
      name: name,
      exerciseId: item['exercise_id'] as String?,
      subtitle: item['subtitle'] as String?,
      isSystem: item['is_system'] as bool? ?? false,
    );
  }

  String _sessionComponentKey(_SessionComponent component) => component.name;

  _EditableSessionItem _editableItemFromRecommendation(
    TrainingRecommendationItem item,
  ) {
    final category = SkillCategoryCatalog.findById(item.sourceSkillCategoryId);
    final selectedOption = _resolvedBranches[item.track];
    final selectedBranchId =
        selectedOption?.sourceSkillCategoryId == item.sourceSkillCategoryId
            ? selectedOption?.trainingPathId
            : null;
    if (category != null) {
      return _EditableSessionItem.progression(
        id: 'strength-${item.track.dbValue}-${item.exercise.id}',
        name: item.exercise.name,
        skillCategoryId: item.sourceSkillCategoryId,
        branchId: selectedBranchId ?? item.exercise.branchId,
        exerciseId: item.exercise.id,
      );
    }

    return _EditableSessionItem.exercise(
      id: 'strength-${item.track.dbValue}-${item.exercise.id}',
      name: item.exercise.name,
      exerciseId: item.exercise.id,
    );
  }

  String _titleCase(String value) {
    return value
        .split('_')
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }

  String _sessionBlockTitle(TrainingSessionType sessionType) {
    switch (sessionType) {
      case TrainingSessionType.fullBody:
        return 'Full Body';
      case TrainingSessionType.push:
        return 'Push';
      case TrainingSessionType.pull:
        return 'Pull';
      case TrainingSessionType.upper:
        return 'Upper';
      case TrainingSessionType.lower:
        return 'Lower';
      case TrainingSessionType.rest:
        return 'Rest';
    }
  }

  String _sessionBlockFooter(TrainingSessionType sessionType) {
    switch (sessionType) {
      case TrainingSessionType.fullBody:
        return 'This block trains every main pattern in a single session.';
      case TrainingSessionType.push:
        return 'Push days bias pressing strength while keeping squat and trunk work in the session.';
      case TrainingSessionType.pull:
        return 'Pull days bias back and pulling strength while keeping hinge and trunk work in the session.';
      case TrainingSessionType.upper:
        return 'Upper days keep the skill opener and all main pressing and pulling patterns together.';
      case TrainingSessionType.lower:
        return 'Lower days focus on squat, hinge, and trunk strength with the same warm-up and cool-down structure.';
      case TrainingSessionType.rest:
        return 'Rest day';
    }
  }

  Future<void> _openItemChoiceSheet(
    BuildContext context, {
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    _EditableSessionItem? existingItem,
  }) async {
    final selection = await showModalBottomSheet<ExerciseSwitchChoice>(
      context: context,
      backgroundColor: _group,
      barrierColor: Colors.black.withValues(alpha: 0.65),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => ExerciseSwitchChooserSheet(
        title: existingItem == null ? 'Add Item' : 'Switch Item',
        description: existingItem == null
            ? 'Choose how you want to add to ${_sessionComponentLabel(component).toLowerCase()} for ${_sessionBlockTitle(sessionType).toLowerCase()}.'
            : 'Replace this item with a progression path or a standalone exercise.',
        showRemoveAction: existingItem != null,
      ),
    );

    if (selection == null || !mounted) return;

    if (selection == ExerciseSwitchChoice.remove && existingItem != null) {
      _removeSessionItem(
        sessionType: sessionType,
        component: component,
        itemId: existingItem.id,
      );
      return;
    }

    if (selection == ExerciseSwitchChoice.progression) {
      final result = await _openProgressionPickerSheet(
        this.context,
        sessionType: sessionType,
        component: component,
        currentItem: existingItem?.kind == _EditableSessionItemKind.progression
            ? existingItem
            : null,
      );
      if (result == null || !mounted) return;
      _upsertSessionItem(
        sessionType: sessionType,
        component: component,
        item: _EditableSessionItem.progression(
          id: existingItem?.id ?? _newSessionItemId(),
          name: result.exerciseName,
          skillCategoryId: result.skillCategoryId,
          branchId: result.branchId,
          exerciseId: result.exerciseId,
        ),
        replaceId: existingItem?.id,
      );
      return;
    }

    if (selection == ExerciseSwitchChoice.exercise) {
      final result = await _openExercisePickerSheet(
        this.context,
        sessionType: sessionType,
        component: component,
        currentItem: existingItem?.kind == _EditableSessionItemKind.exercise
            ? existingItem
            : null,
      );
      if (result == null || !mounted) return;
      _upsertSessionItem(
        sessionType: sessionType,
        component: component,
        item: _EditableSessionItem.exercise(
          id: existingItem?.id ?? _newSessionItemId(),
          name: result.name,
          exerciseId: result.exerciseId,
          isSystem: false,
        ),
        replaceId: existingItem?.id,
      );
    }
  }

  Future<_ProgressionPickerResult?> _openProgressionPickerSheet(
    BuildContext context, {
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    _EditableSessionItem? currentItem,
  }) async {
    final categories = _progressionCategoriesFor(sessionType, component);
    if (categories.isEmpty) return null;

    return showModalBottomSheet<_ProgressionPickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (sheetContext) => _ProgressionPickerSheet(
        categories: categories,
        currentItem: currentItem,
        branchLabelBuilder: _displayBranchLabel,
        currentExerciseBuilder: _currentExerciseForProgression,
      ),
    );
  }

  Future<_ExercisePickerResult?> _openExercisePickerSheet(
    BuildContext context, {
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    _EditableSessionItem? currentItem,
  }) async {
    return showModalBottomSheet<_ExercisePickerResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (sheetContext) => _ExercisePickerSheet(
        title: currentItem == null ? 'Add Exercise' : 'Switch Exercise',
        eyebrow: _sessionComponentLabel(component).toUpperCase(),
        suggestions: _exerciseSuggestionsFor(sessionType, component),
        exerciseIdResolver: _exerciseIdForName,
        currentName: currentItem?.name,
      ),
    );
  }

  void _upsertSessionItem({
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    required _EditableSessionItem item,
    String? replaceId,
  }) {
    setState(() {
      final sessionMap = _sessionItems[sessionType]!;
      final currentList = List<_EditableSessionItem>.from(
        sessionMap[component] ?? const [],
      );

      if (replaceId != null) {
        final index = currentList.indexWhere((entry) => entry.id == replaceId);
        if (index != -1) {
          currentList[index] = item;
        } else {
          currentList.add(item);
        }
      } else {
        currentList.add(item);
      }

      sessionMap[component] = currentList;
    });
  }

  void _removeSessionItem({
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    required String itemId,
  }) {
    setState(() {
      final sessionMap = _sessionItems[sessionType]!;
      sessionMap[component] = List<_EditableSessionItem>.from(
        sessionMap[component] ?? const [],
      )..removeWhere((item) => item.id == itemId);
    });
  }

  void _reorderSessionItems({
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    required int oldIndex,
    required int newIndex,
  }) {
    setState(() {
      final sessionMap = _sessionItems[sessionType]!;
      final items = List<_EditableSessionItem>.from(
        sessionMap[component] ?? const [],
      );
      if (newIndex > oldIndex) {
        newIndex -= 1;
      }
      final item = items.removeAt(oldIndex);
      items.insert(newIndex, item);
      sessionMap[component] = items;
    });
  }

  String _newSessionItemId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  Widget _buildSessionItemsSection({
    required BuildContext context,
    required List<_EditableSessionItem> items,
    required TrainingSessionType sessionType,
    required _SessionComponent component,
    required Color defaultTone,
    required VoidCallback? Function(_EditableSessionItem item) onItemTap,
  }) {
    return Column(
      children: [
        if (items.isNotEmpty)
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: items.length,
            onReorder: (oldIndex, newIndex) => _reorderSessionItems(
              sessionType: sessionType,
              component: component,
              oldIndex: oldIndex,
              newIndex: newIndex,
            ),
            proxyDecorator: (child, _, __) => Material(
              color: Colors.transparent,
              child: child,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _SessionDetailTile(
                key: ValueKey('${component.name}-${item.id}'),
                title: item.name,
                eyebrow: _sessionItemEyebrowText(item)?.toUpperCase(),
                subtitle: _sessionItemSubtitle(item),
                tone: _sessionItemTone(item, defaultTone),
                emphasized: item.kind == _EditableSessionItemKind.progression,
                onTap: onItemTap(item),
                onSwitch: () => _openItemChoiceSheet(
                  this.context,
                  sessionType: sessionType,
                  component: component,
                  existingItem: item,
                ),
                leading: ReorderableDragStartListener(
                  index: index,
                  child: _TileDragHandle(
                    tone: _sessionItemTone(item, defaultTone),
                  ),
                ),
              );
            },
          ),
        _SessionAddItemButton(
          onTap: () => _openItemChoiceSheet(
            context,
            sessionType: sessionType,
            component: component,
          ),
        ),
      ],
    );
  }

  List<SkillCategory> _progressionCategoriesFor(
    TrainingSessionType sessionType,
    _SessionComponent component,
  ) {
    if (component != _SessionComponent.strength) {
      return SkillCategoryCatalog.browsable();
    }

    final allowedTracks = switch (sessionType) {
      TrainingSessionType.fullBody => {
          ExerciseCategory.verticalPush,
          ExerciseCategory.horizontalPush,
          ExerciseCategory.verticalPull,
          ExerciseCategory.horizontalPull,
          ExerciseCategory.core,
          ExerciseCategory.squat,
        },
      TrainingSessionType.push => {
          ExerciseCategory.verticalPush,
          ExerciseCategory.horizontalPush,
          ExerciseCategory.core,
          ExerciseCategory.squat,
        },
      TrainingSessionType.pull => {
          ExerciseCategory.verticalPull,
          ExerciseCategory.horizontalPull,
          ExerciseCategory.core,
        },
      TrainingSessionType.upper => {
          ExerciseCategory.verticalPush,
          ExerciseCategory.horizontalPush,
          ExerciseCategory.verticalPull,
          ExerciseCategory.horizontalPull,
        },
      TrainingSessionType.lower => {
          ExerciseCategory.squat,
          ExerciseCategory.core,
        },
      TrainingSessionType.rest => <ExerciseCategory>{},
    };

    return SkillCategoryCatalog.browsable()
        .where(
          (category) =>
              allowedTracks.contains(category.track) &&
              _selectableBranchesForCategory(category).isNotEmpty,
        )
        .toList();
  }

  List<String> _exerciseSuggestionsFor(
    TrainingSessionType sessionType,
    _SessionComponent component,
  ) {
    if (component == _SessionComponent.warmup) {
      return const [
        'Cat-Cow',
        'Wrist Circles',
        'Hip Openers',
        'Shoulder Pass-throughs',
        'World\'s Greatest Stretch',
        'Spinal Twist',
      ];
    }
    if (component == _SessionComponent.cooldown) {
      return const [
        'Couch Stretch',
        'Pigeon Stretch',
        'Foam Roll Quads',
        'Foam Roll Lats',
        'Diaphragmatic Breathing',
      ];
    }

    final Set<ExerciseCategory> allowedCategories;
    if (component == _SessionComponent.skill) {
      allowedCategories = ExerciseCategory.values.toSet();
    } else if (component == _SessionComponent.strength) {
      allowedCategories = switch (sessionType) {
        TrainingSessionType.fullBody => {
            ExerciseCategory.verticalPush,
            ExerciseCategory.horizontalPush,
            ExerciseCategory.verticalPull,
            ExerciseCategory.horizontalPull,
            ExerciseCategory.core,
            ExerciseCategory.squat,
            ExerciseCategory.hinge,
          },
        TrainingSessionType.push => {
            ExerciseCategory.verticalPush,
            ExerciseCategory.horizontalPush,
            ExerciseCategory.core,
            ExerciseCategory.squat,
          },
        TrainingSessionType.pull => {
            ExerciseCategory.verticalPull,
            ExerciseCategory.horizontalPull,
            ExerciseCategory.core,
            ExerciseCategory.hinge,
          },
        TrainingSessionType.upper => {
            ExerciseCategory.verticalPush,
            ExerciseCategory.horizontalPush,
            ExerciseCategory.verticalPull,
            ExerciseCategory.horizontalPull,
          },
        TrainingSessionType.lower => {
            ExerciseCategory.squat,
            ExerciseCategory.core,
            ExerciseCategory.hinge,
          },
        TrainingSessionType.rest => <ExerciseCategory>{},
      };
    } else {
      allowedCategories = <ExerciseCategory>{};
    }

    final names = ExerciseCatalog.all()
        .where((exercise) => allowedCategories.contains(exercise.category))
        .map((exercise) => exercise.name)
        .toSet()
        .toList()
      ..sort();
    return names;
  }

  String? _sessionItemEyebrowText(_EditableSessionItem item) {
    if (item.isSystem) return null;
    if (item.kind == _EditableSessionItemKind.exercise) {
      return 'Standalone exercise';
    }
    final category = item.skillCategoryId == null
        ? null
        : SkillCategoryCatalog.findById(item.skillCategoryId!);
    if (category == null) {
      return 'Standalone exercise';
    }
    return '${_singularize(category.title)} progression';
  }

  String? _sessionItemSubtitle(_EditableSessionItem item) {
    if (item.kind == _EditableSessionItemKind.progression &&
        item.skillCategoryId != null &&
        item.branchId != null) {
      return _branchLabel(item.skillCategoryId!, item.branchId!);
    }
    return item.subtitle;
  }

  Color _sessionItemTone(_EditableSessionItem item, Color defaultTone) {
    if (item.kind == _EditableSessionItemKind.exercise && !item.isSystem) {
      return _red;
    }
    return defaultTone;
  }

  String _branchLabel(String skillCategoryId, String branchId) {
    final category = SkillCategoryCatalog.findById(skillCategoryId);
    if (category == null) return _titleCase(branchId);
    for (final branch in category.branches) {
      if (branch.id == branchId) {
        return _displayBranchLabel(category, branch);
      }
    }
    return _titleCase(branchId);
  }

  List<SkillCategoryBranch> _selectableBranchesForCategory(
    SkillCategory category,
  ) {
    return category.branches
        .where(
          (branch) => (category.trainingPaths[branch.id] ?? const <String>[])
              .isNotEmpty,
        )
        .toList();
  }

  String _displayBranchLabel(
    SkillCategory category,
    SkillCategoryBranch branch,
  ) {
    switch (branch.id) {
      case 'main':
        return 'Foundation';
      case 'one_arm':
        return 'One-arm';
      case 'rings':
        return 'Ring';
      case 'close_grip':
        if (category.id == SkillCategoryCatalog.pullupsId) {
          return 'High Pull';
        }
        return 'Close Grip';
      default:
        return branch.label;
    }
  }

  Exercise? _exerciseForSessionItem(_EditableSessionItem item) {
    final exerciseId = item.exerciseId;
    if (exerciseId != null) {
      return ExerciseCatalog.findById(exerciseId);
    }

    if (item.kind == _EditableSessionItemKind.progression &&
        item.skillCategoryId != null &&
        item.branchId != null) {
      return _currentExerciseForProgression(
        skillCategoryId: item.skillCategoryId!,
        branchId: item.branchId!,
      );
    }

    for (final exercise in ExerciseCatalog.all()) {
      if (exercise.name == item.name) return exercise;
    }

    return null;
  }

  String? _exerciseIdForName(String name) {
    for (final exercise in ExerciseCatalog.all()) {
      if (exercise.name == name) return exercise.id;
    }
    return null;
  }

  VoidCallback? _exerciseDetailTapHandler(_EditableSessionItem item) {
    final exercise = _exerciseForSessionItem(item);
    if (exercise == null) return null;

    return () => openExerciseDetailView<void>(
          context,
          exercise: exercise,
          skillCategoryId: item.skillCategoryId,
        );
  }

  Exercise? _currentExerciseForProgression({
    required String skillCategoryId,
    required String branchId,
  }) {
    final category = SkillCategoryCatalog.findById(skillCategoryId);
    final exerciseIds = category?.trainingPaths[branchId] ?? const <String>[];
    final exercises = exerciseIds
        .map(ExerciseCatalog.findById)
        .whereType<Exercise>()
        .toList();

    if (exercises.isEmpty) return null;

    for (final exercise in exercises) {
      if (widget.progressMap[exercise.id] == ExerciseStatus.active) {
        return exercise;
      }
    }

    for (final exercise in exercises) {
      if (widget.progressMap[exercise.id] != ExerciseStatus.mastered) {
        return exercise;
      }
    }

    return exercises.last;
  }

  String _singularize(String value) {
    if (value.endsWith('Pushups')) {
      return value.replaceFirst(RegExp(r'Pushups$'), 'Pushup');
    }
    if (value.endsWith('Pullups')) {
      return value.replaceFirst(RegExp(r'Pullups$'), 'Pullup');
    }
    if (value.endsWith('Rows')) {
      return value.replaceFirst(RegExp(r'Rows$'), 'Row');
    }
    if (value.endsWith('Dips')) {
      return value.replaceFirst(RegExp(r'Dips$'), 'Dip');
    }
    return value;
  }

  String _sessionComponentLabel(_SessionComponent component) {
    switch (component) {
      case _SessionComponent.warmup:
        return 'Warm-up';
      case _SessionComponent.skill:
        return 'Skill Work';
      case _SessionComponent.strength:
        return 'Strength';
      case _SessionComponent.cooldown:
        return 'Cool-down';
    }
  }

  Future<void> _openSplitScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<TrainingProgramType>(
      MaterialPageRoute(
        builder: (_) => _SplitSettingsView(
          current: _selectedProgramType,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _selectedProgramType = result;
      _expandedSessionComponents = _defaultExpandedSessionComponents(result);
      _sessionItems = _buildDefaultSessionItems(result);
    });
  }

  Future<void> _openRepGoalScreen(BuildContext context) async {
    final result = await Navigator.of(context).push<RepGoalProfile>(
      MaterialPageRoute(
        builder: (_) => _RepGoalSettingsView(
          current: _repGoalProfile,
          subBuilder: _repSub,
        ),
      ),
    );

    if (result == null) return;
    setState(() => _repGoalProfile = result);
  }

  Future<void> _openStrengthScreen(BuildContext context) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _StrengthSettingsView(
          tracks: _strengthTracks,
          resolvedBranches: _resolvedBranches,
          progressMap: widget.progressMap,
          programService: _programService,
          repGoalProfile: _repGoalProfile,
          onOpenTrack: (track) => _openTrackScreen(context, track: track),
        ),
      ),
    );
  }

  Future<void> _openTrackScreen(
    BuildContext context, {
    required TrainingTrack track,
  }) async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => _TrackSettingsView(
          track: track,
          selectedId: _selectedBranches[track]!,
          options: _programService.branchOptionsForTrack(track),
          currentExercise: _programService.currentExerciseForOption(
            _resolvedBranches[track]!,
            widget.progressMap,
          ),
          repGoalProfile: _repGoalProfile,
        ),
      ),
    );

    if (result == null) return;
    setState(() {
      _selectedBranches[track] = result;
      _sessionItems = _buildDefaultSessionItems(_selectedProgramType);
    });
  }

  Future<void> _openInfoScreen(
    BuildContext context, {
    required String title,
    required String footer,
    required List<_StaticRowData> rows,
  }) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _InfoSettingsView(
          title: title,
          footer: footer,
          rows: rows,
        ),
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _selectedProgramType = widget.initialLogic.program.programType;
      _selectedBranches = {
        ..._programService.defaultBranchSelections(),
        ...widget.initialLogic.branchSelections,
      };
      _repGoalProfile = widget.initialLogic.repGoalProfile;
      _expandedSessionComponents = _defaultExpandedSessionComponents(
        _selectedProgramType,
      );
      _sessionItems = _buildInitialSessionItems(_selectedProgramType);
    });
  }
}

class _SplitSettingsView extends StatefulWidget {
  final TrainingProgramType current;

  const _SplitSettingsView({
    required this.current,
  });

  @override
  State<_SplitSettingsView> createState() => _SplitSettingsViewState();
}

class _SplitSettingsViewState extends State<_SplitSettingsView> {
  late TrainingProgramType _picked;
  final _programService = TrainingProgramService();

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    final cycle = _programService.scheduleCycleFor(programType: _picked);

    return _SettingsScreenScaffold(
      title: 'Split',
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Choose'),
          _SettingsGroup(
            footer: _splitRationale(_picked),
            children: [
              for (var i = 0; i < TrainingProgramType.values.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == TrainingProgramType.values.length - 1,
                  title: _splitName(TrainingProgramType.values[i]),
                  sub:
                      '${_programService.scheduleCycleFor(programType: TrainingProgramType.values[i]).where((day) => day != TrainingSessionType.rest).length} training days',
                  accessory: _picked == TrainingProgramType.values[i]
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = TrainingProgramType.values[i]);
                  },
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Preview'),
          _SettingsGroup(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    for (final day in cycle)
                      Expanded(
                        child: Container(
                          height: 52,
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          decoration: BoxDecoration(
                            color: day == TrainingSessionType.rest
                                ? Colors.white.withValues(alpha: 0.04)
                                : _accentDim,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              day == TrainingSessionType.rest
                                  ? '·'
                                  : _shortSplitPreview(day),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: day == TrainingSessionType.rest
                                    ? _text3
                                    : _accent,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _splitName(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return 'Full Body';
      case TrainingProgramType.pushPull:
        return 'Push / Pull';
      case TrainingProgramType.upperLower:
        return 'Upper / Lower';
    }
  }

  String _splitRationale(TrainingProgramType type) {
    switch (type) {
      case TrainingProgramType.fullBody:
        return '3 sessions per week hitting every pattern. Best for lower frequency and balanced trainees.';
      case TrainingProgramType.pushPull:
        return 'Alternates pressing and pulling emphasis while still keeping trunk and legs in the week.';
      case TrainingProgramType.upperLower:
        return 'Classic 4-day rhythm with more room for upper-body work and good recovery.';
    }
  }

  String _shortSplitPreview(TrainingSessionType type) {
    switch (type) {
      case TrainingSessionType.fullBody:
        return 'FB';
      case TrainingSessionType.push:
        return 'PUSH';
      case TrainingSessionType.pull:
        return 'PULL';
      case TrainingSessionType.upper:
        return 'UP';
      case TrainingSessionType.lower:
        return 'LOW';
      case TrainingSessionType.rest:
        return '·';
    }
  }
}

class _RepGoalSettingsView extends StatefulWidget {
  final RepGoalProfile current;
  final String Function(RepGoalProfile profile) subBuilder;

  const _RepGoalSettingsView({
    required this.current,
    required this.subBuilder,
  });

  @override
  State<_RepGoalSettingsView> createState() => _RepGoalSettingsViewState();
}

class _RepGoalSettingsViewState extends State<_RepGoalSettingsView> {
  late RepGoalProfile _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.current;
  }

  @override
  Widget build(BuildContext context) {
    return _SettingsScreenScaffold(
      title: 'Rep Target',
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Threshold'),
          _SettingsGroup(
            footer: _goalDescription(_picked),
            children: [
              for (var i = 0; i < RepGoalProfile.values.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == RepGoalProfile.values.length - 1,
                  title: RepGoalProfile.values[i].label,
                  sub: widget.subBuilder(RepGoalProfile.values[i]),
                  accessory: _picked == RepGoalProfile.values[i]
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = RepGoalProfile.values[i]);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _goalDescription(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return 'Heavier loads, longer rest. Treats the branch like a strength pursuit.';
      case RepGoalProfile.balanced:
        return 'Moderate loads and moderate rest. Balances progression speed, skill quality, and total work.';
      case RepGoalProfile.volume:
        return 'Longer sets and shorter rest. Pushes the branch toward work capacity and repeatable volume.';
    }
  }
}

class _StrengthSettingsView extends StatelessWidget {
  final List<TrainingTrack> tracks;
  final Map<TrainingTrack, TrainingBranchOption> resolvedBranches;
  final Map<String, ExerciseStatus> progressMap;
  final TrainingProgramService programService;
  final RepGoalProfile repGoalProfile;
  final ValueChanged<TrainingTrack> onOpenTrack;

  const _StrengthSettingsView({
    required this.tracks,
    required this.resolvedBranches,
    required this.progressMap,
    required this.programService,
    required this.repGoalProfile,
    required this.onOpenTrack,
  });

  @override
  Widget build(BuildContext context) {
    final total = tracks.length;

    return _SettingsScreenScaffold(
      title: 'Strength',
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Movement Patterns'),
          _SettingsGroup(
            footer:
                'Seven movement patterns cover every basic plane. Each slot can hold a calisthenics progression or a single weighted lift.',
            children: [
              for (var i = 0; i < tracks.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == tracks.length - 1,
                  title: tracks[i].label,
                  sub: _strengthSubline(
                    resolvedBranches[tracks[i]]!,
                    programService.currentExerciseForOption(
                      resolvedBranches[tracks[i]]!,
                      progressMap,
                    ),
                    repGoalProfile,
                  ),
                  value: '1/1',
                  onTap: () => onOpenTrack(tracks[i]),
                ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Summary'),
          _SettingsGroup(
            footer: 'Tracks across all seven patterns.',
            children: [
              _SettingsRow(
                first: true,
                last: true,
                title: 'Total tracks',
                value: '$total',
                accessory: _RowAccessory.none,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _strengthSubline(
    TrainingBranchOption option,
    Exercise? currentExercise,
    RepGoalProfile profile,
  ) {
    final reps = switch (profile) {
      RepGoalProfile.strength => '3–8 reps',
      RepGoalProfile.balanced => '3x8 reps',
      RepGoalProfile.volume => '3x12 reps',
    };
    return '${option.title} · ${currentExercise?.name ?? option.title} · $reps';
  }
}

class _TrackSettingsView extends StatelessWidget {
  final TrainingTrack track;
  final String selectedId;
  final List<TrainingBranchOption> options;
  final Exercise? currentExercise;
  final RepGoalProfile repGoalProfile;

  const _TrackSettingsView({
    required this.track,
    required this.selectedId,
    required this.options,
    required this.currentExercise,
    required this.repGoalProfile,
  });

  @override
  Widget build(BuildContext context) {
    final option = options.firstWhere(
      (item) => item.id == selectedId,
      orElse: () => options.first,
    );

    return _SettingsScreenScaffold(
      title: track.label,
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Track'),
          _SettingsGroup(
            footer: option.rationale,
            children: [
              _SettingsRow(
                first: true,
                title: 'Skill Tree',
                value: option.sourceSkillCategoryId,
                accessory: _RowAccessory.none,
              ),
              _SettingsRow(
                title: 'Branch',
                value: option.title,
                onTap: () async {
                  final picked = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => _TrackOptionPickerView(
                        title: track.label,
                        options: options,
                        selectedId: selectedId,
                      ),
                    ),
                  );

                  if (picked == null || !context.mounted) return;
                  Navigator.of(context).pop(picked);
                },
              ),
              _SettingsRow(
                last: true,
                title: 'Current step',
                sub: currentExercise?.name,
                value: _repGoalValue(repGoalProfile),
                accessory: _RowAccessory.none,
              ),
            ],
          ),
          const SizedBox(height: 22),
          const _SectionLabel(text: 'Actions'),
          _SettingsGroup(
            children: [
              _SettingsRow(
                first: true,
                title: 'Switch Track',
                onTap: () async {
                  final picked = await Navigator.of(context).push<String>(
                    MaterialPageRoute(
                      builder: (_) => _TrackOptionPickerView(
                        title: track.label,
                        options: options,
                        selectedId: selectedId,
                      ),
                    ),
                  );

                  if (picked == null || !context.mounted) return;
                  Navigator.of(context).pop(picked);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _repGoalValue(RepGoalProfile profile) {
    switch (profile) {
      case RepGoalProfile.strength:
        return '5x5';
      case RepGoalProfile.balanced:
        return '3x8';
      case RepGoalProfile.volume:
        return '3x12';
    }
  }
}

class _TrackOptionPickerView extends StatefulWidget {
  final String title;
  final List<TrainingBranchOption> options;
  final String selectedId;

  const _TrackOptionPickerView({
    required this.title,
    required this.options,
    required this.selectedId,
  });

  @override
  State<_TrackOptionPickerView> createState() => _TrackOptionPickerViewState();
}

class _TrackOptionPickerViewState extends State<_TrackOptionPickerView> {
  late String _picked;

  @override
  void initState() {
    super.initState();
    _picked = widget.selectedId;
  }

  @override
  Widget build(BuildContext context) {
    final current = widget.options.firstWhere(
      (option) => option.id == _picked,
      orElse: () => widget.options.first,
    );

    return _SettingsScreenScaffold(
      title: 'Switch Track',
      large: true,
      onBack: () => Navigator.of(context).pop(),
      trailingText: 'Save',
      onTrailingTap: () => Navigator.of(context).pop(_picked),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Choose a Track'),
          _SettingsGroup(
            footer: current.rationale,
            children: [
              for (var i = 0; i < widget.options.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == widget.options.length - 1,
                  title: widget.options[i].title,
                  sub:
                      '${widget.options[i].exerciseIds.length} steps · ${widget.options[i].subtitle}',
                  accessory: _picked == widget.options[i].id
                      ? _RowAccessory.check
                      : _RowAccessory.none,
                  onTap: () {
                    setState(() => _picked = widget.options[i].id);
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoSettingsView extends StatelessWidget {
  final String title;
  final String footer;
  final List<_StaticRowData> rows;

  const _InfoSettingsView({
    required this.title,
    required this.footer,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return _SettingsScreenScaffold(
      title: title,
      large: true,
      onBack: () => Navigator.of(context).pop(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(text: 'Overview'),
          _SettingsGroup(
            footer: footer,
            children: [
              for (var i = 0; i < rows.length; i++)
                _SettingsRow(
                  first: i == 0,
                  last: i == rows.length - 1,
                  title: rows[i].title,
                  value: rows[i].value,
                  accessory: _RowAccessory.none,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SettingsScreenScaffold extends StatelessWidget {
  final String title;
  final bool large;
  final VoidCallback onBack;
  final String? trailingText;
  final VoidCallback? onTrailingTap;
  final Widget child;

  const _SettingsScreenScaffold({
    required this.title,
    required this.onBack,
    required this.child,
    this.large = false,
    this.trailingText,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        surfaceTintColor: _bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.chevron_left_rounded,
            size: 30,
            color: _accent,
          ),
          onPressed: onBack,
        ),
        actions: [
          if (trailingText != null)
            TextButton(
              onPressed: onTrailingTap,
              child: Text(
                trailingText!,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  color: _accent,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: large ? 34 : 28,
                        fontWeight: FontWeight.w700,
                        letterSpacing: large ? -1.1 : -0.7,
                        color: _text,
                      ),
                    ),
                    const SizedBox(height: 18),
                    child,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel({
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 4, 8),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.7,
          color: _text2,
        ),
      ),
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  final List<Widget> children;
  final String? footer;

  const _SettingsGroup({
    required this.children,
    this.footer,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: _group,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(children: children),
        ),
        if (footer != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Text(
              footer!,
              style: const TextStyle(
                fontSize: 12,
                height: 1.45,
                color: _text2,
              ),
            ),
          ),
      ],
    );
  }
}

enum _SessionComponent { warmup, skill, strength, cooldown }

class _ComponentAccordionRow extends StatelessWidget {
  final String title;
  final String count;
  final bool expanded;
  final Color accentColor;
  final VoidCallback onToggle;
  final Widget child;

  const _ComponentAccordionRow({
    required this.title,
    required this.count,
    required this.expanded,
    required this.accentColor,
    required this.onToggle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: _sep, width: 0.5)),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.35,
                        color: _text,
                      ),
                    ),
                  ),
                  Text(
                    count,
                    style: GoogleFonts.robotoMono(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: accentColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  AnimatedRotation(
                    turns: expanded ? 0.25 : 0,
                    duration: const Duration(milliseconds: 220),
                    child: const Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: _text,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (expanded) child,
        ],
      ),
    );
  }
}

class _SessionDetailTile extends StatelessWidget {
  final String title;
  final String? eyebrow;
  final String? subtitle;
  final Color tone;
  final bool emphasized;
  final VoidCallback? onTap;
  final VoidCallback? onSwitch;
  final Widget? leading;

  const _SessionDetailTile({
    super.key,
    required this.title,
    this.eyebrow,
    this.subtitle,
    required this.tone,
    this.emphasized = false,
    this.onTap,
    this.onSwitch,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final tile = Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.fromLTRB(10, 10, 12, 10),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: emphasized ? tone.withValues(alpha: 0.18) : _sep,
        ),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (eyebrow != null)
                  Text(
                    eyebrow!,
                    style: GoogleFonts.robotoMono(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: emphasized ? tone : _text3,
                    ),
                  ),
                if (eyebrow != null) const SizedBox(height: 4),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: emphasized ? FontWeight.w600 : FontWeight.w500,
                    letterSpacing: -0.15,
                    color: _text,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle!,
                    style: const TextStyle(
                      fontSize: 12.5,
                      letterSpacing: -0.05,
                      color: _text2,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onSwitch != null)
            _TileSwitchButton(
              tone: emphasized ? tone : _text3,
              onTap: onSwitch!,
            ),
          if (onSwitch == null)
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: emphasized ? tone : _text3,
            ),
        ],
      ),
    );

    final tappableTile = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: tile,
    );

    if (onTap == null) {
      return tile;
    }
    return tappableTile;
  }
}

class _TileSwitchButton extends StatelessWidget {
  final Color tone;
  final VoidCallback onTap;

  const _TileSwitchButton({
    required this.tone,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: tone.withValues(alpha: 0.35)),
          borderRadius: BorderRadius.circular(999),
          color: tone.withValues(alpha: 0.08),
        ),
        alignment: Alignment.center,
        child: CustomPaint(
          size: const Size(13, 13),
          painter: _SwitchGlyphPainter(tone),
        ),
      ),
    );
  }
}

class _TileDragHandle extends StatelessWidget {
  final Color tone;

  const _TileDragHandle({
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Icon(
        Icons.drag_indicator_rounded,
        size: 18,
        color: tone.withValues(alpha: 0.75),
      ),
    );
  }
}

class _SwitchGlyphPainter extends CustomPainter {
  final Color color;

  const _SwitchGlyphPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.4
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final topPath = Path()
      ..moveTo(1, 4.2)
      ..lineTo(9.2, 4.2)
      ..moveTo(7.1, 2)
      ..lineTo(9.6, 4.2)
      ..lineTo(7.1, 6.4);
    final bottomPath = Path()
      ..moveTo(12, 8.8)
      ..lineTo(3.8, 8.8)
      ..moveTo(5.9, 6.6)
      ..lineTo(3.4, 8.8)
      ..lineTo(5.9, 11);

    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant _SwitchGlyphPainter oldDelegate) =>
      oldDelegate.color != color;
}

enum _EditableSessionItemKind { progression, exercise }

class _EditableSessionItem {
  final String id;
  final _EditableSessionItemKind kind;
  final String name;
  final String? skillCategoryId;
  final String? branchId;
  final String? exerciseId;
  final String? subtitle;
  final bool isSystem;

  const _EditableSessionItem._({
    required this.id,
    required this.kind,
    required this.name,
    this.skillCategoryId,
    this.branchId,
    this.exerciseId,
    this.subtitle,
    this.isSystem = false,
  });

  factory _EditableSessionItem.progression({
    required String id,
    required String name,
    required String skillCategoryId,
    required String branchId,
    String? exerciseId,
  }) {
    return _EditableSessionItem._(
      id: id,
      kind: _EditableSessionItemKind.progression,
      name: name,
      skillCategoryId: skillCategoryId,
      branchId: branchId,
      exerciseId: exerciseId,
    );
  }

  factory _EditableSessionItem.exercise({
    required String id,
    required String name,
    String? exerciseId,
    String? subtitle,
    bool isSystem = false,
  }) {
    return _EditableSessionItem._(
      id: id,
      kind: _EditableSessionItemKind.exercise,
      name: name,
      exerciseId: exerciseId,
      subtitle: subtitle,
      isSystem: isSystem,
    );
  }
}

class _ProgressionPickerResult {
  final String skillCategoryId;
  final String branchId;
  final String? exerciseId;
  final String exerciseName;

  const _ProgressionPickerResult({
    required this.skillCategoryId,
    required this.branchId,
    required this.exerciseId,
    required this.exerciseName,
  });
}

class _ExercisePickerResult {
  final String name;
  final String? exerciseId;

  const _ExercisePickerResult({
    required this.name,
    this.exerciseId,
  });
}

class _SessionAddItemButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SessionAddItemButton({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          decoration: BoxDecoration(
            border: Border.all(color: _accent.withValues(alpha: 0.32)),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.add_rounded,
                size: 16,
                color: _accent,
              ),
              const SizedBox(width: 8),
              Text(
                'Add item',
                style: GoogleFonts.robotoMono(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.7,
                  color: _accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrototypeSheet extends StatelessWidget {
  final String eyebrow;
  final String title;
  final Widget child;

  const _PrototypeSheet({
    required this.eyebrow,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: const BoxDecoration(
          color: _group,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: _text2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.6,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
              ),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.72,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProgressionPickerSheet extends StatefulWidget {
  final List<SkillCategory> categories;
  final _EditableSessionItem? currentItem;
  final String Function(SkillCategory, SkillCategoryBranch) branchLabelBuilder;
  final Exercise? Function({
    required String skillCategoryId,
    required String branchId,
  }) currentExerciseBuilder;

  const _ProgressionPickerSheet({
    required this.categories,
    this.currentItem,
    required this.branchLabelBuilder,
    required this.currentExerciseBuilder,
  });

  @override
  State<_ProgressionPickerSheet> createState() =>
      _ProgressionPickerSheetState();
}

class _ProgressionPickerSheetState extends State<_ProgressionPickerSheet> {
  late String _selectedCategoryId;
  String? _selectedBranchId;
  late bool _showBranches;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId =
        widget.currentItem?.skillCategoryId ?? widget.categories.first.id;
    _selectedBranchId = widget.currentItem?.branchId;
    _showBranches = widget.currentItem?.skillCategoryId != null;
  }

  @override
  Widget build(BuildContext context) {
    final category = widget.categories.firstWhere(
      (item) => item.id == _selectedCategoryId,
      orElse: () => widget.categories.first,
    );

    if (!_showBranches) {
      return _PrototypeSheet(
        eyebrow: 'STEP 1 OF 2',
        title: 'Pick Progression',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose the skill tree you want this item to follow.',
              style: TextStyle(
                fontSize: 14,
                height: 1.45,
                color: _text2,
              ),
            ),
            const SizedBox(height: 18),
            for (final item in widget.categories) ...[
              _PickerOptionTile(
                title: item.title,
                subtitle:
                    '${_selectableBranches(item).length} branches · ${item.track.label}',
                tone: _accent,
                onTap: () {
                  setState(() {
                    _selectedCategoryId = item.id;
                    _selectedBranchId = null;
                    _showBranches = true;
                  });
                },
              ),
              const SizedBox(height: 10),
            ],
          ],
        ),
      );
    }

    final branches = _selectableBranches(category);

    return _PrototypeSheet(
      eyebrow: '${category.title.toUpperCase()} · STEP 2 OF 2',
      title: 'Pick Branch',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Each branch is a different path through the ${category.title.toLowerCase()} tree.',
            style: const TextStyle(
              fontSize: 14,
              height: 1.45,
              color: _text2,
            ),
          ),
          const SizedBox(height: 18),
          for (final branch in branches) ...[
            _BranchOptionTile(
              title: widget.branchLabelBuilder(category, branch),
              subtitle: _branchRange(category, branch.id),
              selected: _selectedBranchId == branch.id,
              onTap: () => setState(() => _selectedBranchId = branch.id),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => setState(() => _showBranches = false),
                  style: OutlinedButton.styleFrom(
                    side:
                        BorderSide(color: Colors.white.withValues(alpha: 0.14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Back',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.8,
                      color: _text,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FilledButton(
                  onPressed: _selectedBranchId == null
                      ? null
                      : () {
                          final branchId = _selectedBranchId!;
                          final exercise = widget.currentExerciseBuilder(
                            skillCategoryId: category.id,
                            branchId: branchId,
                          );
                          Navigator.of(context).pop(
                            _ProgressionPickerResult(
                              skillCategoryId: category.id,
                              branchId: branchId,
                              exerciseId: exercise?.id,
                              exerciseName: exercise?.name ?? category.title,
                            ),
                          );
                        },
                  style: FilledButton.styleFrom(
                    backgroundColor: _accent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Text(
                    'Set Progression',
                    style: GoogleFonts.robotoMono(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<SkillCategoryBranch> _selectableBranches(SkillCategory category) {
    return category.branches
        .where(
          (branch) => (category.trainingPaths[branch.id] ?? const <String>[])
              .isNotEmpty,
        )
        .toList();
  }

  String _branchRange(SkillCategory category, String branchId) {
    final steps = category.trainingPaths[branchId] ?? const <String>[];
    if (steps.isEmpty) return 'No steps';
    final first = ExerciseCatalog.findById(steps.first)?.name ?? steps.first;
    final last = ExerciseCatalog.findById(steps.last)?.name ?? steps.last;
    return '$first -> $last';
  }
}

class _ExercisePickerSheet extends StatefulWidget {
  final String title;
  final String eyebrow;
  final List<String> suggestions;
  final String? currentName;
  final String? Function(String name) exerciseIdResolver;

  const _ExercisePickerSheet({
    required this.title,
    required this.eyebrow,
    required this.suggestions,
    required this.exerciseIdResolver,
    this.currentName,
  });

  @override
  State<_ExercisePickerSheet> createState() => _ExercisePickerSheetState();
}

class _ExercisePickerSheetState extends State<_ExercisePickerSheet> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _controller.text.trim().toLowerCase();
    final filtered = widget.suggestions
        .where((item) => item.toLowerCase().contains(query))
        .toList();

    return _PrototypeSheet(
      eyebrow: widget.eyebrow,
      title: widget.title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.search_rounded,
                  size: 16,
                  color: _text2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _controller,
                    onChanged: (_) => setState(() {}),
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      letterSpacing: 1.3,
                      color: _text,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'SEARCH EXERCISES…',
                      hintStyle: GoogleFonts.robotoMono(
                        fontSize: 12,
                        letterSpacing: 1.3,
                        color: _text3,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          for (final item in filtered.take(16)) ...[
            _PickerOptionTile(
              title: item,
              subtitle: 'Single exercise',
              tone: _red,
              trailingPlus: true,
              onTap: () => Navigator.of(context).pop(
                _ExercisePickerResult(
                  name: item,
                  exerciseId: widget.exerciseIdResolver(item),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          if (_controller.text.trim().isNotEmpty &&
              !widget.suggestions.contains(_controller.text.trim())) ...[
            _PickerOptionTile(
              title: _controller.text.trim(),
              subtitle: 'Create custom exercise',
              tone: _accent,
              onTap: () => Navigator.of(context).pop(
                _ExercisePickerResult(name: _controller.text.trim()),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PickerOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color tone;
  final bool trailingPlus;
  final VoidCallback onTap;

  const _PickerOptionTile({
    required this.title,
    required this.subtitle,
    required this.tone,
    this.trailingPlus = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(color: tone.withValues(alpha: 0.22)),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.18,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _text2,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              trailingPlus ? Icons.add_rounded : Icons.chevron_right_rounded,
              size: 18,
              color: tone,
            ),
          ],
        ),
      ),
    );
  }
}

class _BranchOptionTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _BranchOptionTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: Border.all(
            color: selected
                ? _accent.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.08),
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.18,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12.5,
                      color: _text2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _accent : Colors.transparent,
                border: Border.all(
                  color: selected ? _accent : Colors.white24,
                ),
              ),
              alignment: Alignment.center,
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 15,
                      color: Colors.black,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}

enum _RowAccessory { chevron, check, none }

class _SettingsRow extends StatelessWidget {
  final bool first;
  final bool last;
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String? sub;
  final String? value;
  final Color? titleColor;
  final _RowAccessory accessory;
  final VoidCallback? onTap;

  const _SettingsRow({
    this.first = false,
    this.last = false,
    this.icon,
    this.iconColor,
    required this.title,
    this.sub,
    this.value,
    this.titleColor,
    this.accessory = _RowAccessory.chevron,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: (iconColor ?? _text2).withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(7),
              ),
              alignment: Alignment.center,
              child: Icon(
                icon,
                size: 17,
                color: iconColor ?? _text2,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    letterSpacing: -0.1,
                    color: titleColor ?? _text,
                  ),
                ),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    sub!,
                    style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: -0.05,
                      color: _text2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (value != null)
                  Flexible(
                    child: Text(
                      value!,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 15,
                        letterSpacing: -0.05,
                        color: _text2,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                if (accessory == _RowAccessory.chevron && onTap != null) ...[
                  if (value != null) const SizedBox(width: 8),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: _text3,
                  ),
                ],
                if (accessory == _RowAccessory.check) ...[
                  if (value != null) const SizedBox(width: 8),
                  const Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: _accent,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final row = first
        ? content
        : Container(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: _sep, width: 0.5)),
            ),
            child: content,
          );

    if (onTap == null) return row;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: row,
    );
  }
}

class _StaticRowData {
  final String title;
  final String value;

  const _StaticRowData({
    required this.title,
    required this.value,
  });
}

class _ProgramSessionBlock {
  final TrainingSessionType sessionType;
  final String title;
  final List<_EditableSessionItem> warmupItems;
  final List<_EditableSessionItem> skillItems;
  final List<_EditableSessionItem> strengthItems;
  final List<_EditableSessionItem> cooldownItems;
  final String footer;

  const _ProgramSessionBlock({
    required this.sessionType,
    required this.title,
    required this.warmupItems,
    required this.skillItems,
    required this.strengthItems,
    required this.cooldownItems,
    required this.footer,
  });
}
