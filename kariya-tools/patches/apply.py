#!/usr/bin/env python3
"""
اعمال تغییرات «کاریا دسک» روی سورس اصلی RustDesk.

فلسفه: فورک دستی نگه نمی‌داریم. سورس بالادست را روی یک تگ مشخص می‌گیریم و این
اسکریپت تغییرات ما را رویش می‌زند. با هر نسخه‌ی تازه‌ی RustDesk فقط همین اسکریپت
به‌روز می‌شود.

    python3 patches/apply.py <مسیر-سورس-rustdesk>

همه‌ی تغییرها ایدمپوتنت‌اند: اجرای دوباره چیزی را خراب نمی‌کند.
"""

import os
import shutil
import sys

try:  # کنسول ویندوز پیش‌فرض cp1252 است و متن فارسی را نمی‌پذیرد
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

HERE = os.path.dirname(os.path.abspath(__file__))
ROOT = os.path.dirname(HERE)

# ---------------------------------------------------------------- تنظیمات برند
APP_NAME = "KariyaDesk"
ID_SERVER = "desk.kariyahesab.com"
PUB_KEY = "yQh7HGyWBw2sb6SvcKWdXDFgec+a+2oEDLg4QUWh9ic="
API_SERVER = "https://desk.kariyahesab.com"
APP_VERSION = "1.0.0"   # نسخه‌ی محصولِ خودمان، جدا از نسخه‌ی RustDesk

NL = chr(10)


def edit(path, replacements, required=True):
    """
    جایگزینی رشته‌ای. هر مورد سه‌تایی است: (رشته‌ی قدیم، رشته‌ی تازه، نشانه).
    «نشانه» رشته‌ای یکتا از تغییر ماست؛ اگر در فایل باشد یعنی قبلاً اعمال شده.
    بدون این نشانه، تشخیصِ «قبلاً اعمال شده» اشتباه می‌شود و تغییر بی‌صدا رد می‌شود.
    """
    if not os.path.isfile(path):
        if required:
            raise SystemExit("فایل پیدا نشد: %s" % path)
        print("  - رد شد (نبود): %s" % path)
        return
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    original = src
    for old, new, marker in replacements:
        if marker and marker in src:
            continue  # از قبل اعمال شده
        if old not in src:
            if required:
                raise SystemExit("رشته پیدا نشد در %s:%s%s" % (path, NL, old[:160]))
            print("  - رشته نبود، رد شد: %s" % path)
            continue
        src = src.replace(old, new, 1)
    if src != original:
        with open(path, "w", encoding="utf-8") as fh:
            fh.write(src)
        print("  ✓ %s" % os.path.relpath(path))
    else:
        print("  = از قبل اعمال شده: %s" % os.path.relpath(path))


def add_imports(path, imports):
    """ایمپورت‌های دارت باید بالای فایل و قبل از هر تعریفی باشند."""
    with open(path, encoding="utf-8") as fh:
        src = fh.read()
    needed = [i for i in imports if i not in src]
    if not needed:
        print("  = ایمپورت‌ها از قبل هست: %s" % os.path.relpath(path))
        return
    lines = src.split(NL)
    # ⚠️ ایمپورت شرطیِ دارت دو خطی است:
    #     import 'a.dart'
    #         if (dart.library.html) 'b.dart';
    # پس باید بعد از خطی درج کنیم که دستور ایمپورت را با ';' تمام کرده،
    # نه صرفاً بعد از آخرین خطی که با import شروع می‌شود.
    in_import = False
    last = -1
    for i, ln in enumerate(lines):
        if ln.startswith("import ") or ln.startswith("export "):
            in_import = True
        if in_import and ln.rstrip().endswith(";"):
            last = i
            in_import = False
    if last < 0:
        raise SystemExit("هیچ ایمپورتی در %s پیدا نشد" % path)
    lines[last + 1:last + 1] = ["// --- کاریا دسک ---"] + needed
    with open(path, "w", encoding="utf-8") as fh:
        fh.write(NL.join(lines))
    print("  ✓ ایمپورت اضافه شد: %s" % os.path.relpath(path))


def main(target):
    if not os.path.isdir(os.path.join(target, "flutter")):
        raise SystemExit("این مسیر سورس RustDesk نیست: %s" % target)

    # ۱) فایل‌های خودمان
    dst = os.path.join(target, "flutter", "lib", "kariya")
    os.makedirs(dst, exist_ok=True)
    for name in sorted(os.listdir(os.path.join(ROOT, "kariya"))):
        if name.endswith(".dart"):
            shutil.copy2(os.path.join(ROOT, "kariya", name), os.path.join(dst, name))
    print("  ✓ فایل‌های کاریا در flutter/lib/kariya کپی شد")

    # ۲) سرور و کلید پیش‌فرض — کاربر هیچ تنظیمی نباید بکند
    edit(os.path.join(target, "libs", "hbb_common", "src", "config.rs"), [
        ('pub const RENDEZVOUS_SERVERS: &[&str] = &["rs-ny.rustdesk.com"];',
         'pub const RENDEZVOUS_SERVERS: &[&str] = &["%s"];' % ID_SERVER,
         ID_SERVER),
        ('pub const RS_PUB_KEY: &str = "OeVuKk5nlHiXp+APNn0Y3pC1Iwpwn44JGqrQCsWqmBw=";',
         'pub const RS_PUB_KEY: &str = "%s";' % PUB_KEY, PUB_KEY),
    ])

    # ۳) نام پنجره‌ی ویندوز
    edit(os.path.join(target, "flutter", "windows", "runner", "main.cpp"), [
        ('std::wstring app_name = L"RustDesk";',
         'std::wstring app_name = L"%s";' % APP_NAME, 'L"%s"' % APP_NAME),
    ])

    # ۴) صفحه‌ی اصلی: گیت ورود + بنر تبلیغ
    home = os.path.join(target, "flutter", "lib", "desktop", "pages",
                        "desktop_home_page.dart")
    add_imports(home, [
        "import 'package:flutter_hbb/kariya/kariya_theme.dart';",
        "import 'package:flutter_hbb/kariya/kariya_api.dart';",
        "import 'package:flutter_hbb/kariya/login_gate.dart';",
        "import 'package:flutter_hbb/kariya/ad_banner.dart';",
    ])
    gate_old = (
        "  Widget build(BuildContext context) {" + NL +
        "    super.build(context);" + NL +
        "    final isIncomingOnly = bind.isIncomingOnly();" + NL)
    gate_new = (
        "  Widget build(BuildContext context) {" + NL +
        "    super.build(context);" + NL +
        "    // --- کاریا: تا وارد نشده، شناسه و رمز اتصال نشان داده نمی‌شود ---" + NL +
        "    return ValueListenableBuilder<bool>(" + NL +
        "      valueListenable: KariyaApi.loggedIn," + NL +
        "      builder: (context, isLoggedIn, _) => isLoggedIn" + NL +
        "          ? _kariyaHome(context)" + NL +
        "          : KariyaLoginGate(onSuccess: () => setState(() {}))," + NL +
        "    );" + NL +
        "  }" + NL + NL +
        "  Widget _kariyaHome(BuildContext context) {" + NL +
        "    final isIncomingOnly = bind.isIncomingOnly();" + NL)
    banner_old = "      if (!isOutgoingOnly) buildPasswordBoard(context),"
    banner_new = (banner_old + NL + "      const KariyaAdBanner(),")
    edit(home, [(gate_old, gate_new, "_kariyaHome"),
                (banner_old, banner_new, "KariyaAdBanner()")])

    # ۵) خواندن نشست ذخیره‌شده هنگام بالا آمدن برنامه
    main_dart = os.path.join(target, "flutter", "lib", "main.dart")
    add_imports(main_dart, ["import 'package:flutter_hbb/kariya/kariya_api.dart';"])
    edit(main_dart, [
        ("Future<void> main(List<String> args) async {",
         "Future<void> main(List<String> args) async {" + NL +
         "  // نشست ذخیره‌شده‌ی کاریا را می‌خوانیم تا هر بار لاگین لازم نباشد." + NL +
         "  KariyaApi.load();", "KariyaApi.load();"),
    ])

    # ۶) فونت سایت کاریا (یکان‌بخ) — همان فونتی که kariyahesab.com با آن نوشته شده
    font_src = os.path.join(ROOT, "assets", "fonts")
    font_dst = os.path.join(target, "flutter", "assets", "fonts")
    os.makedirs(font_dst, exist_ok=True)
    weights = {"Sakou-400.ttf": "Kariya-Regular.ttf",
               "Sakou-600.ttf": "Kariya-SemiBold.ttf",
               "Sakou-700.ttf": "Kariya-Bold.ttf"}
    for src_name, dst_name in weights.items():
        src = os.path.join(font_src, src_name)
        if os.path.isfile(src):
            shutil.copy2(src, os.path.join(font_dst, dst_name))
    print("  ✓ فونت کاریا در flutter/assets/fonts کپی شد")

    pubspec = os.path.join(target, "flutter", "pubspec.yaml")
    edit(pubspec, [(
        "  fonts:" + NL,
        "  fonts:" + NL +
        "    - family: Kariya" + NL +
        "      fonts:" + NL +
        "        - asset: assets/fonts/Kariya-Regular.ttf" + NL +
        "          weight: 400" + NL +
        "        - asset: assets/fonts/Kariya-SemiBold.ttf" + NL +
        "          weight: 600" + NL +
        "        - asset: assets/fonts/Kariya-Bold.ttf" + NL +
        "          weight: 700" + NL,
        "family: Kariya")])

    # ۷) فونت برند روی کل برنامه، نه فقط صفحه‌های خودمان
    common = os.path.join(target, "flutter", "lib", "common.dart")
    edit(common, [
        ("  static ThemeData lightTheme = ThemeData(" + NL,
         "  static ThemeData lightTheme = ThemeData(" + NL +
         "    fontFamily: 'Kariya', // kariya-light" + NL, "// kariya-light"),
        ("  static ThemeData darkTheme = ThemeData(" + NL,
         "  static ThemeData darkTheme = ThemeData(" + NL +
         "    fontFamily: 'Kariya', // kariya-dark" + NL, "// kariya-dark"),
    ])

    # ۸) به‌روزرسانی خودکار — سازوکار خودِ RustDesk را به سرور خودمان می‌چرخانیم
    #    (کامل و تست‌شده است: دانلود، نصب بی‌صدا، و انتظار تا پایان نشست‌های فعال)
    edit(os.path.join(target, "libs", "hbb_common", "src", "lib.rs"), [
        ('const URL: &str = "https://api.rustdesk.com/version/latest";',
         'const URL: &str = "%s/version/latest";' % API_SERVER, API_SERVER)])

    # بدون این، چون نام برنامه عوض شده، RustDesk بررسی نسخه را خاموش می‌کند
    edit(os.path.join(target, "src", "common.rs"), [
        ("pub fn check_software_update() {" + NL +
         "    if is_custom_client() {" + NL +
         "        return;" + NL +
         "    }" + NL,
         "pub fn check_software_update() {" + NL +
         "    // کاریا: نسخه‌ی برندشده هم باید به‌روزرسانی بگیرد" + NL,
         "کاریا: نسخه‌ی برندشده")])

    # به‌روزرسانی خودکار به‌صورت پیش‌فرض روشن باشد، مگر کاربر صریحاً خاموشش کند
    edit(os.path.join(target, "src", "updater.rs"), [
        ("    if !(manually || config::Config::get_bool_option("
         "config::keys::OPTION_ALLOW_AUTO_UPDATE)) {" + NL,
         "    // کاریا: پیش‌فرض روشن؛ فقط \"N\" صریح خاموشش می‌کند" + NL +
         "    let auto_ok = config::Config::get_option("
         "config::keys::OPTION_ALLOW_AUTO_UPDATE) != \"N\";" + NL +
         "    if !(manually || auto_ok) {" + NL, "کاریا: پیش‌فرض روشن")])

    # نسخه‌ی محصول خودمان؛ به‌روزرسانی‌های بعدی از همین‌جا جلو می‌روند
    edit(os.path.join(target, "Cargo.toml"), [
        ('version = "1.4.9"', 'version = "%s"' % APP_VERSION,
         'version = "%s"' % APP_VERSION)])
    # ⚠️ بیلد با `cargo build --locked` اجرا می‌شود: اگر نسخه در Cargo.toml عوض
    # شود ولی در Cargo.lock نه، کارگو کل بیلد را رد می‌کند.
    edit(os.path.join(target, "Cargo.lock"), [
        ('name = "rustdesk"' + NL + 'version = "1.4.9"',
         'name = "rustdesk"' + NL + 'version = "%s"' % APP_VERSION,
         'name = "rustdesk"' + NL + 'version = "%s"' % APP_VERSION)])

    # ۹) رنگ تأکید کل برنامه: آبیِ کاریا به‌جای آبیِ RustDesk
    #    (دکمه‌ها، سوییچ‌ها، هایلایت‌ها و همه‌ی جاهایی که MyTheme.accent را می‌خوانند)
    edit(common, [
        ("static const Color accent = Color(0xFF0071FF);",
         "static const Color accent = Color(0xFF16449B); // کاریا", "0xFF16449B"),
        ("static const Color accent50 = Color(0x770071FF);",
         "static const Color accent50 = Color(0x7716449B);", "0x7716449B"),
        ("static const Color accent80 = Color(0xAA0071FF);",
         "static const Color accent80 = Color(0xAA16449B);", "0xAA16449B"),
    ])

    print(NL + "تمام شد؛ سورس آماده‌ی ساخت است.")


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(os.path.abspath(sys.argv[1]))
