import '../models/hsk_exam_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Repository for HSK Exam related API calls
class HskExamRepo {
  final ApiClient _api;

  HskExamRepo(this._api);

  /// Get exam overview with stats
  Future<HskExamOverview> getOverview() async {
    final response = await _api.get(ApiEndpoints.hskExamOverview);
    final data = response.data['data'] ?? response.data;
    return HskExamOverview.fromJson(data);
  }

  /// Get list of available tests
  Future<List<MockTestModel>> getTests({
    String? level,
    String? type,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (level != null && level != 'all') 'level': level,
      if (type != null) 'type': type,
    };

    print('🔍 [HSK Exam Repo] Fetching tests with params: $queryParams');
    final response = await _api.get(
      ApiEndpoints.hskExamTests,
      queryParameters: queryParams,
    );
    print('📦 [HSK Exam Repo] Response data: ${response.data}');
    
    final data = response.data['data'] ?? response.data;
    final tests = data['tests'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    print('📊 [HSK Exam Repo] Found ${tests.length} tests in response');
    
    final parsedTests = tests.map((e) => MockTestModel.fromJson(e as Map<String, dynamic>)).toList();
    print('✅ [HSK Exam Repo] Parsed ${parsedTests.length} tests');
    
    return parsedTests;
  }

  /// Get test details (start attempt)
  Future<MockTestWithAttempt> getTestDetail(String testId) async {
    print('🔍 [HSK Exam Repo] Fetching test detail for: $testId');
    final response = await _api.get('${ApiEndpoints.hskExamTests}/$testId');
    print('📦 [HSK Exam Repo] Test detail response: ${response.data}');
    
    final data = response.data['data'] ?? response.data;
    final result = MockTestWithAttempt.fromJson(data);
    
    print('✅ [HSK Exam Repo] Test detail parsed:');
    print('   - Title: ${result.test.title}');
    print('   - Level: ${result.test.level}');
    print('   - Sections: ${result.test.sections.length}');
    print('   - Total questions: ${result.test.totalQuestions}');
    
    for (var i = 0; i < result.test.sections.length; i++) {
      final section = result.test.sections[i];
      print('   - Section ${i + 1}: ${section.name} (${section.questions.length} questions)');
    }
    
    return result;
  }

  /// Submit test answers
  Future<ExamResult> submitTest({
    required String testId,
    required String attemptId,
    required List<Map<String, String>> answers,
    required int timeSpent,
  }) async {
    final response = await _api.post(
      '${ApiEndpoints.hskExamTests}/$testId/submit',
      data: {
        'attemptId': attemptId,
        'answers': answers,
        'timeSpent': timeSpent,
      },
    );
    final data = response.data['data'] ?? response.data;
    return ExamResult.fromJson(data);
  }

  /// Get exam history
  Future<List<ExamAttemptSummary>> getHistory({
    String? level,
    int page = 1,
    int limit = 20,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (level != null && level != 'all') 'level': level,
    };

    final response = await _api.get(
      ApiEndpoints.hskExamHistory,
      queryParameters: queryParams,
    );
    final data = response.data['data'] ?? response.data;
    final attempts = data['attempts'] as List<dynamic>? ?? data as List<dynamic>? ?? [];
    return attempts.map((e) => ExamAttemptSummary.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Get attempt review (answers with explanations)
  Future<ExamReview> getAttemptReview(String testId, String attemptId) async {
    final response = await _api.get(
      '${ApiEndpoints.hskExamTests}/$testId/review/$attemptId',
    );
    final data = response.data['data'] ?? response.data;
    return ExamReview.fromJson(data);
  }
}

/// Mock test with active attempt
class MockTestWithAttempt {
  final MockTestModel test;
  final ExamAttempt attempt;

  MockTestWithAttempt({
    required this.test,
    required this.attempt,
  });

  factory MockTestWithAttempt.fromJson(Map<String, dynamic> json) {
    return MockTestWithAttempt(
      test: MockTestModel.fromJson(json['test'] as Map<String, dynamic>? ?? json),
      attempt: ExamAttempt.fromJson(json['attempt'] as Map<String, dynamic>? ?? {}),
    );
  }
}

/// Exam review with full answers
class ExamReview {
  final ExamAttemptSummary attempt;
  final MockTestModel test;
  final List<AnswerReview> answers;

  ExamReview({
    required this.attempt,
    required this.test,
    this.answers = const [],
  });

  factory ExamReview.fromJson(Map<String, dynamic> json) {
    return ExamReview(
      attempt: ExamAttemptSummary.fromJson(json['attempt'] as Map<String, dynamic>? ?? {}),
      test: MockTestModel.fromJson(json['test'] as Map<String, dynamic>? ?? {}),
      answers: (json['answers'] as List<dynamic>?)
              ?.map((e) => AnswerReview.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

