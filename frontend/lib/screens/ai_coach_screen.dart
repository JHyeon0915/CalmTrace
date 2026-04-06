import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/ai_coach_service.dart';
import '../services/goals_service.dart';
import '../widgets/ai_coach/coach_app_bar.dart';
import '../widgets/ai_coach/ai_avatar.dart';
import '../widgets/ai_coach/chat_bubble.dart';
import '../widgets/ai_coach/typing_indicator.dart';
import '../widgets/ai_coach/quick_choices.dart';
import '../widgets/ai_coach/chat_input_bar.dart';

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final AICoachService _aiService = AICoachService();
  final GoalsService _goalsService = GoalsService();

  List<AIChatMessage> _messages = [];
  List<QuickResponse> _quickResponses = [];
  bool _isTyping = false;
  bool _showChoices = true;
  bool _isLoading = true;
  bool _aiAvailable = false;
  int? _currentStressLevel;
  bool _goalCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    try {
      final status = await _aiService.getStatus();
      if (mounted) {
        setState(() {
          _aiAvailable = status.available;
          _quickResponses = status.quickResponses;
          _messages = [
            AIChatMessage(role: 'assistant', content: status.greeting),
          ];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error initializing chat: $e');
      if (mounted) {
        setState(() {
          _messages = [
            AIChatMessage(
              role: 'assistant',
              content:
                  "Hello! I'm your stress support coach. I'm here to help you explore techniques that might work for you. What would you like to try?",
            ),
          ];
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleQuickChoice(QuickResponse choice) {
    setState(() => _showChoices = false);
    _sendMessage(choice.message);
  }

  Future<void> _sendMessage([String? text]) async {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    final userMessage = AIChatMessage(role: 'user', content: messageText);
    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _showChoices = false;
    });
    _textController.clear();
    _scrollToBottom();

    try {
      final history = _messages
          .where((m) => m != userMessage)
          .map((m) => AIChatMessage(role: m.role, content: m.content))
          .toList();

      final response = await _aiService.sendMessage(
        message: messageText,
        conversationHistory: history,
        stressLevel: _currentStressLevel,
      );

      if (!mounted) return;
      setState(() {
        _messages.add(
          AIChatMessage(role: 'assistant', content: response.response),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    } catch (e) {
      debugPrint('❌ Error getting AI response: $e');
      if (!mounted) return;
      setState(() {
        _messages.add(
          AIChatMessage(
            role: 'assistant',
            content:
                "I'm having trouble responding right now. Let's try again - what's on your mind?",
          ),
        );
        _isTyping = false;
      });
      _scrollToBottom();
    }

    if (!_goalCompleted) {
      _goalCompleted = true;
      _completeGoalIfNeeded();
    }
  }

  Future<void> _completeGoalIfNeeded() async {
    try {
      final goalsData = await _goalsService.getDailyGoals();
      final match = goalsData.goals.where(
        (g) => g.goalType == 'chat' && !g.isCompleted,
      );
      if (match.isNotEmpty) await _goalsService.completeGoal('chat');
    } catch (e) {
      debugPrint('❌ [AICoachScreen] Error completing goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: CoachAppBar(aiAvailable: _aiAvailable),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildChatArea()),
                ChatInputBar(
                  controller: _textController,
                  focusNode: _focusNode,
                  isTyping: _isTyping,
                  onSend: _sendMessage,
                ),
              ],
            ),
    );
  }

  Widget _buildChatArea() {
    return Column(
      children: [
        // Fixed avatar at the top
        Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
          child: AIAvatar(isSpeaking: _isTyping),
        ),
        // Scrollable chat messages
        Expanded(
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
            children: [
              ..._messages.map((msg) => ChatBubble(message: msg)),
              if (_isTyping) const TypingIndicator(),
              if (_showChoices &&
                  _messages.length == 1 &&
                  _quickResponses.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                QuickChoices(
                  quickResponses: _quickResponses,
                  onChoiceSelected: _handleQuickChoice,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
