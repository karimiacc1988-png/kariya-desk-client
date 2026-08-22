// تکه‌های برند در ستون کاربری: سربرگ با لوگو، و پانویسِ «محصول کاریا حساب».

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'kariya_theme.dart';

/// سربرگ ستون: لوگوی کاریا، نام برنامه و یک خط توضیح.
class KariyaBrandHeader extends StatelessWidget {
  const KariyaBrandHeader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: (dark ? K.blueDark : K.blue).withOpacity(0.10),
          ),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: const Color(0xFFD6E4F7),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: K.blue, width: 1.4),
              boxShadow: [
                BoxShadow(
                  color: K.blue.withOpacity(0.16),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Image.asset('assets/logo.png', fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.desktop_windows_rounded,
                        color: K.blue, size: 20)),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('کاریا دسک',
                    style: TextStyle(
                      fontFamily: K.font,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: dark ? K.inkDark : K.ink,
                    )),
                const SizedBox(height: 2),
                Text('پشتیبانی از راه دور',
                    style: TextStyle(
                      fontFamily: K.font,
                      fontSize: 10.5,
                      color: dark ? K.softDark : K.soft,
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// پانویس: «محصول کاریا حساب» با لینک به سایت و راهنمای شناور.
///
/// ⚠️ متنِ راهنما خواسته‌ی مالک است و عمداً وعده‌ی همیشگی می‌دهد؛ اگر روزی
/// سیاست عوض شد، همین‌جا باید عوض شود، نه جای دیگر.
class KariyaMadeBy extends StatelessWidget {
  const KariyaMadeBy({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
      child: Tooltip(
        message: 'این محصول رایگان بوده و رایگان خواهد ماند',
        textStyle: const TextStyle(
            fontFamily: K.font, fontSize: 11.5, color: Colors.white),
        decoration: BoxDecoration(
          color: K.ink,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('محصول ',
                style: TextStyle(
                  fontFamily: K.font,
                  fontSize: 11,
                  color: dark ? K.softDark : K.soft,
                )),
            InkWell(
              onTap: () => launchUrlString('https://kariyahesab.com',
                  mode: LaunchMode.externalApplication),
              child: Text('کاریا حساب',
                  style: TextStyle(
                    fontFamily: K.font,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: dark ? K.blueDark : K.blue,
                  )),
            ),
          ],
        ),
      ),
    );
  }
}
