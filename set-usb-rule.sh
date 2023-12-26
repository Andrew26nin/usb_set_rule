#!/bin/bash

# Путь к файлу правил udev
udev_rules_file="/etc/udev/rules.d/99-usb-block.rules"
# Файл с серийными номерами
input_file="./serial_numbers"

# Проверяем, существует ли файл
if [ -f "$udev_rules_file" ]; then
  # Создаём бэкап с текущей датой и временем в названии
  backup_file="${udev_rules_file}.$(date +%Y%m%d%H%M%S).bak"
  cp "$udev_rules_file" "$backup_file"
  echo "Бэкап создан: $backup_file"
else
  echo "Файл правил не существует. Бэкап не требуется."
fi

# Создаём начало файла правил
echo 'ACTION!="add", GOTO="dont_remove_usb"' >"$udev_rules_file"

# Читаем серийные номера и добавляем соответствующие правила
while IFS= read -r serial; do
  echo "ENV{ID_SERIAL_SHORT}==\"$serial\", GOTO=\"dont_remove_usb\"" >>"$udev_rules_file"
done <"$input_file"

{
  # shellcheck disable=SC2016
  echo 'ENV{ID_TYPE}=="cd", RUN+="/usr/sbin/astra-mount $devpath"'
  # shellcheck disable=SC2016
  echo 'ENV{ID_BUS}=="usb", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"'
  # shellcheck disable=SC2016
  echo 'ENV{ID_BUS}=="ata", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"'
  echo 'LABEL="dont_remove_usb"'
} >>"$udev_rules_file"

echo "Правила udev были успешно записаны в файл $udev_rules_file."

echo "Применени правил udev..."
udevadm control --reload-rules
sleep 1
udevadm trigger
echo "Правила udev были успешно применены"
