import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transaction.dart';
import '../providers/transaction_provider.dart';
import '../utils/constants.dart';
import '../services/database_helper.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../widgets/neumorphic_container.dart';

class CategoryData {
  final String name;
  final IconData icon;
  final Color color;

  CategoryData({required this.name, required this.icon, required this.color});
}

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key});

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  String _type = 'Gasto';
  String _category = 'Comida';
  final _amountController = TextEditingController();
  final _descController = TextEditingController();
  final _customCategoryController = TextEditingController();
  final _originalAmountController = TextEditingController();
  final _exchangeRateController = TextEditingController();
  String _originalCurrency = 'USD';
  bool _isTravelMode = false;

  final List<CategoryData> _expenseCategories = [
    CategoryData(
      name: 'Comida',
      icon: Icons.restaurant_rounded,
      color: Colors.orange,
    ),
    CategoryData(
      name: 'Transporte',
      icon: Icons.directions_bus_rounded,
      color: Colors.blue,
    ),
    CategoryData(
      name: 'Salud',
      icon: Icons.favorite_rounded,
      color: Colors.red,
    ),
    CategoryData(
      name: 'Ocio',
      icon: Icons.sports_esports_rounded,
      color: Colors.teal,
    ),
    CategoryData(name: 'Hogar', icon: Icons.home_rounded, color: Colors.brown),
    CategoryData(
      name: 'Educación',
      icon: Icons.school_rounded,
      color: Colors.indigo,
    ),
    CategoryData(
      name: 'Regalos',
      icon: Icons.card_giftcard_rounded,
      color: Colors.pink,
    ),
    CategoryData(
      name: 'Otros',
      icon: Icons.more_horiz_rounded,
      color: Colors.grey,
    ),
  ];

  final List<CategoryData> _incomeCategories = [
    CategoryData(
      name: 'Salario',
      icon: Icons.payments_rounded,
      color: Colors.green,
    ),
    CategoryData(
      name: 'Venta',
      icon: Icons.storefront_rounded,
      color: Colors.lightGreen,
    ),
    CategoryData(
      name: 'Inversión',
      icon: Icons.trending_up_rounded,
      color: Colors.cyan,
    ),
    CategoryData(
      name: 'Regalo',
      icon: Icons.card_giftcard_rounded,
      color: Colors.pink,
    ),
    CategoryData(
      name: 'Otros',
      icon: Icons.more_horiz_rounded,
      color: Colors.grey,
    ),
  ];

  void _save() {
    if (_formKey.currentState!.validate()) {
      final finalCategory =
          _category == 'Otros' && _customCategoryController.text.isNotEmpty
          ? _customCategoryController.text.trim()
          : _category;

      final amount = _isTravelMode
          ? (double.tryParse(_originalAmountController.text) ?? 0) *
                (double.tryParse(_exchangeRateController.text) ?? 1)
          : double.parse(_amountController.text);

      final transaction = TransactionModel(
        amount: amount,
        type: _type,
        category: finalCategory,
        date: DateTime.now(),
        description: _descController.text.trim(),
        originalAmount: _isTravelMode
            ? double.tryParse(_originalAmountController.text)
            : null,
        originalCurrency: _isTravelMode ? _originalCurrency : null,
        exchangeRate: _isTravelMode
            ? double.tryParse(_exchangeRateController.text)
            : null,
      );

      Provider.of<TransactionProvider>(
        context,
        listen: false,
      ).addTransaction(transaction);
      Navigator.pop(context);
    }
  }

  Future<void> _predictCategory(String desc) async {
    if (desc.isEmpty) return;
    final predicted = await DatabaseHelper().getMostUsedCategory(desc);
    if (predicted != null && mounted) {
      setState(() => _category = predicted);
    }
  }

  Future<void> _scanTicket() async {
    final textRecognizer = TextRecognizer();
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.camera);
      if (image == null) return;

      final inputImage = InputImage.fromFilePath(image.path);
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );

      double totalDetected = 0;
      double maxAmount = 0;
      final totalKeywords = [
        'TOTAL',
        'IMPORTE',
        'PAGAR',
        'NETO',
        'MONTO',
        'SUBTOTAL',
        'CONSUMO',
      ];

      for (var block in recognizedText.blocks) {
        String blockText = block.text.toUpperCase();
        bool blockHasKeyword = totalKeywords.any((k) => blockText.contains(k));

        for (var line in block.lines) {
          String lineText = line.text.toUpperCase();
          bool lineHasKeyword = totalKeywords.any((k) => lineText.contains(k));

          final amountRegex = RegExp(
            r'\d{1,3}(?:\.\d{3})*(?:,\d{2})|\d{1,3}(?:,\d{3})*(?:\.\d{2})|\d+\.\d{2}|\d+,\d{2}',
          );
          final matches = amountRegex.allMatches(line.text);

          for (var match in matches) {
            String raw = match.group(0)!;
            String cleaned = raw.replaceAll(RegExp(r'[^\d,.]'), '');

            if (cleaned.contains(',') && cleaned.contains('.')) {
              if (cleaned.lastIndexOf('.') > cleaned.lastIndexOf(',')) {
                cleaned = cleaned.replaceAll(',', '');
              } else {
                cleaned = cleaned.replaceAll('.', '').replaceAll(',', '.');
              }
            } else if (cleaned.contains(',')) {
              if (cleaned.lastIndexOf(',') == cleaned.length - 3) {
                cleaned = cleaned.replaceAll(',', '.');
              } else {
                cleaned = cleaned.replaceAll(',', '');
              }
            }

            final val = double.tryParse(cleaned);
            if (val != null && val > 0.5) {
              if (lineHasKeyword || blockHasKeyword) {
                if (val > totalDetected) totalDetected = val;
              }
              if (val > maxAmount) maxAmount = val;
            }
          }
        }
      }

      final finalAmount = totalDetected > 0 ? totalDetected : maxAmount;
      if (finalAmount > 0 && mounted) {
        setState(() => _amountController.text = finalAmount.toStringAsFixed(2));
      }
    } finally {
      textRecognizer.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final categories = _type == 'Gasto'
        ? _expenseCategories
        : _incomeCategories;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Nuevo Registro'),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Type Selector
              Row(
                children: [
                  Expanded(
                    child: _buildTypeButton(
                      'Gasto',
                      Icons.remove_circle_outline,
                      AppColors.lightAlert,
                      isDark,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _buildTypeButton(
                      'Ingreso',
                      Icons.add_circle_outline,
                      AppColors.lightPrimary,
                      isDark,
                    ),
                  ),
                ],
              ).animate().fadeIn().slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Amount Field
              const Text(
                'Monto',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                borderRadius: 16,
                child: Row(
                  children: [
                    Text(
                      '\$ ',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.darkPrimary
                            : AppColors.lightPrimary,
                      ),
                    ),
                    Expanded(
                      child: TextFormField(
                        controller: _amountController,
                        enabled: !_isTravelMode,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d*[.,]?\d*'),
                          ),
                        ],
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          hintText: '0.00',
                        ),
                        validator: (v) =>
                            (!_isTravelMode && (v == null || v.isEmpty))
                            ? 'Requerido'
                            : null,
                      ),
                    ),
                    IconButton(
                      onPressed: _scanTicket,
                      icon: const Icon(Icons.camera_alt_outlined),
                      color: AppColors.lightPrimary,
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Description
              const Text(
                'Descripción',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              NeumorphicContainer(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                borderRadius: 16,
                child: TextFormField(
                  controller: _descController,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    hintText: '¿En qué lo gastaste?',
                  ),
                  onFieldSubmitted: _predictCategory,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Requerido' : null,
                ),
              ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),
              const SizedBox(height: 24),

              // Travel Mode
              NeumorphicContainer(
                borderRadius: 16,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SwitchListTile(
                  title: const Text(
                    'Modo Viaje',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: const Text(
                    'Convertir divisa extranjera',
                    style: TextStyle(fontSize: 12),
                  ),
                  value: _isTravelMode,
                  onChanged: (v) => setState(() => _isTravelMode = v),
                  activeThumbColor: AppColors.lightPrimary,
                ),
              ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

              if (_isTravelMode)
                ...[
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          borderRadius: 12,
                          child: TextFormField(
                            controller: _originalAmountController,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'^\d*[.,]?\d*'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              border: InputBorder.none,
                              labelText: 'Monto',
                            ),
                            validator: (v) =>
                                (_isTravelMode && (v == null || v.isEmpty))
                                ? 'Requerido'
                                : null,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: NeumorphicContainer(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          borderRadius: 12,
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _originalCurrency,
                              isExpanded: true,
                              items: ['USD', 'EUR', 'MXN', 'GBP', 'JPY']
                                  .map(
                                    (c) => DropdownMenuItem(
                                      value: c,
                                      child: Text(
                                        c,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _originalCurrency = v!),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  NeumorphicContainer(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    borderRadius: 12,
                    child: TextFormField(
                      controller: _exchangeRateController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(
                          RegExp(r'^\d*[.,]?\d*'),
                        ),
                      ],
                      decoration: InputDecoration(
                        border: InputBorder.none,
                        labelText: 'Tipo de cambio (1 $_originalCurrency = ?)',
                      ),
                      validator: (v) =>
                          (_isTravelMode && (v == null || v.isEmpty))
                          ? 'Requerido'
                          : null,
                    ),
                  ),
                ].animate().fadeIn(),

              const SizedBox(height: 32),
              const Text(
                'Categoría',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  childAspectRatio: 0.8,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final cat = categories[index];
                  final isSelected = _category == cat.name;
                  return GestureDetector(
                    onTap: () => setState(() => _category = cat.name),
                    child: Column(
                      children: [
                        NeumorphicContainer(
                          borderRadius: 30,
                          padding: const EdgeInsets.all(12),
                          isPressed: isSelected,
                          color: isSelected ? cat.color.withOpacity(0.2) : null,
                          child: Icon(
                            cat.icon,
                            color: isSelected ? cat.color : Colors.grey,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected ? cat.color : Colors.grey,
                          ),
                          textAlign: TextAlign.center,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ).animate().scale(delay: (index * 20).ms, duration: 250.ms);
                },
              ),

              if (_category == 'Otros') ...[
                const SizedBox(height: 24),
                NeumorphicContainer(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  borderRadius: 16,
                  child: TextFormField(
                    controller: _customCategoryController,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      labelText: 'Nombre de la Categoría',
                    ),
                    validator: (v) =>
                        (_category == 'Otros' && (v == null || v.isEmpty))
                        ? 'Requerido'
                        : null,
                  ),
                ),
              ],

              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: NeumorphicContainer(
                  borderRadius: 16,
                  padding: EdgeInsets.zero,
                  color: _type == 'Gasto'
                      ? AppColors.lightAlert
                      : AppColors.lightPrimary,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'GUARDAR REGISTRO',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.2),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeButton(
    String type,
    IconData icon,
    Color activeColor,
    bool isDark,
  ) {
    final isSelected = _type == type;
    return GestureDetector(
      onTap: () {
        setState(() {
          _type = type;
          _category = type == 'Gasto'
              ? _expenseCategories.first.name
              : _incomeCategories.first.name;
        });
      },
      child: NeumorphicContainer(
        borderRadius: 16,
        padding: const EdgeInsets.symmetric(vertical: 12),
        isPressed: isSelected,
        color: isSelected ? activeColor.withOpacity(0.15) : null,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: isSelected ? activeColor : Colors.grey, size: 20),
            const SizedBox(width: 8),
            Text(
              type,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isSelected ? activeColor : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
