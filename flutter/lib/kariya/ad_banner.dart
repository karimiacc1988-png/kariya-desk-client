// بنر تبلیغ کاریا — زیر کادر شناسه و رمز، در همان پنجره‌ای که مشتری ساعت‌ها باز می‌گذارد.
//
// محتوای بنر از سرور می‌آید، پس عوض کردن تبلیغ نسخه‌ی جدید لازم ندارد.
// اگر تبلیغی تعریف نشده باشد یا شبکه قطع باشد، چیزی نشان داده نمی‌شود.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'kariya_api.dart';
import 'kariya_theme.dart';

class KariyaAdBanner extends StatefulWidget {
  const KariyaAdBanner({Key? key}) : super(key: key);

  @override
  State<KariyaAdBanner> createState() => _KariyaAdBannerState();
}

class _KariyaAdBannerState extends State<KariyaAdBanner> {
  Map<String, dynamic>? _ad;
  Timer? _timer;
  bool _hover = false;

  @override
  void initState() {
    super.initState();
    _load();
    // هر ۱۰ دقیقه یک‌بار بنر تازه گرفته می‌شود.
    _timer = Timer.periodic(const Duration(minutes: 10), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final ad = await KariyaApi.fetchAd();
    if (mounted) setState(() => _ad = ad);
  }

  Future<void> _open() async {
    final ad = _ad;
    if (ad == null) return;
    final link = (ad['link'] ?? '') as String;
    if (link.isEmpty) return;
    KariyaApi.clickAd((ad['id'] ?? 0) as int);
    await launchUrlString(link, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (ad == null) return const Offstage();
    final image = (ad['image'] ?? '') as String;
    final title = (ad['title'] ?? '') as String;
    if (image.isEmpty && title.isEmpty) return const Offstage();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: GestureDetector(
          onTap: _open,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            transform: Matrix4.translationValues(0, _hover ? -3 : 0, 0),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: K.blue.withOpacity(_hover ? 0.28 : 0.14),
                  blurRadius: _hover ? 22 : 14,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  if (image.isNotEmpty)
                    Image.network(
                      image,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (_, __, ___) => const Offstage(),
                    ),
                  if (title.isNotEmpty)
                    Container(
                      width: double.infinity,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.65),
                          ],
                        ),
                      ),
                      child: Text(
                        title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: K.font,
                          color: Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
