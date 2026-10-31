#!/bin/sh
# 用法: cd /tmp/repo && sh build.sh
# 扫描 debs/<子目录>/*.deb，从 control 重建 Packages / Packages.gz / Release
# 目录名改了就同步改下面 REL，保持一致即可
REL=debs/a7c9c483
cd "$(dirname "$0")" || exit 1
set -e
: > Packages
find debs -name '*.deb' | while read -r deb; do
  tmp=$(mktemp -d)
  ( cd "$tmp" && ar x "$OLDPWD/$deb" )
  ctl=""
  for f in "$tmp"/control.tar.*; do
    [ -f "$f" ] || continue
    case "$f" in
      *.xz)  tar xJf "$f" -C "$tmp" ;;
      *.gz)  tar xzf "$f" -C "$tmp" ;;
      *.zst) tar --zstd -xf "$f" -C "$tmp" ;;
      *)     tar xf "$f" -C "$tmp" ;;
    esac
  done
  ctl=$(find "$tmp" -maxdepth 3 -name control | head -1)
  rg -v '^(Filename|Size|SHA256|MD5sum):' "$ctl" >> Packages
  echo "Filename: $deb" >> Packages
  echo "Size: $(stat -c %s "$deb")" >> Packages
  echo "SHA256: $(sha256sum "$deb" | cut -d' ' -f1)" >> Packages
  echo "" >> Packages
  rm -rf "$tmp"
  echo "  + $deb"
done
gzip -9 -n -c Packages > Packages.gz
sed -i '/^Date:/d' Release
echo "Date: $(date -u '+%a, %d %b %Y %H:%M:%S UTC')" >> Release
echo "完成: $(rg -c '^Package: ' Packages 2>/dev/null || echo 0) 个包"
