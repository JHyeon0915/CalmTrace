import 'dart:async';
import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Message model for chat
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}

/// Quick choice option
class QuickChoice {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const QuickChoice({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });
}

class AICoachScreen extends StatefulWidget {
  const AICoachScreen({super.key});

  @override
  State<AICoachScreen> createState() => _AICoachScreenState();
}

class _AICoachScreenState extends State<AICoachScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();

  List<ChatMessage> _messages = [];
  bool _isTyping = false;
  bool _showChoices = true;

  final List<QuickChoice> _quickChoices = const [
    QuickChoice(
      id: 'breathing',
      label: 'Breathing Exercise',
      icon: Icons.air,
      color: Color(0xFF6B9BD1),
    ),
    QuickChoice(
      id: 'grounding',
      label: 'Grounding Technique',
      icon: Icons.local_florist,
      color: Color(0xFF8FB996),
    ),
    QuickChoice(
      id: 'reflection',
      label: 'Reflection & Talk',
      icon: Icons.chat_bubble_outline,
      color: Color(0xFFB4A7D6),
    ),
  ];

  @override
  void initState() {
    super.initState();
    // Initial AI greeting
    _messages = [
      ChatMessage(
        id: '1',
        text:
            "Hello, I'm your stress support coach. I'm here to help you explore techniques that might work for you. What would you like to try?",
        isUser: false,
      ),
    ];
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

  void _handleChoiceTap(QuickChoice choice) {
    setState(() => _showChoices = false);
    _sendMessage(choice.label);
  }

  void _sendMessage([String? text]) {
    final messageText = text ?? _textController.text.trim();
    if (messageText.isEmpty) return;

    // Add user message
    setState(() {
      _messages.add(
        ChatMessage(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          text: messageText,
          isUser: true,
        ),
      );
      _isTyping = true;
      _showChoices = false;
    });

    _textController.clear();
    _scrollToBottom();

    // Simulate AI response
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;

      final response = _generateResponse(messageText);

      setState(() {
        _messages.add(
          ChatMessage(
            id: (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            text: response,
            isUser: false,
          ),
        );
        _isTyping = false;
      });

      _scrollToBottom();
    });
  }

  String _generateResponse(String userMessage) {
    final lowerMessage = userMessage.toLowerCase();

    if (lowerMessage.contains('breathing')) {
      return "Great choice. Let's focus on your breath. Try this: Breathe in slowly for 4 counts, hold for 4, then exhale for 6. This activates your parasympathetic nervous system, which helps you feel calmer. Would you like to try it now?";
    } else if (lowerMessage.contains('grounding')) {
      return "Grounding is excellent for bringing you back to the present. Try the 5-4-3-2-1 technique: Name 5 things you see, 4 you can touch, 3 you hear, 2 you smell, and 1 you taste. This helps interrupt anxious thoughts.";
    } else if (lowerMessage.contains('reflection')) {
      return "Reflection can help you understand your stress patterns. What's one thing that's been on your mind today? Sometimes just naming it can reduce its power.";
    } else if (lowerMessage.contains('anxious') ||
        lowerMessage.contains('stressed') ||
        lowerMessage.contains('anxiety')) {
      return "I hear you. It's okay to feel this way. Remember, stress is your body trying to protect you. Let's work with it, not against it. Would you like to try a quick breathing exercise or grounding technique?";
    } else if (lowerMessage.contains('yes') || lowerMessage.contains('try')) {
      return "Perfect! Let's start with a simple breathing exercise. Close your eyes if you're comfortable, and take a deep breath in through your nose for 4 seconds... Hold for 4 seconds... And slowly exhale through your mouth for 6 seconds. How did that feel?";
    } else if (lowerMessage.contains('good') ||
        lowerMessage.contains('better') ||
        lowerMessage.contains('great')) {
      return "That's wonderful to hear! Remember, you can use this technique anytime you feel overwhelmed. Is there anything else you'd like to explore today?";
    } else if (lowerMessage.contains('thank')) {
      return "You're welcome! Remember, taking time for your mental health is a sign of strength, not weakness. I'm here whenever you need support. Take care of yourself! 💚";
    } else {
      return "I'm here to support you. Would you like to explore breathing exercises, grounding techniques, or take a moment to reflect on what you're feeling?";
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: _buildAppBar(),
      body: Column(
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
                child: Text(
                  'AI-generated guidance',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: const Color(0xFFB4A7D6),
                    fontWeight: FontWeight.w500,
                    fontSize: 10,
                  ),
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

        // Quick choices
        if (_showChoices && _messages.length == 1) ...[
          const SizedBox(height: AppSpacing.md),
          _buildQuickChoices(),
        ],
      ],
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
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
              message.text,
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
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: 1),
                  duration: Duration(milliseconds: 600 + (index * 200)),
                  builder: (context, value, child) {
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      child: _BouncingDot(delay: index * 0.2),
                    );
                  },
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickChoices() {
    return Column(
      children: [
        Text(
          "Choose what you'd like to explore:",
          style: AppTextStyles.bodySmall.copyWith(color: AppColors.textHint),
        ),
        const SizedBox(height: AppSpacing.md),
        ..._quickChoices.map(
          (choice) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _buildChoiceButton(choice),
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceButton(QuickChoice choice) {
    return Material(
      color: AppColors.background,
      borderRadius: AppRadius.lgBorder,
      child: InkWell(
        onTap: () => _handleChoiceTap(choice),
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
                  color: choice.color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.mdBorder,
                ),
                child: Icon(choice.icon, color: choice.color, size: 22),
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
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                      color: const Color(0xFF6B9BD1).withValues(alpha: 0.5),
                    ),
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
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(24),
                  ),
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

/// AI Avatar Widget
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

    if (widget.isSpeaking) {
      _pulseController.repeat(reverse: true);
    }
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
          // Pulse background
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

          // Avatar face
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.background,
              border: Border.all(color: const Color(0xFFB4A7D6), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 8),
                // Eyes
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _BlinkingEye(),
                    const SizedBox(width: 12),
                    _BlinkingEye(),
                  ],
                ),
                const SizedBox(height: 6),
                // Mouth
                _AnimatedMouth(isSpeaking: widget.isSpeaking),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Blinking eye widget
class _BlinkingEye extends StatefulWidget {
  @override
  State<_BlinkingEye> createState() => _BlinkingEyeState();
}

class _BlinkingEyeState extends State<_BlinkingEye>
    with SingleTickerProviderStateMixin {
  late AnimationController _blinkController;
  late Animation<double> _blinkAnimation;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );

    _blinkAnimation = Tween<double>(begin: 1.0, end: 0.1).animate(
      CurvedAnimation(parent: _blinkController, curve: Curves.easeInOut),
    );

    // Random blinking
    _startBlinking();
  }

  void _startBlinking() {
    Future.delayed(
      Duration(milliseconds: 3000 + (DateTime.now().millisecond % 2000)),
      () {
        if (mounted) {
          _blinkController.forward().then((_) {
            _blinkController.reverse().then((_) {
              _startBlinking();
            });
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _blinkAnimation,
      builder: (context, child) {
        return Transform.scale(
          scaleY: _blinkAnimation.value,
          child: Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.textPrimary,
            ),
          ),
        );
      },
    );
  }
}

/// Animated mouth widget
class _AnimatedMouth extends StatefulWidget {
  final bool isSpeaking;

  const _AnimatedMouth({required this.isSpeaking});

  @override
  State<_AnimatedMouth> createState() => _AnimatedMouthState();
}

class _AnimatedMouthState extends State<_AnimatedMouth>
    with SingleTickerProviderStateMixin {
  late AnimationController _mouthController;
  late Animation<double> _heightAnimation;
  late Animation<double> _widthAnimation;

  @override
  void initState() {
    super.initState();
    _mouthController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _heightAnimation = Tween<double>(begin: 4, end: 8).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    _widthAnimation = Tween<double>(begin: 10, end: 12).animate(
      CurvedAnimation(parent: _mouthController, curve: Curves.easeInOut),
    );

    if (widget.isSpeaking) {
      _mouthController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(_AnimatedMouth oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSpeaking && !oldWidget.isSpeaking) {
      _mouthController.repeat(reverse: true);
    } else if (!widget.isSpeaking && oldWidget.isSpeaking) {
      _mouthController.stop();
      _mouthController.reset();
    }
  }

  @override
  void dispose() {
    _mouthController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _mouthController,
      builder: (context, child) {
        return Container(
          width: widget.isSpeaking ? _widthAnimation.value : 10,
          height: widget.isSpeaking ? _heightAnimation.value : 4,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: AppColors.textPrimary.withValues(alpha: 0.6),
          ),
        );
      },
    );
  }
}

/// Bouncing dot for typing indicator
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
      if (mounted) {
        _controller.repeat(reverse: true);
      }
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
