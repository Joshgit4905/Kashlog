import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'neumorphic_container.dart';
import 'neumorphic_visualizer.dart';

class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TransactionProvider>(context);
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return NeumorphicContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: 24,
      child: Column(
        children: [
          Text(
            'Balance Total',
            style: TextStyle(
              color: isDark
                  ? AppColors.darkText.withOpacity(0.7)
                  : AppColors.lightText.withOpacity(0.7),
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: 600.ms,
            switchInCurve: Curves.easeOutBack,
            switchOutCurve: Curves.easeIn,
            transitionBuilder: (child, animation) {
              return FadeTransition(
                opacity: animation,
                child: ScaleTransition(scale: animation, child: child),
              );
            },
            child: userProvider.isSteganographyMode
                ? NeumorphicVisualizer(
                    key: const ValueKey('visualizer'),
                    balance: provider.totalBalance,
                    activity: provider.monthlyIncome + provider.monthlyExpenses,
                  )
                : Text(
                    '${userProvider.currencySymbol}${provider.totalBalance.toStringAsFixed(2)}',
                    key: const ValueKey('balance_text'),
                    style: TextStyle(
                      color: provider.totalBalance < 0
                          ? Colors.red
                          : (isDark ? AppColors.darkText : AppColors.lightText),
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildStat(
                context,
                'Ingresos',
                provider.monthlyIncome,
                Icons.arrow_upward,
                Colors.green,
                isDark,
              ),
              Container(
                width: 1,
                height: 40,
                color: isDark
                    ? AppColors.darkDivider
                    : Colors.grey.withOpacity(0.2),
              ),
              _buildStat(
                context,
                'Gastos',
                provider.monthlyExpenses,
                Icons.arrow_downward,
                Colors.orange,
                isDark,
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildStat(
    BuildContext context,
    String label,
    double amount,
    IconData icon,
    Color color,
    bool isDark,
  ) {
    final userProvider = Provider.of<UserProvider>(context);
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: isDark
                      ? AppColors.darkText.withOpacity(0.6)
                      : AppColors.lightText.withOpacity(0.6),
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (userProvider.isSteganographyMode)
            Text(
              '---',
              style: TextStyle(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            )
          else
            Text(
              '${userProvider.currencySymbol}${amount.toStringAsFixed(0)}',
              style: TextStyle(
                color: isDark ? AppColors.darkText : AppColors.lightText,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
        ],
      ),
    );
  }
}
