// صفحه‌ی ورود کاریا دسک — تا وارد نشوی، برنامه شناسه و رمز اتصال را نشان نمی‌دهد.
//
// طراحی: گوشه‌های نرم، بدون بوردر خشن، حرکت در هاور — همان زبان بصری پنل.

import 'package:flutter/material.dart';

import 'kariya_api.dart';

class KariyaLoginGate extends StatefulWidget {
  final VoidCallback? onSuccess;
  const KariyaLoginGate({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<KariyaLoginGate> createState() => _KariyaLoginGateState();
}

class _KariyaLoginGateState extends State<KariyaLoginGate> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    final err = await KariyaApi.login(
      _phone.text.trim(),
      _password.text,
      'windows',
    );
    if (!mounted) return;
    setState(() {
      _busy = false;
      _error = err;
    });
    if (err == null) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    final accent = const Color(0xFF4A6CF7);
    final accent2 = const Color(0xFF17B8A6);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [
              accent.withOpacity(0.10),
              accent2.withOpacity(0.10),
            ],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 26),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 340),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    height: 62,
                    width: 62,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(colors: [accent, accent2]),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.desktop_windows_rounded,
                        color: Colors.white, size: 30),
                  ).paddingOnly(bottom: 16),
                  const Text(
                    'کاریا دسک',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const Text(
                    'برای استفاده از پشتیبانی از راه دور وارد شوید',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey),
                  ).paddingOnly(top: 6, bottom: 20),
                  _field(_phone, 'شماره موبایل', TextInputType.phone, false),
                  const SizedBox(height: 10),
                  _field(_password, 'رمز عبور', TextInputType.text, true),
                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: Color(0xFFF2455A), fontSize: 12.5),
                      ),
                    ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 46,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: accent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      onPressed: _busy ? null : _submit,
                      child: _busy
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('ورود',
                              style: TextStyle(fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'حساب ندارید؟ با پشتیبانی کاریا حساب تماس بگیرید.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 11.5, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, TextInputType type,
      bool obscure) {
    return TextField(
      controller: c,
      keyboardType: type,
      obscureText: obscure,
      textInputAction:
          obscure ? TextInputAction.done : TextInputAction.next,
      onSubmitted: (_) => obscure ? _submit() : FocusScope.of(context).nextFocus(),
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

extension _Pad on Widget {
  Widget paddingOnly({double top = 0, double bottom = 0}) => Padding(
        padding: EdgeInsets.only(top: top, bottom: bottom),
        child: this,
      );
}
