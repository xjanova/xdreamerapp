import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/net/api_exception.dart';
import '../../core/theme/xdr_colors.dart';
import '../../core/theme/xdr_type.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/metal.dart';
import '../../core/widgets/metal_field.dart';
import '../../core/widgets/motion.dart';
import '../../core/widgets/press.dart';
import '../../state/auth_controller.dart';
import '../shell/brand_mark.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _showPassword = false;
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  /// Client-side checks only catch typos. The server is the authority, and its
  /// failure message is deliberately identical for a wrong email and a wrong
  /// password so this screen cannot be used to discover who has an account.
  bool _validate() {
    final email = _email.text.trim();
    final password = _password.text;

    final emailLooksRight = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email);
    setState(() {
      _emailError = emailLooksRight ? null : 'รูปแบบอีเมลไม่ถูกต้อง';
      _passwordError = password.length >= 8 ? null : 'รหัสผ่านอย่างน้อย 8 ตัวอักษร';
    });

    return _emailError == null && _passwordError == null;
  }

  Future<void> _submit() async {
    final auth = ref.read(authControllerProvider);
    if (auth.isLoading) return; // guards a double tap on the CTA
    if (!_validate()) return;

    FocusScope.of(context).unfocus();
    await ref.read(authControllerProvider.notifier).signIn(
          email: _email.text,
          password: _password.text,
        );
    // Routing to the studio is the router's job — it redirects as soon as the
    // auth state carries a session.
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final busy = auth.isLoading;
    final failure = auth.hasError ? ApiException.from(auth.error!) : null;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/showcase/login-panel.jpg',
            fit: BoxFit.cover,
            opacity: const AlwaysStoppedAnimation(0.28),
          ),
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.2),
                  radius: 1.0,
                  colors: [Color(0x8C030612), XdrColors.base],
                  stops: [0.0, 0.78],
                ),
              ),
            ),
          ),
          SafeArea(
            child: XdrEnter(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 28, 22, 40),
                child: Column(
                  children: [
                    const BrandMark(size: 64, radius: 19, glow: 22),
                    const SizedBox(height: 12),
                    Text('X-DREAMER', style: XdrType.wordmark(size: 12).copyWith(shadows: engraved)),
                    const SizedBox(height: 22),
                    MetalSurface(
                      radius: 22,
                      brushed: true,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            'เข้าสู่ระบบ',
                            style: XdrType.thai(
                              size: 19,
                              weight: FontWeight.w500,
                              color: XdrColors.textPrimary,
                            ).copyWith(shadows: engraved),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            'ใช้บัญชีเดียวกับ xman4289.com',
                            style: XdrType.thai(size: 12, color: XdrColors.textMuted),
                          ),
                          const SizedBox(height: 16),
                          MetalField(
                            controller: _email,
                            label: 'อีเมล',
                            hint: 'you@example.com',
                            error: _emailError,
                            enabled: !busy,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.next,
                            autofillHints: const [AutofillHints.email],
                          ),
                          const SizedBox(height: 14),
                          MetalField(
                            controller: _password,
                            label: 'รหัสผ่าน',
                            error: _passwordError,
                            enabled: !busy,
                            obscure: !_showPassword,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                            autofillHints: const [AutofillHints.password],
                            trailing: PressSink(
                              radius: 8,
                              depth: 1,
                              haptic: false,
                              onTap: () => setState(() => _showPassword = !_showPassword),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                child: Text(
                                  _showPassword ? 'ซ่อน' : 'แสดง',
                                  style: XdrType.thai(size: 11, color: XdrColors.ice),
                                ),
                              ),
                            ),
                          ),
                          if (failure != null) ...[
                            const SizedBox(height: 14),
                            ErrorPanel(message: failure.message),
                          ],
                          const SizedBox(height: 18),
                          BrandButton(
                            label: 'เข้าสู่ระบบ',
                            busy: busy,
                            radius: 14,
                            fontSize: 15,
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            onPressed: _submit,
                          ),
                          const SizedBox(height: 16),
                          const _OrDivider(),
                          const SizedBox(height: 16),
                          // The design put a "continue with XMAN Studio" button
                          // here, but there is no SSO handoff — the accounts are
                          // literally the same row in the same table. The slot
                          // is better spent on the thing a customer stuck at
                          // this screen actually needs.
                          GhostButton(
                            label: 'ลืมรหัสผ่าน · รีเซ็ตที่ xman4289.com',
                            fontSize: 13,
                            onPressed: busy
                                ? null
                                : () => launchUrl(
                                      Uri.parse('${AppConfig.xmanBaseUrl}/password/reset'),
                                      mode: LaunchMode.externalApplication,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 18),
                    PressSink(
                      radius: 10,
                      onTap: busy
                          ? null
                          : () => launchUrl(
                                AppConfig.registerUrl,
                                mode: LaunchMode.externalApplication,
                              ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: 'ยังไม่มีบัญชี? ',
                                style: XdrType.thai(size: 12.5, color: XdrColors.textMuted),
                              ),
                              TextSpan(
                                // The welcome grant is configured server-side
                                // (`ai_settings.new_user_free_credits`), so the
                                // app must not promise a specific number.
                                text: 'สมัครฟรี รับเครดิตเริ่มต้น',
                                style: XdrType.thai(
                                  size: 12.5,
                                  color: XdrColors.ice,
                                  weight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Expanded(child: Divider(color: XdrColors.hairline)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('หรือ', style: XdrType.thai(size: 11, color: XdrColors.textDim)),
        ),
        const Expanded(child: Divider(color: XdrColors.hairline)),
      ],
    );
  }
}
