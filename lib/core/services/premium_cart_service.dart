import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/models.dart';

/// Status of a cart automation job
enum CartJobStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

/// Result of cart creation job
class CartJob {
  final String jobId;
  final CartJobStatus status;
  final String? shareUrl;
  final String? errorMessage;
  final int? estimatedTime;
  final int itemCount;
  final DateTime createdAt;
  final DateTime? completedAt;
  final List<CartJobLog> logs;

  CartJob({
    required this.jobId,
    required this.status,
    this.shareUrl,
    this.errorMessage,
    this.estimatedTime,
    required this.itemCount,
    required this.createdAt,
    this.completedAt,
    this.logs = const [],
  });

  factory CartJob.fromJson(Map<String, dynamic> json) {
    return CartJob(
      jobId: json['jobId'] as String,
      status: _parseStatus(json['status'] as String),
      shareUrl: json['shareUrl'] as String?,
      errorMessage: json['errorMessage'] as String?,
      estimatedTime: json['estimatedTime'] as int?,
      itemCount: json['itemCount'] as int? ?? 0,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      completedAt: json['completedAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['completedAt'] as int)
          : null,
      logs: (json['logs'] as List<dynamic>?)
              ?.map((log) => CartJobLog.fromJson(log as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  static CartJobStatus _parseStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return CartJobStatus.pending;
      case 'processing':
        return CartJobStatus.processing;
      case 'completed':
        return CartJobStatus.completed;
      case 'failed':
        return CartJobStatus.failed;
      case 'cancelled':
        return CartJobStatus.cancelled;
      default:
        return CartJobStatus.pending;
    }
  }

  bool get isComplete =>
      status == CartJobStatus.completed ||
      status == CartJobStatus.failed ||
      status == CartJobStatus.cancelled;

  bool get isSuccess => status == CartJobStatus.completed && shareUrl != null;
}

/// Log entry for a cart job
class CartJobLog {
  final String level;
  final String message;
  final DateTime timestamp;

  CartJobLog({
    required this.level,
    required this.message,
    required this.timestamp,
  });

  factory CartJobLog.fromJson(Map<String, dynamic> json) {
    return CartJobLog(
      level: json['level'] as String,
      message: json['message'] as String,
      timestamp: DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int),
    );
  }
}

/// Service for creating automated shopping carts via backend
class PremiumCartService {
  final String baseUrl;
  final String Function() getAuthToken;

  PremiumCartService({
    required this.baseUrl,
    required this.getAuthToken,
  });

  /// Create a Walmart cart automation job
  Future<CartJob> createWalmartCart(
    List<GroceryItem> items, {
    String? webhookUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/cart/create-walmart'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'items': items
              .map((item) => {
                    'name': item.name,
                    'quantity': item.quantity ?? 1,
                  })
              .toList(),
          'webhookUrl': webhookUrl,
        }),
      );

      if (response.statusCode == 403) {
        throw PremiumRequiredException(
          'Premium subscription required for automated cart creation',
        );
      }

      if (response.statusCode != 201) {
        final error = jsonDecode(response.body);
        throw CartServiceException(
          error['error'] ?? 'Failed to create cart job',
        );
      }

      final data = jsonDecode(response.body);
      return CartJob.fromJson(data);
    } catch (e) {
      if (e is PremiumRequiredException || e is CartServiceException) {
        rethrow;
      }
      throw CartServiceException('Network error: $e');
    }
  }

  /// Get status of a cart job
  Future<CartJob> getJobStatus(String jobId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/job/$jobId'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        throw CartServiceException('Failed to fetch job status');
      }

      final data = jsonDecode(response.body);
      return CartJob.fromJson(data);
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException('Network error: $e');
    }
  }

  /// Watch a cart job until completion
  /// Returns a stream that emits job status updates
  Stream<CartJob> watchCartJob(String jobId) async* {
    while (true) {
      final job = await getJobStatus(jobId);
      yield job;

      if (job.isComplete) {
        break;
      }

      // Poll every 2 seconds
      await Future.delayed(const Duration(seconds: 2));
    }
  }

  /// Get all cart jobs for current user
  Future<List<CartJob>> getUserJobs({int limit = 50}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cart/jobs?limit=$limit'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        throw CartServiceException('Failed to fetch jobs');
      }

      final data = jsonDecode(response.body);
      final jobs = (data['jobs'] as List<dynamic>)
          .map((job) => CartJob.fromJson(job as Map<String, dynamic>))
          .toList();

      return jobs;
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException('Network error: $e');
    }
  }

  /// Cancel a pending job
  Future<void> cancelJob(String jobId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/cart/job/$jobId'),
        headers: {
          'Authorization': 'Bearer ${getAuthToken()}',
        },
      );

      if (response.statusCode != 200) {
        final error = jsonDecode(response.body);
        throw CartServiceException(
          error['error'] ?? 'Failed to cancel job',
        );
      }
    } catch (e) {
      if (e is CartServiceException) rethrow;
      throw CartServiceException('Network error: $e');
    }
  }

  /// Check backend health
  Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/health'),
      ).timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}

/// Exception thrown when premium subscription is required
class PremiumRequiredException implements Exception {
  final String message;
  PremiumRequiredException(this.message);

  @override
  String toString() => message;
}

/// Exception thrown when cart service encounters an error
class CartServiceException implements Exception {
  final String message;
  CartServiceException(this.message);

  @override
  String toString() => message;
}
