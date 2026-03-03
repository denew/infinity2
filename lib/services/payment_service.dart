import 'payment_provider.dart';

/// A service to access the current payment provider.
/// To ensure Google Play doesn't flag crypto libraries, we use Dependency Injection.
/// You will instantiate this service at app startup (e.g., in `main.dart`)
/// passing in the correct provider for the current build flavor.
class PaymentService {
  final PaymentProvider provider;

  PaymentService({required this.provider});

  /// Entry point to initialize billing/wallet connection
  Future<void> initialize() async {
    await provider.initialize();
  }

  // Forward methods to the provider to keep the UI decoupled
  int get minNotch => provider.minNotch;
  int get maxNotch => provider.maxNotch;

  Future<String> getFormattedPriceForNotch(int notch) =>
      provider.getFormattedPriceForNotch(notch);

  Future<bool> purchase(int notch) => provider.purchase(notch);
}
