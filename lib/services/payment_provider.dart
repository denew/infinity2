abstract class PaymentProvider {
  /// The minimum value of the slider notch.
  int get minNotch;

  /// The maximum value of the slider notch.
  int get maxNotch;

  /// Initializes the provider. Useful for setting up billing clients or connecting to wallets.
  Future<void> initialize();

  /// Returns the formatted price string to display to the user for a given notch.
  /// For IAP, it might return a localized string like "$1.99" or "€1.99".
  /// For Solana, it might return "2.5 SKR" or "0.05 SOL".
  Future<String> getFormattedPriceForNotch(int notch);

  /// Executes the purchase or transaction for the selected notch.
  Future<bool> purchase(int notch);
}
