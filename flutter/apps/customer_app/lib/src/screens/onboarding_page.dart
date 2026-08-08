import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../customer_controller.dart';
import '../domain.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({required this.controller, super.key});

  final CustomerController controller;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _mobileController = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _saving = true);
    await widget.controller.saveProfile(
      CustomerProfile(
        name: _nameController.text.trim(),
        mobile: _mobileController.text.trim(),
      ),
    );
    if (!mounted) return;
    setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Align(
                    alignment: Alignment.centerLeft,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(18),
                        child: Icon(
                          Icons.local_grocery_store_rounded,
                          size: 42,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Apni kirana dukaan,\nab aapke phone par',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Fresh stock dekhiye, ghar se order kijiye aur delivery ko live track kijiye.',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            Text(
                              'Aapki basic details',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              key: const Key('profile-name'),
                              controller: _nameController,
                              textCapitalization: TextCapitalization.words,
                              textInputAction: TextInputAction.next,
                              autofillHints: const <String>[AutofillHints.name],
                              decoration: const InputDecoration(
                                labelText: 'Naam',
                                prefixIcon: Icon(Icons.person_outline_rounded),
                              ),
                              validator: (String? value) {
                                if ((value ?? '').trim().length < 2) {
                                  return 'Apna poora naam daaliye';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              key: const Key('profile-mobile'),
                              controller: _mobileController,
                              keyboardType: TextInputType.phone,
                              textInputAction: TextInputAction.done,
                              autofillHints: const <String>[
                                AutofillHints.telephoneNumber,
                              ],
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              decoration: const InputDecoration(
                                labelText: '10-digit mobile number',
                                prefixIcon: Icon(Icons.phone_android_rounded),
                                prefixText: '+91  ',
                              ),
                              validator: (String? value) {
                                final String mobile = (value ?? '').trim();
                                if (!RegExp(r'^[6-9]\d{9}$').hasMatch(mobile)) {
                                  return 'Valid 10-digit Indian mobile number daaliye';
                                }
                                return null;
                              },
                              onFieldSubmitted: (_) =>
                                  _saving ? null : _continue(),
                            ),
                            const SizedBox(height: 18),
                            FilledButton.icon(
                              key: const Key('profile-continue'),
                              onPressed: _saving ? null : _continue,
                              icon: _saving
                                  ? const SizedBox.square(
                                      dimension: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Icon(Icons.arrow_forward_rounded),
                              label: Text(
                                _saving
                                    ? 'Profile save ho rahi hai…'
                                    : 'Dukaan chunein',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: <Widget>[
                      Icon(Icons.lock_outline_rounded, size: 16),
                      SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Details sirf order aur delivery ke liye use hongi.',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
