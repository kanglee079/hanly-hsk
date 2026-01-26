import 'package:get/get.dart';

class RequestMetricsService extends GetxService {
  final RxInt totalRequests = 0.obs;
  final RxInt totalFailures = 0.obs;

  void recordRequest() => totalRequests.value++;
  void recordFailure() => totalFailures.value++;
}
