import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customer_controller.dart';
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
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _submitError = null);
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
            size: 52,
            color: Color(0xFF177448),
          ),
          title: const Text('Order placed!'),
          content: Text(
            'Order #${order.id} ${widget.controller.selectedStore!.name} ko bhej diya gaya hai.',
            textAlign: TextAlign.center,
          ),
          actions: <Widget>[
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Track order'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } on CustomerRepositoryException catch (error) {
      if (!mounted) return;
      setState(() => _submitError = error.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final CustomerController controller = widget.controller;
    final CustomerStore store = controller.selectedStore!;
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
          children: <Widget>[
            _SectionCard(
              number: '1',
              title: 'Delivery address',
              icon: Icons.location_on_outlined,
              child: Column(
                children: <Widget>[
                  TextFormField(
                    key: const Key('checkout-address'),
                    controller: _addressController,
                    textCapitalization: TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLines: 2,
                    autofillHints: const <String>[
                      AutofillHints.fullStreetAddress,
                    ],
                    decoration: const InputDecoration(
                      labelText: 'House / flat, street, area',
                      alignLabelWithHint: true,
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
                      labelText: 'Landmark (optional)',
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
                      labelText: '6-digit pincode',
                    ),
                    validator: (String? value) =>
                        RegExp(r'^\d{6}$').hasMatch(value ?? '')
                        ? null
                        : 'Valid 6-digit pincode daaliye',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
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
                        secondary: Icon(Icons.payments_outlined),
                        title: Text('Cash on Delivery'),
                        subtitle: Text('Delivery ke samay cash dein'),
                      ),
                    if (store.upiEnabled)
                      const RadioListTile<PaymentChoice>(
                        key: Key('payment-upi'),
                        value: PaymentChoice.upi,
                        contentPadding: EdgeInsets.zero,
                        secondary: Icon(Icons.qr_code_2_rounded),
                        title: Text('UPI'),
                        subtitle: Text(
                          'Order confirm hone par UPI payment complete karein',
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
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
                  ),
                  const Divider(height: 24),
                  _SummaryRow(
                    label: 'Total payable',
                    value: formatRupees(controller.total),
                    emphasize: true,
                  ),
                ],
              ),
            ),
            if (_submitError != null) ...<Widget>[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.error_outline_rounded),
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
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border(
              top: BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            ),
          ),
          child: FilledButton.icon(
            key: const Key('place-order'),
            onPressed: controller.placingOrder ? null : _placeOrder,
            icon: controller.placingOrder
                ? const SizedBox.square(
                    dimension: 19,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.verified_rounded),
            label: Text(
              controller.placingOrder
                  ? 'Order place ho raha hai…'
                  : 'Place order • ${formatRupees(controller.total)}',
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
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                CircleAvatar(radius: 14, child: Text(number)),
                const SizedBox(width: 9),
                Icon(icon, size: 20),
                const SizedBox(width: 7),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
  });

  final String label;
  final String value;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final TextStyle? style = emphasize
        ? Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900)
        : Theme.of(context).textTheme.bodyMedium;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(label, style: style)),
          Text(value, style: style?.copyWith(fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }
}
