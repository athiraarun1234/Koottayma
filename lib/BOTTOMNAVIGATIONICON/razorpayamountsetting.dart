import 'package:Koottaayma/USER%20FOLDER/6bottomnavigation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';


class PaymentGateway extends StatelessWidget {
  final int languageId;
  final int phoneNumber;
  const PaymentGateway({
    super.key,
    required this.languageId,
    required this.phoneNumber,
  });

  void _openCheckoutPage(BuildContext context, String title, IconData icon) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentAmountPage(
          title: title,
          icon: icon,
          languageId: languageId,
          phoneNumber: phoneNumber,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if (didPop) return;

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => BottomNavigation(
              languageId: languageId,
              phoneNumber: phoneNumber,
            ),
          ),
          (route) => false,
        );
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          backgroundColor: const Color.fromARGB(255, 14, 189, 212),
          title: Text(
            "Payments",
            style: GoogleFonts.poppins(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 20,
              letterSpacing: 0.3,
            ),
          ),
        ),
        body: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF00BCD4),
                Color(0xFFB2EBF2),
                Color(0xFFFFFFFF),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 24),
                _buildPaymentCard(
                  title: "Contribution",
                  onTap: () =>
                      _openCheckoutPage(context, "Donation", Icons.favorite),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

 
   Widget _buildPaymentCard({
    required String title,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: const Color.fromARGB(255, 51, 141, 155), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color.fromARGB(255, 23, 82, 91).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 28),
            child: Column(
              children: [
                Text(
                  title,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.cyan.shade800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  height: 45,
                  width: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.cyan.shade600, Colors.teal.shade400],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.cyan.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "Pay Now",
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}


class PaymentAmountPage extends StatefulWidget {
  final String title; // "Subscription" or "Donation"
  final IconData icon;
  final int languageId;
  final int phoneNumber;

  const PaymentAmountPage({
    super.key,
    required this.title,
    required this.icon,
    required this.languageId,
    required this.phoneNumber,
  });

  @override
  State<PaymentAmountPage> createState() => _PaymentAmountPageState();
}

class _PaymentAmountPageState extends State<PaymentAmountPage> {
  static const int minAmount = 10; // rupees
  static const int maxAmount = 500; // rupees
  static const List<int> quickAmounts = [10, 50, 100, 200, 500];

  Razorpay? _razorpay;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();

    _razorpay = Razorpay();
    _razorpay!.on(Razorpay.EVENT_PAYMENT_ERROR, handlePaymentErrorResponse);
    _razorpay!.on(Razorpay.EVENT_PAYMENT_SUCCESS, handlePaymentSuccessResponse);
    _razorpay!.on(Razorpay.EVENT_EXTERNAL_WALLET, handleExternalWalletSelected);
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _amountController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void handlePaymentErrorResponse(PaymentFailureResponse response) {
    debugPrint('Payment Failed: ${response.message}');
    _showMessage('Payment failed: ${response.message ?? 'Please try again'}');
  }

  void handlePaymentSuccessResponse(PaymentSuccessResponse response) {
    debugPrint('Payment Success: ${response.paymentId}');
    _showMessage('Payment successful');
    
  }

  void handleExternalWalletSelected(ExternalWalletResponse response) {
    debugPrint('External Wallet: ${response.walletName}');
  }

  String? _validate(String value) {
    final amount = int.tryParse(value);
    if (amount == null) return 'Enter a valid amount';
    if (amount < minAmount) return 'Minimum amount is ₹$minAmount';
    if (amount > maxAmount) return 'Maximum amount is ₹$maxAmount';
    return null;
  }

  void openCheckout() {
    FocusScope.of(context).unfocus();

    final text = _amountController.text.trim();
    final error = _validate(text);
    if (error != null) {
      _showMessage(error);
      return;
    }

    final amountInRupees = int.parse(text);

    final options = {
      'key': 'rzp_live_TqWAnUwYgn2toM',
      'amount': amountInRupees * 100, // paise (100 paise = ₹1)
      'currency': 'INR',
      'name': 'Koottaayma ( കൂട്ടായ്മ )',
      'description': widget.title == 'Subscription'
          ? 'Subscription Fees'
          : 'Contribution',
      'prefill': {
        'contact': widget.phoneNumber.toString(),
        // 'email': 'test@razorpay.com',
      },
    };
    print('razorpay phonenumber: ${widget.phoneNumber}');
    try {
      _razorpay!.open(options);
    } catch (e) {
      debugPrint('Error: $e');
      _showMessage('Could not open payment. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color.fromARGB(255, 0, 188, 212),
     
        title: Text(
          "Payment Details",
          style: GoogleFonts.poppins(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
            letterSpacing: 0.3,
          ),
        ),
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF00BCD4),
              Color(0xFFB2EBF2),
              Color(0xFFFFFFFF),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(20),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ValueListenableBuilder<TextEditingValue>(
              valueListenable: _amountController,
              builder: (context, value, _) {
                final text = value.text;
                final error = text.isEmpty ? null : _validate(text);
                final valid = text.isNotEmpty && error == null;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Merchant header
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.cyan.shade50,
                      child: Image.asset('assets/god.png', width: 85, height: 85),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Koottaayma ( കൂട്ടായ്മ )',
                      style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.cyan.shade900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.title == 'Subscription'
                          ? 'Subscription Fees'
                          : 'Contribution',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.shade200, height: 28),

                    // Amount entry
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Enter amount to pay',
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _amountController,
                      autofocus: true,
                      textAlign: TextAlign.center,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(3),
                      ],
                      style: GoogleFonts.poppins(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: Colors.cyan.shade900,
                      ),
                      decoration: InputDecoration(
                        prefixText: '₹ ',
                        prefixStyle: GoogleFonts.poppins(
                          fontSize: 32,
                          fontWeight: FontWeight.w600,
                          color: Colors.cyan.shade900,
                        ),
                        hintText: '0',
                        helperText: 'Min ₹$minAmount  •  Max ₹$maxAmount',
                        errorText: error,
                        filled: true,
                        fillColor: Colors.cyan.shade50,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide:
                              BorderSide(color: Colors.cyan.shade600, width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      alignment: WrapAlignment.center,
                      children: quickAmounts.map((amt) {
                        final selected = text == amt.toString();
                        return ChoiceChip(
                          label: Text('₹$amt'),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: Colors.cyan.shade600,
                          backgroundColor: Colors.white,
                          side: BorderSide(color: Colors.cyan.shade200),
                          labelStyle: GoogleFonts.poppins(
                            fontWeight: FontWeight.w500,
                            color:
                                selected ? Colors.white : Colors.cyan.shade800,
                          ),
                          onSelected: (_) {
                            _amountController.text = amt.toString();
                            _amountController.selection =
                                TextSelection.collapsed(
                                    offset: _amountController.text.length);
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    // Pay button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: valid
                                ? [Colors.cyan.shade600, Colors.teal.shade400]
                                : [Colors.grey.shade300, Colors.grey.shade300],
                          ),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: valid ? openCheckout : null,
                          child: Text(
                            valid ? 'Pay ₹$text' : 'Pay',
                            style: GoogleFonts.poppins(
                              color: valid ? Colors.white : Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.lock_outline,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text(
                          'Secured by Razorpay',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}