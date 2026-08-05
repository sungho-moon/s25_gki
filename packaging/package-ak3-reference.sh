#!/usr/bin/env bash
set -euo pipefail

root=/tmp/codex-gki-6.6.142
script_dir=/mnt/c/Users/Admin/Documents/Codex/2026-08-04/k-k-3/work/gki-6.6.142-attempt
template=$script_dir/restore/q/work/gki-device-id/original_v1
outputs=$script_dir/outputs
name=S25U-S938B-6.6.142-ReSukiSU-SUSFS-KMI-3030-AK3
destination=$outputs/$name
archive=$outputs/$name.zip
image=$root/resukisu-common-v2-6.6.142/arch/arm64/boot/Image
config=$root/resukisu-common-v2-6.6.142/.config

test -d "$template/META-INF"
test -x "$template/tools/magiskboot"
test -s "$image"
test "$(sha256sum "$image" | cut -d' ' -f1)" = \
  e4d2dad042b73636c0333bb8bfdb479de9000cfac41d3c0c053ad9e416b1b1da
test "$(sha256sum "$config" | cut -d' ' -f1)" = \
  c4e3c7a493f9fc15f7cb93d6d7a833f9f4cf0baaae9948e4d083742eebb39404
test ! -e "$destination"
test ! -e "$archive"

cp -a "$template" "$destination"
cp -f "$image" "$destination/Image"
cp -f "$config" "$destination/Image.config"
cp -f "$script_dir/anykernel-s25u-6.6.142-kmi3030.sh" "$destination/anykernel.sh"
cp -f "$script_dir/final-kmi3030-manifest.txt" "$destination/build-manifest.txt"
rm -f "$destination/tools/patch_android"
chmod 0755 "$destination/anykernel.sh"

bash -n "$destination/anykernel.sh"
test ! -e "$destination/tools/patch_android"
! grep -R -q 'patch_android\|Apply KPM' "$destination"

cd "$destination"
zip -q -r -9 "$archive" .
unzip -tq "$archive"
test "$(unzip -p "$archive" Image | sha256sum | cut -d' ' -f1)" = \
  e4d2dad042b73636c0333bb8bfdb479de9000cfac41d3c0c053ad9e416b1b1da
! unzip -Z1 "$archive" | grep -q 'patch_android'

sha256sum "$archive" "$destination/Image" "$destination/Image.config"
unzip -Z1 "$archive" | sort
