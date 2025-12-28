import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'storage_service.dart';

/// Tutorial step definition
class TutorialStep {
  final String id;
  final String title;
  final String description;
  final String? emoji;
  final String targetKey; // GlobalKey identifier for target widget
  final TutorialPosition position;
  final bool showSkip;
  final bool isLast;
  final bool needsScroll; // Whether to scroll to this element

  const TutorialStep({
    required this.id,
    required this.title,
    required this.description,
    this.emoji,
    required this.targetKey,
    this.position = TutorialPosition.bottom,
    this.showSkip = true,
    this.isLast = false,
    this.needsScroll = true,
  });
}

/// Position of tooltip relative to target
enum TutorialPosition { top, bottom, left, right, center }

/// Tutorial flow definition
class TutorialFlow {
  final String id;
  final List<TutorialStep> steps;
  final String screenRoute;

  const TutorialFlow({
    required this.id,
    required this.steps,
    required this.screenRoute,
  });
}

/// Service to manage tutorial state and progress
class TutorialService extends GetxService {
  late final StorageService _storage;

  // Current tutorial state
  final RxBool isShowingTutorial = false.obs;
  final RxInt currentStepIndex = 0.obs;
  final Rxn<TutorialFlow> currentFlow = Rxn<TutorialFlow>();

  // Completed tutorials
  final RxSet<String> completedTutorials = <String>{}.obs;

  // Key registry for target widgets
  final Map<String, GlobalKey> _keyRegistry = {};
  
  // Scroll controller registry for auto-scrolling
  final Map<String, ScrollController> _scrollControllers = {};

  @override
  void onInit() {
    super.onInit();
    _storage = Get.find<StorageService>();
    _loadCompletedTutorials();
  }

  void _loadCompletedTutorials() {
    final completed = _storage.getCompletedTutorials();
    completedTutorials.addAll(completed);
  }

  /// Register a GlobalKey for a target widget
  void registerKey(String keyId, GlobalKey key) {
    _keyRegistry[keyId] = key;
  }

  /// Unregister a GlobalKey
  void unregisterKey(String keyId) {
    _keyRegistry.remove(keyId);
  }

  /// Get registered key
  GlobalKey? getKey(String keyId) => _keyRegistry[keyId];

  /// Register a ScrollController for auto-scrolling
  void registerScrollController(String screenId, ScrollController controller) {
    _scrollControllers[screenId] = controller;
  }

  /// Unregister a ScrollController
  void unregisterScrollController(String screenId) {
    _scrollControllers.remove(screenId);
  }

  /// Scroll to make target visible
  Future<void> scrollToTarget(String targetKey, {String? screenId}) async {
    final key = _keyRegistry[targetKey];
    if (key == null || key.currentContext == null) return;
    
    // Use Scrollable.ensureVisible for reliable scrolling
    await Scrollable.ensureVisible(
      key.currentContext!,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
      alignment: 0.3, // Position target at 30% from top
    );
  }

  /// Check if a tutorial should be shown
  bool shouldShowTutorial(String tutorialId) {
    return !completedTutorials.contains(tutorialId);
  }

  /// Start a tutorial flow
  void startTutorial(TutorialFlow flow) {
    if (completedTutorials.contains(flow.id)) return;
    
    currentFlow.value = flow;
    currentStepIndex.value = 0;
    isShowingTutorial.value = true;
  }

  /// Get current step
  TutorialStep? get currentStep {
    final flow = currentFlow.value;
    if (flow == null) return null;
    if (currentStepIndex.value >= flow.steps.length) return null;
    return flow.steps[currentStepIndex.value];
  }

  /// Move to next step
  void nextStep() {
    final flow = currentFlow.value;
    if (flow == null) return;

    if (currentStepIndex.value < flow.steps.length - 1) {
      currentStepIndex.value++;
    } else {
      // Tutorial completed
      completeTutorial();
    }
  }

  /// Go to previous step
  void previousStep() {
    if (currentStepIndex.value > 0) {
      currentStepIndex.value--;
    }
  }

  /// Skip/complete tutorial
  void completeTutorial() {
    final flow = currentFlow.value;
    if (flow != null) {
      completedTutorials.add(flow.id);
      _storage.setCompletedTutorials(completedTutorials.toList());
    }
    
    isShowingTutorial.value = false;
    currentFlow.value = null;
    currentStepIndex.value = 0;
  }

  /// Skip tutorial without completing
  void skipTutorial() {
    completeTutorial();
  }

  /// Reset all tutorials (for testing)
  void resetAllTutorials() {
    completedTutorials.clear();
    _storage.setCompletedTutorials([]);
    isShowingTutorial.value = false;
    currentFlow.value = null;
    currentStepIndex.value = 0;
  }

  /// Get progress percentage
  double get progress {
    final flow = currentFlow.value;
    if (flow == null || flow.steps.isEmpty) return 0;
    return (currentStepIndex.value + 1) / flow.steps.length;
  }

  /// Get step count text
  String get stepCountText {
    final flow = currentFlow.value;
    if (flow == null) return '';
    return '${currentStepIndex.value + 1}/${flow.steps.length}';
  }
}

/// GlobalKey extension for easy registration
extension GlobalKeyExtension on GlobalKey {
  void registerWith(TutorialService service, String keyId) {
    service.registerKey(keyId, this);
  }
}

