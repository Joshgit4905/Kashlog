import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import '../providers/user_provider.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import 'package:sqflite/sqflite.dart' as sql;
import 'package:path/path.dart' as p;
import 'package:share_plus/share_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../widgets/neumorphic_container.dart';
import '../services/log_stream_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _nameController;
  late TextEditingController _ageController;
  late Map<String, String> _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    _nameController = TextEditingController(text: userProvider.name);
    _ageController = TextEditingController(text: userProvider.age.toString());
    _selectedCurrency = AppConstants.currencies.firstWhere(
      (c) => c['code'] == userProvider.currencyCode,
      orElse: () => AppConstants.currencies[0],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final age = int.tryParse(_ageController.text) ?? 0;
    userProvider.setUserProfile(
      _nameController.text.trim(),
      age,
      _selectedCurrency['code']!,
      _selectedCurrency['symbol']!,
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Perfil actualizado')));
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('¿Borrar todos los datos?'),
        content: const Text(
          'Esta acción eliminará todos tus ingresos, gastos y pagos planeados de forma permanente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Provider.of<TransactionProvider>(
                context,
                listen: false,
              ).clearAllTransactions();
              Navigator.pop(context);
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Datos borrados')));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.lightAlert,
              foregroundColor: Colors.white,
            ),
            child: const Text('Borrar Todo'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ajustes'),
        backgroundColor: Colors.transparent,
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _buildSectionTitle('Perfil', primaryColor),
          const SizedBox(height: 16),
          NeumorphicContainer(
            padding: const EdgeInsets.all(16),
            borderRadius: 20,
            child: Column(
              children: [
                _buildTextField(
                  _nameController,
                  'Tu nombre',
                  Icons.person_outline,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  _ageController,
                  'Tu edad',
                  Icons.calendar_month_outlined,
                  isNumber: true,
                ),
                const SizedBox(height: 16),
                _buildCurrencyDropdown(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: NeumorphicContainer(
              borderRadius: 16,
              padding: EdgeInsets.zero,
              color: primaryColor,
              child: ElevatedButton(
                onPressed: _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'GUARDAR CAMBIOS',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Apariencia', primaryColor),
          const SizedBox(height: 16),
          NeumorphicContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            child: ListTile(
              title: const Text(
                'Modo Oscuro',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              trailing: Switch(
                value: isDark,
                onChanged: (value) => userProvider.setThemeMode(
                  value ? ThemeMode.dark : ThemeMode.light,
                ),
                activeThumbColor: primaryColor,
              ),
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Privacidad', primaryColor),
          const SizedBox(height: 16),
          NeumorphicContainer(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                ListTile(
                  title: const Text(
                    'Modo Steganography',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Ocultar montos bajo un ecualizador'),
                  trailing: Switch(
                    value: userProvider.isSteganographyMode,
                    onChanged: (value) =>
                        userProvider.setSteganographyMode(value),
                    activeThumbColor: primaryColor,
                  ),
                ),
                const Divider(indent: 20, endIndent: 20),
                ListTile(
                  title: const Text(
                    'Modo Desarrollador',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text('Ver consola de logs técnicos'),
                  trailing: Switch(
                    value: userProvider.isDeveloperMode,
                    onChanged: (value) => userProvider.setDeveloperMode(value),
                    activeThumbColor: primaryColor,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Herramientas', primaryColor),
          const SizedBox(height: 16),
          NeumorphicContainer(
            borderRadius: 20,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                _buildToolTile(
                  icon: Icons.description_outlined,
                  title: 'Exportar a CSV',
                  onTap: () {
                    LogStreamService.log('[UI] Button Pressed: Export to CSV');
                    Provider.of<TransactionProvider>(
                      context,
                      listen: false,
                    ).exportToCSV();
                  },
                ),
                const Divider(indent: 50),
                _buildToolTile(
                  icon: Icons.backup_outlined,
                  title: 'Copia de Seguridad',
                  onTap: () async {
                    final dbPath = p.join(
                      await sql.getDatabasesPath(),
                      'kashlog.db',
                    );
                    await Share.shareXFiles([
                      XFile(dbPath, name: 'kashlog_backup.db'),
                    ], subject: 'KashLog Backup');
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),

          _buildSectionTitle('Zona de Peligro', AppColors.lightAlert),
          const SizedBox(height: 16),
          NeumorphicContainer(
            borderRadius: 20,
            padding: EdgeInsets.zero,
            color: AppColors.lightAlert.withOpacity(0.05),
            child: ListTile(
              leading: const Icon(
                Icons.delete_forever_rounded,
                color: AppColors.lightAlert,
              ),
              title: const Text(
                'Borrar todos los datos',
                style: TextStyle(
                  color: AppColors.lightAlert,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: _showDeleteDialog,
            ),
          ),
          const SizedBox(height: 40),

          Center(
            child: Text(
              'KashLog v1.2.0\nElegancia en tus finanzas',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ).animate().fadeIn(duration: 400.ms),
    );
  }

  Widget _buildSectionTitle(String title, Color color) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w900,
        color: color,
        letterSpacing: 1.5,
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon, {
    bool isNumber = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      inputFormatters: isNumber ? [FilteringTextInputFormatter.digitsOnly] : [],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: InputBorder.none,
        filled: true,
        fillColor: Colors.transparent,
      ),
    );
  }

  Widget _buildCurrencyDropdown() {
    return DropdownButtonFormField<Map<String, String>>(
      initialValue: _selectedCurrency,
      decoration: const InputDecoration(
        labelText: 'Moneda Principal',
        prefixIcon: Icon(Icons.currency_exchange, size: 20),
        border: InputBorder.none,
      ),
      items: AppConstants.currencies.map((curr) {
        return DropdownMenuItem(
          value: curr,
          child: Text('${curr['code']} (${curr['symbol']})'),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCurrency = value);
      },
    );
  }

  Widget _buildToolTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.lightPrimary, size: 24),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      onTap: onTap,
      trailing: const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
    );
  }
}
