import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/gemini_provider.dart';
import '../providers/transaction_provider.dart';
import '../models/chat_message.dart';
import '../theme/app_theme.dart';
import '../utils/app_env.dart';

class AiChatScreen extends StatefulWidget {
  const AiChatScreen({super.key});

  @override
  State<AiChatScreen> createState() => _AiChatScreenState();
}

class _AiChatScreenState extends State<AiChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send(GeminiProvider gemini, TransactionProvider tx, {String? quickText}) async {
    final text = quickText ?? _controller.text.trim();
    if (text.isEmpty || gemini.isChatLoading) return;
    _controller.clear();
    await gemini.sendMessage(text, tx);
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<GeminiProvider, TransactionProvider>(
      builder: (context, gemini, tx, _) {
        _scrollToBottom();
        return Scaffold(
          backgroundColor: AppTheme.backgroundLight,
          appBar: AppBar(
            title: const Row(
              children: [
                Icon(Icons.auto_awesome, color: Color(0xFFFFD700), size: 20),
                SizedBox(width: 8),
                Text('AI 소비 상담'),
              ],
            ),
            flexibleSpace: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryBlue, AppTheme.primaryTeal],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                tooltip: '대화 초기화',
                onPressed: () => gemini.clearChat(),
              ),
            ],
          ),
          body: !AppEnv.geminiEnabled
              ? _buildApiKeyNotice()
              : Column(
                  children: [
                    Expanded(
                      child: gemini.chatHistory.isEmpty
                          ? _buildWelcome()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              itemCount: gemini.chatHistory.length + (gemini.isChatLoading ? 1 : 0),
                              itemBuilder: (ctx, idx) {
                                if (idx == gemini.chatHistory.length) {
                                  return _buildTypingIndicator();
                                }
                                return _buildBubble(gemini.chatHistory[idx]);
                              },
                            ),
                    ),
                    _buildQuickButtons(gemini, tx),
                    _buildInputBar(gemini, tx),
                  ],
                ),
        );
      },
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.auto_awesome, color: AppTheme.primaryBlue, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('AI 재무 상담사', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppTheme.textPrimary)),
            const SizedBox(height: 8),
            const Text(
              '이번 달 소비 데이터를 기반으로\n맞춤형 재무 상담을 제공합니다.',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(ChatMessage msg) {
    final isUser = msg.role == ChatRole.user;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            Container(
              width: 32, height: 32,
              decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
              child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? AppTheme.primaryBlue : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(18),
                  topRight: const Radius.circular(18),
                  bottomLeft: Radius.circular(isUser ? 18 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 18),
                ),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6, offset: const Offset(0, 2)),
                ],
              ),
              child: Text(
                msg.text,
                style: TextStyle(
                  fontSize: 14,
                  color: isUser ? Colors.white : AppTheme.textPrimary,
                  height: 1.5,
                ),
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 6)],
            ),
            child: const SizedBox(
              width: 40, height: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _Dot(delay: 0),
                  _Dot(delay: 200),
                  _Dot(delay: 400),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickButtons(GeminiProvider gemini, TransactionProvider tx) {
    final questions = ['이번 달 얼마 썼어?', '어디서 가장 많이 썼어?', '절약 팁 알려줘'];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: questions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (ctx, idx) => ActionChip(
          label: Text(questions[idx], style: const TextStyle(fontSize: 12)),
          onPressed: gemini.isChatLoading ? null : () => _send(gemini, tx, quickText: questions[idx]),
          backgroundColor: AppTheme.primaryBlue.withValues(alpha: 0.08),
          side: BorderSide(color: AppTheme.primaryBlue.withValues(alpha: 0.3)),
        ),
      ),
    );
  }

  Widget _buildInputBar(GeminiProvider gemini, TransactionProvider tx) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 8, offset: const Offset(0, -2))],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: '소비 관련 질문을 입력하세요...',
                  hintStyle: const TextStyle(fontSize: 14, color: AppTheme.textLight),
                  filled: true,
                  fillColor: AppTheme.backgroundLight,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                onSubmitted: (_) => _send(gemini, tx),
                textInputAction: TextInputAction.send,
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: gemini.isChatLoading ? null : () => _send(gemini, tx),
              child: Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: gemini.isChatLoading ? AppTheme.textLight : AppTheme.primaryBlue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyNotice() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.key_off, color: AppTheme.textLight, size: 64),
            const SizedBox(height: 16),
            const Text('Gemini API 키 미설정', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            const Text(
              '실행 시 아래 옵션을 추가하세요:\n--dart-define=GEMINI_API_KEY=AIza...',
              style: TextStyle(fontSize: 13, color: AppTheme.textSecondary, height: 1.6),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _Dot extends StatefulWidget {
  final int delay;
  const _Dot({required this.delay});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))
      ..repeat(reverse: true);
    _anim = Tween(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut),
    );
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 8, height: 8,
        decoration: const BoxDecoration(color: AppTheme.primaryBlue, shape: BoxShape.circle),
      ),
    );
  }
}
