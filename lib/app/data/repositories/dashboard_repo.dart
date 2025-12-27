import '../models/dashboard_model.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';

/// Dashboard repository - aggregated data loading
class DashboardRepo {
  final ApiClient _apiClient;

  DashboardRepo(this._apiClient);

  /// Get aggregated dashboard data (me + today + studyModes)
  /// One request replaces multiple
  Future<DashboardModel> getDashboard() async {
    final response = await _apiClient.get(ApiEndpoints.dashboard);
    return DashboardModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get forecast for next X days
  Future<ForecastModel> getForecast({int days = 7}) async {
    final response = await _apiClient.get(
      ApiEndpoints.todayForecast,
      queryParameters: {'days': days},
    );
    return ForecastModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get words learned today
  Future<LearnedTodayModel> getLearnedToday() async {
    final response = await _apiClient.get(ApiEndpoints.todayLearnedToday);
    return LearnedTodayModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }

  /// Get daily pick word
  Future<DailyPickModel> getDailyPick() async {
    final response = await _apiClient.get(ApiEndpoints.dailyPick);
    return DailyPickModel.fromJson(response.data['data'] as Map<String, dynamic>);
  }
}

