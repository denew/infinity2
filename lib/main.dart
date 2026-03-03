import 'package:flutter/material.dart';
import 'screens/puzzle_screen.dart';
import 'strings.dart';
import 'services/payment_service.dart';
import 'services/iap_provider.dart';

// Global instance for Dependency Injection (Google Play flavor)
final paymentService = PaymentService(provider: IapProvider());

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStrings.init();
  await paymentService.initialize(); // Init billing client
  runApp(const InfinityPuzzleApp());
}

class InfinityPuzzleApp extends StatelessWidget {
  const InfinityPuzzleApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Infinity II',
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: const Color(0xFF1E1E2C),
      ),
      home: const PuzzleScreen(),
    );
  }
}
