import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../services/ai_coach_service.dart';

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

  List<AIChatMessage> _messages = [];
  List<QuickResponse> _quickResponses = [];
  bool _isTyping = false;
  bool _showChoices = true;
  bool _isLoading = true;
  bool _aiAvailable = false;
  int? _currentStressLevel;

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

    // Add user message
    final userMessage = AIChatMessage(role: 'user', content: messageText);

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
      _showChoices = false;
    });

    _textController.clear();
    _scrollToBottom();

    try {
      // Build conversation history (exclude the message we just added)
      final history = _messages
          .where((m) => m != userMessage)
          .map((m) => AIChatMessage(role: m.role, content: m.content))
          .toList();

      // Call AI API
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(child: _buildChatArea()),
                _buildInputArea(),
              ],
            ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.background,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
        onPressed: () => Navigator.pop(context),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Stress Coach',
            style: AppTextStyles.bodyLarge.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFB4A7D6).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _aiAvailable
                            ? AppColors.success
                            : AppColors.error,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'AI-powered',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: const Color(0xFFB4A7D6),
                        fontWeight: FontWeight.w500,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '• Not medical advice',
                style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textHint,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ],
      ),
      titleSpacing: 0,
    );
  }

  Widget _buildChatArea() {
    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        // AI Avatar
        Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
            child: _AIAvatar(isSpeaking: _isTyping),
          ),
        ),

        // Messages
        ..._messages.map((msg) => _buildMessageBubble(msg)),

        // Typing indicator
        if (_isTyping) _buildTypingIndicator(),

        // Quick choices (only show at start)
        if (_showChoices &&
            _messages.length == 1 &&
            _quickResponses.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _buildQuickChoices(),
        ],
      ],
    );
  }

  Widget _buildMessageBubble(AIChatMessage message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: message.isUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: message.isUser
                  ? const Color(0xFF6B9BD1)
                  : AppColors.background,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(16),
                topRight: const Radius.circular(16),
                bottomLeft: Radius.circular(message.isUser ? 16 : 4),
                bottomRight: Radius.circular(message.isUser ? 4 : 16),
              ),
              border: message.isUser
                  ? null
                  : Border.all(color: AppColors.border),
              boxShadow: message.isUser
                  ? null
                  : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Text(
              message.content,
              style: AppTextStyles.bodyMedium.copyWith(
                color: message.isUser ? Colors.white : AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (index) {
                return _BouncingDot(delay: index * 0.2);
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChoices() {
    // Default choices if none from API
    final choices = _quickResponses.isNotEmpty
        ? _quickResponses
        : [
            QuickResponse(
              id: 'breathing',
              label: 'Breathing Exercise',
              message: "I'd like to try a breathing exercise",
            ),
            QuickResponse(
              id: 'grounding',
              label: 'Grounding Technique',
              message: 'Can you guide me through a grounding technique?',
            ),
            QuickResponse(
              id: 'talk',
              label: 'Just Talk',
              message: 'I just need someone to talk to',
            ),
          ];

    final icons = {
      'breathing': Icons.air,
      'grounding': Icons.local_florist,
      'talk': Icons.chat_bubble_outline,
      'stressed': Icons.favorite_outline,
    };

    final colors = {
      'breathing': const Color(0xFF6B9BD1),
      'grounding': const Color(0xFF8FB996),
      'talk': const Color(0xFFB4A7D6),
      'stressed': const Color(0xFFE89B9B),
    };

    return Column(
      children: [
        Text(
          "Choose what you'd like to explore:",
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: AppSpacing.md),
        ...choices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildChoiceButton(
              choice,
              icons[choice.id] ?? Icons.arrow_forward,
              colors[choice.id] ?? const Color(0xFF6B9BD1),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(QuickResponse choice, IconData icon, Color color) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.lgBorder,
      child: InkWell(
        onTap: () => _handleQuickChoice(choice),
        borderRadius: AppRadius.lgBorder,
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: AppRadius.lgBorder,
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  choice.label,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _textController,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textHint,
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Material(
              color: const Color(0xFF6B9BD1),
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _isTyping ? null : () => _sendMessage(),
                borderRadius: BorderRadius.circular(24),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.send,
                    color: _isTyping ? Colors.white54 : Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Keep the _AIAvatar, _BouncingDot, etc. widgets from the previous version
// (I'll include them for completeness)

class _AIAvatar extends StatefulWidget {
  final bool isSpeaking;
  const _AIAvatar({this.isSpeaking = false});

  @override
  State<_AIAvatar> createState() => _AIAvatarState();
}

class _AIAvatarState extends State<_AIAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    if (widget.isSpeaking) _pulseController.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_AIAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _pulseController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _pulseController.stop();
      _pulseController.reset();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: widget.isSpeaking ? _pulseAnimation.value : 1.0,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(
                      0xFFB4A7D6,
                    ).withValues(alpha: widget.isSpeaking ? 0.4 : 0.3),
                  ),
                ),
              );
            },
          ),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: const Color(0xFFB4A7D6), width: 2),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: widget.isSpeaking ? 12 : 10,
                  height: widget.isSpeaking ? 8 : 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: AppColors.textPrimary.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BouncingDot extends StatefulWidget {
  final double delay;
  const _BouncingDot({required this.delay});

  @override
  State<_BouncingDot> createState() => _BouncingDotState();
}

class _BouncingDotState extends State<_BouncingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _animation = Tween<double>(
      begin: 0,
      end: -6,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
    Future.delayed(Duration(milliseconds: (widget.delay * 200).toInt()), () {
      if (mounted) _controller.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 2),
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textHint,
            ),
          ),
        );
      },
    );
  }
}
