// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables, unused_field, non_constant_identifier_names, avoid_types_as_parameter_names, prefer_const_constructors

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';
import 'package:v2rp3/BE/reqip.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/FE/mainScreen/otp_verification_screen.dart';
import 'package:v2rp3/FE/shared/auth_ui.dart';
import 'package:v2rp3/main.dart' show getAndSaveFcmToken;

class ChooseRoleScreen extends StatefulWidget {
  const ChooseRoleScreen({Key? key}) : super(key: key);

  @override
  State<ChooseRoleScreen> createState() => _ChooseRoleScreenState();
}

class _ChooseRoleScreenState extends State<ChooseRoleScreen> {
  bool _isLoading = false;
  String? _selectedCompanyName;
  bool _isLoadingRoles = true;
  bool _isLoadingBadges = false;
  List<Map<String, dynamic>> _roles = [];
  final Map<String, ApprovalPendingSummary> _pendingBySeckey = {};

  @override
  void initState() {
    super.initState();
    _loadRoles();
  }

  Future<void> _loadRoles() async {
    setState(() {
      _isLoadingRoles = true;
      _roles = [];
      _pendingBySeckey.clear();
    });

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? rolesJson = prefs.getString('otp_roles');

    if (rolesJson != null) {
      try {
        final decoded = jsonDecode(rolesJson);
        if (decoded is List) {
          if (mounted) {
            setState(() {
              _roles = List<Map<String, dynamic>>.from(
                decoded.map((role) => role as Map<String, dynamic>),
              );
            });
          }
        }
      } catch (e) {
        print('Error loading roles: $e');
      }
    }

    if (_roles.isEmpty && MsgHeader.rolesData != null) {
      try {
        if (MsgHeader.rolesData is List) {
          if (mounted) {
            setState(() {
              _roles = List<Map<String, dynamic>>.from(
                (MsgHeader.rolesData as List)
                    .map((role) => role as Map<String, dynamic>),
              );
            });
          }
        }
      } catch (e) {
        print('Error loading roles from MsgHeader: $e');
      }
    }

    if (_roles.isNotEmpty) {
      final cached = await approvalLoadPendingSummaryCache();
      if (mounted) {
        setState(() {
          for (final role in _roles) {
            final seckey = role['seckey']?.toString() ?? '';
            final summary = cached[approvalPendingRoleCacheKey(role)];
            if (summary != null) _pendingBySeckey[seckey] = summary;
          }
          _isLoadingRoles = false;
        });
      }

      final hasMissingBadges = _roles.any((role) {
        final seckey = role['seckey']?.toString() ?? '';
        return seckey.isNotEmpty && !_pendingBySeckey.containsKey(seckey);
      });
      if (hasMissingBadges) {
        unawaited(_loadPendingBadges());
      }
    } else if (mounted) {
      setState(() => _isLoadingRoles = false);
    }
  }

  Future<void> _loadPendingBadges() async {
    if (!mounted || _roles.isEmpty) return;
    final rolesToLoad = _roles.where((role) {
      final seckey = role['seckey']?.toString() ?? '';
      return seckey.isNotEmpty && !_pendingBySeckey.containsKey(seckey);
    }).toList(growable: false);
    if (rolesToLoad.isEmpty) return;

    setState(() => _isLoadingBadges = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await getAndSaveFcmToken();
      }

      await approvalProbePendingCountsForRoles(
        rolesToLoad,
        fcmToken: fcmToken ?? '',
        onSummary: (seckey, summary) {
          if (!mounted) return;
          setState(() => _pendingBySeckey[seckey] = summary);
        },
      );
    } catch (e) {
      print('Error loading company pending badges: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoadingBadges = false);
      }
    }
  }

  Future<void> _chooseRole(Map<String, dynamic> role) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _selectedCompanyName =
          role['companyname']?.toString() ?? role['company']?.toString();
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');

      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await getAndSaveFcmToken();
      }

      final String seckey = role['seckey'] ?? '';
      final String platform = Platform.isAndroid ? 'android' : 'ios';

      await MsgHeader.chooseRole(
        seckey,
        fcmToken ?? '',
        platform,
      );

      if (MsgHeader.roleSuccess == true) {
        await prefs.setString('kulonuwun', MsgHeader.kulonuwun ?? '');
        await prefs.setString('monggo', MsgHeader.monggo ?? '');
        await prefs.setString(
          'selected_pending_cache_key',
          approvalPendingRoleCacheKey(role),
        );

        // Prefetch pending approvals for the newly selected company.
        await approvalReloadAfterCompanyChange();

        if (mounted) {
          Get.snackbar(
            'Success',
            'Company selected successfully',
            colorText: Colors.white,
            icon: const Icon(Icons.check, color: Colors.white),
            backgroundColor: Colors.green,
            isDismissible: true,
            dismissDirection: DismissDirection.vertical,
            duration: const Duration(seconds: 2),
          );

          Get.offAll(const Navbar());
        }
      } else {
        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Failed',
            text: MsgHeader.roleMessage ??
                'Failed to select company. Please try again.',
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
              'Failed to select company. Please check your internet connection and try again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor('#F4A62A'),
        );
      }
      print('Choose role error: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _selectedCompanyName = null;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AuthHeroShell(
          step: AuthStep.company,
          title: 'Select Your Port',
          onBack: () => Get.offAll(const OtpVerificationScreen()),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              const AuthHeroSubtitle(
                text: 'Pick your role and company to enter',
              ),
              const SizedBox(height: 20),
              if (_isLoadingRoles)
                const AuthRoleLoadingSkeleton(heroStyle: true)
              else if (_roles.isEmpty)
                AuthEmptyState(
                  message: 'No company roles found. Please sign in again.',
                  onRetry: _loadRoles,
                  heroStyle: true,
                )
              else ...[
                AuthInfoBanner(
                  message:
                      '${_roles.length} role${_roles.length == 1 ? '' : 's'} available',
                  icon: Icons.directions_boat_filled_outlined,
                  heroStyle: true,
                ),
                const SizedBox(height: 10),
                for (final role in _roles)
                  AuthRoleCard(
                    role: role,
                    isLoading: _isLoading,
                    heroStyle: true,
                    pending: _pendingBySeckey[role['seckey']?.toString()] ??
                        ApprovalPendingSummary.empty,
                    isLoadingBadge: _isLoadingBadges &&
                        !_pendingBySeckey
                            .containsKey(role['seckey']?.toString()),
                    onTap: () => _chooseRole(role),
                  ),
              ],
            ],
          ),
        ),
        if (_isLoading) ...[
          const Positioned.fill(
            child: ModalBarrier(
              dismissible: false,
              color: Color(0x99071325),
            ),
          ),
          Positioned.fill(
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 300),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 24,
                      offset: Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(
                      color: HexColor('#F4A62A'),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Preparing your company',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF071325),
                      ),
                    ),
                    if (_selectedCompanyName?.trim().isNotEmpty == true) ...[
                      const SizedBox(height: 6),
                      Text(
                        _selectedCompanyName!,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      'Setting up your session and approval data...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
