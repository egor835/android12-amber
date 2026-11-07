# android12-amber

Неофициальный порт **LineageOS 19.1 (Android 12L)** на **Яндекс.Телефон** (YNDX-000SB, кодовое имя `Amber`, Snapdragon 630).

Официальная поддержка Amber в LineageOS закончилась на 17.1, ветка 18.1 существовала, но так и не вышла. Здесь — дерево устройства и патчи, с которыми 19.1 собирается и загружается на ядре 4.4.

> ⚠️ Неофициальная сборка, всё на свой страх и риск. Перед прошивкой снимите полный бекап разделов.

## Статус

Работает (проверено на одном устройстве):

- звонки, SMS, мобильный интернет (LTE), Wi-Fi
- Bluetooth
- камера, звук, отпечаток пальца
- recovery (Lineage Recovery)

Известные проблемы и ограничения:

- **NFC**: метки не определяются (не проверено, работает ли на стоке на тестовом аппарате — возможно, аппаратная проблема).
- **eBPF**: ядро 4.4 не умеет того eBPF, на который рассчитан Android 12. `bpfloader` и `netd` пропатчены так, чтобы на ядрах младше 4.9 работать без BPF: учёт трафика идёт через `xt_qtaguid`, BPF-ускорения раздачи интернета нет. Правильное решение — бэкпорт eBPF в ядро.
- Экран загрузчика «Your device is corrupt» может появиться после сбоя dm-verity. Сбрасывается командой:
  ```
  adb shell "reboot 'dm-verity enforcing'"
  ```

## Что изменено

**Дерево устройства** (ветка [`lineage-19.1`](../../tree/lineage-19.1), поверх `lineage-18.1` из LineageOS):

- телефония на 18.1: убрано внедрение QTI-телефонии (блоб от Android 10 падает на 11+), из манифеста убран `radio.config`, который никто не обслуживает;
- bring-up 19.1: ELF-блобы в `PRODUCT_COPY_FILES`, NFC-конфиг в `/product`, камера HAL1 с `VANILLA_HAL`, строки для Doze, без дублирующихся свойств;
- интерфейсные HIDL-библиотеки (`*.vendor`), которые Android 12 убрал из VNDK — без них не стартуют keymaster/gatekeeper;
- `PRODUCT_COMPRESSED_APEX := false` — распакованные в `/data` APEX ломают dm-verity ядра 4.4;
- `uceservice` объявлен как 2.1 (IMS RCS-демон падал в цикле);
- оверлей tethering без BPF-offload.

**Патчи** (`patches/`):

| Каталог | Что |
|---|---|
| `kernel_yandex_sdm660` | сборка clang 12 (`dtc` yylloc, `stpcpy`, `qcacld` без `-Werror`), без dm-verity для `vendor` в DTS, `CONFIG_BPF_SYSCALL=y`, `CONFIG_RT_GROUP_SCHED` выключен (иначе Bluetooth не может получить RT-приоритет) |
| `vendor_yandex` | сертификат `TimeService`, без дубля `perf@1.0.so`, `check_elf_files: false` |
| `system_bpf` | `bpfloader` не загружает программы на ядрах < 4.9 |
| `system_netd` | `netd` не требует `TrafficController` на ядрах < 4.9 |

## Сборка

```bash
mkdir lineage-19.1 && cd lineage-19.1
repo init -u https://github.com/LineageOS/android.git -b lineage-19.1 --git-lfs
mkdir -p .repo/local_manifests
curl -L -o .repo/local_manifests/amber.xml \
  https://raw.githubusercontent.com/egor835/android12-amber/main/local_manifests/amber.xml
repo sync -c -j4

git clone https://github.com/egor835/android12-amber /tmp/android12-amber
/tmp/android12-amber/scripts/apply-patches.sh "$PWD"

source build/envsetup.sh
breakfast Amber
mka bacon
```

Собиралось в контейнере Ubuntu 20.04. Если AOSP-сервер ругается на `RESOURCE_EXHAUSTED`, синхронизируйте с меньшим `-j`.

Необязательно: положите свой публичный adb-ключ в `device/yandex/Amber/recovery/adb_keys` — тогда recovery и система будут сразу доверять вашему компьютеру (без «Enable ADB»).

## Установка

Загрузчик разблокируется на стоковой прошивке: `fastboot oem yandex_unlock` (fastboot загрузчика плохо работает с некоторыми USB-контроллерами под Linux — может понадобиться другой компьютер или порт).

Важно:

- **`vbmeta` на этом телефоне — сплошные нули** (AVB 1.0). Не прошивайте туда образы `avbtool`.
- Телефон A/B. Пакет из `mka bacon`, установленный через `adb sideload` в Lineage Recovery, записывается в **неактивный** слот и переключает на него.

Установка через recovery:

1. Загрузите Lineage Recovery: прошейте `boot.img` из сборки в текущий слот (`fastboot flash boot boot.img`), затем Громкость вверх + Питание.
2. *Apply update → Apply from ADB*, на компьютере: `adb sideload lineage-19.1-*-UNOFFICIAL-Amber.zip`.
3. *Factory reset → Format data*.
4. Перезагрузка. Первый запуск — несколько минут.

Если появился красный экран «corrupt» — подтвердите его, а после загрузки выполните команду из раздела «Статус».

## Благодарности

LineageOS, vm03 и HighwayStar — исходное дерево и ядро Amber; TheMuppets — проприетарные блобы.
