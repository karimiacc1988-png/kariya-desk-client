// «دیگر محصولات کاریا» — فهرستی که از سرور می‌آید، نه از داخل برنامه.
//
// ⚠️ عمداً هاردکد نیست: اگر فهرست داخل برنامه بود، هر محصول تازه یعنی یک بیلد
// و یک به‌روزرسانی برای همه‌ی کاربران. حالا افزودن محصول فقط یک ردیف در پنل
// است و همان روز در برنامه‌ی همه دیده می‌شود.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import 'kariya_api.dart';
import 'kariya_theme.dart';

class KariyaProductsButton extends StatelessWidget {
  const KariyaProductsButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 2, 12, 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => showDialog(
            context: context,
            builder: (_) => const KariyaProductsDialog(),
          ),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: dark ? Colors.white10 : K.tint,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.apps_rounded,
                    size: 17, color: dark ? K.blueDark : K.blue),
                const SizedBox(width: 8),
                Text('دیگر محصولات کاریا',
                    style: TextStyle(
                      fontFamily: K.font,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                      color: dark ? K.inkDark : K.blue,
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class KariyaProductsDialog extends StatefulWidget {
  const KariyaProductsDialog({Key? key}) : super(key: key);

  @override
  State<KariyaProductsDialog> createState() => _KariyaProductsDialogState();
}

class _KariyaProductsDialogState extends State<KariyaProductsDialog> {
  List<Map<String, dynamic>>? _items;

  @override
  void initState() {
    super.initState();
    KariyaApi.fetchProducts().then((v) {
      if (mounted) setState(() => _items = v);
    });
  }

  Future<void> _open(Map<String, dynamic> p) async {
    final link = (p['link'] ?? '') as String;
    if (link.isEmpty) return;
    KariyaApi.productClick((p['id'] ?? 0) as int);
    await launchUrlString(link, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final dark = K.isDark(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720, maxHeight: 560),
          child: Container(
            decoration: BoxDecoration(
              color: dark ? K.surfaceDark : K.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: K.shadowPanel,
            ),
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Icon(Icons.apps_rounded, color: dark ? K.blueDark : K.blue),
                    const SizedBox(width: 8),
                    Text('دیگر محصولات کاریا',
                        style: TextStyle(
                          fontFamily: K.font,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: dark ? K.inkDark : K.ink,
                        )),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20),
                      color: dark ? K.softDark : K.soft,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Flexible(child: _body(dark)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _body(bool dark) {
    final items = _items;
    if (items == null) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(
          child: SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(strokeWidth: 2.2, color: K.blue),
          ),
        ),
      );
    }
    if (items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 50),
        child: Text('فعلاً محصولی برای نمایش نیست.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontFamily: K.font,
                fontSize: 13,
                color: dark ? K.softDark : K.soft)),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      padding: const EdgeInsets.only(bottom: 6),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisExtent: 116,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: items.length,
      itemBuilder: (_, i) => _card(items[i], dark),
    );
  }

  Widget _card(Map<String, dynamic> p, bool dark) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _open(p),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: dark ? Colors.white10 : K.ground,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: const LinearGradient(
                        colors: [K.brandLift, K.blue2],
                      ),
                    ),
                    child: const Icon(Icons.widgets_rounded,
                        color: Colors.white, size: 17),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      (p['title'] ?? '') as String,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: K.font,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: dark ? K.inkDark : K.ink,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Text(
                  (p['description'] ?? '') as String,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: K.font,
                    fontSize: 11,
                    height: 1.9,
                    color: dark ? K.softDark : K.soft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
