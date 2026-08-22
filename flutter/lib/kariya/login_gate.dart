// ورود به حساب کاریا از داخل برنامه‌ی ویندوزی.
//
// ⚠️ چرا کد می‌گیریم و فرم رمز نمی‌گذاریم: ورود کاریا با موبایل، بله، تلگرام
// و گوگل انجام می‌شود و همه‌ی این‌ها روی سایت پیاده شده‌اند. اگر می‌خواستیم
// داخل برنامه تکرارشان کنیم، باید چهار مسیر احراز هویت را از نو می‌نوشتیم و
// هر تغییرِ سایت، برنامه را می‌شکست. به‌جایش برنامه یک کد کوتاه نشان می‌دهد،
// کاربر در مرورگر با هر روشی که همیشه وارد می‌شود تأیید می‌کند، و برنامه با
// نظرسنجی متوجه می‌شود — همان کاری که تلویزیون‌های هوشمند می‌کنند.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'kariya_api.dart';
import 'kariya_theme.dart';

class KariyaLoginGate extends StatefulWidget {
  final VoidCallback? onSuccess;
  const KariyaLoginGate({Key? key, this.onSuccess}) : super(key: key);

  @override
  State<KariyaLoginGate> createState() => _KariyaLoginGateState();
}

class _KariyaLoginGateState extends State<KariyaLoginGate> {
  String? _userCode;
  String? _deviceCode;
  String? _verifyUrl;
  String? _error;
  bool _busy = true;
  bool _expired = false;
  Timer? _poll;

  // حالت دوم: کسی که حساب کاریا ندارد و فقط خودش را معرفی می‌کند.
  bool _selfMode = false;
  final _name = TextEditingController();
  final _business = TextEditingController();
  final _phone = TextEditingController();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void dispose() {
    _poll?.cancel();
    _name.dispose();
    _business.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    final err = await KariyaApi.register(_name.text.trim(),
        _business.text.trim(), _phone.text.trim(), 'windows');
    if (!mounted) return;
    setState(() {
      _saving = false;
      _error = err;
    });
    if (err == null) {
      _poll?.cancel();
      widget.onSuccess?.call();
    }
  }

  Future<void> _start() async {
    setState(() {
      _busy = true;
      _error = null;
      _expired = false;
    });
    final data = await KariyaApi.deviceStart('windows');
    if (!mounted) return;
    if (data == null) {
      setState(() {
        _busy = false;
        _error = 'ارتباط با سرور کاریا برقرار نشد. اینترنت را بررسی کنید.';
      });
      return;
    }
    setState(() {
      _busy = false;
      _userCode = data['user_code'] as String?;
      _deviceCode = data['device_code'] as String?;
      _verifyUrl = data['verify_url_full'] as String?;
    });
    final seconds = (data['interval'] as int?) ?? 3;
    _poll?.cancel();
    _poll = Timer.periodic(Duration(seconds: seconds), (_) => _check());
  }

  Future<void> _check() async {
    final code = _deviceCode;
    if (code == null) return;
    final status = await KariyaApi.devicePoll(code);
    if (!mounted) return;
    if (status == 'authorized') {
      _poll?.cancel();
      widget.onSuccess?.call();
    } else if (status == 'expired' || status == 'unknown') {
      _poll?.cancel();
      setState(() => _expired = true);
    }
  }

  Future<void> _openBrowser() async {
    final url = _verifyUrl;
    if (url == null) return;
    await launchUrlString(url, mode: LaunchMode.externalApplication);
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
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Container(
                padding: const EdgeInsets.fromLTRB(26, 28, 26, 22),
                decoration: BoxDecoration(
                  color: dark ? K.surfaceDark : K.surface,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: K.shadowPanel,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: _body(dark),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _body(bool dark) {
    final ink = dark ? K.inkDark : K.ink;
    final soft = dark ? K.softDark : K.soft;

    if (_busy) {
      return [
        const SizedBox(height: 40),
        const Center(
          child: SizedBox(
            height: 26,
            width: 26,
            child: CircularProgressIndicator(strokeWidth: 2.4, color: K.blue),
          ),
        ),
        const SizedBox(height: 40),
      ];
    }

    if (_error != null || _expired) {
      return [
        Icon(Icons.error_outline_rounded,
            color: _expired ? K.blue : K.danger, size: 34),
        const SizedBox(height: 12),
        Text(
          _expired ? 'مهلت این کد تمام شد' : _error!,
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: K.font, fontSize: 13.5, height: 2, color: ink),
        ),
        const SizedBox(height: 18),
        _button('گرفتن کد تازه', _start),
      ];
    }

    if (_selfMode) return _selfForm(dark, ink, soft);

    return [
      Center(child: _mark()),
      const SizedBox(height: 16),
      Text('ورود به حساب کاریا',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontFamily: K.font,
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: ink)),
      const SizedBox(height: 6),
      Text(
        'صفحه‌ی ورود کاریا را باز کنید و این کد را تأیید کنید.\nبا موبایل، بله، تلگرام یا گوگل — هر کدام که همیشه وارد می‌شوید.',
        textAlign: TextAlign.center,
        style: TextStyle(
            fontFamily: K.font, fontSize: 12.5, height: 2, color: soft),
      ),
      const SizedBox(height: 20),
      _codeBox(dark),
      const SizedBox(height: 18),
      _button('باز کردن صفحه‌ی ورود', _openBrowser),
      const SizedBox(height: 12),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            height: 13,
            width: 13,
            child: CircularProgressIndicator(strokeWidth: 1.6, color: soft),
          ),
          const SizedBox(width: 8),
          Text('منتظر تأیید شما…',
              style: TextStyle(fontFamily: K.font, fontSize: 11.5, color: soft)),
        ],
      ),
      const SizedBox(height: 10),
      Center(
        child: TextButton(
          onPressed: () => setState(() => _selfMode = true),
          child: Text('حساب کاریا ندارم',
              style: TextStyle(
                  fontFamily: K.font,
                  fontSize: 12,
                  color: dark ? K.blueDark : K.blue)),
        ),
      ),
    ];
  }

  /// معرفی ساده: نام و نام کسب‌وکار — بدون حساب کاریا، بدون رمز.
  List<Widget> _selfForm(bool dark, Color ink, Color soft) => [
        Center(child: _mark()),
        const SizedBox(height: 16),
        Text('معرفی کوتاه',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: K.font,
                fontSize: 19,
                fontWeight: FontWeight.w700,
                color: ink)),
        const SizedBox(height: 6),
        Text('حساب کاریا لازم نیست؛ فقط بگویید کی هستید.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: K.font, fontSize: 12.5, height: 2, color: soft)),
        const SizedBox(height: 18),
        _field(_name, 'نام و نام خانوادگی', Icons.person_rounded, dark),
        const SizedBox(height: 10),
        _field(_business, 'نام کسب‌وکار', Icons.storefront_rounded, dark),
        const SizedBox(height: 10),
        _field(_phone, 'شماره موبایل (اختیاری)', Icons.smartphone_rounded,
            dark, digits: true),
        if (_error != null) ...[
          const SizedBox(height: 12),
          Text(_error!,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontFamily: K.font, fontSize: 12.5, color: K.danger)),
        ],
        const SizedBox(height: 18),
        _button(_saving ? 'در حال ثبت…' : 'شروع استفاده', _register),
        const SizedBox(height: 6),
        Center(
          child: TextButton(
            onPressed: () => setState(() {
              _selfMode = false;
              _error = null;
            }),
            child: Text('حساب کاریا دارم',
                style: TextStyle(
                    fontFamily: K.font,
                    fontSize: 12,
                    color: dark ? K.blueDark : K.blue)),
          ),
        ),
      ];

  Widget _field(TextEditingController c, String label, IconData icon,
          bool dark, {bool digits = false}) =>
      TextField(
        controller: c,
        inputFormatters:
            digits ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: TextStyle(
            fontFamily: K.font, fontSize: 14, color: dark ? K.inkDark : K.ink),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
              fontFamily: K.font,
              fontSize: 13,
              color: dark ? K.softDark : K.soft),
          prefixIcon: Icon(icon, size: 19, color: dark ? K.blueDark : K.blue2),
          filled: true,
          fillColor: dark ? Colors.white10 : K.ground,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide:
                BorderSide(color: dark ? K.blueDark : K.blue, width: 1.6),
          ),
        ),
      );

  Widget _mark() => Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [K.brandLift, K.blue2],
          ),
          boxShadow: [
            BoxShadow(
                color: K.blue.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 9)),
          ],
        ),
        child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 28),
      );

  Widget _codeBox(bool dark) {
    final code = _userCode ?? '';
    return GestureDetector(
      onTap: () => Clipboard.setData(ClipboardData(text: code)),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: dark ? Colors.white10 : K.ground,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          children: [
            Text(
              code,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: K.font,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                letterSpacing: 6,
                color: dark ? K.blueDark : K.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text('برای کپی، روی کد بزنید',
                style: TextStyle(
                    fontFamily: K.font,
                    fontSize: 10.5,
                    color: dark ? K.softDark : K.soft)),
          ],
        ),
      ),
    );
  }

  Widget _button(String label, VoidCallback onTap) => SizedBox(
        height: 46,
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
                  color: K.blue.withOpacity(0.28),
                  blurRadius: 16,
                  offset: const Offset(0, 8)),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: onTap,
              child: Center(
                child: Text(label,
                    style: const TextStyle(
                        fontFamily: K.font,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white)),
              ),
            ),
          ),
        ),
      );
}
