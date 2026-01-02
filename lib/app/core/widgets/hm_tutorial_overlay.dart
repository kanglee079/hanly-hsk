import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:showcaseview/showcaseview.dart';
import '../../services/tutorial_service.dart';

/// Centralized tutorial overlay widget
///
/// This widget wraps the entire app shell with a SINGLE ShowCaseWidget,
/// preventing the overlapping tutorial bug that occurred when each screen
/// had its own ShowCaseWidget.
///
/// Key features:
/// - Single ShowCaseWidget instance for entire app
/// - Controlled by TutorialService
/// - Triggers tutorials per-tab on first visit
class HMTutorialOverlay extends StatefulWidget {
  final Widget child;

  const HMTutorialOverlay({super.key, required this.child});

  @override
  State<HMTutorialOverlay> createState() => _HMTutorialOverlayState();
}

class _HMTutorialOverlayState extends State<HMTutorialOverlay> {
  @override
  Widget build(BuildContext context) {
    // Check if TutorialService is available
    if (!Get.isRegistered<TutorialService>()) {
      // Fallback if service not registered yet
      return widget.child;
    }

    final tutorialService = Get.find<TutorialService>();

    return ShowCaseWidget(
      autoPlay: false,
      autoPlayDelay: const Duration(seconds: 3),
      enableAutoScroll: true,
      disableBarrierInteraction: false,
      onFinish: () {
        // Mark current tutorial as complete
        tutorialService.onShowcaseComplete();
      },
      onComplete: (index, key) {
        // Optional: track step completion
        debugPrint('Showcase step $index completed');
      },
      builder: (context) {
        // Store context reference in service for later use
        tutorialService.setShowcaseContext(context);
        return widget.child;
      },
    );
  }
}
