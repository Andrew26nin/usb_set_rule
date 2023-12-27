#!/bin/bash

udevadm monitor --udev --subsystem-match=block | while read -r line; do
	# Проверяем, что это событие подключения
	if echo $line | grep -q 'UDEV.*add.*s[b-z][0-9]*'; then
		# Извлекаем имя устройства
		device=$(echo $line | awk '{print $4}' | awk -F'/' '{print $NF}')
		echo "$device"
	fi
done
