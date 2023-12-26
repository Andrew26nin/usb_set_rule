#!/bin/bash

# Файл для записи серийных номеров
output_file="./serial_numbers"

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
	if echo $line | grep -q 'UDEV.*add.*sd[b-z][0-9]*'; then
		# Извлекаем имя устройства
		device=$(echo $line | awk '{print $4}' | awk -F'/' '{print $NF}')
		on_usb_connect "/dev/$device"
	fi
done
