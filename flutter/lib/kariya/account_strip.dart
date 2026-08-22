// نوار حساب کاریا در ستون اصلی.
//
// ورود «اختیاری» است: برنامه بدون حساب هم کامل کار می‌کند. این نوار فقط
// می‌گوید وارد شده‌اید یا نه، و راه ورود را کنار دست می‌گذارد.

import 'package:flutter/material.dart';

import 'kariya_api.dart';
import 'kariya_theme.dart';
import 'login_gate.dart';

class KariyaAccountStrip extends StatelessWidget {
  const KariyaAccountStrip({Key? key}) : super(key: key);

  Future<void> _openLogin(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420, maxHeight: 560),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: KariyaLoginGate(onSuccess: () => Navigator.of(ctx).pop()),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return ValueListenableBuilder<bool>(
      valueListenable: KariyaApi.loggedIn,
      builder: (context, isLoggedIn, _) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: isLoggedIn
                  ? () => KariyaApi.logout()
                  : () => _openLogin(context),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: isLoggedIn
                      ? (dark ? Colors.white10 : K.tint)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  border: isLoggedIn
                      ? null
                      : Border.all(
                          color: (dark ? K.blueDark : K.blue).withOpacity(0.35),
                        ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isLoggedIn ? Icons.person_rounded : Icons.login_rounded,
                      size: 17,
                      color: dark ? K.blueDark : K.blue,
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        isLoggedIn
                            ? (KariyaApi.userName.isNotEmpty
                                ? KariyaApi.userName
                                : KariyaApi.userPhone)
                            : 'ورود به حساب کاریا',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: K.font,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: dark ? K.inkDark : K.ink,
                        ),
                      ),
                    ),
                    if (isLoggedIn) ...[
                      const SizedBox(width: 6),
                      Icon(Icons.logout_rounded,
                          size: 15, color: dark ? K.softDark : K.soft),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
