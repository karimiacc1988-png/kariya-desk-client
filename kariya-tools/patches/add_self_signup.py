#!/usr/bin/env python3
"""
افزودن «معرفی کوتاه» به صفحه‌ی ورود — برای کسی که حساب کاریا ندارد.

⚠️ قاعده‌ی خودِ کاریا: هیچ‌کس به‌خاطر چیزی که ندارد بیرون نمی‌ماند؛ نداشته‌ها
پرسیده می‌شوند. پس نبودِ حساب کاریا در نمی‌بندد، فقط نام و نام کسب‌وکار
پرسیده می‌شود.

این اسکریپت یک‌بار مصرف است و روی kariya/login_gate.dart کار می‌کند.
"""

import sys

sys.stdout.reconfigure(encoding="utf-8")
NL = chr(10)
P = "kariya/login_gate.dart"
s = open(P, encoding="utf-8").read()

if "_selfMode" in s:
    print("از قبل اضافه شده")
    sys.exit(0)

s = s.replace(
    "  Timer? _poll;",
    "  Timer? _poll;" + NL + NL +
    "  // حالت دوم: کسی که حساب کاریا ندارد و فقط خودش را معرفی می‌کند." + NL +
    "  bool _selfMode = false;" + NL +
    "  final _name = TextEditingController();" + NL +
    "  final _business = TextEditingController();" + NL +
    "  final _phone = TextEditingController();" + NL +
    "  bool _saving = false;", 1)

s = s.replace(
    "  @override" + NL + "  void dispose() {" + NL + "    _poll?.cancel();" + NL +
    "    super.dispose();" + NL + "  }",
    "  @override" + NL + "  void dispose() {" + NL + "    _poll?.cancel();" + NL +
    "    _name.dispose();" + NL + "    _business.dispose();" + NL +
    "    _phone.dispose();" + NL + "    super.dispose();" + NL + "  }" + NL + NL +
    "  Future<void> _register() async {" + NL +
    "    if (_saving) return;" + NL +
    "    setState(() {" + NL +
    "      _saving = true;" + NL +
    "      _error = null;" + NL +
    "    });" + NL +
    "    final err = await KariyaApi.register(_name.text.trim()," + NL +
    "        _business.text.trim(), _phone.text.trim(), 'windows');" + NL +
    "    if (!mounted) return;" + NL +
    "    setState(() {" + NL +
    "      _saving = false;" + NL +
    "      _error = err;" + NL +
    "    });" + NL +
    "    if (err == null) {" + NL +
    "      _poll?.cancel();" + NL +
    "      widget.onSuccess?.call();" + NL +
    "    }" + NL +
    "  }", 1)

s = s.replace(
    "          Text('منتظر تأیید شما…'," + NL +
    "              style: TextStyle(fontFamily: K.font, fontSize: 11.5, color: soft))," + NL +
    "        ]," + NL +
    "      )," + NL +
    "    ];",
    "          Text('منتظر تأیید شما…'," + NL +
    "              style: TextStyle(fontFamily: K.font, fontSize: 11.5, color: soft))," + NL +
    "        ]," + NL +
    "      )," + NL +
    "      const SizedBox(height: 10)," + NL +
    "      Center(" + NL +
    "        child: TextButton(" + NL +
    "          onPressed: () => setState(() => _selfMode = true)," + NL +
    "          child: Text('حساب کاریا ندارم'," + NL +
    "              style: TextStyle(" + NL +
    "                  fontFamily: K.font," + NL +
    "                  fontSize: 12," + NL +
    "                  color: dark ? K.blueDark : K.blue))," + NL +
    "        )," + NL +
    "      )," + NL +
    "    ];", 1)

s = s.replace(
    "    return [" + NL + "      Center(child: _mark()),",
    "    if (_selfMode) return _selfForm(dark, ink, soft);" + NL + NL +
    "    return [" + NL + "      Center(child: _mark()),", 1)

self_form = (
    "  /// معرفی ساده: نام و نام کسب‌وکار — بدون حساب کاریا، بدون رمز." + NL +
    "  List<Widget> _selfForm(bool dark, Color ink, Color soft) => [" + NL +
    "        Center(child: _mark())," + NL +
    "        const SizedBox(height: 16)," + NL +
    "        Text('معرفی کوتاه'," + NL +
    "            textAlign: TextAlign.center," + NL +
    "            style: TextStyle(" + NL +
    "                fontFamily: K.font," + NL +
    "                fontSize: 19," + NL +
    "                fontWeight: FontWeight.w700," + NL +
    "                color: ink))," + NL +
    "        const SizedBox(height: 6)," + NL +
    "        Text('حساب کاریا لازم نیست؛ فقط بگویید کی هستید.'," + NL +
    "            textAlign: TextAlign.center," + NL +
    "            style: TextStyle(" + NL +
    "                fontFamily: K.font, fontSize: 12.5, height: 2, color: soft))," + NL +
    "        const SizedBox(height: 18)," + NL +
    "        _field(_name, 'نام و نام خانوادگی', Icons.person_rounded, dark)," + NL +
    "        const SizedBox(height: 10)," + NL +
    "        _field(_business, 'نام کسب‌وکار', Icons.storefront_rounded, dark)," + NL +
    "        const SizedBox(height: 10)," + NL +
    "        _field(_phone, 'شماره موبایل (اختیاری)', Icons.smartphone_rounded," + NL +
    "            dark, digits: true)," + NL +
    "        if (_error != null) ...[" + NL +
    "          const SizedBox(height: 12)," + NL +
    "          Text(_error!," + NL +
    "              textAlign: TextAlign.center," + NL +
    "              style: const TextStyle(" + NL +
    "                  fontFamily: K.font, fontSize: 12.5, color: K.danger))," + NL +
    "        ]," + NL +
    "        const SizedBox(height: 18)," + NL +
    "        _button(_saving ? 'در حال ثبت…' : 'شروع استفاده', _register)," + NL +
    "        const SizedBox(height: 6)," + NL +
    "        Center(" + NL +
    "          child: TextButton(" + NL +
    "            onPressed: () => setState(() {" + NL +
    "              _selfMode = false;" + NL +
    "              _error = null;" + NL +
    "            })," + NL +
    "            child: Text('حساب کاریا دارم'," + NL +
    "                style: TextStyle(" + NL +
    "                    fontFamily: K.font," + NL +
    "                    fontSize: 12," + NL +
    "                    color: dark ? K.blueDark : K.blue))," + NL +
    "          )," + NL +
    "        )," + NL +
    "      ];" + NL + NL +
    "  Widget _field(TextEditingController c, String label, IconData icon," + NL +
    "          bool dark, {bool digits = false}) =>" + NL +
    "      TextField(" + NL +
    "        controller: c," + NL +
    "        inputFormatters:" + NL +
    "            digits ? [FilteringTextInputFormatter.digitsOnly] : null," + NL +
    "        style: TextStyle(" + NL +
    "            fontFamily: K.font, fontSize: 14, color: dark ? K.inkDark : K.ink)," + NL +
    "        decoration: InputDecoration(" + NL +
    "          labelText: label," + NL +
    "          labelStyle: TextStyle(" + NL +
    "              fontFamily: K.font," + NL +
    "              fontSize: 13," + NL +
    "              color: dark ? K.softDark : K.soft)," + NL +
    "          prefixIcon: Icon(icon, size: 19, color: dark ? K.blueDark : K.blue2)," + NL +
    "          filled: true," + NL +
    "          fillColor: dark ? Colors.white10 : K.ground," + NL +
    "          contentPadding:" + NL +
    "              const EdgeInsets.symmetric(horizontal: 14, vertical: 15)," + NL +
    "          border: OutlineInputBorder(" + NL +
    "            borderRadius: BorderRadius.circular(16)," + NL +
    "            borderSide: BorderSide.none," + NL +
    "          )," + NL +
    "          focusedBorder: OutlineInputBorder(" + NL +
    "            borderRadius: BorderRadius.circular(16)," + NL +
    "            borderSide:" + NL +
    "                BorderSide(color: dark ? K.blueDark : K.blue, width: 1.6)," + NL +
    "          )," + NL +
    "        )," + NL +
    "      );" + NL + NL +
    "  Widget _mark() => Container(")

s = s.replace("  Widget _mark() => Container(", self_form, 1)

open(P, "w", encoding="utf-8").write(s)
print("اضافه شد — بررسی تعادل:",
      "paren", s.count("(") - s.count(")"),
      "| brace", s.count("{") - s.count("}"),
      "| bracket", s.count("[") - s.count("]"))
