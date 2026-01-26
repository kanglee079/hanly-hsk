import 'package:dio/dio.dart';
import '../network/api_client.dart';
import '../network/api_endpoints.dart';
import '../../core/utils/logger.dart';

class DatasetMeta {
  final String version;
  final String checksum;
  final String updatedAt;
  final int count;

  DatasetMeta({
    required this.version,
    required this.checksum,
    required this.updatedAt,
    required this.count,
  });

  factory DatasetMeta.fromJson(Map<String, dynamic> json) {
    return DatasetMeta(
      version: json['version'] as String? ?? '0',
      checksum: json['checksum'] as String? ?? '',
      updatedAt: json['updatedAt'] as String? ?? '',
      count: json['count'] as int? ?? 0,
    );
  }
}

class DatasetPayload {
  final DatasetMeta meta;
  final List<Map<String, dynamic>> vocabs;

  DatasetPayload({
    required this.meta,
    required this.vocabs,
  });
}

class DatasetRepo {
  final ApiClient _api;

  DatasetRepo(this._api);

  Future<DatasetMeta> getDatasetMeta() async {
    final response = await _api.get(ApiEndpoints.offlineDatasetMeta);
    final data = response.data;

    if (data is Map<String, dynamic> && data['success'] == false) {
      final error = data['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ?? 'Dataset meta error');
    }

    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    return DatasetMeta.fromJson(payload);
  }

  Future<DatasetPayload> downloadDataset({
    void Function(int received, int total)? onProgress,
  }) async {
    final response = await _api.dio.get(
      ApiEndpoints.offlineDataset,
      options: Options(responseType: ResponseType.json),
      onReceiveProgress: onProgress,
    );

    final data = response.data;
    if (data is Map<String, dynamic> && data['success'] == false) {
      final error = data['error'] as Map<String, dynamic>?;
      throw Exception(error?['message'] ?? 'Dataset download error');
    }

    final payload = (data['data'] ?? data) as Map<String, dynamic>;
    final meta = DatasetMeta.fromJson(payload);
    final rawVocabs = payload['vocabs'] as List<dynamic>? ?? [];
    final vocabs = rawVocabs
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();

    Logger.d('DatasetRepo', 'Downloaded dataset: ${vocabs.length} items');

    return DatasetPayload(meta: meta, vocabs: vocabs);
  }
}
