// زبان بصری کاریا — همان چیزی که سایت kariyahesab.com با آن ساخته شده.
//
// رنگ‌ها و اندازه‌ها مستقیم از توکن‌های سایت برداشته شده‌اند تا برنامه و سایت
// یک جنس دیده شوند: همان آبی، همان کاغذ، و همان «مربع‌های محو» پس‌زمینه.

import 'package:flutter/material.dart';

class K {
  // ---- رنگ‌های برند (از globals.css سایت) ----
  static const brandLift = Color(0xFF1A4FAE); // --brand-lift
  static const brandDeep = Color(0xFF123063); // --brand-deep
  static const blue = Color(0xFF16449B); // --c-blue
  static const blue2 = Color(0xFF2F63C7); // --c-blue-2
  static const ink = Color(0xFF16223B); // --c-ink
  static const soft = Color(0xFF5F6E85); // --c-soft
  static const tint = Color(0xFFEAF1FC); // --c-tint
  static const ground = Color(0xFFF7FAFE); // --c-ground
  static const surface = Color(0xFFFFFFFF); // --c-surface
  static const danger = Color(0xFFF2455A);

  // ---- رنگ‌های حالت تیره ----
  static const inkDark = Color(0xFFE8EEFA);
  static const blueDark = Color(0xFF8FB3F5);
  static const softDark = Color(0xFF93A5C2);
  static const groundDark = Color(0xFF0B1220);
  static const surfaceDark = Color(0xFF16223A);

  /// فونت سایت کاریا (یکان‌بخ) که با نام Kariya در pubspec ثبت شده.
  static const font = 'Kariya';

  // ---- سایه‌ها (--sh-soft و --sh-panel سایت) ----
  static const shadowSoft = [
    BoxShadow(color: Color(0x0D10285A), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F10285A), blurRadius: 24, offset: Offset(0, 8)),
  ];
  static const shadowPanel = [
    BoxShadow(color: Color(0x1410285A), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x2910285A), blurRadius: 64, offset: Offset(0, 28)),
  ];

  static bool isDark(BuildContext c) =>
      Theme.of(c).brightness == Brightness.dark;
}

/// پس‌زمینه‌ی «مربع‌های محو» سایت: خط‌کشیِ یکنواخت با خانه‌های ۳۴ پیکسلی.
///
/// روی سایت این لایه یک ورقِ واحد پشت کل صفحه است تا خانه‌ها بین بخش‌ها
/// نشکنند؛ اینجا هم همین‌طور رسم می‌شود، نه بخش‌بخش.
class KariyaWeave extends StatelessWidget {
  final Widget child;
  const KariyaWeave({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: dark
              ? [K.groundDark, const Color(0xFF101B2E)]
              : [K.ground, K.tint],
        ),
      ),
      child: CustomPaint(
        painter: _WeavePainter(
          // ⚠️ خیلی کم‌رنگ، در حد کاغذِ مهندسی: نسخه‌ی اول ۰.۱۶ بود و مالک
          // گفت «خیلی پررنگ است». خط باید حس بدهد، نه دیده شود.
          rule: dark
              ? const Color(0xFF8FB3F5).withOpacity(0.035)
              : const Color(0xFF16449B).withOpacity(0.022),
          ground: dark ? K.groundDark : K.ground,
          cell: 34,
        ),
        child: child,
      ),
    );
  }
}

class _WeavePainter extends CustomPainter {
  final Color rule;
  final Color ground;
  final double cell;

  _WeavePainter({required this.rule, required this.ground, required this.cell});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = rule
      ..strokeWidth = 1
      ..isAntiAlias = false;

    for (double x = 0; x <= size.width; x += cell) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += cell) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // وسط صفحه با رنگِ خودِ کاغذ محو می‌شود تا خط‌ها پشت متن ننشینند — همان
    // کاری که ماسکِ سایت با ستون محتوا می‌کند، ولی ساده‌تر: یک هاله‌ی هم‌رنگ.
    // در این شدت، دیگر به محوکردنِ مرکز نیازی نیست؛ خط‌ها خودشان پس‌زمینه‌اند.
  }

  @override
  bool shouldRepaint(covariant _WeavePainter old) =>
      old.rule != rule || old.cell != cell || old.ground != ground;
}


/// کارتِ کاریا: سطح سفید با گوشه‌ی نرم و سایه‌ی ملایم — همان کارت‌های سایت.
/// دور کادرهای شناسه و رمزِ RustDesk می‌پیچد تا ستون اصلی هم زبان بصری ما را بگیرد.
class KariyaCard extends StatelessWidget {
  final Widget child;
  const KariyaCard({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Container(
      margin: const EdgeInsets.fromLTRB(10, 6, 10, 6),
      padding: const EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: dark ? K.surfaceDark.withOpacity(0.92) : K.surface.withOpacity(0.94),
        borderRadius: BorderRadius.circular(18),
        boxShadow: K.shadowSoft,
      ),
      child: child,
    );
  }
}
