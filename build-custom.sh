#!/usr/bin/env bash
# Сборка OpenWrt для Xiaomi AX3000T ревизии RD03V2 (Qualcomm IPQ5018)
# с AmneziaWG 3.1 и Podkop, встроенными прямо в прошивку.
#
# Основа — порт ADCDS/openwrt-xiaomi-ax3000t-rd03v2 (снапшот OpenWrt, ядро 6.12).
# Модули ядра должны собираться в том же проходе, что и прошивка:
# у снапшота нет совместимого репозитория kmod, поставить их потом не выйдет.
#
# Переменные окружения:
#   WORK=<каталог>      где собирать (по умолчанию ./work)
#   PREPARE_ONLY=1      только подготовить исходники и .config, без компиляции
#   JOBS=<n>            число потоков make (по умолчанию nproc)
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
WORK="${WORK:-$HERE/work}"

# --- зафиксированные версии (меняйте осознанно) -----------------------------
UPSTREAM_URL=https://github.com/ADCDS/openwrt-xiaomi-ax3000t-rd03v2.git
UPSTREAM_REF=9e1d2d477676a8573d8f423962e0293490da870b   # 2026-09-20, "release: verify IPQ5018 BDF inside every image"
AWG_URL=https://github.com/maksimkurb/awg-openwrt.git
AWG_REF=111a0f757a6e30c54d08c71a23459d7926444c36        # тег v25.12.5: kmod v3.1.20260906, tools v3.1.20260812, luci v3.1.1
PODKOP_URL=https://github.com/itdoginfo/podkop.git
PODKOP_REF=c0a2736bb95884c19fedf638345ed6148c5fd6af     # тег 0.7.22
PODKOP_VERSION=0.7.22
# ---------------------------------------------------------------------------

log() { printf '\n>>> %s\n' "$*"; }

mkdir -p "$WORK"
cd "$WORK"

if [ ! -d rd03v2/.git ]; then
	log "Клонирую порт RD03V2"
	git clone "$UPSTREAM_URL" rd03v2
fi
git -C rd03v2 checkout -q "$UPSTREAM_REF"
cd rd03v2

if [ ! -d openwrt ]; then
	log "Готовлю исходники OpenWrt через build.sh порта (PREPARE_ONLY)"
	PREPARE_ONLY=1 ./build.sh
else
	log "openwrt/ уже есть — пропускаю подготовку порта"
fi
cd openwrt

log "Подключаю фиды AmneziaWG и Podkop"
sed -i '/^src-git awg /d;/^src-git podkop /d' feeds.conf.default
{
	echo "src-git awg ${AWG_URL}^${AWG_REF}"
	echo "src-git podkop ${PODKOP_URL}^${PODKOP_REF}"
} >> feeds.conf.default
./scripts/feeds update awg podkop
./scripts/feeds install -a -p awg
./scripts/feeds install -a -p podkop

log "Добавляю свои файлы в образ (часовой пояс, язык, ночная перезагрузка)"
mkdir -p files
cp -a "$HERE/files/." files/
find files -type d -exec chmod 755 {} +
find files -type f -exec chmod 644 {} +
chmod 755 files/etc/uci-defaults/*

log "Дописываю конфигурацию пакетов"
cat "$HERE/config/custom.config" >> .config
make defconfig

log "Проверяю, что нужные пакеты попали в образ (=y)"
missing=""
while read -r pkg; do
	case "$pkg" in ''|\#*) continue ;; esac
	grep -q "^CONFIG_PACKAGE_${pkg}=y\$" .config || missing="$missing $pkg"
done < "$HERE/config/required-packages.txt"
if [ -n "$missing" ]; then
	echo "ОШИБКА: не попали в образ:$missing" >&2
	exit 1
fi
echo "Все обязательные пакеты на месте."

if [ "${PREPARE_ONLY:-0}" = "1" ]; then
	log "PREPARE_ONLY=1: исходники и .config готовы в $PWD, компиляцию пропускаю"
	exit 0
fi

export PODKOP_VERSION
JOBS="${JOBS:-$(nproc)}"

log "Скачиваю исходники пакетов"
make -j"$JOBS" download || make -j1 download V=s

log "Собираю прошивку ($JOBS потоков)"
if ! make -j"$JOBS"; then
	log "Параллельная сборка упала — повторяю в один поток с подробным логом"
	make -j1 V=s
fi

log "Готово: $PWD/bin/targets/qualcommax/ipq50xx/"
