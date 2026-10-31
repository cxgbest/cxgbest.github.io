#!/bin/sh
# 用法: cd /tmp/repo && sh build.sh
# 扫描 debs/*.deb，从 control 重建 Packages / Packages.gz / Release
cd "$(dirname "$0")" || exit 1
set -e
mkdir -p debs
: > Packages
for deb in debs/*.deb; do
  [ -f "$deb" ] || continue
  tmp=$(mktemp -d)
  ar x "$deb" control.tar.* --output="$tmp" 2>/dev/null || ar x "$deb"
  if [ -f control.tar.xz ]; then tar xJf control.tar.xz -C "$tmp"; fi
  if [ -f control.tar.gz ]; then tar xzf control.tar.gz -C "$tmp"; fi
  if [ -f control.tar.zst ]; then tar --zstd -xf control.tar.zst -C "$tmp"; fi
  ctrl=$(find "$tmp" -name control -maxdepth 3 | head -1)
  # 去掉旧的字段
  rg -v '^(Filename|Size|SHA256|MD5sum):' "$ctrl" >> Packages
  echo "Filename: $deb" >> Packages
  echo "Size: $(stat -c %s "$deb")" >> Packages
  echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)" >> Packages
  echo "" >> Packages
  rm -rf "$tmp"
done
gzip -9 -n -c Packages > Packages.gz
sed -i '/^Date:/d' Release
echo "Date: $(date -u '+%a, %d %b %Y %H:%M:%S UTC')" >> Release
echo "完成: $(rg -c '^Package: ' Packages || echo 0) 个包"
