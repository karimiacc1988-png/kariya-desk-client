// صفحه‌ی ورود کاریا دسک — تا وارد نشوی، شناسه و رمز اتصال نشان داده نمی‌شود.
//
// طرح دقیقاً از سایت kariyahesab.com آمده: کاغذِ روشن با مربع‌های محو، آبیِ برند،
// گوشه‌های نرم، سایه‌ی عمیقِ پنل، و فونت خودِ سایت.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'kariya_api.dart';
import 'kariya_theme.dart';

class KariyaLoginGate extends StatefulWidget {
  final VoidCallback? onSuccess;
  const KariyaLoginGate({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<KariyaLoginGate> createState() => _KariyaLoginGateState();
}

class _KariyaLoginGateState extends State<KariyaLoginGate>
    with SingleTickerProviderStateMixin {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  late final AnimationController _anim;
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..forward();
  }

  @override
  void dispose() {
    _anim.dispose();
    _phone.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await KariyaApi.login(_phone.text.trim(), _password.text, 'windows');
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: KariyaWeave(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: FadeTransition(
              opacity: _anim,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.06),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                    parent: _anim, curve: Curves.easeOutCubic)),
                child: _card(dark),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(bool dark) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: Container(
        padding: const EdgeInsets.fromLTRB(26, 30, 26, 24),
        decoration: BoxDecoration(
          color: dark ? K.surfaceDark : K.surface,
          borderRadius: BorderRadius.circular(24),
          boxShadow: K.shadowPanel,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(child: _mark()),
            const SizedBox(height: 16),
            Text(
              'کاریا دسک',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: K.font,
                fontSize: 23,
                fontWeight: FontWeight.w700,
                color: dark ? K.inkDark : K.ink,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'برای استفاده از پشتیبانی از راه دور وارد شوید',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: K.font,
                fontSize: 12.5,
                height: 1.9,
                color: dark ? K.softDark : K.soft,
              ),
            ),
            const SizedBox(height: 22),
            _field(
              controller: _phone,
              label: 'شماره موبایل',
              icon: Icons.smartphone_rounded,
              dark: dark,
              keyboard: TextInputType.phone,
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onSubmit: () => _passwordFocus.requestFocus(),
            ),
            const SizedBox(height: 12),
            _field(
              controller: _password,
              label: 'رمز عبور',
              icon: Icons.lock_rounded,
              dark: dark,
              obscure: true,
              focusNode: _passwordFocus,
              onSubmit: _submit,
            ),
            if (_error != null) _errorBox(),
            const SizedBox(height: 20),
            _submitButton(),
            const SizedBox(height: 16),
            Text(
              'حساب ندارید؟ با پشتیبانی کاریا حساب تماس بگیرید.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: K.font,
                fontSize: 11.5,
                color: dark ? K.softDark : K.soft,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// نشانِ برند: همان کاشیِ آبیِ گرادیانی که سر سایت نشسته.
  Widget _mark() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [K.brandLift, K.blue2],
        ),
        boxShadow: [
          BoxShadow(
            color: K.blue.withOpacity(0.32),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: const Icon(Icons.desktop_windows_rounded,
          color: Colors.white, size: 30),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool dark,
    TextInputType keyboard = TextInputType.text,
    List<TextInputFormatter>? formatters,
    bool obscure = false,
    FocusNode? focusNode,
    VoidCallback? onSubmit,
  }) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboard,
      inputFormatters: formatters,
      obscureText: obscure,
      textInputAction:
          obscure ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) => onSubmit?.call(),
      style: TextStyle(
        fontFamily: K.font,
        fontSize: 14,
        color: dark ? K.inkDark : K.ink,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: K.font,
          fontSize: 13,
          color: dark ? K.softDark : K.soft,
        ),
        prefixIcon: Icon(icon, size: 19, color: dark ? K.blueDark : K.blue2),
        filled: true,
        fillColor: dark ? Colors.white10 : K.ground,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: dark ? K.blueDark : K.blue, width: 1.6),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Widget _errorBox() {
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: K.danger.withOpacity(0.10),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: K.danger, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _error!,
              style: const TextStyle(
                fontFamily: K.font,
                fontSize: 12.5,
                height: 1.8,
                color: K.danger,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _submitButton() {
    return SizedBox(
      height: 48,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            begin: Alignment.centerRight,
            end: Alignment.centerLeft,
            colors: [K.brandLift, K.blue2],
          ),
          boxShadow: [
            BoxShadow(
              color: K.blue.withOpacity(_busy ? 0.10 : 0.30),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: _busy ? null : _submit,
            child: Center(
              child: _busy
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'ورود',
                      style: TextStyle(
                        fontFamily: K.font,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
