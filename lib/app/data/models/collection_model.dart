import 'package:flutter/material.dart';
import 'vocab_model.dart';

/// Collection model - matches BE API response
class CollectionModel {
  final String id;
  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final int wordCount;
  final String? level;
  final String? topic;
  final String type; // 'level', 'topic', 'special'

  CollectionModel({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.wordCount,
    this.level,
    this.topic,
    required this.type,
  });

  factory CollectionModel.fromJson(Map<String, dynamic> json) {
    return CollectionModel(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      subtitle: json['subtitle'] ?? '',
      badge: json['badge'] ?? '',
      badgeColor: _parseColor(json['badgeColor']),
      wordCount: json['wordCount'] ?? 0,
      level: json['level'],
      topic: json['topic'],
      type: json['type'] ?? 'special',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'subtitle': subtitle,
    'badge': badge,
    'badgeColor': '#${badgeColor.toARGB32().toRadixString(16).padLeft(8, '0').substring(2)}',
    'wordCount': wordCount,
    'level': level,
    'topic': topic,
    'type': type,
  };

  static Color _parseColor(String? colorStr) {
    if (colorStr == null || colorStr.isEmpty) {
      return const Color(0xFF2196F3); // Default blue
    }
    try {
      String hex = colorStr.replaceAll('#', '');
      if (hex.length == 6) {
        hex = 'FF$hex'; // Add alpha if not present
      }
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF2196F3);
    }
  }
}

/// Collection detail response with vocabs and pagination
class CollectionDetailResponse {
  final CollectionModel collection;
  final List<VocabModel> vocabs;
  final PaginationInfo pagination;

  CollectionDetailResponse({
    required this.collection,
    required this.vocabs,
    required this.pagination,
  });

  factory CollectionDetailResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    
    return CollectionDetailResponse(
      collection: CollectionModel.fromJson(data['collection'] ?? {}),
      vocabs: (data['vocabs'] as List<dynamic>?)
          ?.map((e) => VocabModel.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      pagination: PaginationInfo.fromJson(json['pagination'] ?? {}),
    );
  }
}

/// Pagination info
class PaginationInfo {
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final bool hasNext;
  final bool hasPrev;

  PaginationInfo({
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.hasNext,
    required this.hasPrev,
  });

  factory PaginationInfo.fromJson(Map<String, dynamic> json) {
    return PaginationInfo(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 20,
      total: json['total'] ?? 0,
      totalPages: json['totalPages'] ?? 0,
      hasNext: json['hasNext'] ?? false,
      hasPrev: json['hasPrev'] ?? false,
    );
  }
}

