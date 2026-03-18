import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_theme.dart';

import '../../../core/services/ml_service.dart';
import '../../../core/services/app_ai_service.dart';
import '../../../providers/finance_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

class AIChatInterface extends ConsumerStatefulWidget {
  const AIChatInterface({super.key});

  @override
  ConsumerState<AIChatInterface> createState() => _AIChatInterfaceState();
}

class _AIChatInterfaceState extends ConsumerState<AIChatInterface> {
  final TextEditingController _controller = TextEditingController();
  final List<Message> _messages = [];

  @override
  void initState() {
    super.initState();
    _loadInitialMessage();
  }

  void _loadInitialMessage() async {
    final name = await MLService.getUserName() ?? 'Alex';
    setState(() {
      _messages.add(Message(
        text: "Hello $name! I analyzed your recent transactions. You're doing great, but I noticed a spike in food delivery.",
        isUser: false,
      ));
    });
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;
    
    final text = _controller.text;
    setState(() {
      _messages.insert(0, Message(text: text, isUser: true));
    });
    
    _controller.clear();
    
    // Process with AppAIService
    final transactions = ref.read(transactionProvider);
    final response = AppAIService.processQuery(text, transactions);

    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _messages.insert(0, Message(
            text: response,
            isUser: false,
          ));
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppTheme.cardShadow,
        border: Border.all(color: AppColors.primaryAccent.withOpacity(0.1)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.background.withOpacity(0.5),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppSpacing.radius),
                topRight: Radius.circular(AppSpacing.radius),
              ),
            ),
            child: Row(
              children: [
                Icon(LucideIcons.bot, color: AppColors.primaryAccent, size: 20),
                const Gap(8),
                Text(
                  'FinSight AI',
                  style: AppTypography.textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 250,
            child: ListView.separated(
              reverse: true,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              separatorBuilder: (context, index) => const Gap(12),
              itemBuilder: (context, index) {
                final msg = _messages[index];
                return Align(
                  alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: msg.isUser ? AppColors.primaryAccent : AppColors.background,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(msg.isUser ? 16 : 4),
                        bottomRight: Radius.circular(msg.isUser ? 4 : 16),
                      ),
                    ),
                    child: Text(
                      msg.text,
                      style: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: msg.isUser ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: 'Ask about your spending...',
                      hintStyle: AppTypography.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    style: AppTypography.textTheme.bodyMedium,
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(LucideIcons.send, color: AppColors.primaryAccent),
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.primaryAccent.withOpacity(0.1),
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

class Message {
  final String text;
  final bool isUser;

  Message({required this.text, required this.isUser});
}
