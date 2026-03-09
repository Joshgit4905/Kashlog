import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class TutorialStep {
  final String title;
  final String description;
  final IconData icon;

  TutorialStep({
    required this.title,
    required this.description,
    required this.icon,
  });
}

class TutorialOverlay extends StatefulWidget {
  final VoidCallback onComplete;

  const TutorialOverlay({super.key, required this.onComplete});

  @override
  State<TutorialOverlay> createState() => _TutorialOverlayState();
}

class _TutorialOverlayState extends State<TutorialOverlay> {
  int _currentStep = 0;

  final List<TutorialStep> _steps = [
    TutorialStep(
      title: '¡Bienvenido a Kashlog!',
      description:
          'Tu compañero financiero inteligente. Vamos a darte un breve recorrido por tus nuevas herramientas.',
      icon: Icons.auto_awesome_rounded,
    ),
    TutorialStep(
      title: 'Tu Resumen Financiero',
      description:
          'Aquí verás tu saldo actual, ingresos y gastos del mes de un vistazo rápido.',
      icon: Icons.account_balance_wallet_rounded,
    ),
    TutorialStep(
      title: 'Control del Tiempo',
      description:
          'Usa el selector de mes arriba para ver tus movimientos pasados o planificar los futuros.',
      icon: Icons.calendar_month_rounded,
    ),
    TutorialStep(
      title: 'Registra tus Gastos',
      description:
          'El botón "+" te permite añadir ingresos o gastos. ¡Incluso puedes escanear tus tickets físicos!',
      icon: Icons.add_circle_rounded,
    ),
    TutorialStep(
      title: 'Análisis Potente',
      description:
          'Desliza hacia abajo para ver gráficos de tus gastos por categoría y el estado de tu ahorro.',
      icon: Icons.analytics_rounded,
    ),
    TutorialStep(
      title: 'Studio Mixer',
      description:
          '¡Experimenta sin riesgos! Entra al Mixer para simular cambios en tu presupuesto. Ajusta los faders como un profesional.',
      icon: Icons.tune_rounded,
    ),
    TutorialStep(
      title: 'Modo Pro (Oscuro)',
      description:
          'Personaliza tu experiencia. Cambia entre Modo Claro y Oscuro en los Ajustes para que Kashlog se adapte a tu estilo.',
      icon: Icons.dark_mode_rounded,
    ),
    TutorialStep(
      title: 'Modo Dev / Terminal',
      description:
          'Para los expertos, el Modo Dev activa una consola neomórfica para ejecutar comandos y monitorear el sistema.',
      icon: Icons.terminal_rounded,
    ),
  ];

  void _next() {
    if (_currentStep < _steps.length - 1) {
      setState(() => _currentStep++);
    } else {
      widget.onComplete();
    }
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    final progress = (_currentStep + 1) / _steps.length;
    final primaryColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.black54,
      body: Center(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Progress indicator
              Stack(
                children: [
                  Container(
                    height: 4,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  AnimatedContainer(
                    duration: 300.ms,
                    height: 4,
                    width: (MediaQuery.of(context).size.width - 128) * progress,
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(step.icon, size: 48, color: primaryColor),
                  )
                  .animate(key: ValueKey('icon_$_currentStep'))
                  .scale(duration: 400.ms, curve: Curves.easeOutBack),

              const SizedBox(height: 24),

              Text(
                    step.title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                  .animate(key: ValueKey('title_$_currentStep'))
                  .fadeIn(delay: 100.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 16),

              Text(
                    step.description,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                      height: 1.5,
                    ),
                  )
                  .animate(key: ValueKey('desc_$_currentStep'))
                  .fadeIn(delay: 200.ms)
                  .slideY(begin: 0.2),

              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: Text(
                    _currentStep == _steps.length - 1
                        ? '¡Empezar ahora!'
                        : 'Siguiente',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
      ),
    );
  }
}
