import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v2rp3/FE/shared/approval_menu_ui.dart';

enum AuthStep { login, otp, company }

class AuthMaritimeTheme {
  static const Color oceanDeep = Color(0xFF0A2540);
  static const Color oceanMid = Color(0xFF13466B);
  static const Color oceanBright = Color(0xFF1E6A94);
  static const Color seaFoam = Color(0xFFE6F2F8);
  static const Color mist = Color(0xFFF2F8FB);

  /// Orange hero overlay — matches Approval Menu theme (darkened)
  static const Color overlayDeep = Color(0xFF2A1804);
  static const Color overlayDark = Color(0xFF3D2408);
  static const Color overlayMid = Color(0xFF5A3410);
}

/// Responsive sizing for immersive auth hero screens (login, OTP, company).
class AuthHeroLayout {
  final double maxContentWidth;
  final double horizontalPadding;
  final bool isTablet;
  final bool isLargeTablet;
  final double logoSize;
  final double titleFontSize;
  final double bodyFontSize;
  final double buttonHeight;

  const AuthHeroLayout({
    required this.maxContentWidth,
    required this.horizontalPadding,
    required this.isTablet,
    required this.isLargeTablet,
    required this.logoSize,
    required this.titleFontSize,
    required this.bodyFontSize,
    required this.buttonHeight,
  });

  factory AuthHeroLayout.of(Size size) {
    final width = size.width;
    final isTablet = size.shortestSide >= 600;
    final isLargeTablet = size.shortestSide >= 900;

    final horizontalPadding =
        isLargeTablet ? 56.0 : (isTablet ? 40.0 : 24.0);

    final maxContentWidth = isLargeTablet
        ? (width * 0.62).clamp(600.0, 780.0)
        : isTablet
            ? (width * 0.74).clamp(520.0, 680.0)
            : (width - horizontalPadding * 2).clamp(300.0, 400.0);

    return AuthHeroLayout(
      maxContentWidth: maxContentWidth,
      horizontalPadding: horizontalPadding,
      isTablet: isTablet,
      isLargeTablet: isLargeTablet,
      logoSize: isLargeTablet ? 72.0 : (isTablet ? 62.0 : 48.0),
      titleFontSize: isLargeTablet ? 34.0 : (isTablet ? 30.0 : 24.0),
      bodyFontSize: isTablet ? 16.0 : 14.0,
      buttonHeight: isTablet ? 54.0 : 48.0,
    );
  }
}

/// Muted subtitle text below the hero title on auth screens.
class AuthHeroSubtitle extends StatelessWidget {
  final String text;

  const AuthHeroSubtitle({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));

    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: Colors.white.withOpacity(0.75),
        fontSize: layout.isTablet ? 16 : 14,
        height: 1.35,
      ),
    );
  }
}

/// Shows OTP delivery channels on the verification screen.
class AuthOtpChannelsRow extends StatelessWidget {
  const AuthOtpChannelsRow({super.key});

  static const _channels = [
    (Icons.alternate_email_rounded, 'Email'),
    (Icons.send_rounded, 'Telegram'),
    (Icons.chat_bubble_outline_rounded, 'WhatsApp'),
  ];

  @override
  Widget build(BuildContext context) {
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < _channels.length; i++) ...[
          if (i > 0) SizedBox(width: layout.isTablet ? 10 : 7),
          _DecorPill(
            icon: _channels[i].$1,
            label: _channels[i].$2,
            isTablet: layout.isTablet,
          ),
        ],
      ],
    );
  }
}

class AuthScreenShell extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Widget child;
  final VoidCallback? onBack;
  final AuthStep step;

  const AuthScreenShell({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.child,
    this.onBack,
    this.step = AuthStep.login,
  });

  @override
  State<AuthScreenShell> createState() => _AuthScreenShellState();
}

class _AuthScreenShellState extends State<AuthScreenShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 18),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isTablet = size.width > 600;
    final heroHeight = (size.height * 0.30).clamp(220.0, 280.0);

    return Scaffold(
      backgroundColor: AuthMaritimeTheme.mist,
      body: Column(
        children: [
          SizedBox(
            height: heroHeight,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  'images/vessel.png',
                  fit: BoxFit.cover,
                  alignment: const Alignment(0.5, 0.35),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        AuthMaritimeTheme.oceanDeep.withOpacity(0.72),
                        AuthMaritimeTheme.oceanMid.withOpacity(0.82),
                        AuthMaritimeTheme.oceanBright.withOpacity(0.88),
                      ],
                    ),
                  ),
                ),
                AnimatedBuilder(
                  animation: _waveController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _MaritimeWavePainter(
                        progress: _waveController.value,
                        waveColor: AuthMaritimeTheme.mist,
                        layers: 3,
                        amplitude: 12,
                      ),
                      size: Size.infinite,
                    );
                  },
                ),
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Row(
                          children: [
                            if (widget.onBack != null)
                              IconButton(
                                onPressed: widget.onBack,
                                icon: const Icon(Icons.arrow_back_rounded),
                                color: Colors.white,
                                tooltip: 'Back',
                              )
                            else
                              const SizedBox(width: 8),
                            const Spacer(),
                            _MaritimeBrandChip(isTablet: isTablet),
                          ],
                        ),
                        const Spacer(),
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(7),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.12),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.35),
                                width: 1.5,
                              ),
                            ),
                            child: SizedBox(
                              height: isTablet ? 44 : 38,
                              width: isTablet ? 44 : 38,
                              child: Image.asset('images/v2rpLogo.png'),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          widget.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isTablet ? 22 : 20,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isTablet ? 40 : 24,
                          ),
                          child: Text(
                            widget.subtitle,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.9),
                              fontSize: isTablet ? 13 : 12,
                              height: 1.35,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        _AuthStepIndicator(current: widget.step),
                        const SizedBox(height: 4),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Transform.translate(
              offset: const Offset(0, -22),
              child: Container(
                decoration: BoxDecoration(
                  color: AuthMaritimeTheme.mist,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AuthMaritimeTheme.oceanDeep.withOpacity(0.1),
                      blurRadius: 16,
                      offset: const Offset(0, -3),
                    ),
                  ],
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      padding: EdgeInsets.fromLTRB(
                        isTablet ? 28 : 20,
                        4,
                        isTablet ? 28 : 20,
                        20,
                      ),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 24,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Center(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  maxWidth: isTablet ? 400 : 360,
                                ),
                                child: widget.child,
                              ),
                            ),
                          ],
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
  }
}

/// Immersive hero layout — decoration and content share one canvas.
class AuthHeroShell extends StatefulWidget {
  final AuthStep step;
  final String title;
  final Widget child;
  final VoidCallback? onBack;
  final bool showDecorPills;

  const AuthHeroShell({
    super.key,
    required this.step,
    required this.title,
    required this.child,
    this.onBack,
    this.showDecorPills = false,
  });

  @override
  State<AuthHeroShell> createState() => _AuthHeroShellState();
}

/// Login wrapper — keeps existing call sites simple.
class AuthLoginShell extends StatelessWidget {
  final Widget form;

  const AuthLoginShell({super.key, required this.form});

  @override
  Widget build(BuildContext context) {
    return AuthHeroShell(
      step: AuthStep.login,
      title: 'Welcome Aboard',
      showDecorPills: true,
      child: form,
    );
  }
}

class _AuthHeroShellState extends State<AuthHeroShell>
    with TickerProviderStateMixin {
  late final AnimationController _oceanController;
  late final AnimationController _ambientController;

  @override
  void initState() {
    super.initState();
    _oceanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 24),
    )..repeat();
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 6200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _oceanController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final layout = AuthHeroLayout.of(size);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AuthMaritimeTheme.overlayDeep,
      body: AnimatedBuilder(
        animation: Listenable.merge([_oceanController, _ambientController]),
        builder: (context, _) {
          final oceanTime = _oceanController.value * 24;
          final ambient = _ambientController.value;
          final logoBob = math.sin(ambient * math.pi * 2) * 5;
          final vesselDrift = math.sin(oceanTime * 0.41) * 0.04;
          final lightShift = math.sin(ambient * math.pi) * 0.08;

          return Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'images/vessel.png',
                fit: BoxFit.cover,
                alignment: Alignment(
                  0.5 + vesselDrift,
                  0.32 + lightShift * 0.3,
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment(-0.8 + lightShift, -1),
                    end: Alignment(0.85 - lightShift, 1),
                    colors: [
                      AuthMaritimeTheme.overlayDeep.withOpacity(0.92),
                      AuthMaritimeTheme.overlayDark.withOpacity(0.88),
                      AuthMaritimeTheme.overlayMid.withOpacity(0.72),
                      ApprovalMenuTheme.primaryDark.withOpacity(0.38),
                      AuthMaritimeTheme.overlayDeep.withOpacity(0.96),
                    ],
                    stops: const [0.0, 0.35, 0.62, 0.82, 1.0],
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.22),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.5, 0.3),
                    radius: 0.85,
                    colors: [
                      ApprovalMenuTheme.primaryDark.withOpacity(0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
              CustomPaint(
                painter: _OceanCausticsPainter(time: oceanTime),
                size: Size.infinite,
              ),
              CustomPaint(
                painter: _OceanSparklePainter(time: oceanTime),
                size: Size.infinite,
              ),
              CustomPaint(
                painter: _OrganicOceanWavePainter(
                  time: oceanTime,
                  layers: _loginWaveLayers,
                ),
                size: Size.infinite,
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    layout.horizontalPadding,
                    8,
                    layout.horizontalPadding,
                    20 + bottomInset,
                  ),
                  child: Center(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(maxWidth: layout.maxContentWidth),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              if (widget.onBack != null)
                                IconButton(
                                  onPressed: widget.onBack,
                                  icon: const Icon(Icons.arrow_back_rounded),
                                  color: Colors.white,
                                  tooltip: 'Back',
                                )
                              else
                                const SizedBox(width: 8),
                              const Spacer(),
                              _MaritimeBrandChip(isTablet: layout.isTablet),
                            ],
                          ),
                          SizedBox(height: size.height * 0.03),
                          Transform.translate(
                            offset: Offset(0, logoBob),
                            child: Center(
                              child: Container(
                                padding: EdgeInsets.all(layout.isTablet ? 12 : 10),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: RadialGradient(
                                    colors: [
                                      Colors.white.withOpacity(0.22),
                                      Colors.white.withOpacity(0.06),
                                    ],
                                  ),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.42),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: ApprovalMenuTheme.primary
                                          .withOpacity(0.28),
                                      blurRadius: 22,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: SizedBox(
                                  height: layout.logoSize,
                                  width: layout.logoSize,
                                  child: Image.asset('images/v2rpLogo.png'),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            widget.title,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: layout.titleFontSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                          if (widget.showDecorPills) ...[
                            const SizedBox(height: 16),
                            _LoginDecorRow(
                              isTablet: layout.isTablet,
                              ambient: ambient,
                            ),
                          ],
                          const SizedBox(height: 12),
                          Center(
                            child: _AuthStepIndicator(
                              current: widget.step,
                              isTablet: layout.isTablet,
                            ),
                          ),
                          const SizedBox(height: 28),
                          widget.child,
                          SizedBox(height: size.height * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

const _loginWaveLayers = [
  _OceanWaveLayer(
    baseHeightFactor: 0.0,
    baseOffset: 4,
    amplitude: 10,
    opacity: 0.04,
    color: Colors.white,
    speedMul: 0.85,
    harmonics: [
      _WaveHarmonic(length: 1.05, speed: 0.62, amp: 1.0, phase: 0.4),
      _WaveHarmonic(length: 2.15, speed: -0.91, amp: 0.45, phase: 1.7),
    ],
  ),
  _OceanWaveLayer(
    baseHeightFactor: 0.0,
    baseOffset: 10,
    amplitude: 7,
    opacity: 0.05,
    color: Color(0xFF8B5A18),
    speedMul: 1.0,
    harmonics: [
      _WaveHarmonic(length: 1.35, speed: 0.78, amp: 1.0, phase: 1.1),
      _WaveHarmonic(length: 0.72, speed: -1.18, amp: 0.52, phase: 0.2),
    ],
  ),
  _OceanWaveLayer(
    baseHeightFactor: 0.0,
    baseOffset: 16,
    amplitude: 5,
    opacity: 0.06,
    color: const Color(0xFFD4891A),
    speedMul: 1.12,
    harmonics: [
      _WaveHarmonic(length: 0.95, speed: -0.55, amp: 0.85, phase: 2.1),
      _WaveHarmonic(length: 1.65, speed: 1.05, amp: 0.48, phase: 0.85),
    ],
  ),
];

class _LoginDecorRow extends StatelessWidget {
  final bool isTablet;
  final double ambient;

  const _LoginDecorRow({
    required this.isTablet,
    this.ambient = 0,
  });

  @override
  Widget build(BuildContext context) {
    final pills = [
      (Icons.directions_boat_filled_outlined, 'Vessel', 0.0),
      (Icons.public_outlined, 'Vindo', 0.15),
      (Icons.analytics_outlined, 'Planning', 0.3),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < pills.length; i++) ...[
          if (i > 0) SizedBox(width: isTablet ? 10 : 7),
          Transform.translate(
            offset: Offset(
              0,
              math.sin((ambient + pills[i].$3) * math.pi * 2) * 2.5,
            ),
            child: _DecorPill(
              icon: pills[i].$1,
              label: pills[i].$2,
              isTablet: isTablet,
            ),
          ),
        ],
      ],
    );
  }
}

class _DecorPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isTablet;

  const _DecorPill({
    required this.icon,
    required this.label,
    required this.isTablet,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: isTablet ? 8 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.22)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: isTablet ? 15 : 13, color: ApprovalMenuTheme.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 11 : 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MaritimeBrandChip extends StatelessWidget {
  final bool isTablet;

  const _MaritimeBrandChip({required this.isTablet});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isTablet ? 12 : 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.apartment_rounded,
            size: isTablet ? 16 : 14,
            color: ApprovalMenuTheme.primary,
          ),
          const SizedBox(width: 6),
          Text(
            'KCT Group',
            style: TextStyle(
              color: Colors.white,
              fontSize: isTablet ? 12 : 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthStepIndicator extends StatelessWidget {
  final AuthStep current;
  final bool isTablet;

  const _AuthStepIndicator({
    required this.current,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    const steps = [
      (AuthStep.login, Icons.login_rounded, 'Login'),
      (AuthStep.otp, Icons.verified_outlined, 'OTP'),
      (AuthStep.company, Icons.business_center_outlined, 'Company'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isTablet ? 8 : 16),
      child: Row(
        children: [
          _StepDot(
            icon: steps[0].$2,
            label: steps[0].$3,
            active: current == steps[0].$1,
            completed: _stepIndex(current) > 0,
            isTablet: isTablet,
          ),
          Expanded(child: _StepConnector(active: _stepIndex(current) >= 1)),
          _StepDot(
            icon: steps[1].$2,
            label: steps[1].$3,
            active: current == steps[1].$1,
            completed: _stepIndex(current) > 1,
            isTablet: isTablet,
          ),
          Expanded(child: _StepConnector(active: _stepIndex(current) >= 2)),
          _StepDot(
            icon: steps[2].$2,
            label: steps[2].$3,
            active: current == steps[2].$1,
            completed: false,
            isTablet: isTablet,
          ),
        ],
      ),
    );
  }

  int _stepIndex(AuthStep step) {
    switch (step) {
      case AuthStep.login:
        return 0;
      case AuthStep.otp:
        return 1;
      case AuthStep.company:
        return 2;
    }
  }
}

class _StepConnector extends StatelessWidget {
  final bool active;

  const _StepConnector({required this.active});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 2,
      margin: const EdgeInsets.only(bottom: 18, left: 4, right: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: active
              ? [
                  ApprovalMenuTheme.primary,
                  ApprovalMenuTheme.primary.withOpacity(0.5),
                ]
              : [
                  Colors.white.withOpacity(0.25),
                  Colors.white.withOpacity(0.15),
                ],
        ),
        borderRadius: BorderRadius.circular(1),
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool completed;
  final bool isTablet;

  const _StepDot({
    required this.icon,
    required this.label,
    required this.active,
    required this.completed,
    this.isTablet = false,
  });

  @override
  Widget build(BuildContext context) {
    final highlight = active || completed;
    final dotSize = isTablet ? 34.0 : 28.0;
    final iconSize = isTablet ? 17.0 : 14.0;
    final labelSize = isTablet ? 11.0 : 9.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: dotSize,
          height: dotSize,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: highlight
                ? ApprovalMenuTheme.primary
                : Colors.white.withOpacity(0.18),
            border: Border.all(
              color: highlight
                  ? Colors.white
                  : Colors.white.withOpacity(0.35),
              width: highlight ? 1.5 : 1,
            ),
          ),
          child: Icon(
            completed && !active ? Icons.check_rounded : icon,
            size: iconSize,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          label,
          style: TextStyle(
            fontSize: labelSize,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : Colors.white.withOpacity(0.75),
          ),
        ),
      ],
    );
  }
}

class _WaveHarmonic {
  final double length;
  final double speed;
  final double amp;
  final double phase;

  const _WaveHarmonic({
    required this.length,
    required this.speed,
    required this.amp,
    required this.phase,
  });
}

class _OceanWaveLayer {
  final double baseHeightFactor;
  final double baseOffset;
  final double amplitude;
  final double opacity;
  final Color color;
  final double speedMul;
  final List<_WaveHarmonic> harmonics;

  const _OceanWaveLayer({
    required this.baseHeightFactor,
    required this.baseOffset,
    required this.amplitude,
    required this.opacity,
    required this.color,
    required this.speedMul,
    required this.harmonics,
  });
}

class _OrganicOceanWavePainter extends CustomPainter {
  final double time;
  final List<_OceanWaveLayer> layers;

  _OrganicOceanWavePainter({
    required this.time,
    required this.layers,
  });

  double _sampleWave(double xNorm, _OceanWaveLayer layer) {
    var sum = 0.0;
    final t = time * layer.speedMul;
    for (final h in layer.harmonics) {
      sum += h.amp *
          math.sin(
            (xNorm * h.length * math.pi * 2) + (t * h.speed) + h.phase,
          );
    }
    return sum * layer.amplitude;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;

    final paint = Paint()..style = PaintingStyle.fill;
    const step = 1.5;

    for (final layer in layers) {
      final path = Path();
      final baseY = size.height - layer.baseOffset;

      path.moveTo(0, size.height);
      path.lineTo(0, baseY + _sampleWave(0, layer));

      for (var x = 0.0; x <= size.width; x += step) {
        final xNorm = x / size.width;
        path.lineTo(x, baseY + _sampleWave(xNorm, layer));
      }

      path.lineTo(size.width, size.height);
      path.close();

      paint.color = layer.color.withOpacity(layer.opacity);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OrganicOceanWavePainter oldDelegate) {
    return (oldDelegate.time - time).abs() > 0.0001;
  }
}

class _OceanCausticsPainter extends CustomPainter {
  final double time;

  _OceanCausticsPainter({required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final clipHeight = size.height * 0.55;
    canvas.clipRect(Rect.fromLTWH(0, size.height - clipHeight, size.width, clipHeight));

    for (var i = 0; i < 6; i++) {
      final path = Path();
      final bandTop = size.height - clipHeight + (i * clipHeight / 7);
      final bandAmp = 4.0 + i * 1.2;
      final speed = 0.35 + i * 0.11;
      final freq = 1.4 + i * 0.37;

      path.moveTo(0, bandTop);
      for (var x = 0.0; x <= size.width; x += 2) {
        final xNorm = x / size.width;
        final y = bandTop +
            math.sin(xNorm * freq * math.pi * 2 + time * speed + i * 1.3) *
                bandAmp;
        path.lineTo(x, y);
      }
      path.lineTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.close();

      paint.color = Colors.white.withOpacity(0.018 + i * 0.004);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanCausticsPainter oldDelegate) {
    return (oldDelegate.time - time).abs() > 0.0001;
  }
}

class _OceanSparklePainter extends CustomPainter {
  final double time;

  _OceanSparklePainter({required this.time});

  static const _seeds = [
    (0.12, 0.72, 1.1),
    (0.28, 0.78, 0.7),
    (0.45, 0.68, 1.4),
    (0.61, 0.82, 0.9),
    (0.74, 0.74, 1.2),
    (0.88, 0.79, 0.65),
    (0.33, 0.85, 1.0),
    (0.52, 0.76, 0.8),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    for (final seed in _seeds) {
      final pulse =
          (math.sin(time * seed.$3 + seed.$1 * 9) + 1) * 0.5;
      if (pulse < 0.35) continue;

      final cx = size.width * seed.$1;
      final cy = size.height * seed.$2;
      final radius = 1.2 + pulse * 1.8;

      paint.color = Colors.white.withOpacity(0.08 + pulse * 0.18);
      canvas.drawCircle(Offset(cx, cy), radius, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _OceanSparklePainter oldDelegate) {
    return (oldDelegate.time - time).abs() > 0.0001;
  }
}

class _MaritimeWavePainter extends CustomPainter {
  final double progress;
  final Color waveColor;
  final int layers;
  final double amplitude;

  _MaritimeWavePainter({
    required this.progress,
    required this.waveColor,
    this.layers = 2,
    this.amplitude = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _OrganicOceanWavePainter(
      time: progress * 12,
      layers: [
        for (var i = 0; i < layers; i++)
          _OceanWaveLayer(
            baseHeightFactor: 0,
            baseOffset: 8 + i * 6.0,
            amplitude: amplitude - i * 3,
            opacity: (1 - i * 0.15) * 0.35,
            color: waveColor,
            speedMul: 0.9 + i * 0.15,
            harmonics: [
              _WaveHarmonic(
                length: 1.0 + i * 0.2,
                speed: 0.7 + i * 0.1,
                amp: 1.0,
                phase: i * 0.9,
              ),
              _WaveHarmonic(
                length: 2.1 - i * 0.15,
                speed: -0.85,
                amp: 0.4,
                phase: 1.4 + i,
              ),
              _WaveHarmonic(
                length: 0.55 + i * 0.08,
                speed: 1.2,
                amp: 0.22,
                phase: 2.6,
              ),
            ],
          ),
      ],
    ).paint(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _MaritimeWavePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.waveColor != waveColor;
  }
}

class AuthFormCard extends StatelessWidget {
  final Widget child;
  final String? headerTitle;
  final IconData? headerIcon;

  const AuthFormCard({
    super.key,
    required this.child,
    this.headerTitle,
    this.headerIcon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AuthMaritimeTheme.seaFoam),
        boxShadow: [
          BoxShadow(
            color: AuthMaritimeTheme.oceanDeep.withOpacity(0.07),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 3,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    ApprovalMenuTheme.primary,
                    ApprovalMenuTheme.primaryDark,
                    AuthMaritimeTheme.oceanMid,
                  ],
                ),
              ),
            ),
            if (headerTitle != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: Row(
                  children: [
                    Icon(
                      headerIcon ?? Icons.anchor_rounded,
                      size: 16,
                      color: AuthMaritimeTheme.oceanMid,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        headerTitle!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AuthMaritimeTheme.oceanDeep,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                14,
                headerTitle != null ? 10 : 14,
                14,
                14,
              ),
              child: child,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthLoginTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final VoidCallback? onEditingComplete;

  const AuthLoginTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onToggleObscure,
    this.onSubmitted,
    this.autofillHints,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: layout.isTablet ? 13 : 12,
            fontWeight: FontWeight.w600,
            color: Colors.white.withOpacity(0.88),
            letterSpacing: 0.3,
          ),
        ),
        SizedBox(height: layout.isTablet ? 8 : 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          onEditingComplete: onEditingComplete,
          validator: validator,
          style: TextStyle(
            fontSize: layout.bodyFontSize,
            color: Colors.white,
            fontWeight: FontWeight.w500,
          ),
          cursorColor: ApprovalMenuTheme.primary,
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.white.withOpacity(0.45),
              fontSize: layout.isTablet ? 15 : 13,
            ),
            prefixIcon: Icon(
              icon,
              color: ApprovalMenuTheme.primary,
              size: layout.isTablet ? 22 : 20,
            ),
            prefixIconConstraints: BoxConstraints(
              minWidth: layout.isTablet ? 48 : 44,
              minHeight: layout.isTablet ? 44 : 40,
            ),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.white.withOpacity(0.65),
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            filled: true,
            fillColor: Colors.white.withOpacity(0.1),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 14,
              vertical: layout.isTablet ? 16 : 12,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.28)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: ApprovalMenuTheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.red.shade300, width: 1.5),
            ),
            errorStyle: TextStyle(
              color: Colors.red.shade200,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final String? Function(String?)? validator;
  final VoidCallback? onToggleObscure;
  final VoidCallback? onSubmitted;
  final Iterable<String>? autofillHints;
  final VoidCallback? onEditingComplete;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.validator,
    this.onToggleObscure,
    this.onSubmitted,
    this.autofillHints,
    this.onEditingComplete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            color: AuthMaritimeTheme.oceanMid,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onSubmitted != null ? (_) => onSubmitted!() : null,
          onEditingComplete: onEditingComplete,
          validator: validator,
          style: TextStyle(
            fontSize: 14,
            color: AuthMaritimeTheme.oceanDeep,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            isDense: true,
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
            prefixIcon: Icon(icon, color: AuthMaritimeTheme.oceanBright, size: 20),
            prefixIconConstraints: const BoxConstraints(minWidth: 44, minHeight: 40),
            suffixIcon: onToggleObscure != null
                ? IconButton(
                    icon: Icon(
                      obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade500,
                      size: 20,
                    ),
                    onPressed: onToggleObscure,
                    visualDensity: VisualDensity.compact,
                  )
                : null,
            filled: true,
            fillColor: AuthMaritimeTheme.mist,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: AuthMaritimeTheme.seaFoam),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: ApprovalMenuTheme.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

class AuthPrimaryButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AuthPrimaryButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));

    return Material(
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: enabled ? onPressed : null,
        child: Ink(
          decoration: BoxDecoration(
            gradient: enabled
                ? LinearGradient(
                    colors: [
                      ApprovalMenuTheme.primary,
                      ApprovalMenuTheme.primaryDark,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : null,
            color: enabled ? null : ApprovalMenuTheme.primary.withOpacity(0.45),
            borderRadius: BorderRadius.circular(14),
            boxShadow: enabled
                ? [
                    BoxShadow(
                      color: ApprovalMenuTheme.primary.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ]
                : null,
          ),
          child: Container(
            width: double.infinity,
            height: layout.buttonHeight,
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                else ...[
                  if (icon != null) ...[
                    Icon(icon, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: layout.isTablet ? 17 : 15,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthSecondaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool heroStyle;

  const AuthSecondaryButton({
    super.key,
    required this.label,
    required this.icon,
    this.onPressed,
    this.isLoading = false,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = heroStyle ? Colors.white : AuthMaritimeTheme.oceanMid;
    final border = heroStyle
        ? Colors.white.withOpacity(0.35)
        : AuthMaritimeTheme.oceanBright.withOpacity(0.4);
    final bg = heroStyle
        ? Colors.white.withOpacity(0.08)
        : AuthMaritimeTheme.mist;
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));

    return OutlinedButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: fg,
              ),
            )
          : Icon(icon, size: 18, color: fg),
      label: Text(
        label,
        style: TextStyle(
          color: fg,
          fontWeight: FontWeight.w600,
          fontSize: layout.isTablet ? 15 : 14,
        ),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: Size(double.infinity, layout.buttonHeight - 4),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        side: BorderSide(color: border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        backgroundColor: bg,
      ),
    );
  }
}

class AuthOtpInputRow extends StatelessWidget {
  final List<TextEditingController> controllers;
  final List<FocusNode> focusNodes;
  final void Function(int index, String value) onChanged;
  final VoidCallback? onSubmit;
  final String? Function(String?)? validator;
  final bool heroStyle;

  const AuthOtpInputRow({
    super.key,
    required this.controllers,
    required this.focusNodes,
    required this.onChanged,
    this.onSubmit,
    this.validator,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final layout = AuthHeroLayout.of(size);
    final fieldSize = layout.isTablet
        ? ((layout.maxContentWidth - 40) / 6).clamp(48.0, 60.0)
        : (size.width * 0.105).clamp(36.0, 42.0);
    final fontSize = layout.isTablet ? 22.0 : 17.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: fieldSize,
          height: fieldSize + 2,
          child: TextFormField(
            controller: controllers[index],
            focusNode: focusNodes[index],
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            textInputAction:
                index < 5 ? TextInputAction.next : TextInputAction.done,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              color: heroStyle ? Colors.white : AuthMaritimeTheme.oceanDeep,
            ),
            cursorColor: ApprovalMenuTheme.primary,
            decoration: InputDecoration(
              isDense: true,
              counterText: '',
              filled: true,
              fillColor: heroStyle
                  ? Colors.white.withOpacity(0.1)
                  : AuthMaritimeTheme.mist,
              contentPadding: EdgeInsets.zero,
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: heroStyle
                      ? Colors.white.withOpacity(0.28)
                      : AuthMaritimeTheme.seaFoam,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: ApprovalMenuTheme.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: Colors.red.shade300),
              ),
            ),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            onChanged: (value) => onChanged(index, value),
            onFieldSubmitted: (value) {
              if (index < 5 && value.isNotEmpty) {
                focusNodes[index + 1].requestFocus();
              } else {
                onSubmit?.call();
              }
            },
            validator: validator,
          ),
        );
      }),
    );
  }
}

class AuthCountdownChip extends StatelessWidget {
  final String text;
  final bool heroStyle;

  const AuthCountdownChip({
    super.key,
    required this.text,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg = heroStyle ? Colors.white.withOpacity(0.9) : AuthMaritimeTheme.oceanMid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: heroStyle
            ? Colors.white.withOpacity(0.1)
            : AuthMaritimeTheme.seaFoam.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: heroStyle
              ? Colors.white.withOpacity(0.25)
              : AuthMaritimeTheme.oceanBright.withOpacity(0.2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            text,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class AuthRoleCard extends StatelessWidget {
  final Map<String, dynamic> role;
  final VoidCallback? onTap;
  final bool isLoading;
  final bool heroStyle;

  const AuthRoleCard({
    super.key,
    required this.role,
    this.onTap,
    this.isLoading = false,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final layout = AuthHeroLayout.of(MediaQuery.sizeOf(context));
    final cardColor =
        heroStyle ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = heroStyle
        ? Colors.white.withOpacity(0.25)
        : AuthMaritimeTheme.seaFoam;
    final roleColor =
        heroStyle ? Colors.white : AuthMaritimeTheme.oceanDeep;
    final companyNameColor =
        heroStyle ? Colors.white.withOpacity(0.92) : Colors.grey.shade800;
    final companyColor =
        heroStyle ? Colors.white.withOpacity(0.65) : Colors.grey.shade500;
    final iconBg = heroStyle
        ? Colors.white.withOpacity(0.15)
        : AuthMaritimeTheme.seaFoam;
    final iconColor =
        heroStyle ? Colors.white : AuthMaritimeTheme.oceanMid;
    final boatIconColor = heroStyle
        ? Colors.white.withOpacity(0.7)
        : AuthMaritimeTheme.oceanBright;
    final chevronColor = heroStyle
        ? ApprovalMenuTheme.primary
        : ApprovalMenuTheme.primaryDark;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: heroStyle
            ? null
            : [
                BoxShadow(
                  color: AuthMaritimeTheme.oceanDeep.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onTap,
          borderRadius: BorderRadius.circular(16),
          splashColor: heroStyle
              ? Colors.white.withOpacity(0.08)
              : null,
          highlightColor: heroStyle
              ? Colors.white.withOpacity(0.04)
              : null,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ApprovalMenuTheme.primary,
                        heroStyle
                            ? ApprovalMenuTheme.primaryDark
                            : AuthMaritimeTheme.oceanMid,
                      ],
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(16),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.isTablet ? 16 : 12,
                      vertical: layout.isTablet ? 16 : 12,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: layout.isTablet ? 52 : 44,
                          height: layout.isTablet ? 52 : 44,
                          decoration: BoxDecoration(
                            color: iconBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            Icons.anchor_rounded,
                            color: iconColor,
                            size: layout.isTablet ? 26 : 22,
                          ),
                        ),
                        SizedBox(width: layout.isTablet ? 16 : 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                role['role']?.toString() ?? '—',
                                style: TextStyle(
                                  fontSize: layout.isTablet ? 17 : 15,
                                  fontWeight: FontWeight.bold,
                                  color: roleColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                role['companyname']?.toString() ?? '—',
                                style: TextStyle(
                                  fontSize: layout.isTablet ? 15 : 13,
                                  fontWeight: FontWeight.w600,
                                  color: companyNameColor,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.directions_boat_outlined,
                                    size: 13,
                                    color: boatIconColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Expanded(
                                    child: Text(
                                      role['company']?.toString() ?? '—',
                                      style: TextStyle(
                                        fontSize: layout.isTablet ? 13 : 11,
                                        color: companyColor,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: layout.isTablet ? 26 : 22,
                          color: chevronColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AuthRoleLoadingSkeleton extends StatelessWidget {
  final bool heroStyle;

  const AuthRoleLoadingSkeleton({super.key, this.heroStyle = false});

  @override
  Widget build(BuildContext context) {
    final cardColor =
        heroStyle ? Colors.white.withOpacity(0.1) : Colors.white;
    final borderColor = heroStyle
        ? Colors.white.withOpacity(0.25)
        : AuthMaritimeTheme.seaFoam;
    final stripeColor = heroStyle
        ? Colors.white.withOpacity(0.2)
        : AuthMaritimeTheme.seaFoam;
    final shimmerBase = heroStyle
        ? Colors.white.withOpacity(0.12)
        : const Color(0xFFE8E8ED);
    final shimmerHighlight = heroStyle
        ? Colors.white.withOpacity(0.22)
        : const Color(0xFFF8F8FA);
    final labelColor = heroStyle
        ? Colors.white.withOpacity(0.85)
        : AuthMaritimeTheme.oceanMid;
    final spinnerColor =
        heroStyle ? Colors.white : AuthMaritimeTheme.oceanMid;

    return Column(
      children: [
        for (var i = 0; i < 3; i++)
          Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: borderColor),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 88,
                  decoration: BoxDecoration(
                    color: stripeColor,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(18),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        ApprovalMenuShimmerBox(
                          width: 52,
                          height: 52,
                          borderRadius: BorderRadius.circular(14),
                          baseColor: shimmerBase,
                          highlightColor: shimmerHighlight,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ApprovalMenuShimmerBox(
                                width: 120,
                                height: 14,
                                borderRadius: BorderRadius.circular(6),
                                baseColor: shimmerBase,
                                highlightColor: shimmerHighlight,
                              ),
                              const SizedBox(height: 8),
                              ApprovalMenuShimmerBox(
                                height: 12,
                                borderRadius: BorderRadius.circular(6),
                                baseColor: shimmerBase,
                                highlightColor: shimmerHighlight,
                              ),
                              const SizedBox(height: 6),
                              ApprovalMenuShimmerBox(
                                width: 80,
                                height: 10,
                                borderRadius: BorderRadius.circular(6),
                                baseColor: shimmerBase,
                                highlightColor: shimmerHighlight,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: spinnerColor,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Memuat daftar company...',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: labelColor,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class AuthEmptyState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final bool heroStyle;

  const AuthEmptyState({
    super.key,
    required this.message,
    this.onRetry,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final iconBg = heroStyle
        ? Colors.white.withOpacity(0.12)
        : AuthMaritimeTheme.seaFoam;
    final iconColor =
        heroStyle ? Colors.white : AuthMaritimeTheme.oceanMid;
    final textColor =
        heroStyle ? Colors.white.withOpacity(0.9) : AuthMaritimeTheme.oceanMid;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.sailing_rounded,
              size: 40,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: onRetry,
              icon: Icon(Icons.refresh_rounded, color: textColor),
              label: Text('Coba lagi', style: TextStyle(color: textColor)),
            ),
          ],
        ],
      ),
    );
  }
}

class AuthInfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final bool heroStyle;

  const AuthInfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.heroStyle = false,
  });

  @override
  Widget build(BuildContext context) {
    final fg =
        heroStyle ? Colors.white.withOpacity(0.9) : AuthMaritimeTheme.oceanMid;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: heroStyle
            ? Colors.white.withOpacity(0.1)
            : AuthMaritimeTheme.seaFoam.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: heroStyle
              ? Colors.white.withOpacity(0.25)
              : AuthMaritimeTheme.oceanBright.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: fg),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: fg,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
