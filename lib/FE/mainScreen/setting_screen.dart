// ignore_for_file: avoid_print, prefer_typing_uninitialized_variables
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:v2rp3/utils/hex_color.dart';
import 'package:http/http.dart' as http;
import 'package:quickalert/quickalert.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:v2rp3/BE/approval_notif_controller.dart';
import 'package:v2rp3/BE/reqip.dart';
import 'package:v2rp3/FE/shared/approval_menu_ui.dart';
import 'package:v2rp3/FE/shared/auth_ui.dart';
import 'package:v2rp3/FE/mainScreen/login_screen4.dart';
import 'package:v2rp3/FE/navbar/navbar.dart';
import 'package:v2rp3/main.dart' show getAndSaveFcmToken;

class SettingScreen extends StatefulWidget {
  const SettingScreen({Key? key}) : super(key: key);

  @override
  State<SettingScreen> createState() => _SettingScreenState();
}

class _SettingScreenState extends State<SettingScreen> {
  final RefreshController _refreshController = RefreshController();
  String? finalEmail = '';
  String? finalUsername = '';
  bool _isLoading = true;
  Map<String, dynamic>? _profileData;
  String? _errorMessage;
  bool _isLoadingRoles = false;
  List<Map<String, dynamic>> _roles = [];
  final Map<String, ApprovalPendingSummary> _pendingBySeckey = {};
  bool _isLoadingRoleBadges = false;
  bool _roleBadgeProbeStarted = false;

  @override
  void initState() {
    super.initState();
    getEmail();
    fetchProfile();
  }

  Future<void> fetchProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? kulonuwun = prefs.getString('kulonuwun');
      final String? monggo = prefs.getString('monggo');

      if (kulonuwun == null || monggo == null) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Session expired. Please login again.';
        });
        return;
      }

      var headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'kulonuwun': kulonuwun,
        'monggo': monggo,
      };

      var request = http.Request(
        'GET',
        Uri.parse('https://v2rp.net/api/v2/mobile/profile'),
      );

      request.headers.addAll(headers);

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            _profileData = responseData['data'] as Map<String, dynamic>;
            _isLoading = false;
          });
        } else {
          setState(() {
            _isLoading = false;
            _errorMessage = responseData['message'] ?? 'Failed to load profile';
          });
        }
      } else {
        setState(() {
          _isLoading = false;
          _errorMessage =
              'Failed to load profile. Status: ${response.statusCode}';
        });
      }
    } on TimeoutException {
      setState(() {
        _isLoading = false;
        _errorMessage =
            'Connection timeout. Please check your internet connection.';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Error loading profile: $e';
      });
      print('Profile fetch error: $e');
    }
  }

  @override
  void dispose() {
    _refreshController.dispose();
    super.dispose();
  }

  Future<void> _onPullRefresh() async {
    final started = DateTime.now();
    try {
      await fetchProfile();
      await getEmail();
    } finally {
      final elapsed = DateTime.now().difference(started);
      const minDuration = Duration(milliseconds: 900);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
      if (mounted) {
        _refreshController.refreshCompleted();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;

    return WillPopScope(
      onWillPop: () async {
        final shouldPop = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Are You sure?'),
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
      child: Scaffold(
        backgroundColor: ApprovalMenuTheme.background,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          elevation: 0,
          backgroundColor: ApprovalMenuTheme.primary,
          title: const Text(
            'Profile',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
        body: RefreshConfiguration(
          headerTriggerDistance: 110,
          dragSpeedRatio: 0.65,
          child: SmartRefresher(
            controller: _refreshController,
            enablePullDown: true,
            enablePullUp: false,
            onRefresh: _onPullRefresh,
            header: WaterDropMaterialHeader(
              backgroundColor: Colors.white,
              color: ApprovalMenuTheme.primary,
              distance: 80,
              offset: 12,
            ),
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: ColoredBox(
                    color: ApprovalMenuTheme.primary,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: _buildProfileHero(isTablet),
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: ApprovalMenuTheme.background,
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildProfileBody(isTablet),
                        const SizedBox(height: 12),
                        _buildActionButton(
                          label:
                              _isLoadingRoles ? 'Loading...' : 'Change Company',
                          icon: Icons.business_center_outlined,
                          color: ApprovalMenuTheme.primary,
                          onPressed:
                              _isLoadingRoles ? null : _showChangeCompanyDialog,
                          isLoading: _isLoadingRoles,
                          isTablet: isTablet,
                        ),
                        const SizedBox(height: 10),
                        _buildActionButton(
                          label: 'Logout',
                          icon: Icons.logout_rounded,
                          color: Colors.red.shade600,
                          onPressed: _confirmLogout,
                          isTablet: isTablet,
                          outlined: true,
                        ),
                        const SizedBox(height: 12),
                        _buildVersionCard(isTablet),
                      ],
                    ),
                  ),
                ),
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: ColoredBox(
                    color: ApprovalMenuTheme.background,
                    child: SizedBox.expand(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHero(bool isTablet) {
    final avatarSize = isTablet ? 72.0 : 64.0;

    return Container(
      padding: EdgeInsets.all(isTablet ? 18 : 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: avatarSize,
            height: avatarSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'images/pp.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: Colors.white,
                  child: Icon(
                    Icons.person_rounded,
                    size: avatarSize * 0.5,
                    color: ApprovalMenuTheme.primary,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (finalUsername?.isNotEmpty ?? false)
                      ? finalUsername!
                      : 'User',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isTablet ? 20 : 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  (finalEmail?.isNotEmpty ?? false) ? finalEmail! : '—',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isTablet ? 14 : 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_profileData?['role'] != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_profileData!['role']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileBody(bool isTablet) {
    if (_isLoading) {
      return _buildSectionCard(
        isTablet: isTablet,
        title: 'Profile Information',
        icon: Icons.person_outline_rounded,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32),
          child: Center(
            child: CircularProgressIndicator(
              color: ApprovalMenuTheme.primary,
            ),
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return _buildSectionCard(
        isTablet: isTablet,
        title: 'Profile Information',
        icon: Icons.error_outline_rounded,
        child: Column(
          children: [
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: fetchProfile,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Retry'),
              style: TextButton.styleFrom(
                foregroundColor: ApprovalMenuTheme.primaryDark,
              ),
            ),
          ],
        ),
      );
    }

    if (_profileData == null) {
      return const SizedBox.shrink();
    }

    return _buildSectionCard(
      isTablet: isTablet,
      title: 'Profile Information',
      icon: Icons.person_outline_rounded,
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.badge_outlined,
            label: 'Role',
            value: _profileData!['role'] ?? 'N/A',
            isTablet: isTablet,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.business_outlined,
            label: 'Company',
            value: _profileData!['company'] ?? 'N/A',
            isTablet: isTablet,
          ),
          _buildDivider(),
          _buildInfoRow(
            icon: Icons.apartment_outlined,
            label: 'Company Name',
            value: _profileData!['companyname'] ?? 'N/A',
            isTablet: isTablet,
            isMultiline: true,
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required bool isTablet,
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ApprovalMenuTheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: ApprovalMenuTheme.primaryDark,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: isTablet ? 17 : 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: Colors.grey.shade100),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: child,
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Divider(height: 1, color: Colors.grey.shade100),
      );

  Widget _buildActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    required bool isTablet,
    bool isLoading = false,
    bool outlined = false,
  }) {
    return Material(
      color: outlined ? Colors.white : color,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Container(
          padding: EdgeInsets.symmetric(vertical: isTablet ? 16 : 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: outlined ? Border.all(color: color.withOpacity(0.5)) : null,
            boxShadow: outlined
                ? null
                : [
                    BoxShadow(
                      color: color.withOpacity(0.25),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: outlined ? color : Colors.white,
                  ),
                )
              else
                Icon(icon, color: outlined ? color : Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: outlined ? color : Colors.white,
                  fontSize: isTablet ? 16 : 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVersionCard(bool isTablet) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 18 : 16,
        vertical: isTablet ? 16 : 14,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: ApprovalMenuTheme.primaryDark,
            size: isTablet ? 22 : 20,
          ),
          const SizedBox(width: 10),
          Text(
            'App Version',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade700,
            ),
          ),
          const Spacer(),
          Text(
            '1.4.1',
            style: TextStyle(
              fontSize: isTablet ? 15 : 14,
              fontWeight: FontWeight.bold,
              color: ApprovalMenuTheme.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    final sharedPreferences = await SharedPreferences.getInstance();
    sharedPreferences.remove('username');
    sharedPreferences.remove('email');
    sharedPreferences.remove('password');
    sharedPreferences.remove('kulonuwun');
    sharedPreferences.remove('monggo');
    sharedPreferences.remove('seckey');
    sharedPreferences.remove('otp_roles');
    await sharedPreferences.clear();

    Get.offAll(() => const LoginPage4());
    Get.snackbar(
      'Success Logout',
      'From V2RP Mobile',
      colorText: Colors.white,
      icon: const Icon(Icons.logout, color: Colors.white),
      backgroundColor: Colors.red,
      isDismissible: true,
      dismissDirection: DismissDirection.vertical,
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required bool isTablet,
    bool isMultiline = false,
  }) {
    return Row(
      crossAxisAlignment:
          isMultiline ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: ApprovalMenuTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: ApprovalMenuTheme.primaryDark,
            size: isTablet ? 20.0 : 18.0,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: isTablet ? 12.0 : 11.0,
                  color: Colors.grey.shade500,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                value,
                style: TextStyle(
                  fontSize: isTablet ? 15.0 : 14.0,
                  color: Colors.grey.shade900,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: isMultiline ? 3 : 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future getEmail() async {
    final SharedPreferences sharedPreferences =
        await SharedPreferences.getInstance();
    setState(() {
      finalEmail = sharedPreferences.getString('email');
      finalUsername = sharedPreferences.getString('username');
    });
  }

  Future<void> _fetchRoles() async {
    setState(() {
      _isLoadingRoles = true;
      _roles = [];
      _pendingBySeckey.clear();
    });

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? kulonuwun = prefs.getString('kulonuwun');
      final String? monggo = prefs.getString('monggo');

      if (kulonuwun == null || monggo == null) {
        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'Session expired. Please login again.',
            barrierDismissible: true,
            confirmBtnColor: HexColor("#F4A62A"),
          );
        }
        setState(() {
          _isLoadingRoles = false;
        });
        return;
      }

      var headers = {
        'Content-Type': 'application/json; charset=utf-8',
        'kulonuwun': kulonuwun,
        'monggo': monggo,
      };

      var request = http.Request(
        'GET',
        Uri.parse('https://v2rp.net/api/v2/mobile/change/role'),
      );

      request.headers.addAll(headers);

      var streamedResponse = await request.send().timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('Connection timeout. Please try again.');
        },
      );

      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          List<dynamic> rolesList = responseData['data'] as List<dynamic>;
          setState(() {
            _roles =
                rolesList.map((role) => role as Map<String, dynamic>).toList();
            _isLoadingRoles = false;
          });
        } else {
          setState(() {
            _isLoadingRoles = false;
          });
          if (mounted) {
            QuickAlert.show(
              context: context,
              type: QuickAlertType.error,
              title: 'Error',
              text: responseData['message'] ?? 'Failed to load roles',
              barrierDismissible: true,
              confirmBtnColor: HexColor("#F4A62A"),
            );
          }
        }
      } else {
        setState(() {
          _isLoadingRoles = false;
        });
        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.error,
            title: 'Error',
            text: 'Failed to load roles. Status: ${response.statusCode}',
            barrierDismissible: true,
            confirmBtnColor: HexColor("#F4A62A"),
          );
        }
      }
    } on TimeoutException {
      setState(() {
        _isLoadingRoles = false;
      });
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Connection Timeout',
          text: 'Please check your internet connection and try again.',
          barrierDismissible: true,
          confirmBtnColor: HexColor("#F4A62A"),
        );
      }
    } catch (e) {
      setState(() {
        _isLoadingRoles = false;
      });
      if (mounted) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Error loading roles: $e',
          barrierDismissible: true,
          confirmBtnColor: HexColor("#F4A62A"),
        );
      }
      print('Fetch roles error: $e');
    }
  }

  Future<void> _loadRolePendingBadges({
    void Function(void Function())? setModalState,
  }) async {
    if (_roles.isEmpty) return;
    _isLoadingRoleBadges = true;
    setModalState?.call(() {});
    if (mounted) setState(() {});

    try {
      // Prefer already-loaded summary for the active company session.
      if (Get.isRegistered<ApprovalNotifController>()) {
        final totals = Get.find<ApprovalNotifController>().totals.value;
        final current = ApprovalPendingSummary.fromTotals(totals);
        final currentRole = _profileData?['role']?.toString();
        final currentCompany = _profileData?['company']?.toString();
        for (final role in _roles) {
          if (role['role']?.toString() == currentRole &&
              role['company']?.toString() == currentCompany) {
            final seckey = role['seckey']?.toString() ?? '';
            if (seckey.isNotEmpty) {
              _pendingBySeckey[seckey] = current;
              setModalState?.call(() {});
            }
            break;
          }
        }
      }

      final prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');
      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await getAndSaveFcmToken();
      }

      await approvalProbePendingCountsForRoles(
        _roles,
        fcmToken: fcmToken ?? '',
        onSummary: (seckey, summary) {
          _pendingBySeckey[seckey] = summary;
          setModalState?.call(() {});
          if (mounted) setState(() {});
        },
      );
    } catch (e) {
      print('Error loading role pending badges: $e');
    } finally {
      _isLoadingRoleBadges = false;
      setModalState?.call(() {});
      if (mounted) setState(() {});
    }
  }

  void _showChangeCompanyDialog() {
    _roleBadgeProbeStarted = false;
    _fetchRoles().then((_) {
      if (!mounted || _roles.isEmpty) return;

      showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setModalState) {
              if (!_roleBadgeProbeStarted && _roles.isNotEmpty) {
                _roleBadgeProbeStarted = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _loadRolePendingBadges(setModalState: setModalState);
                });
              }

              Size dialogSize = MediaQuery.of(context).size;
              bool isTabletDialog = dialogSize.width > 600;
              double dialogPadding = isTabletDialog ? 24.0 : 20.0;
              double dialogTitleFontSize = isTabletDialog ? 24.0 : 22.0;
              double dialogIconSize = isTabletDialog ? 32.0 : 28.0;
              double roleCardPadding = isTabletDialog ? 20.0 : 16.0;
              double roleIconSize = isTabletDialog ? 56.0 : 48.0;
              double roleIconInnerSize = isTabletDialog ? 28.0 : 24.0;
              double roleTitleFontSize = isTabletDialog ? 18.0 : 16.0;
              double roleSubtitleFontSize = isTabletDialog ? 15.0 : 14.0;
              double roleCompanyFontSize = isTabletDialog ? 13.0 : 12.0;
              double roleBadgeFontSize = isTabletDialog ? 12.0 : 11.0;
              double listPadding = isTabletDialog ? 24.0 : 16.0;
              double maxDialogWidth = isTabletDialog ? 600.0 : double.infinity;
              double sheetHeight = dialogSize.height * 0.75;

              return Container(
                height: sheetHeight,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(isTabletDialog ? 28.0 : 24.0),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: EdgeInsets.all(dialogPadding),
                      decoration: BoxDecoration(
                        color: HexColor("#F4A62A"),
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(isTabletDialog ? 28.0 : 24.0),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.business_center,
                            color: Colors.white,
                            size: dialogIconSize,
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Change Company',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: dialogTitleFontSize,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.close,
                              color: Colors.white,
                              size: isTabletDialog ? 28.0 : 24.0,
                            ),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Center(
                        child: ConstrainedBox(
                          constraints: BoxConstraints(maxWidth: maxDialogWidth),
                          child: ListView.builder(
                            padding: EdgeInsets.all(listPadding),
                            itemCount: _roles.length,
                            itemBuilder: (context, index) {
                              final role = _roles[index];
                              final seckey = role['seckey']?.toString() ?? '';
                              final pending = _pendingBySeckey[seckey] ??
                                  ApprovalPendingSummary.empty;
                              final showBadgeLoader = _isLoadingRoleBadges &&
                                  !_pendingBySeckey.containsKey(seckey);
                              final currentRole = _profileData?['role'] ?? '';
                              final currentCompany =
                                  _profileData?['company'] ?? '';
                              final isCurrentRole =
                                  role['role'] == currentRole &&
                                      role['company'] == currentCompany;

                              return Container(
                                margin: EdgeInsets.only(
                                  bottom: isTabletDialog ? 16.0 : 12.0,
                                ),
                                decoration: BoxDecoration(
                                  color: isCurrentRole
                                      ? HexColor("#F4A62A").withOpacity(0.1)
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: isCurrentRole
                                        ? HexColor("#F4A62A")
                                        : Colors.grey[300]!,
                                    width: isCurrentRole ? 2 : 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 5,
                                      offset: Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: isCurrentRole
                                        ? null
                                        : () => _chooseRole(role),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Padding(
                                      padding: EdgeInsets.all(roleCardPadding),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Container(
                                            width: roleIconSize,
                                            height: roleIconSize,
                                            decoration: BoxDecoration(
                                              color: HexColor("#F4A62A")
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                            ),
                                            child: Icon(
                                              Icons.business,
                                              color: HexColor("#F4A62A"),
                                              size: roleIconInnerSize,
                                            ),
                                          ),
                                          SizedBox(
                                              width:
                                                  isTabletDialog ? 20.0 : 16.0),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        role['role'] ?? 'N/A',
                                                        style: TextStyle(
                                                          fontSize:
                                                              roleTitleFontSize,
                                                          fontWeight:
                                                              FontWeight.bold,
                                                          color:
                                                              Colors.grey[900],
                                                        ),
                                                      ),
                                                    ),
                                                    if (isCurrentRole)
                                                      Container(
                                                        padding: EdgeInsets
                                                            .symmetric(
                                                          horizontal:
                                                              isTabletDialog
                                                                  ? 10.0
                                                                  : 8.0,
                                                          vertical:
                                                              isTabletDialog
                                                                  ? 6.0
                                                                  : 4.0,
                                                        ),
                                                        decoration:
                                                            BoxDecoration(
                                                          color: HexColor(
                                                              "#F4A62A"),
                                                          borderRadius:
                                                              BorderRadius
                                                                  .circular(12),
                                                        ),
                                                        child: Text(
                                                          'Current',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize:
                                                                roleBadgeFontSize,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                SizedBox(height: 4),
                                                Text(
                                                  role['companyname'] ?? 'N/A',
                                                  style: TextStyle(
                                                    fontSize:
                                                        roleSubtitleFontSize,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                ),
                                                SizedBox(height: 4),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.domain,
                                                      size: isTabletDialog
                                                          ? 14.0
                                                          : 12.0,
                                                      color: Colors.grey[600],
                                                    ),
                                                    SizedBox(width: 4),
                                                    Text(
                                                      role['company'] ?? 'N/A',
                                                      style: TextStyle(
                                                        fontSize:
                                                            roleCompanyFontSize,
                                                        color: Colors.grey[600],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                if (showBadgeLoader) ...[
                                                  const SizedBox(height: 8),
                                                  const AuthRolePendingLoading(),
                                                ] else if (pending
                                                    .hasPending) ...[
                                                  const SizedBox(height: 8),
                                                  AuthRolePendingMenus(
                                                    summary: pending,
                                                  ),
                                                ],
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Column(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              if (!showBadgeLoader &&
                                                  pending.hasPending)
                                                AuthRolePendingTotal(
                                                  total: pending.total,
                                                ),
                                              if (!isCurrentRole)
                                                Icon(
                                                  Icons.arrow_forward_ios,
                                                  size: isTabletDialog
                                                      ? 18.0
                                                      : 16.0,
                                                  color: Colors.grey[400],
                                                ),
                                            ],
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    });
  }

  Future<void> _chooseRole(Map<String, dynamic> role) async {
    Navigator.of(context).pop(); // Close dialog

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      String? fcmToken = prefs.getString('fcm_token');
      final String? seckey = role['seckey'];

      if (seckey == null || seckey.isEmpty) {
        QuickAlert.show(
          context: context,
          type: QuickAlertType.error,
          title: 'Error',
          text: 'Invalid role data',
          barrierDismissible: true,
          confirmBtnColor: HexColor("#F4A62A"),
        );
        return;
      }

      // If FCM token is not available, get it first
      if (fcmToken == null || fcmToken.isEmpty) {
        fcmToken = await getAndSaveFcmToken();
      }

      String platform = Platform.isAndroid ? 'android' : 'ios';

      await MsgHeader.chooseRole(
        seckey,
        fcmToken ?? '',
        platform,
      );

      if (MsgHeader.roleSuccess == true &&
          (MsgHeader.kulonuwun ?? '').toString().isNotEmpty &&
          (MsgHeader.monggo ?? '').toString().isNotEmpty) {
        await prefs.setString('kulonuwun', MsgHeader.kulonuwun ?? '');
        await prefs.setString('monggo', MsgHeader.monggo ?? '');

        // Refresh profile + pending approvals for the new company session.
        await fetchProfile();
        await approvalReloadAfterCompanyChange();

        if (mounted) {
          QuickAlert.show(
            context: context,
            type: QuickAlertType.success,
            title: 'Success',
            text: 'Company changed successfully',
            barrierDismissible: true,
            confirmBtnColor: HexColor("#F4A62A"),
            onConfirmBtnTap: () {
              Navigator.of(context).pop();
              // Navigate to navbar to refresh the app
              Get.offAll(const Navbar());
            },
          );
        }
      } else {
        throw Exception(MsgHeader.roleMessage ?? 'Failed to select company');
      }
    } on TimeoutException {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Connection Timeout',
        text: 'Please check your internet connection and try again.',
        barrierDismissible: true,
        confirmBtnColor: HexColor("#F4A62A"),
      );
    } catch (e) {
      QuickAlert.show(
        context: context,
        type: QuickAlertType.error,
        title: 'Error',
        text: 'Error changing company: $e',
        barrierDismissible: true,
        confirmBtnColor: HexColor("#F4A62A"),
      );
      print('Choose role error: $e');
    }
  }
}
