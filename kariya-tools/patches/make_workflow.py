#!/usr/bin/env python3
"""
ساخت ورک‌فلوی ساخت ویندوزِ کاریا دسک از روی ورک‌فلوی خودِ RustDesk.

چرا این‌طوری: مراحل ساخت ویندوزِ RustDesk (موتور فلاتر سفارشی، vcpkg، LLVM،
بریج راست) پیچیده و حساس است. به‌جای بازنویسی، همان جاب‌های بالادست را
برمی‌داریم و فقط چیزهای اضافه را حذف می‌کنیم:

  - فقط سه جاب لازم برای ویندوز نگه داشته می‌شود
  - فقط معماری x86_64 (نه ARM) تا نصف زمان ساخت صرفه‌جویی شود
  - تریگر روی workflow_dispatch تا هر پوش، بیلد راه نیندازد

    python3 patches/make_workflow.py <مسیر-سورس-rustdesk>
"""

import os
import sys

try:
    sys.stdout.reconfigure(encoding="utf-8")
except Exception:
    pass

KEEP_JOBS = ["generate-bridge", "build-RustDeskTempTopMostWindow",
             "build-for-windows-flutter"]
NL = chr(10)

NEW_TRIGGER = """name: ساخت کاریا دسک برای ویندوز

on:
  workflow_dispatch:
    inputs:
      upload-artifact:
        type: boolean
        default: true
      upload-tag:
        type: string
        default: "kariya"
"""


def split_jobs(lines, jobs_idx):
    """مرزهای هر جاب را پیدا می‌کند (جاب‌ها با دو فاصله تورفتگی شروع می‌شوند)."""
    jobs = {}
    current = None
    start = None
    for i in range(jobs_idx + 1, len(lines)):
        line = lines[i]
        if line.startswith("  ") and not line.startswith("   ") and line.rstrip().endswith(":"):
            if current:
                jobs[current] = (start, i)
            current = line.strip().rstrip(":")
            start = i
    if current:
        jobs[current] = (start, len(lines))
    return jobs


def main(target):
    src_path = os.path.join(target, ".github", "workflows", "flutter-build.yml")
    with open(src_path, encoding="utf-8") as fh:
        lines = fh.read().split(NL)

    jobs_idx = next(i for i, ln in enumerate(lines) if ln.rstrip() == "jobs:")
    env_start = next(i for i, ln in enumerate(lines) if ln.rstrip() == "env:")
    env_block = lines[env_start:jobs_idx]

    jobs = split_jobs(lines, jobs_idx)
    missing = [j for j in KEEP_JOBS if j not in jobs]
    if missing:
        raise SystemExit("این جاب‌ها در ورک‌فلوی بالادست پیدا نشدند: %s" % missing)

    out = [NEW_TRIGGER, NL.join(env_block), "jobs:"]
    for name in KEEP_JOBS:
        a, b = jobs[name]
        block = drop_arm(NL.join(lines[a:b]).rstrip() + NL)
        if name == "build-for-windows-flutter":
            block = use_artifact_instead_of_release(block)
        out.append(block)

    dst = os.path.join(target, ".github", "workflows", "kariya-windows.yml")
    with open(dst, "w", encoding="utf-8") as fh:
        fh.write(NL.join(out) + NL)
    print("  ✓ ساخته شد: .github/workflows/kariya-windows.yml")

    # بریجِ مخصوص فلاتر ۳.۴۴ فقط برای ویندوز ARM لازم است؛ ما ARM نمی‌سازیم و
    # این جاب هر بیلد را حدود بیست دقیقه طولانی‌تر می‌کند.
    bridge = os.path.join(target, ".github", "workflows", "bridge.yml")
    with open(bridge, encoding="utf-8") as fh:
        btext = fh.read()
    if "bridge-artifact-flutter-3.44" in btext:
        blines = btext.split(NL)
        keep, entry = [], None
        for ln in blines:
            st = ln.strip()
            if entry is None and st.startswith("- {"):
                entry = [ln]
                continue
            if entry is not None:
                entry.append(ln)
                if st in ("}", "},"):
                    if "3.44" not in NL.join(entry):
                        keep.extend(entry)
                    entry = None
                continue
            keep.append(ln)
        with open(bridge, "w", encoding="utf-8") as fh:
            fh.write(NL.join(keep))
        print("  ✓ بریج ۳.۴۴ (مخصوص ARM) از bridge.yml حذف شد")

    # ورک‌فلوهای بی‌ربط حذف می‌شوند تا هر پوش، ده‌ها بیلد راه نیندازد
    keep_files = {"kariya-windows.yml", "bridge.yml",
                  "third-party-RustDeskTempTopMostWindow.yml"}
    wf_dir = os.path.join(target, ".github", "workflows")
    for name in sorted(os.listdir(wf_dir)):
        if name not in keep_files:
            os.remove(os.path.join(wf_dir, name))
            print("  - حذف شد: %s" % name)


ARM_MARKERS = ("aarch64", "windows-11-arm", "ARM64")


def use_artifact_instead_of_release(block):
    """
    گام آخرِ بالادست فایل نصب را روی «ریلیز» گیت‌هاب می‌گذارد که برای مخزن ما
    نه لازم است نه اجازه‌اش را دارد — و کل بیلد را در آخرین قدم می‌انداخت.
    به‌جایش همان فایل‌ها را به‌عنوان آرتیفکت بالا می‌دهیم تا بشود برداشت.
    """
    lines = block.split(NL)
    out, skip = [], False
    for ln in lines:
        if ln.strip() == "- name: Publish Release":
            out.extend([
                "      - name: Upload installer",
                "        uses: actions/upload-artifact@v4",
                "        if: env.UPLOAD_ARTIFACT == 'true'",
                "        with:",
                "          name: kariyadesk-installer",
                "          path: |",
                "            ./SignOutput/*.msi",
                "            ./SignOutput/*.exe",
            ])
            skip = True
            continue
        if skip:
            # تا شروع گام بعدی یا پایان بلوک رد می‌شویم
            if ln.strip().startswith("- name:") or (ln.strip() and not ln.startswith("        ")):
                skip = False
                out.append(ln)
            continue
        out.append(ln)
    return NL.join(out)


def drop_arm(block):
    """
    ورودی‌های ARM را از ماتریس‌ها بیرون می‌کشد (ویندوز ARM فعلاً لازم نیست و
    رانرش کمیاب است). هر ورودیِ ماتریس یک بلوکِ '- { ... }' است؛ اگر داخلش
    نشانه‌ی ARM باشد، کل بلوک حذف می‌شود.
    """
    lines = block.split(NL)
    out = []
    entry = None
    for ln in lines:
        stripped = ln.strip()
        if entry is None and stripped.startswith("- {"):
            entry = [ln]
            if stripped.endswith("}") or stripped.endswith("},"):
                if not any(m in entry[0] for m in ARM_MARKERS):
                    out.extend(entry)
                entry = None
            continue
        if entry is not None:
            entry.append(ln)
            if stripped in ("}", "},"):
                if not any(m in x for x in entry for m in ARM_MARKERS):
                    out.extend(entry)
                entry = None
            continue
        out.append(ln)
    if entry:
        out.extend(entry)
    return NL.join(out)


if __name__ == "__main__":
    if len(sys.argv) < 2:
        raise SystemExit(__doc__)
    main(os.path.abspath(sys.argv[1]))
