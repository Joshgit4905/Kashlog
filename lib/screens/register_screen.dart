import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/constants.dart';
import 'initial_balance_screen.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  int _selectedAge = 25;
  Map<String, String> _selectedCurrency = AppConstants.currencies[0];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_nameController.text.isNotEmpty) {
      final userProvider = Provider.of<UserProvider>(context, listen: false);

      userProvider
          .setUserProfile(
            _nameController.text,
            _selectedAge,
            _selectedCurrency['code']!,
            _selectedCurrency['symbol']!,
          )
          .then((_) {
            if (mounted) {
              Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const InitialBalanceScreen()),
              );
            }
          });
    }
  }

  Widget _buildNeumorphicContainer({
    required Widget child,
    double borderRadius = 20,
    EdgeInsets padding = const EdgeInsets.all(4),
    bool isPressed = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark
        ? AppColors.darkBackground
        : AppColors.lightBackground;

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: isPressed
            ? []
            : [
                // Darker shadow for bottom-right
                BoxShadow(
                  color: isDark
                      ? Colors.black.withOpacity(0.5)
                      : Colors.black.withOpacity(0.07),
                  offset: const Offset(6, 6),
                  blurRadius: 12,
                ),
                // Lighter shadow for top-left
                BoxShadow(
                  color: isDark
                      ? Color(0xFF1A2A1A).withOpacity(0.5)
                      : Colors.white,
                  offset: const Offset(-6, -6),
                  blurRadius: 12,
                ),
              ],
      ),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final textColor = isDark ? AppColors.darkText : AppColors.lightText;

    return Scaffold(
      backgroundColor: isDark
          ? AppColors.darkBackground
          : AppColors.lightBackground,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 60),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              _buildNeumorphicContainer(
                    borderRadius: 40,
                    padding: const EdgeInsets.all(24),
                    child: Icon(
                      Icons.account_balance_wallet_rounded,
                      size: 60,
                      color: primaryColor,
                    ),
                  )
                  .animate()
                  .scale(duration: 600.ms, curve: Curves.easeOutBack)
                  .fade(),

              const SizedBox(height: 32),

              // Welcome Text
              Text(
                'KashLog',
                style: TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.5,
                  color: primaryColor,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.3, end: 0),

              const SizedBox(height: 8),

              Text(
                'Tu asistente financiero premium',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.6),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 60),

              // Form fields
              Column(
                children: [
                  // Name Field
                  _buildNeumorphicContainer(
                    child: TextField(
                      controller: _nameController,
                      style: TextStyle(color: textColor),
                      decoration: InputDecoration(
                        hintText: 'Tu nombre',
                        hintStyle: TextStyle(color: textColor.withOpacity(0.4)),
                        prefixIcon: Icon(
                          Icons.person_rounded,
                          color: primaryColor,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ).animate().fadeIn(delay: 600.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 24),

                  // Age Dropdown
                  _buildNeumorphicContainer(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: DropdownButtonFormField<int>(
                      initialValue: _selectedAge,
                      dropdownColor: isDark
                          ? AppColors.darkSurface
                          : AppColors.lightSurface,
                      elevation: 0,
                      decoration: InputDecoration(
                        hintText: 'Edad',
                        prefixIcon: Icon(
                          Icons.cake_rounded,
                          color: primaryColor,
                        ),
                        border: InputBorder.none,
                      ),
                      style: TextStyle(color: textColor, fontSize: 16),
                      items: List.generate(80, (index) => index + 13).map((
                        age,
                      ) {
                        return DropdownMenuItem(
                          value: age,
                          child: Text('$age años'),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _selectedAge = value);
                      },
                    ),
                  ).animate().fadeIn(delay: 800.ms).slideX(begin: -0.2, end: 0),

                  const SizedBox(height: 24),

                  // Currency Dropdown
                  _buildNeumorphicContainer(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: DropdownButtonFormField<Map<String, String>>(
                          initialValue: _selectedCurrency,
                          dropdownColor: isDark
                              ? AppColors.darkSurface
                              : AppColors.lightSurface,
                          elevation: 0,
                          decoration: InputDecoration(
                            hintText: 'Moneda',
                            prefixIcon: Icon(
                              Icons.currency_exchange_rounded,
                              color: primaryColor,
                            ),
                            border: InputBorder.none,
                          ),
                          style: TextStyle(color: textColor, fontSize: 16),
                          items: AppConstants.currencies.map((curr) {
                            return DropdownMenuItem(
                              value: curr,
                              child: Text(
                                '${curr['code']} (${curr['symbol']})',
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedCurrency = value);
                            }
                          },
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 1000.ms)
                      .slideX(begin: -0.2, end: 0),
                ],
              ),

              const SizedBox(height: 60),

              // Submit Button
              GestureDetector(
                onTap: _submit,
                child: _buildNeumorphicContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  child: Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      color: primaryColor.withOpacity(0.1),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'COMENZAR',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: primaryColor,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 1200.ms).slideY(begin: 0.5, end: 0),
            ],
          ),
        ),
      ),
    );
  }
}
