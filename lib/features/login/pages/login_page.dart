import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_images.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/services/auth/auth_cubit.dart';
import '../../../core/services/auth/auth_state.dart';
import '../../../core/services/auth/biometric_service.dart';
import '../../../core/services/auth/credential_store.dart';
import '../../../core/services/auth/login_exception.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/utils/snackbar_helper.dart';

/// Classic username / password sign-in.
///
/// Flow:
/// 1. First visit: the user types credentials. After a successful sign-in,
///    if the device has biometrics, we offer to save the login.
/// 2. Later visits: if a login is saved, the biometric prompt opens at once;
///    passing it reads the pair back and signs in silently. The form stays
///    available underneath as a fallback.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  final _credentialStore = CredentialStore();
  final _biometrics = BiometricService();

  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  bool _hasSavedLogin = false;
  bool _biometricBusy = false;
  BiometricKind _biometricKind = BiometricKind.generic;

  /// Credentials of the sign-in currently in flight, so we can offer to save
  /// them once the cubit reports success. Null for biometric sign-ins.
  ({String username, String password})? _pendingManualLogin;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _prepareSavedLogin());
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  // ───────────────────────── saved login / biometrics ─────────────────────────

  Future<void> _prepareSavedLogin() async {
    final available = await _biometrics.isAvailable();
    final kind = available ? await _biometrics.kind() : BiometricKind.generic;
    final savedUsername = await _credentialStore.savedUsername;
    final hasSaved = available && await _credentialStore.hasSavedCredentials;
    print('🔐 [Login] biometrics=$available kind=$kind saved=$hasSaved');
    if (!mounted) return;

    setState(() {
      _biometricAvailable = available;
      _biometricKind = kind;
      _hasSavedLogin = hasSaved;
      if (savedUsername != null && _usernameController.text.isEmpty) {
        _usernameController.text = savedUsername;
      }
    });

    if (hasSaved) {
      // Let the route transition settle before putting a dialog up.
      await Future.delayed(const Duration(milliseconds: 400));
      if (mounted) _offerBiometricSignIn();
    }
  }

  /// Asks first; the system Face ID / fingerprint sheet only opens once the
  /// user taps "Use Face ID". Declining leaves the password form.
  Future<void> _offerBiometricSignIn() async {
    final l = AppLocalizations.of(context);
    final label = _biometricLabel(l);
    final accepted = await _showChoiceDialog(
      icon: _biometricIcon,
      title: l.biometricPromptTitle(label),
      body: l.biometricPromptBody(label),
      acceptLabel: l.biometricPromptAccept(label),
      declineLabel: l.biometricPromptDecline,
      username: _usernameController.text.trim(),
    );
    if (accepted == true && mounted) _signInWithBiometrics();
  }

  Future<void> _signInWithBiometrics() async {
    if (_biometricBusy) return;
    final l = AppLocalizations.of(context);
    setState(() => _biometricBusy = true);
    try {
      final passed = await _biometrics.authenticate(l.biometricReason);
      if (!mounted) return;
      if (!passed) {
        SnackbarHelper.showWarning(
          context,
          l.biometricFailed(_biometricLabel(l)),
        );
        return;
      }
      final saved = await _credentialStore.read();
      if (!mounted) return;
      if (saved == null) {
        setState(() => _hasSavedLogin = false);
        return;
      }
      _pendingManualLogin = null;
      await context.read<AuthCubit>().loginWithPassword(
        username: saved.username,
        password: saved.password,
      );
    } finally {
      if (mounted) setState(() => _biometricBusy = false);
    }
  }

  Future<void> _useAnotherAccount() async {
    await _credentialStore.clear();
    if (!mounted) return;
    setState(() {
      _hasSavedLogin = false;
      _usernameController.clear();
      _passwordController.clear();
    });
  }

  String _biometricLabel(AppLocalizations l) => switch (_biometricKind) {
    BiometricKind.face => l.faceId,
    BiometricKind.fingerprint => l.fingerprint,
    BiometricKind.generic => l.biometrics,
  };

  IconData get _biometricIcon => switch (_biometricKind) {
    BiometricKind.face => Icons.face_rounded,
    BiometricKind.fingerprint => Icons.fingerprint_rounded,
    BiometricKind.generic => Icons.lock_open_rounded,
  };

  // ───────────────────────────── manual sign-in ──────────────────────────────

  void _submit() {
    FocusManager.instance.primaryFocus?.unfocus();
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final username = _usernameController.text.trim();
    final password = _passwordController.text;
    _pendingManualLogin = (username: username, password: password);
    context.read<AuthCubit>().loginWithPassword(
      username: username,
      password: password,
    );
  }

  Future<void> _onAuthenticated() async {
    final pending = _pendingManualLogin;
    _pendingManualLogin = null;

    // Offer to save only after a typed sign-in, on a device that can gate the
    // stored password behind biometrics, and only while nothing is saved yet.
    if (pending != null && _biometricAvailable && !_hasSavedLogin) {
      final save = await _askToSaveLogin();
      if (save == true) {
        await _credentialStore.save(
          username: pending.username,
          password: pending.password,
        );
      }
    }
    if (!mounted) return;
    HapticFeedback.lightImpact();
    context.go(AppRoutes.home);
  }

  Future<void> _onLoginError(LoginErrorType type) async {
    final l = AppLocalizations.of(context);
    final message = switch (type) {
      LoginErrorType.invalidCredentials => l.loginInvalidCredentials,
      LoginErrorType.network => l.loginNetworkError,
      LoginErrorType.tooManyAttempts => l.loginTooManyAttempts,
      LoginErrorType.mfaRequired => l.loginMfaRequired,
      LoginErrorType.identityNotFound => l.loginIdentityNotFound,
      LoginErrorType.notConfigured => l.loginNotConfigured,
      LoginErrorType.sessionExpired => l.sessionExpired,
      LoginErrorType.unknown => l.loginFailedGeneric,
    };

    // A saved password that Auth0 now rejects is stale: drop it so the next
    // visit goes straight to the form instead of a failing biometric loop.
    if (_pendingManualLogin == null &&
        _hasSavedLogin &&
        type == LoginErrorType.invalidCredentials) {
      await _credentialStore.forgetPassword();
      if (!mounted) return;
      setState(() => _hasSavedLogin = false);
      SnackbarHelper.showError(context, l.savedLoginInvalid);
      return;
    }
    _pendingManualLogin = null;
    SnackbarHelper.showError(context, message);
  }

  Future<bool?> _askToSaveLogin() {
    final l = AppLocalizations.of(context);
    final label = _biometricLabel(l);
    return _showChoiceDialog(
      icon: _biometricIcon,
      title: l.saveLoginTitle,
      body: l.saveLoginBody(label),
      acceptLabel: l.saveLoginYes,
      declineLabel: l.saveLoginNo,
    );
  }

  /// Dialog per design.md §7.9, adapted for sign-in: a ringed icon medallion,
  /// title, body, an optional "as <username>" pill, then the accept button
  /// full-width with the decline action as a text button beneath it. Stacked
  /// buttons keep long Uzbek / Russian labels on one line without clipping.
  Future<bool?> _showChoiceDialog({
    required IconData icon,
    required String title,
    required String body,
    required String acceptLabel,
    required String declineLabel,
    String? username,
  }) {
    final t = context.tokens;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.55),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: EdgeInsets.symmetric(horizontal: 28.w),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 400),
          padding: EdgeInsets.fromLTRB(24.w, 28.h, 24.w, 20.h),
          decoration: BoxDecoration(
            color: t.surface,
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: t.outline),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _IconMedallion(icon: icon),
              SizedBox(height: 20.h),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                  color: t.textPrimary,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                body,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  height: 1.5,
                  color: t.textSecondary,
                ),
              ),
              if (username != null && username.isNotEmpty) ...[
                SizedBox(height: 14.h),
                _UsernamePill(username: username),
              ],
              SizedBox(height: 24.h),
              _PrimaryButton(
                label: acceptLabel,
                onPressed: () => Navigator.of(ctx).pop(true),
              ),
              SizedBox(height: 4.h),
              SizedBox(
                height: 48.h,
                child: TextButton(
                  onPressed: () => Navigator.of(ctx).pop(false),
                  style: TextButton.styleFrom(
                    foregroundColor: t.textSecondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.r),
                    ),
                    textStyle: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(declineLabel, textAlign: TextAlign.center),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────────────────────── build ───────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.tokens;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _onAuthenticated();
        } else if (state is AuthError &&
            state.type != LoginErrorType.sessionExpired) {
          _onLoginError(state.type);
        }
      },
      child: Scaffold(
        backgroundColor: t.background,
        resizeToAvoidBottomInset: true,
        body: GestureDetector(
          // Tapping anywhere outside a field dismisses the keyboard.
          behavior: HitTestBehavior.translucent,
          onTap: () => FocusManager.instance.primaryFocus?.unfocus(),
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImages.clouds),
                fit: BoxFit.cover,
              ),
            ),
            child: Container(
              // Night-sky artwork: a light scrim at the top keeps the brand
              // text legible over the stars; the form card carries its own
              // surface color so it reads the same in both modes.
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.35),
                    Colors.black.withValues(alpha: 0.10),
                    Colors.black.withValues(alpha: 0.30),
                  ],
                ),
              ),
              child: SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) => SingleChildScrollView(
                    keyboardDismissBehavior:
                        ScrollViewKeyboardDismissBehavior.onDrag,
                    padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 24.h),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 40.h,
                        maxWidth: 440,
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildBrand(l, t),
                            SizedBox(height: 32.h),
                            BlocBuilder<AuthCubit, AuthState>(
                              builder: (context, state) {
                                // A biometric sign-in has no button to spin,
                                // so cover the whole card with a loader of
                                // the same size.
                                final covering =
                                    _biometricBusy ||
                                    (state is AuthLoading &&
                                        _pendingManualLogin == null);
                                return Stack(
                                  children: [
                                    _buildFormCard(l, t),
                                    if (covering)
                                      Positioned.fill(
                                        child: _LoadingCover(
                                          label: l.signingIn,
                                        ),
                                      ),
                                  ],
                                );
                              },
                            ),
                            if (_hasSavedLogin) ...[
                              SizedBox(height: 16.h),
                              _buildBiometricButton(l, t),
                              SizedBox(height: 8.h),
                              Center(
                                child: TextButton(
                                  onPressed: _useAnotherAccount,
                                  style: TextButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    minimumSize: Size(44.w, 44.h),
                                  ),
                                  child: Text(
                                    l.useAnotherAccount,
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBrand(AppLocalizations l, AppTokens t) {
    // Sits on the night-sky artwork in both modes, so it is always light.
    const onArtwork = Colors.white;
    return Column(
      children: [
        Image.asset(
          AppImages.sievesWhite3D,
          height: 120.h,
          fit: BoxFit.contain,
          semanticLabel: 'Sieves',
        ),
        SizedBox(height: 20.h),
        Text(
          l.loginWelcome,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: onArtwork,
          ),
        ),
        SizedBox(height: 4.h),
        Text(
          l.loginSubtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14.sp,
            color: onArtwork.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildFormCard(AppLocalizations l, AppTokens t) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.outline),
        boxShadow: [
          BoxShadow(
            color: t.shadow,
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final busy = state is AuthLoading || _biometricBusy;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FieldLabel(l.username),
                TextFormField(
                  controller: _usernameController,
                  enabled: !busy,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  autofillHints: const [AutofillHints.username],
                  onFieldSubmitted: (_) => _passwordFocus.requestFocus(),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? l.usernameRequired
                      : null,
                  style: TextStyle(fontSize: 16.sp, color: t.textPrimary),
                  decoration: _inputDecoration(
                    t,
                    prefix: Icons.person_outline_rounded,
                  ),
                ),
                SizedBox(height: 16.h),
                _FieldLabel(l.password),
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  enabled: !busy,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => _submit(),
                  validator: (v) =>
                      (v == null || v.isEmpty) ? l.passwordRequired : null,
                  style: TextStyle(fontSize: 16.sp, color: t.textPrimary),
                  decoration: _inputDecoration(
                    t,
                    prefix: Icons.lock_outline_rounded,
                    suffix: IconButton(
                      tooltip: _obscurePassword
                          ? l.showPassword
                          : l.hidePassword,
                      onPressed: () =>
                          setState(() => _obscurePassword = !_obscurePassword),
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: t.textSecondary,
                        size: 22.sp,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 24.h),
                _PrimaryButton(
                  label: busy ? l.signingIn : l.signIn,
                  loading: state is AuthLoading,
                  onPressed: busy ? null : _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBiometricButton(AppLocalizations l, AppTokens t) {
    return _SecondaryButton(
      label: l.signInWith(_biometricLabel(l)),
      icon: _biometricIcon,
      onArtwork: true,
      onPressed: _biometricBusy ? null : _signInWithBiometrics,
    );
  }

  InputDecoration _inputDecoration(
    AppTokens t, {
    required IconData prefix,
    Widget? suffix,
  }) {
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.r),
          borderSide: BorderSide(color: color, width: width),
        );
    return InputDecoration(
      filled: true,
      fillColor: t.surfaceTint,
      prefixIcon: Icon(prefix, color: t.textSecondary, size: 22.sp),
      suffixIcon: suffix,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      border: border(t.outlineStrong),
      enabledBorder: border(t.outlineStrong),
      disabledBorder: border(t.outline),
      focusedBorder: border(t.primary, 2),
      errorBorder: border(t.error),
      focusedErrorBorder: border(t.error, 2),
      errorStyle: TextStyle(fontSize: 12.sp, color: t.error),
    );
  }
}

// ───────────────────────────── small building blocks ─────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 6.h, left: 2.w),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          color: context.tokens.textSecondary,
        ),
      ),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  const _PrimaryButton({
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SizedBox(
      height: 52.h,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: t.primary,
          foregroundColor: t.textOnAccent,
          disabledBackgroundColor: t.primary.withValues(alpha: 0.4),
          disabledForegroundColor: t.textOnAccent.withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        child: loading
            ? SizedBox(
                width: 20.w,
                height: 20.w,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(t.textOnAccent),
                ),
              )
            : Text(
                label,
                textAlign: TextAlign.center,
                softWrap: false,
                overflow: TextOverflow.visible,
              ),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.label,
    required this.onPressed,
    this.icon,
    this.onArtwork = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Placed directly on the background artwork rather than inside a card.
  final bool onArtwork;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final child = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    final style = OutlinedButton.styleFrom(
      backgroundColor: onArtwork ? t.surface : t.surfaceTint,
      foregroundColor: t.textPrimary,
      side: BorderSide(color: onArtwork ? t.outline : t.outlineStrong),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.r)),
      textStyle: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
    );
    return SizedBox(
      height: 52.h,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, style: style, child: child)
          : OutlinedButton.icon(
              onPressed: onPressed,
              style: style,
              icon: Icon(icon, size: 22.sp, color: t.primary),
              label: child,
            ),
    );
  }
}

/// Opaque card-shaped loader laid over the form while a sign-in that the
/// user did not start from the button (biometrics) is in flight.
class _LoadingCover extends StatelessWidget {
  const _LoadingCover({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      decoration: BoxDecoration(
        color: t.surface,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: t.outline),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 36.w,
            height: 36.w,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(t.primary),
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
              color: t.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

/// Circular icon on a tinted disc with a soft outer ring.
class _IconMedallion extends StatelessWidget {
  const _IconMedallion({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      width: 92.w,
      height: 92.w,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: t.primary.withValues(alpha: 0.06),
        border: Border.all(color: t.primary.withValues(alpha: 0.14)),
      ),
      child: Center(
        child: Container(
          width: 64.w,
          height: 64.w,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.primary, t.primary.withValues(alpha: 0.75)],
            ),
            boxShadow: [
              BoxShadow(
                color: t.primary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Icon(icon, color: t.textOnAccent, size: 32.sp),
        ),
      ),
    );
  }
}

/// "as <username>" pill shown under the dialog body.
class _UsernamePill extends StatelessWidget {
  const _UsernamePill({required this.username});

  final String username;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: t.surfaceTint,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: t.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.person_rounded, size: 16.sp, color: t.textSecondary),
          SizedBox(width: 6.w),
          Flexible(
            child: Text(
              username,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: t.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
