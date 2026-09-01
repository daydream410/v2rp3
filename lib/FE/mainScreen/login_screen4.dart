// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, unused_field, non_constant_identifier_names, avoid_types_as_parameter_names, prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/controller.dart';
import 'package:v2rp3/BE/reqip.dart';
import 'package:v2rp3/FE/mainScreen/otp_verification_screen.dart';
import 'package:v2rp3/FE/shared/auth_ui.dart';

class LoginPage4 extends StatefulWidget {
  const LoginPage4({Key? key}) : super(key: key);

  @override
  State<LoginPage4> createState() => _LoginPage4State();
}

class _LoginPage4State extends State<LoginPage4> {
  bool _obsecuredText = true;
  static TextControllers textControllers = Get.put(TextControllers());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isLoading) return false;
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are you sure?'),
            content: const Text('Do you want to exit V2RP Mobile?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes'),
              ),
            ],
          ),
        );
        if (shouldPop == true) {
          SystemNavigator.pop();
        }
        return false;
      },
      child: AuthLoginShell(
        form: Form(
          key: _formKey,
          child: AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                AuthLoginTextField(
                  controller: textControllers.emailController.value,
                  label: 'Email',
                  hint: 'example@email.com',
                  icon: Icons.alternate_email_rounded,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter email';
                    }
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(value)) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                AuthLoginTextField(
                  controller: textControllers.passwordController.value,
                  label: 'Password',
                  hint: 'Enter your password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: _obsecuredText,
                  keyboardType: TextInputType.visiblePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onToggleObscure: () {
                    setState(() => _obsecuredText = !_obsecuredText);
                  },
                  onSubmitted: _handleLogin,
                  onEditingComplete: () => TextInput.finishAutofillContext(),
                  validator: (value) {
                    if (value == null || value.isEmpty || value.length < 3) {
                      return 'Please enter a valid password';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                AuthPrimaryButton(
                  label: 'Login',
                  icon: Icons.sailing_rounded,
                  isLoading: _isLoading,
                  onPressed: _isLoading ? null : _handleLogin,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_isLoading) return;

    FocusScope.of(context).unfocus();

    if (mounted) {
      setState(() => _isLoading = true);
    }

    await Future.delayed(const Duration(milliseconds: 50));

    try {
      final SharedPreferences sharedPreferences =
          await SharedPreferences.getInstance();
      await sharedPreferences.setString(
        'email',
        textControllers.emailController.value.text,
      );
      await sharedPreferences.setString(
        'password_temp',
        textControllers.passwordController.value.text,
      );

      await MsgHeader.loginProcessNEW();
      await Future.delayed(const Duration(milliseconds: 100));

      final success = MsgHeader.success;

      if (success == true) {
        final email = sharedPreferences.getString('email') ?? '';

        if (mounted) {
          textControllers.emailController.value.clear();
          textControllers.passwordController.value.clear();

          Get.snackbar(
            'Success',
            'Logged in as $email',
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
            backgroundColor: Colors.green,
            isDismissible: true,
            dismissDirection: DismissDirection.vertical,
            duration: const Duration(seconds: 2),
          );

          await Future.delayed(const Duration(milliseconds: 300));

          if (mounted) {
            Get.offAll(const OtpVerificationScreen());
          }
        }
      } else {
        if (mounted) {
          setState(() => _isLoading = false);
          await Future.delayed(const Duration(milliseconds: 100));

          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Failed Login',
            text: 'Incorrect email or password',
            barrierDismissible: true,
            confirmBtnColor: HexColor('#F4A62A'),
          );
        }
      }
    } catch (e) {
      print('Login error: $e');

      if (mounted) {
        setState(() => _isLoading = false);
        await Future.delayed(const Duration(milliseconds: 100));

        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Connection Error',
          text: e.toString().contains('timeout') ||
                  e.toString().contains('Timeout')
              ? 'Connection timeout. Please check your internet connection and try again.'
              : 'Failed to connect to server. Please check your internet connection and try again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
      }
    } finally {
      if (mounted) {
        if (_isLoading) {
          setState(() => _isLoading = false);
        }
        TextInput.finishAutofillContext();
      }
    }
  }
}
