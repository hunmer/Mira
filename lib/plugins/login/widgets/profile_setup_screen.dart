// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:mira/core/plugin_manager.dart';
import 'package:mira/plugins/login/l10n/login_localizations.dart';
import 'package:mira/plugins/login/login_plugin.dart';
import 'package:mira/widgets/image_display_widget.dart';
import 'package:mira/widgets/image_picker_dialog.dart';

class ProfileSetupScreen extends StatefulWidget {
  final String phoneNumber;

  const ProfileSetupScreen({super.key, required this.phoneNumber});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  late final String phoneNumber;
  final LoginPlugin _plugin =
      PluginManager.instance.getPlugin('login') as LoginPlugin;

  @override
  void initState() {
    super.initState();
    phoneNumber = widget.phoneNumber;
  }

  final _formKey = GlobalKey<FormState>();
  final _nicknameController = TextEditingController();
  String? _avatarPath;

  Future<void> _pickAvatar() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder:
          (context) => ImagePickerDialog(
            saveDirectory: 'user_avatars',
            enableCrop: true,
            cropAspectRatio: 1.0,
            enableNetworkImage: false, // 默认关闭网络图片选择
          ),
    );

    if (result != null && result['url'] != null && mounted) {
      setState(() {
        _avatarPath = result['url'];
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = LoginLocalizations.of(context);
    final authController = _plugin.authController;

    return Scaffold(
      appBar: AppBar(title: Text(localizations.completeRegistration)),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickAvatar,
                child: SizedBox(
                  width: 100,
                  height: 100,
                  child:
                      _avatarPath != null
                          ? ImageDisplayWidget(
                            imageUrl: _avatarPath,
                            size: 100,
                            placeholder: const Icon(
                              Icons.add_a_photo,
                              size: 40,
                            ),
                          )
                          : const Icon(Icons.add_a_photo, size: 40),
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nicknameController,
                decoration: InputDecoration(labelText: 'Nickname'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter your nickname';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        if (_formKey.currentState!.validate()) {
                          await authController.completeRegistration(
                            phoneNumber,
                            _nicknameController.text,
                            _avatarPath,
                          );
                          if (mounted) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('注册成功')));
                            // Navigator.pushNamedAndRemoveUntil(
                            //   context,
                            //   '/',
                            //   (route) => false,
                            // );
                          }
                        }
                      },
                      child: Text(localizations.completeRegistration),
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
