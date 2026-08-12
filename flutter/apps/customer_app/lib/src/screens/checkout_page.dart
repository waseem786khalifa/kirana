import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customer_controller.dart';
import '../customer_ui.dart';
import '../domain.dart';
import '../repository.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _pincodeController = TextEditingController();
  late PaymentChoice _payment;
  String? _submitError;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    final CustomerStore store = widget.controller.selectedStore!;
    _payment = store.codEnabled ? PaymentChoice.cod : PaymentChoice.upi;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _landmarkController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _placeOrder() async {
    if (_submitting || widget.controller.placingOrder) return;
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _submitError = null;
      _submitting = true;
    });
    try {
      final CustomerOrder order = await widget.controller.placeOrder(
        address: DeliveryAddress(
          addressLine: _addressController.text.trim(),
          landmark: _landmarkController.text.trim(),
          pincode: _pincodeController.text.trim(),
        ),
        payment: _payment,
      );
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => AlertDialog(
          icon: const Icon(
            Icons.check_circle_rounded,
            size: 54,
            color: CustomerPalette.primary,
          ),
          title: const Text('Order placed!'),
          content: Text(
            'Order #${order.id} ${widget.controller.selectedStore!.name} ko bhej diya gaya hai.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Track order'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      setState(() => _submitting = false);
      Navigator.of(context).pop(true);
    } on CustomerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() {
        _submitError = error.message;
        _submitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final CustomerStore store = controller.selectedStore!;
    return PopScope(
      canPop: !_submitting,
      child: Scaffold(
        appBar: AppBar(
          leading: IconButton(
            tooltip: 'Back',
            onPressed: _submitting ? null : () => Navigator.of(context).pop(),
            icon: const Icon(Icons.arrow_back_rounded),
          ),
          titleSpacing: 0,
          title: const Text('Checkout'),
        ),
        body: Form(
          key: _formKey,
          child: ListView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
            children: <Widget>[
              _SectionCard(
                number: '1',
                title: 'Delivery address',
                icon: Icons.local_shipping_outlined,
                child: Column(
                  children: <Widget>[
                    TextFormField(
                      key: const Key('checkout-address'),
                      controller: _addressController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      maxLines: 2,
                      minLines: 1,
                      autofillHints: const <String>[
                        AutofillHints.fullStreetAddress,
                      ],
                      decoration: const InputDecoration(
                        hintText: 'House / flat, street, area',
                      ),
                      validator: (String? value) =>
                          (value ?? '').trim().length < 8
                          ? 'Poora delivery address daaliye'
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _landmarkController,
                      textCapitalization: TextCapitalization.sentences,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        hintText: 'Landmark (optional)',
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      key: const Key('checkout-pincode'),
                      controller: _pincodeController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      autofillHints: const <String>[AutofillHints.postalCode],
                      inputFormatters: <TextInputFormatter>[
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(6),
                      ],
                      decoration: const InputDecoration(
                        hintText: '6-digit pincode',
                      ),
                      validator: (String? value) =>
                          RegExp(r'^\d{6}$').hasMatch(value ?? '')
                          ? null
                          : 'Valid 6-digit pincode daaliye',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                number: '2',
                title: 'Payment method',
                icon: Icons.account_balance_wallet_outlined,
                child: RadioGroup<PaymentChoice>(
                  groupValue: _payment,
                  onChanged: (PaymentChoice? value) {
                    if (value != null) setState(() => _payment = value);
                  },
                  child: Column(
                    children: <Widget>[
                      if (store.codEnabled)
                        const RadioListTile<PaymentChoice>(
                          key: Key('payment-cod'),
                          value: PaymentChoice.cod,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          secondary: Icon(Icons.payments_outlined, size: 22),
                          title: Text(
                            'Cash on Delivery',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Pay cash to delivery partner',
                            style: TextStyle(fontSize: 10.5),
                          ),
                        ),
                      if (store.codEnabled && store.upiEnabled) const Divider(),
                      if (store.upiEnabled)
                        const RadioListTile<PaymentChoice>(
                          key: Key('payment-upi'),
                          value: PaymentChoice.upi,
                          contentPadding: EdgeInsets.zero,
                          visualDensity: VisualDensity.compact,
                          secondary: Icon(Icons.qr_code_2_rounded, size: 22),
                          title: Text(
                            'UPI',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            'Pay using any UPI app',
                            style: TextStyle(fontSize: 10.5),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              _SectionCard(
                number: '3',
                title: 'Order summary',
                icon: Icons.receipt_long_outlined,
                child: Column(
                  children: <Widget>[
                    _SummaryRow(
                      label: '${controller.cartCount} items',
                      value: formatRupees(controller.subtotal),
                    ),
                    _SummaryRow(
                      label: 'Delivery fee',
                      value: controller.deliveryCharge == 0
                          ? 'FREE'
                          : formatRupees(controller.deliveryCharge),
                      valueColor: controller.deliveryCharge == 0
                          ? CustomerPalette.primaryDark
                          : null,
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(),
                    ),
                    _SummaryRow(
                      label: 'Total payable',
                      value: formatRupees(controller.total),
                      emphasize: true,
                    ),
                  ],
                ),
              ),
              if (_submitError != null) ...<Widget>[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECE9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: <Widget>[
                      const Icon(
                        Icons.error_outline_rounded,
                        color: CustomerPalette.danger,
                      ),
                      const SizedBox(width: 9),
                      Expanded(child: Text(_submitError!)),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 11, 16, 12),
            decoration: const BoxDecoration(
              color: CustomerPalette.surface,
              border: Border(top: BorderSide(color: CustomerPalette.border)),
            ),
            child: CustomerPrimaryButton(
              key: const Key('place-order'),
              label: _submitting
                  ? 'Order place ho raha hai...'
                  : 'Place order  \u2022  ${formatRupees(controller.total)}',
              icon: Icons.verified_user_outlined,
              busy: _submitting,
              onPressed: _submitting ? null : _placeOrder,
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.number,
    required this.title,
    required this.icon,
    required this.child,
  });

  final String number;
  final String title;
  final IconData icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  width: 28,
                  height: 28,
                  decoration: const BoxDecoration(
                    color: CustomerPalette.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    number,
                    style: const TextStyle(
                      color: CustomerPalette.primaryDark,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(icon, size: 18),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: emphasize ? 14 : 12,
                fontWeight: emphasize ? FontWeight.w900 : FontWeight.w500,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor,
              fontSize: emphasize ? 16 : 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
