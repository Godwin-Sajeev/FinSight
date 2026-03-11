import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/theme/app_spacing.dart';

class LinkedBankAccountsScreen extends StatefulWidget {
  const LinkedBankAccountsScreen({super.key});

  @override
  State<LinkedBankAccountsScreen> createState() => _LinkedBankAccountsScreenState();
}

class _LinkedBankAccountsScreenState extends State<LinkedBankAccountsScreen> {
  // List of popular Indian banks
  static const _banks = [
    _BankInfo('State Bank of India', 'SBI', '🏛️'),
    _BankInfo('HDFC Bank', 'HDFC', '🏦'),
    _BankInfo('ICICI Bank', 'ICICI', '🏢'),
    _BankInfo('Axis Bank', 'Axis', '🔵'),
    _BankInfo('Punjab National Bank', 'PNB', '🟢'),
    _BankInfo('Bank of Baroda', 'BOB', '🟠'),
    _BankInfo('Kotak Mahindra Bank', 'Kotak', '🔴'),
    _BankInfo('IndusInd Bank', 'IndusInd', '🟣'),
    _BankInfo('Union Bank of India', 'UBI', '🏛️'),
    _BankInfo('Canara Bank', 'Canara', '🟡'),
    _BankInfo('IDBI Bank', 'IDBI', '🔷'),
    _BankInfo('Yes Bank', 'YES', '✅'),
    _BankInfo('Federal Bank', 'Federal', '🟤'),
    _BankInfo('South Indian Bank', 'SIB', '🌴'),
    _BankInfo('RBL Bank', 'RBL', '🔶'),
    _BankInfo('Paytm Payments Bank', 'Paytm', '💙'),
    _BankInfo('Airtel Payments Bank', 'Airtel', '🌐'),
  ];

  final Set<String> _linkedBanks = {};
  String _searchQuery = '';

  List<_BankInfo> get _filteredBanks {
    if (_searchQuery.isEmpty) return _banks;
    return _banks.where((b) =>
      b.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      b.shortName.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();
  }

  void _toggleBank(_BankInfo bank) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _LinkBankSheet(
        bank: bank,
        isLinked: _linkedBanks.contains(bank.shortName),
        onConfirm: () {
          setState(() {
            if (_linkedBanks.contains(bank.shortName)) {
              _linkedBanks.remove(bank.shortName);
            } else {
              _linkedBanks.add(bank.shortName);
            }
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final linked = _banks.where((b) => _linkedBanks.contains(b.shortName)).toList();
    final filtered = _filteredBanks;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Link Bank Account'),
        actions: [
          if (_linkedBanks.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primaryAccent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_linkedBanks.length} Linked',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: AppColors.primaryAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Search ─────────────────────
          Padding(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            child: TextField(
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Search bank...',
                prefixIcon: const Icon(LucideIcons.search, size: 18),
                filled: true,
                fillColor: Theme.of(context).cardTheme.color,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              children: [
                // ── Linked Banks Section ──────────────
                if (linked.isNotEmpty && _searchQuery.isEmpty) ...[
                  Text(
                    'MY LINKED ACCOUNTS',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(12),
                  Container(
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(AppSpacing.radius),
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: linked.length,
                      separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 64),
                      itemBuilder: (context, i) => _BankTile(
                        bank: linked[i],
                        isLinked: true,
                        onTap: () => _toggleBank(linked[i]),
                      ),
                    ),
                  ),
                  const Gap(24),
                ],

                // ── All Banks Section ─────────────────
                Text(
                  linked.isNotEmpty && _searchQuery.isEmpty ? 'ADD MORE BANKS' : 'SELECT YOUR BANK',
                  style: AppTypography.textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
                const Gap(12),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(AppSpacing.radius),
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(color: AppColors.divider, height: 1, indent: 64),
                    itemBuilder: (context, i) => _BankTile(
                      bank: filtered[i],
                      isLinked: _linkedBanks.contains(filtered[i].shortName),
                      onTap: () => _toggleBank(filtered[i]),
                    ),
                  ),
                ),
                const Gap(80),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bank Tile Widget ─────────────────────────────────────────────────────────
class _BankTile extends StatelessWidget {
  final _BankInfo bank;
  final bool isLinked;
  final VoidCallback onTap;

  const _BankTile({required this.bank, required this.isLinked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: isLinked
              ? AppColors.primaryAccent.withOpacity(0.1)
              : AppColors.divider.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Center(
          child: Text(
            bank.emoji,
            style: const TextStyle(fontSize: 22),
          ),
        ),
      ),
      title: Text(
        bank.name,
        style: AppTypography.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
      ),
      subtitle: Text(
        bank.shortName,
        style: AppTypography.textTheme.labelSmall,
      ),
      trailing: isLinked
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF28C76F).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.checkCircle, size: 14, color: Color(0xFF28C76F)),
                  const Gap(4),
                  Text(
                    'Linked',
                    style: AppTypography.textTheme.labelSmall?.copyWith(
                      color: const Color(0xFF28C76F),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            )
          : const Icon(LucideIcons.chevronRight, size: 18, color: AppColors.textSecondary),
      onTap: onTap,
    );
  }
}

// ── Bottom Sheet for Bank Linking ────────────────────────────────────────────
class _LinkBankSheet extends StatelessWidget {
  final _BankInfo bank;
  final bool isLinked;
  final VoidCallback onConfirm;

  const _LinkBankSheet({
    required this.bank,
    required this.isLinked,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.primaryAccent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(bank.emoji, style: const TextStyle(fontSize: 28)),
            ),
          ),
          const Gap(16),
          Text(
            bank.name,
            style: AppTypography.textTheme.titleLarge,
            textAlign: TextAlign.center,
          ),
          const Gap(8),
          Text(
            isLinked
                ? 'Do you want to unlink your ${bank.name} account?'
                : 'You\'ll be redirected to ${bank.name}\'s UPI portal to securely connect your account.',
            style: AppTypography.textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const Gap(24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: isLinked ? AppColors.danger : AppColors.primaryAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSpacing.radius),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                onConfirm();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isLinked
                          ? '${bank.name} account unlinked.'
                          : '${bank.name} account linked successfully!',
                    ),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: Text(isLinked ? 'Unlink Account' : 'Link Account'),
            ),
          ),
          const Gap(8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }
}

// ── Data Model ───────────────────────────────────────────────────────────────
class _BankInfo {
  final String name;
  final String shortName;
  final String emoji;
  const _BankInfo(this.name, this.shortName, this.emoji);
}
