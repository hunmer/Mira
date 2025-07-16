// ignore_for_file: use_build_context_synchronously

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';
import 'package:mira/plugins/login/controllers/auth_controller.dart';
import 'package:mira/plugins/login/login_plugin.dart';
import 'package:mira/plugins/login/utils/auth_utils.dart';
import 'package:mira/plugins/login/widgets/profile_setup_screen.dart';

class VerificationScreen extends StatefulWidget {
  final String phoneNumber;

  const VerificationScreen({super.key, required this.phoneNumber});

  @override
  State<VerificationScreen> createState() => _VerificationScreenState();
}

class _VerificationScreenState extends State<VerificationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final LoginPlugin _plugin =
      PluginManager.instance.getPlugin('login') as LoginPlugin;
  int _countdown = 60;
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _startCountdown() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        setState(() {
          _countdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LoginLocalizations.of(context);
    final authController = _plugin.authController;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.registerTitle)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Text(
                'Verification code sent to ${widget.phoneNumber}',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeController,
                decoration: InputDecoration(labelText: 'Verification Code'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter verification code';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _countdown == 0
                            ? () {
                              authController.sendVerificationCode(
                                widget.phoneNumber,
                              );
                              setState(() {
                                _countdown = 60;
                              });
                              _startCountdown();
                            }
                            : null,
                    child: Text(
                      _countdown == 0
                          ? 'Resend Code'
                          : 'Resend in $_countdown seconds',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          final LoginErrorCode code = await authController
                              .verifyCodeAndRegister(
                                widget.phoneNumber,
                                _codeController.text,
                              );
                          AuthUtils.showCodeMessage(code, context);
                          if (code == LoginErrorCode.success) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => ProfileSetupScreen(
                                      phoneNumber: widget.phoneNumber,
                                    ),
                              ),
                            );
                          }
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
