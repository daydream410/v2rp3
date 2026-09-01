// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, unused_field, non_constant_identifier_names, avoid_types_as_parameter_names, prefer_const_constructors

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/reqip.dart';
import 'package:v2rp3/FE/mainScreen/choose_role_screen.dart';
import 'package:v2rp3/FE/shared/auth_ui.dart';

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({Key? key}) : super(key: key);

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  Timer? _countdownTimer;
  int _countdown = 180;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_countdown > 0) {
        if (mounted) {
          setState(() => _countdown--);
        }
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    for (final controller in _otpControllers) {
      controller.dispose();
    }
    for (final node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  String _formatCountdown(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _onOtpChanged(int index, String value) {
    if (_isUpdatingOtp) return;

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length > 1) {
      _isUpdatingOtp = true;
      for (var i = 0; i < _otpControllers.length; i++) {
        _otpControllers[i].text =
            i < digits.length ? digits[i] : '';
      }
      _isUpdatingOtp = false;

      if (digits.length >= 6) {
        _focusNodes.last.unfocus();
        _tryAutoVerify();
      } else {
        _focusNodes[digits.length.clamp(0, 5)].requestFocus();
      }
      return;
    }

    if (digits.isEmpty) {
      if (index > 0) {
        _focusNodes[index - 1].requestFocus();
      }
      return;
    }

    _otpControllers[index].text = digits;

    if (index < 5) {
      _focusNodes[index + 1].requestFocus();
    } else {
      _focusNodes[index].unfocus();
      _tryAutoVerify();
    }
  }

  bool _isUpdatingOtp = false;

  void _tryAutoVerify() {
    if (_isLoading) return;

    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length == 6) {
      _verifyOtp();
    }
  }

  void _submitOtp() {
    FocusManager.instance.primaryFocus?.unfocus();
    _verifyOtp();
  }

  Future<void> _goBackToLogin() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('seckey');
    Get.offAllNamed('/Login');
  }

  Future<void> _verifyOtp() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final otp = _otpControllers.map((controller) => controller.text).join();
    if (otp.length != 6) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Invalid OTP',
        text: 'Please enter 6-digit OTP',
        barrierDismissible: true,
        confirmBtnColor: HexColor('#F4A62A'),
      );
      return;
    }

    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? seckey = prefs.getString('seckey');

      if (seckey == null) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Session expired. Please login again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
        Get.offAllNamed('/Login');
        return;
      }

      await MsgHeader.verifyOtp(seckey, otp);

      if (MsgHeader.otpSuccess == true) {
        if (mounted) {
          await prefs.remove('password_temp');

          Get.snackbar(
            'Success',
            'OTP verified successfully',
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
            backgroundColor: Colors.green,
            isDismissible: true,
            dismissDirection: DismissDirection.vertical,
            duration: const Duration(seconds: 2),
          );

          Get.offAll(const ChooseRoleScreen());
        }
      } else {
        if (mounted) {
          String errorMessage = '';
          if (MsgHeader.otpData != null &&
              MsgHeader.otpData.toString().trim().isNotEmpty) {
            errorMessage = MsgHeader.otpData.toString().trim();
          } else if (MsgHeader.otpMessage != null &&
              MsgHeader.otpMessage.toString().trim().isNotEmpty) {
            errorMessage = MsgHeader.otpMessage.toString().trim();
          } else {
            errorMessage = 'Invalid OTP. Please try again.';
          }

          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Verification Failed',
            text: errorMessage,
            barrierDismissible: true,
            confirmBtnColor: HexColor('#F4A62A'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Connection Error',
          text:
              'Failed to verify OTP. Please check your internet connection and try again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
      }
      print('OTP verification error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendOtp() async {
    if (_isLoading) return;

    setState(() => _isLoading = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? email = prefs.getString('email');
      final String? password = prefs.getString('password_temp');

      if (email == null || password == null) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Session expired. Please login again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
        Get.offAllNamed('/Login');
        return;
      }

      await MsgHeader.resendOtp(email, password);

      if (MsgHeader.resendOtpSuccess == true) {
        if (mounted) {
          setState(() => _countdown = 180);
          _startCountdown();

          for (final controller in _otpControllers) {
            controller.clear();
          }
          _focusNodes[0].requestFocus();

          Get.snackbar(
            'Success',
            'OTP has been resent via email, Telegram, or WhatsApp',
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
            backgroundColor: Colors.green,
            isDismissible: true,
            dismissDirection: DismissDirection.vertical,
            duration: const Duration(seconds: 3),
          );
        }
      } else {
        if (mounted) {
          final errorMessage = MsgHeader.resendOtpMessage.isNotEmpty
              ? MsgHeader.resendOtpMessage
              : 'Failed to resend OTP. Please try again.';

          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Resend Failed',
            text: errorMessage,
            barrierDismissible: true,
            confirmBtnColor: HexColor('#F4A62A'),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Connection Error',
          text:
              'Failed to resend OTP. Please check your internet connection and try again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
      }
      print('Resend OTP error: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthHeroShell(
      step: AuthStep.otp,
      title: 'Verify Identity',
      onBack: _goBackToLogin,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            const AuthHeroSubtitle(
              text: 'Enter the 6-digit code from email, Telegram, or WhatsApp',
            ),
            const SizedBox(height: 16),
            const AuthOtpChannelsRow(),
            const SizedBox(height: 16),
            AuthOtpInputRow(
              controllers: _otpControllers,
              focusNodes: _focusNodes,
              onChanged: _onOtpChanged,
              onSubmit: _submitOtp,
              heroStyle: true,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return '';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            Center(
              child: _countdown > 0
                  ? AuthCountdownChip(
                      text: 'Resend in ${_formatCountdown(_countdown)}',
                      heroStyle: true,
                    )
                  : AuthSecondaryButton(
                      label: 'Resend OTP',
                      icon: Icons.refresh_rounded,
                      isLoading: _isLoading,
                      heroStyle: true,
                      onPressed: _isLoading ? null : _resendOtp,
                    ),
            ),
            const SizedBox(height: 14),
            AuthPrimaryButton(
              label: 'Verify',
              icon: Icons.check_circle_outline_rounded,
              isLoading: _isLoading,
              onPressed: _isLoading ? null : _verifyOtp,
            ),
          ],
        ),
      ),
    );
  }
}
