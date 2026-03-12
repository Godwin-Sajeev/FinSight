import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/services/ml_service.dart';
import '../../providers/finance_provider.dart';
import '../ai_center/widgets/ai_chat_interface.dart';
import '../../core/models/transaction_model.dart';

class AIHubSheet extends StatefulWidget {
  const AIHubSheet({super.key});

  @override
  State<AIHubSheet> createState() => _AIHubSheetState();
}

class _AIHubSheetState extends State<AIHubSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Color(0xFFF4F6FA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(AppSpacing.radius),
              topRight: Radius.circular(AppSpacing.radius),
            ),
          ),
          child: Column(
            children: [
              // ── Drag handle ──────────────────────────────────────
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // ── Header ──────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primaryAccent, Color(0xFF8C7BFF)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(LucideIcons.sparkles,
                          color: Colors.white, size: 18),
                    ),
                    const Gap(12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'FinSight AI',
                          style: AppTypography.textTheme.titleLarge,
                        ),
                        Text(
                          'Your Financial Intelligence Hub',
                          style: AppTypography.textTheme.labelSmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Gap(16),
              // ── Tab Bar ─────────────────────────────────────────
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.divider.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.primaryAccent,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textSecondary,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                  dividerColor: Colors.transparent,
                  tabs: const [
                    Tab(text: 'Insights'),
                    Tab(text: 'Chat'),
                    Tab(text: 'Actions'),
                  ],
                ),
              ),
              const Gap(8),
              // ── Tab Views ────────────────────────────────────────
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _InsightsTab(scrollController: scrollController),
                    _ChatTab(scrollController: scrollController),
                    _ActionsTab(scrollController: scrollController),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── INSIGHTS TAB (Live ML Data) ────────────────────────────────────────────
class _InsightsTab extends ConsumerStatefulWidget {
  final ScrollController scrollController;
  const _InsightsTab({required this.scrollController});

  @override
  ConsumerState<_InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends ConsumerState<_InsightsTab> {
  BudgetResult? _budget;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBudget();
  }

  Future<void> _fetchBudget() async {
    final transactions = ref.read(transactionProvider);
    final txList = transactions
        .where((t) => t.isExpense)
        .map((t) => {
              'amount':   t.amount,
              'category': t.category,
              'status':   'Success',
            })
        .toList();

    final result = await MLService.getBudgetSummary(
      transactions:   txList,
      monthlyBudget:  15000.0,
    );

    if (mounted) {
      setState(() {
        _budget  = result;
        _loading = false;
        _error   = result == null ? 'ML server not reachable. Start the Python server.' : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return _buildOfflineView();
    }

    final b = _budget!;
    final spentPct  = b.monthlySpendPercentage ?? 0;
    final remaining = b.remainingBudget;

    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Budget warning banner
        if (b.isOverBudget)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(
              color: AppColors.danger.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: AppColors.danger, size: 18),
                const Gap(8),
                Expanded(
                  child: Text(b.budgetAlertMessage,
                      style: AppTypography.textTheme.labelSmall
                          ?.copyWith(color: AppColors.danger)),
                ),
              ],
            ),
          ),

        _insightCard(
          icon:      LucideIcons.trendingUp,
          color:     AppColors.primaryAccent,
          title:     'Monthly Spend',
          value:     'INR ${b.totalMonthlySpend.toStringAsFixed(0)}',
          subtitle:  '${spentPct.toStringAsFixed(1)}% of INR ${b.monthlyBudget.toStringAsFixed(0)} budget used',
          isPositive: spentPct < 80,
        ),
        const Gap(14),
        _insightCard(
          icon:      LucideIcons.piggyBank,
          color:     AppColors.secondaryAccent,
          title:     'Remaining Budget',
          value:     'INR ${remaining.toStringAsFixed(0)}',
          subtitle:  remaining > 0
              ? 'Budget under control'
              : 'Budget exceeded!',
          isPositive: remaining > 0,
        ),
        const Gap(14),
        _insightCard(
          icon:      LucideIcons.calendar,
          color:     const Color(0xFFFF9F43),
          title:     'Today\'s Spend',
          value:     'INR ${b.totalDailySpend.toStringAsFixed(0)}',
          subtitle:  '${b.transactionCount} transaction(s) this month',
          isPositive: null,
        ),
        const Gap(20),

        // Live category breakdown
        if (b.categoryBreakdown.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            decoration: BoxDecoration(
              color:        Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow:    AppTheme.cardShadow,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Top Spending Categories',
                    style: AppTypography.textTheme.titleLarge
                        ?.copyWith(fontSize: 16)),
                const Gap(14),
                ..._buildCategoryBars(b),
              ],
            ),
          ),
        const Gap(80),
      ],
    );
  }

  List<Widget> _buildCategoryBars(BudgetResult b) {
    if (b.totalMonthlySpend == 0) return [];

    final colors = {
      'Food':     const Color(0xFFFF9F43),
      'Shopping': const Color(0xFF00CFE8),
      'Bills':    const Color(0xFFEA5455),
      'Travel':   const Color(0xFF7367F0),
      'Others':   const Color(0xFF28C76F),
    };

    final sorted = b.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final widgets = <Widget>[];
    for (int i = 0; i < sorted.length && i < 5; i++) {
      final e       = sorted[i];
      final frac    = (e.value / b.totalMonthlySpend).clamp(0.0, 1.0);
      final color   = colors[e.key] ?? AppColors.primaryAccent;
      if (i > 0) widgets.add(const Gap(10));
      widgets.add(_categoryBar(e.key, frac, color));
    }
    return widgets;
  }

  Widget _buildOfflineView() {
    return ListView(
      controller: widget.scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.shade50,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Column(
            children: [
              const Icon(Icons.wifi_off, size: 40, color: Colors.orange),
              const Gap(12),
              const Text(
                'ML Server Offline',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const Gap(6),
              const Text(
                'Start the Python server to see live AI insights:\n\npython api/start_server.py',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: () => setState(() {
                  _loading = true;
                  _error   = null;
                  _fetchBudget();
                }),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _insightCard({
    required IconData icon,
    required Color color,
    required String title,
    required String value,
    required String subtitle,
    required bool? isPositive,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
        boxShadow: AppTheme.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const Gap(14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: AppTypography.textTheme.labelSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
                const Gap(2),
                Text(value,
                    style: AppTypography.textTheme.titleLarge
                        ?.copyWith(color: color)),
                const Gap(2),
                Text(subtitle, style: AppTypography.textTheme.labelSmall),
              ],
            ),
          ),
          if (isPositive != null)
            Icon(
              isPositive ? LucideIcons.arrowUpRight : LucideIcons.arrowDownRight,
              color: isPositive ? AppColors.secondaryAccent : AppColors.danger,
              size: 20,
            ),
        ],
      ),
    );
  }

  Widget _categoryBar(String label, double fraction, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: AppTypography.textTheme.bodyMedium),
            Text('${(fraction * 100).toInt()}%',
                style: AppTypography.textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
          ],
        ),
        const Gap(6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: fraction,
            backgroundColor: AppColors.divider,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

// ─── CHAT TAB ───────────────────────────────────────────────────────────────
class _ChatTab extends StatelessWidget {
  final ScrollController scrollController;
  const _ChatTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        // Prompt suggestions
        Text('Quick prompts',
            style: AppTypography.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w600)),
        const Gap(10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _promptChip('How do I save more?'),
              const Gap(8),
              _promptChip('What is my biggest expense?'),
              const Gap(8),
              _promptChip('Predict next month spend'),
            ],
          ),
        ),
        const Gap(20),
        const AIChatInterface(),
        const Gap(80),
      ],
    );
  }

  Widget _promptChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primaryAccent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: AppColors.primaryAccent.withValues(alpha: 0.2)),
      ),
      child: Text(
        text,
        style: AppTypography.textTheme.labelSmall?.copyWith(
          color: AppColors.primaryAccent,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─── ACTIONS TAB ────────────────────────────────────────────────────────────
class _ActionsTab extends StatelessWidget {
  final ScrollController scrollController;
  const _ActionsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: LucideIcons.target,
        color: AppColors.primaryAccent,
        title: 'Set Budget Goal',
        subtitle: 'Define monthly spending limits per category',
      ),
      _ActionData(
        icon: LucideIcons.barChart2,
        color: const Color(0xFF00CFE8),
        title: 'Run Report',
        subtitle: 'Generate a detailed monthly financial report',
      ),
      _ActionData(
        icon: LucideIcons.bellRing,
        color: const Color(0xFFFF9F43),
        title: 'Set Bill Reminder',
        subtitle: 'Never miss an EMI or subscription payment',
      ),
      _ActionData(
        icon: LucideIcons.piggyBank,
        color: AppColors.secondaryAccent,
        title: 'Create Saving Plan',
        subtitle: 'Let AI design a personalised saving strategy',
      ),
      _ActionData(
        icon: LucideIcons.fileText,
        color: const Color(0xFFEA5455),
        title: 'Tax Summary',
        subtitle: 'Understand your annual tax saving potential',
      ),
      _ActionData(
        icon: LucideIcons.search,
        color: const Color(0xFF7367F0),
        title: 'Find Anomalies',
        subtitle: 'AI scans for unusual or duplicate charges',
      ),
    ];

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      itemCount: actions.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) {
        final a = actions[index];
        return InkWell(
          borderRadius: BorderRadius.circular(AppSpacing.radius),
          onTap: () {},
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(AppSpacing.radius),
              boxShadow: AppTheme.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: a.color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(a.icon, color: a.color, size: 22),
                ),
                const Gap(14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.title,
                          style: AppTypography.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const Gap(2),
                      Text(a.subtitle,
                          style: AppTypography.textTheme.bodyMedium),
                    ],
                  ),
                ),
                Icon(LucideIcons.chevronRight,
                    size: 18, color: AppColors.textSecondary),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ActionData {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _ActionData({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });
}
