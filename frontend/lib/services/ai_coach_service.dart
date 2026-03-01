import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_client.dart';

/// Message model for AI Coach
class AIChatMessage {
  final String role; // 'user' or 'assistant'
  final String content;
  final DateTime timestamp;

  AIChatMessage({
    required this.role,
    required this.content,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {'role': role, 'content': content};

  factory AIChatMessage.fromJson(Map<String, dynamic> json) {
    return AIChatMessage(
      role: json['role'] ?? 'assistant',
      content: json['content'] ?? '',
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  bool get isUser => role == 'user';
  bool get isAssistant => role == 'assistant';
}

/// Quick response option
class QuickResponse {
  final String id;
  final String label;
  final String message;

  QuickResponse({required this.id, required this.label, required this.message});

  factory QuickResponse.fromJson(Map<String, dynamic> json) {
    return QuickResponse(
      id: json['id'] ?? '',
      label: json['label'] ?? '',
      message: json['message'] ?? '',
    );
  }
}

/// AI Coach status
class AICoachStatus {
  final bool available;
  final String model;
  final String greeting;
  final List<QuickResponse> quickResponses;

  AICoachStatus({
    required this.available,
    required this.model,
    required this.greeting,
    required this.quickResponses,
  });

  factory AICoachStatus.fromJson(Map<String, dynamic> json) {
    return AICoachStatus(
      available: json['available'] ?? false,
      model: json['model'] ?? 'unknown',
      greeting: json['greeting'] ?? "Hello! How can I help you today?",
      quickResponses:
          (json['quick_responses'] as List?)
              ?.map((e) => QuickResponse.fromJson(e))
              .toList() ??
          [],
    );
  }
}

/// AI Coach chat response
class AIChatResponse {
  final bool success;
  final String response;
  final String? error;
  final String? model;
  final DateTime timestamp;

  AIChatResponse({
    required this.success,
    required this.response,
    this.error,
    this.model,
    required this.timestamp,
  });

  factory AIChatResponse.fromJson(Map<String, dynamic> json) {
    return AIChatResponse(
      success: json['success'] ?? false,
      response: json['response'] ?? '',
      error: json['error'],
      model: json['model'],
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }
}

/// AI Coach Service
class AICoachService {
  final ApiClient _apiClient = ApiClient();

  /// Get AI coach status and initial greeting
  Future<AICoachStatus> getStatus() async {
    try {
      final response = await _apiClient.get('/ai-coach/status');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AICoachStatus.fromJson(data);
      } else {
        debugPrint('❌ Failed to get AI coach status: ${response.body}');
        return AICoachStatus(
          available: false,
          model: 'unknown',
          greeting:
              "Hello! I'm your stress support coach. How can I help you today?",
          quickResponses: [],
        );
      }
    } catch (e) {
      debugPrint('❌ Error getting AI coach status: $e');
      return AICoachStatus(
        available: false,
        model: 'unknown',
        greeting:
            "Hello! I'm your stress support coach. How can I help you today?",
        quickResponses: [],
      );
    }
  }

  /// Send a message to the AI coach
  Future<AIChatResponse> sendMessage({
    required String message,
    List<AIChatMessage>? conversationHistory,
    int? stressLevel,
  }) async {
    try {
      final body = <String, dynamic>{'message': message};

      if (conversationHistory != null && conversationHistory.isNotEmpty) {
        body['conversation_history'] = conversationHistory
            .map((m) => m.toJson())
            .toList();
      }

      if (stressLevel != null) {
        body['stress_level'] = stressLevel;
      }

      final response = await _apiClient.post('/ai-coach/chat', body: body);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return AIChatResponse.fromJson(data);
      } else {
        debugPrint('❌ AI chat failed: ${response.body}');
        return AIChatResponse(
          success: false,
          response: "I'm having trouble connecting. Please try again.",
          error: 'Request failed: ${response.statusCode}',
          timestamp: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('❌ Error sending message: $e');
      return AIChatResponse(
        success: false,
        response: "I'm having trouble connecting. Please try again.",
        error: e.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// Get chat history
  Future<List<AIChatMessage>> getChatHistory({int limit = 50}) async {
    try {
      final response = await _apiClient.get('/ai-coach/history?limit=$limit');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final history = data['history'] as List? ?? [];

        final messages = <AIChatMessage>[];
        for (final item in history) {
          messages.add(
            AIChatMessage(
              role: 'user',
              content: item['user_message'],
              timestamp: DateTime.parse(item['timestamp']),
            ),
          );
          messages.add(
            AIChatMessage(
              role: 'assistant',
              content: item['ai_response'],
              timestamp: DateTime.parse(item['timestamp']),
            ),
          );
        }
        return messages;
      }
      return [];
    } catch (e) {
      debugPrint('❌ Error getting chat history: $e');
      return [];
    }
  }
}
