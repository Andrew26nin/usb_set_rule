#!/bin/bash

# Путь к файлу правил udev
udev_rules_file="/etc/udev/rules.d/99-usb-block.rules"
# Файл для записи серийных номеров
output_file="./serial_numbers"

# Проверяем, существует ли файл
if [ -f "$udev_rules_file" ]; then
	# Создаём бэкап с текущей датой и временем в названии
	backup_file="${udev_rules_file}.$(date +%Y%m%d%H%M%S).bak"
	mv "$udev_rules_file" "$backup_file"

	echo "Отключение правила блокирования USB. Бэкап создан: $backup_file"
	echo "Применени правила udev. Ожидайте 5 секунд..."
	udevadm control --reload-rules
	sleep 5
	udevadm trigger
	echo "Правило udev было успешно отключено"
else
	echo "Файл правила не существует. Бэкап не требуется."
fi

# Функция, которая будет вызываться при подключении USB-флешки
function on_usb_connect() {
	device=$1
	# Получаем серийный номер устройства
	serial=$(udevadm info --query=property --name=$device | grep ID_SERIAL_SHORT | cut -d'=' -f2)

	# Проверяем, удалось ли получить серийный номер
	if [ ! -z "$serial" ]; then
		echo ""
		echo "=> Устройство: $device, Серийный номер: $serial"
		# Проверяем, нет ли уже такого серийного номера в файле
		if ! grep -q "^$serial$" "$output_file" 2>/dev/null; then
			# Добавляем серийный номер в файл
			echo "$serial" >>"$output_file"
		else
			echo "Серийный номер $serial уже записан в файл."
		fi
	else
		echo "Не удалось получить серийный номер для устройства $device"
	fi
	echo "----------"
}

# Мониторим события udev для USB-флешек
udevadm monitor --udev --subsystem-match=block | while read -r line; do
	# Проверяем, что это событие подключения
	if echo $line | grep -q 'UDEV.*add.*s[b-z][0-9]*'; then
		# Извлекаем имя устройства
		device=$(echo $line | awk '{print $4}' | awk -F'/' '{print $NF}')
		on_usb_connect "/dev/$device"
	fi
done
