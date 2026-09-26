Прошивка OpenWrt для **Xiaomi AX3000T ревизии RD03V2** (Qualcomm IPQ5018, штрихкод на коробке заканчивается на 706330, SKU DVB4510CN).

**Не шейте на другие ревизии AX3000T** (RD03/RD23 на MediaTek) — это другое железо.

Файлы:
- `*-initramfs-uImage.itb` — загружается в память по TFTP через UART; с неё запускается запись.
- `*-squashfs-sysupgrade.bin` — основная прошивка; записывается командой `sysupgrade -n` **из initramfs**, не из установленной системы.
- `sha256sums.txt` — контрольные суммы.

Внутри: порт ADCDS/openwrt-xiaomi-ax3000t-rd03v2 (@9e1d2d4), AmneziaWG 3.1 (kmod v3.1.20260906, luci-proto-amneziawg v3.1.1), Podkop 0.7.22 + sing-box, LuCI на русском, часовой пояс Asia/Yekaterinburg, перезагрузка в 05:00.
