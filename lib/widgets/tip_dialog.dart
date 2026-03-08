import 'package:flutter/material.dart';
import '../services/payment_service.dart';
import '../strings.dart';

class TipDialog extends StatefulWidget {
  final PaymentService paymentService;

  const TipDialog({Key? key, required this.paymentService}) : super(key: key);

  @override
  _TipDialogState createState() => _TipDialogState();
}

class _TipDialogState extends State<TipDialog> {
  late double _currentNotch;
  String _currentPriceFormatted = 'Loading...';
  bool _isProcessingPurchase = false;

  @override
  void initState() {
    super.initState();
    // Default to the first notch
    _currentNotch = widget.paymentService.minNotch.toDouble();
    _updatePriceFormatted();
  }

  Future<void> _updatePriceFormatted() async {
    final priceStr = await widget.paymentService
        .getFormattedPriceForNotch(_currentNotch.toInt());
    if (mounted) {
      setState(() {
        _currentPriceFormatted = priceStr;
      });
    }
  }

  Future<void> _handlePurchase() async {
    setState(() => _isProcessingPurchase = true);

    final success = await widget.paymentService.purchase(_currentNotch.toInt());

    if (mounted) {
      setState(() => _isProcessingPurchase = false);
      if (success) {
        // Show success and close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(AppStrings.thankYouForCoffee),
                const SizedBox(width: 4),
                const Icon(Icons.local_cafe, size: 14, color: Colors.white),
              ],
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppStrings.purchaseFailed),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  /// Map notches to fun drink names
  String _getDrinkNameForNotch(int notch) {
    // This gives a nice semantic meaning to the notches for IAP
    // If Solana uses 100 notches, you can do math like:
    // if (notch < 25) return 'Hot Water'; // etc.
    final totalNotchSpread =
        widget.paymentService.maxNotch - widget.paymentService.minNotch;

    // Normalize safely to a 0 to 1 proportion, fallback if totalNotchSpread is 0
    final proportion = totalNotchSpread <= 0
        ? 0.0
        : (notch - widget.paymentService.minNotch) / totalNotchSpread;

    if (proportion < 0.25) return 'Hot Water';
    if (proportion < 0.50) return 'Drip Coffee';
    if (proportion < 0.75) return 'Espresso';
    return 'Double Espresso';
  }

  @override
  Widget build(BuildContext context) {
    final max = widget.paymentService.maxNotch.toDouble();
    final min = widget.paymentService.minNotch.toDouble();
    // Calculate divisions based on the available range if it's small (like IAP's 4 increments).
    // If it's Solana (1 to 100), we don't define divisions to allow smooth sliding!
    final int? divisions = (max - min) <= 10 ? (max - min).toInt() : null;

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(AppStrings.buyMeACoffee, textAlign: TextAlign.center),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_cafe, size: 64, color: Colors.brown.shade400),
          const SizedBox(height: 16),
          Text(
            _getDrinkNameForNotch(_currentNotch.toInt()),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            _currentPriceFormatted,
            style: const TextStyle(fontSize: 24, color: Colors.blueAccent),
          ),
          const SizedBox(height: 16),
          Slider(
            value: _currentNotch,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: Colors.brown,
            inactiveColor: Colors.brown.shade100,
            onChanged: (value) {
              setState(() {
                _currentNotch = value;
                // Temporarily mark loading so user knows it's updating
                _currentPriceFormatted = '...';
              });
            },
            onChangeEnd: (value) {
              // Only query the billing service when the user stops sliding
              // to prevent slamming the async functions
              _updatePriceFormatted();
            },
          ),
          const SizedBox(height: 16),
          if (_isProcessingPurchase)
            const CircularProgressIndicator()
          else
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: _handlePurchase,
              child: Text(AppStrings.confirmTip,
                  style: const TextStyle(fontSize: 18)),
            )
        ],
      ),
    );
  }
}
