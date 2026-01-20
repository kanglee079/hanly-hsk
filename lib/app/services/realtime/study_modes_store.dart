import 'dart:convert';

import 'package:get/get.dart';

import '../../data/models/study_modes_model.dart';
import '../../data/repositories/learning_repo.dart';
import 'realtime_resource.dart';
import 'realtime_sync_service.dart';

/// Single source of truth for Study Modes (Learn tab).
class StudyModesStore extends GetxService {
  final LearningRepo _learningRepo = Get.find<LearningRepo>();
  final RealtimeSyncService _rt = Get.find<RealtimeSyncService>();

  late final RealtimeResource<StudyModesResponse> studyModes;

  @override
  void onInit() {
    super.onInit();

    // OPTIMIZED: Reduced polling from 30s to 5 minutes
    // Study modes data rarely changes - only after completing sessions
    // Force sync is triggered after session completion anyway
    studyModes = RealtimeResource<StudyModesResponse>(
      key: 'studyModes',
      interval: const Duration(minutes: 5),
      fetcher: () => _learningRepo.getStudyModes(),
      fingerprinter: (v) => jsonEncode(v.toJson()),
    );
    _rt.register(studyModes);
  }

  Future<void> syncNow({bool force = false}) async {
    await _rt.syncNowKeys(const ['studyModes'], force: force);
  }
}


