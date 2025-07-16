// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/login/controllers/auth_controller.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';
import 'package:mira/plugins/login/login_plugin.dart';
import 'package:mira/plugins/login/utils/auth_utils.dart';
import 'package:mira/plugins/login/widgets/verification_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final LoginPlugin _plugin =
      PluginManager.instance.getPlugin('login') as LoginPlugin;
  bool _isPasswordLogin = true;
  bool _isLoading = false;

  Future<void> _handlePasswordLogin(AuthController authController) async {
    setState(() => _isLoading = true);

    try {
      final LoginErrorCode code = await authController.loginWithPassword(
        _phoneController.text,
        _passwordController.text,
      );
      if (mounted) AuthUtils.showCodeMessage(code, context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LoginLocalizations.of(context);
    final authController = _plugin.authController;
    return Scaffold(
      appBar: AppBar(title: Text(localizations.loginTitle)),
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
              if (_isPasswordLogin) ...[
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your password';
                    }
                    return null;
                  },
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          if (_isPasswordLogin) {
                            _handlePasswordLogin(authController);
                          } else {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (context) => VerificationScreen(
                                      phoneNumber: _phoneController.text,
                                    ),
                              ),
                            ).then((success) {
                              if (success == true && mounted) {
                                Navigator.pop(context, true);
                              }
                            });
                          }
                        }
                      },
                      child:
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Text(localizations.loginTitle),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _isPasswordLogin = !_isPasswordLogin;
                  });
                },
                child: Text(
                  _isPasswordLogin
                      ? localizations.phoneLogin
                      : localizations.passwordLogin,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
