import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'utils/constants.dart';
import 'screens/splash_screen.dart';
import 'providers/transaction_provider.dart';
import 'providers/user_provider.dart';
import 'providers/mixer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(
          create: (_) => TransactionProvider()..fetchTransactions(),
        ),
        ChangeNotifierProvider(create: (_) => MixerProvider()),
      ],
      child: const KashLogApp(),
    ),
  );
}

class KashLogApp extends StatelessWidget {
  const KashLogApp({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);

    return MaterialApp(
      title: 'KashLog',
      debugShowCheckedModeBanner: false,
      theme: AppThemes.lightTheme,
      darkTheme: AppThemes.darkTheme,
      themeMode: userProvider.themeMode,
      home: const SplashScreen(),
    );
  }
}
