import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../ai_center/widgets/ai_chat_interface.dart';

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

// ─── INSIGHTS TAB ───────────────────────────────────────────────────────────
class _InsightsTab extends StatelessWidget {
  final ScrollController scrollController;
  const _InsightsTab({required this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        _insightCard(
          icon: LucideIcons.trendingUp,
          color: AppColors.primaryAccent,
          title: 'Spending Summary',
          value: '₹12,400',
          subtitle: 'spent this week · 8% below last week',
          isPositive: true,
        ),
        const Gap(14),
        _insightCard(
          icon: LucideIcons.alertTriangle,
          color: AppColors.danger,
          title: 'Risk Alerts',
          value: '2 alerts',
          subtitle: 'EMI ₹8,200 due in 4 days · Low balance risk',
          isPositive: false,
        ),
        const Gap(14),
        _insightCard(
          icon: LucideIcons.piggyBank,
          color: AppColors.secondaryAccent,
          title: 'Savings Potential',
          value: '₹3,200/mo',
          subtitle: 'Reduce food delivery + cancel unused OTT',
          isPositive: true,
        ),
        const Gap(14),
        _insightCard(
          icon: LucideIcons.calendar,
          color: const Color(0xFFFF9F43),
          title: 'Monthly Prediction',
          value: '₹38,500',
          subtitle: 'Projected spend by month-end at current rate',
          isPositive: null,
        ),
        const Gap(20),
        // Category Heat Map
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            boxShadow: AppTheme.cardShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Top Spending Categories',
                  style: AppTypography.textTheme.titleLarge?.copyWith(fontSize: 16)),
              const Gap(14),
              _categoryBar('Food & Delivery', 0.78, const Color(0xFFFF9F43)),
              const Gap(10),
              _categoryBar('Shopping', 0.55, const Color(0xFF00CFE8)),
              const Gap(10),
              _categoryBar('Bills & Utilities', 0.40, const Color(0xFFEA5455)),
              const Gap(10),
              _categoryBar('Travel', 0.25, const Color(0xFF7367F0)),
            ],
          ),
        ),
        const Gap(80),
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
