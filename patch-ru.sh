#!/usr/bin/env bash
# Патчит bin456789/reinstall для серверов в РФ, где GitHub raw, *.ubuntu.com,
# dl-cdn.alpinelinux.org и qualcomm.cn недоступны или режутся.
#
# Использование:
#   ./patch-ru.sh [SRC_DIR] [OUT_DIR]
#   SRC_DIR — где лежат оригинальные reinstall.sh и trans.sh (по умолчанию ./upstream)
#   OUT_DIR — куда положить пропатченные (по умолчанию ./dist)
#
# Что меняется:
#   reinstall.sh
#     - confhome -> зеркало автора на cnb.cool
#     - проверка страны не ходит в сеть (считаем RU)
#     - Alpine (netboot + apk) -> mirror.yandex.ru
#     - Ubuntu cloud images / releases -> mirror.yandex.ru
#     - trans.sh берётся из папки рядом со скриптом, а не скачивается
#   trans.sh
#     - в новой Ubuntu apt переключается на mirror.yandex.ru (archive + security)
set -euo pipefail

src=${1:-upstream}
out=${2:-dist}
mkdir -p "$out"
cp "$src/reinstall.sh" "$out/reinstall.sh"
cp "$src/trans.sh" "$out/trans.sh"

YA=mirror.yandex.ru

# Заменяет литеральную строку $2 на $3 в файле $1; падает, если вхождений не ровно $4 (по умолчанию 1).
replace() {
    local file=$1 from=$2 to=$3 want=${4:-1} n
    n=$(FROM=$from perl -ne '$n++ while /\Q$ENV{FROM}\E/g; END { print $n+0 }' "$file")
    if [ "$n" != "$want" ]; then
        echo "FAIL $file: '$from' найдено $n раз, ожидалось $want" >&2
        exit 1
    fi
    FROM=$from TO=$to perl -pi -e 's/\Q$ENV{FROM}\E/$ENV{TO}/g' "$file"
    echo "ok   $file: $from"
}

r=$out/reinstall.sh
t=$out/trans.sh

replace "$r" \
    'confhome=https://raw.githubusercontent.com/bin456789/reinstall/main' \
    'confhome=https://cnb.cool/bin456789/reinstall/-/git/raw/main'

replace "$r" \
    '    if [ -z "$_loc" ]; then' \
    '    _loc=${_loc:-RU}
    if [ -z "$_loc" ]; then'

replace "$r" \
    'mirror=http://dl-cdn.alpinelinux.org/alpine/v$releasever' \
    "mirror=http://$YA/mirrors/alpine/v\$releasever"

replace "$r" \
    'mirror=https://dl-cdn.alpinelinux.org/alpine' \
    "mirror=http://$YA/mirrors/alpine"

replace "$r" \
    'ci_mirror=https://cloud-images.ubuntu.com' \
    "ci_mirror=https://$YA/ubuntu-cloud-images"

replace "$r" \
    '"x86_64") mirror=https://releases.ubuntu.com/$releasever ;;' \
    "\"x86_64\") mirror=https://$YA/ubuntu-releases/\$releasever ;;"

replace "$r" \
    'curl -Lo $initrd_dir/trans.sh $confhome/trans.sh' \
    'cp "$(dirname "$THIS_SCRIPT")/trans.sh" $initrd_dir/trans.sh'

# trans.sh: в modify_ubuntu всегда менять apt-источники на Яндекс
replace "$t" \
    "sed -i 's/archive.ubuntu.com/mirror.nju.edu.cn/' \$file # x64" \
    "sed -i 's#//archive.ubuntu.com#//$YA#; s#//security.ubuntu.com#//$YA#' \$file # x64"

# Условие "if is_in_china" прямо над этим блоком — только внутри modify_ubuntu
perl -0pi -e 's/(modify_ubuntu\(\) \{.*?# 更改源\n\s*)if is_in_china; then/${1}if true; then/s or die "modify_ubuntu condition not found\n"' "$t"
echo "ok   $t: modify_ubuntu -> if true"

# bash 3.2 (macOS) не понимает `|&` из оригинала, поэтому проверяем только на bash 4+
if [ "${BASH_VERSINFO[0]}" -ge 4 ]; then
    bash -n "$r"
    bash -n "$t"
else
    echo "skip bash -n: bash $BASH_VERSION слишком старый"
fi
chmod +x "$r"
echo "Готово: $out/reinstall.sh + $out/trans.sh"
