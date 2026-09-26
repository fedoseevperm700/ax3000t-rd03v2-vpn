# OpenWrt для Xiaomi AX3000T RD03V2 + AmneziaWG 3.1 + Podkop

Сборка прошивки для **ревизии RD03V2** (Qualcomm IPQ5018). Проверка ревизии: штрихкод на коробке заканчивается на **706330**, SKU **DVB4510CN**, стоковая прошивка версии 2.0.x.

> ⚠️ На AX3000T RD03/RD23 (MediaTek) эта прошивка не подходит — это другое железо, роутер не загрузится.

## Что внутри

| Компонент | Версия |
| --- | --- |
| Основа | порт [ADCDS/openwrt-xiaomi-ax3000t-rd03v2](https://github.com/ADCDS/openwrt-xiaomi-ax3000t-rd03v2) @ `9e1d2d4`, OpenWrt snapshot, ядро 6.12.94 |
| AmneziaWG | [maksimkurb/awg-openwrt](https://github.com/maksimkurb/awg-openwrt) v25.12.5: kmod v3.1.20260906, tools v3.1.20260812, luci-proto v3.1.1 |
| Podkop | [itdoginfo/podkop](https://github.com/itdoginfo/podkop) 0.7.22 + sing-box 1.14.0 (без Tailscale и gVisor) |
| Интерфейс | LuCI на русском |
| Настройки первого запуска | часовой пояс Asia/Yekaterinburg, перезагрузка каждый день в 05:00 |

Зачем своя сборка: порт RD03V2 собран из тестовой ветки OpenWrt, и модули ядра (AmneziaWG) нельзя поставить потом из интернета — они обязаны собираться вместе с прошивкой.

## Как собрать на GitHub

1. Создайте на GitHub **публичный** репозиторий (у публичных сборка идёт на 4 ядрах и бесплатно; секретов здесь нет).
2. Загрузите в него все файлы этого проекта, включая папку `.github`.
3. Откройте вкладку **Actions** → слева **«Сборка прошивки AX3000T RD03V2»** → **Run workflow**.
4. Сборка идёт **2–3 часа**. Когда закончится, прошивка появится во вкладке **Releases**.

Если сборка упадёт — скачайте артефакт `build-logs` со страницы запуска.

## Файлы в релизе

- `…-initramfs-uImage.itb` — загружается в память по TFTP (через UART). Из неё выполняется запись.
- `…-squashfs-sysupgrade.bin` — основная прошивка. Записывается командой `sysupgrade -n` **только из initramfs**, никогда из уже установленной системы.
- `sha256sums.txt` — контрольные суммы.
- `build.config` — полная конфигурация сборки.

Порядок прошивки (UART, TFTP-восстановление с `recovery.bin` 2.0.28, загрузка в RAM, запись в NAND) — в README порта ADCDS.

## Локальная проверка без компиляции

```sh
PREPARE_ONLY=1 ./build-custom.sh
```

Скачает исходники, подключит фиды и проверит, что все пакеты из `config/required-packages.txt` попали в образ.

## Структура

- `build-custom.sh` — вся логика сборки, версии зафиксированы в начале файла.
- `config/custom.config` — добавляемые пакеты.
- `config/required-packages.txt` — что обязано оказаться в прошивке.
- `files/` — файлы, которые кладутся в образ как есть (`uci-defaults` для первого запуска).
- `.github/workflows/build.yml` — сборка на GitHub Actions.
