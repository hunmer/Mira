import 'package:flutter/material.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';
import 'package:mira/plugins/login/controllers/auth_controller.dart';
import 'package:provider/provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final localizations = LoginLocalizations.of(context);
    final authController = Provider.of<AuthController>(context);

    return Scaffold(
      appBar: AppBar(title: Text(localizations.registerTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _phoneController,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixText: '+86 ',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your phone number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          authController.sendVerificationCode(
                            _phoneController.text,
                          );
                          // TODO: Navigate to verification code screen
                        }
                      },
                      child: Text(localizations.nextStep),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
