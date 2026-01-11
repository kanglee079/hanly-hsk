import 'package:get/get.dart';
import '../../data/models/hsk_exam_model.dart';
import '../../data/repositories/hsk_exam_repo.dart';
import '../../services/auth_session_service.dart';
import '../../core/widgets/hm_toast.dart';
import '../../core/constants/toast_messages.dart';
import '../../routes/app_routes.dart';

/// HSK Exam tab controller
class HskExamController extends GetxController {
  final AuthSessionService _authService = Get.find<AuthSessionService>();
  late final HskExamRepo _examRepo;

  // Selected HSK level filter
  final RxString selectedLevel = 'all'.obs;
  
  // Loading states
  final RxBool isLoading = false.obs;
  final RxBool isLoadingTests = false.obs;
  
  // Data
  final Rxn<HskExamOverview> overview = Rxn<HskExamOverview>();
  final RxList<MockTestModel> tests = <MockTestModel>[].obs;
  
  // Stats (from overview)
  int get totalAttempts => overview.value?.stats.totalAttempts ?? 0;
  int get averageScore => overview.value?.stats.averageScore ?? 0;
  int get bestScore => overview.value?.stats.bestScore ?? 0;
  int get passRate => overview.value?.stats.passRate ?? 0;
  
  // Available levels
  List<String> get availableLevels => overview.value?.availableLevels ?? 
      ['HSK1', 'HSK2', 'HSK3', 'HSK4', 'HSK5', 'HSK6'];
  
  // User's current level
  String get userLevel => _authService.currentUser.value?.profile?.currentLevel ?? 'HSK1';

  @override
  void onInit() {
    super.onInit();
    _initRepo();
    loadOverview();
    loadTests();
    
    // Reload tests when level changes
    ever(selectedLevel, (_) => loadTests());
  }

  void _initRepo() {
    try {
      _examRepo = Get.find<HskExamRepo>();
    } catch (_) {
      // Repo not registered yet, create one
      final apiClient = Get.find();
      _examRepo = HskExamRepo(apiClient);
      Get.put(_examRepo);
    }
  }

  Future<void> loadOverview() async {
    isLoading.value = true;
    try {
      overview.value = await _examRepo.getOverview();
    } catch (e) {
      // Failed to load overview - use defaults
      overview.value = HskExamOverview();
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadTests() async {
    isLoadingTests.value = true;
    try {
      print('🔍 [HSK Exam Controller] Loading tests for level: ${selectedLevel.value}');
      tests.value = await _examRepo.getTests(
        level: selectedLevel.value == 'all' ? null : selectedLevel.value,
      );
      print('✅ [HSK Exam Controller] Tests loaded: ${tests.length}');
      for (var test in tests) {
        print('   - ${test.title} (${test.level}) - ${test.totalQuestions} questions, ${test.sections.length} sections');
      }
    } catch (e, stackTrace) {
      // Failed to load tests
      print('❌ [HSK Exam Controller] Error loading tests: $e');
      print('Stack trace: $stackTrace');
      HMToast.error(ToastMessages.examTestsLoadError);
    } finally {
      isLoadingTests.value = false;
    }
  }

  void selectLevel(String level) {
    selectedLevel.value = level;
  }

  void startMockTest(String testId) {
    // Navigate to test taking screen - all tests are now free
    Get.toNamed(Routes.hskExamTest, arguments: {'testId': testId});
  }

  void viewHistory() {
    Get.toNamed(Routes.hskExamHistory);
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadOverview(),
      loadTests(),
    ]);
  }
}
