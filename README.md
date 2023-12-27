## Cценарий для удаления устройства


Для корректного удаления используется скрипт `/usr/sbin/astra-mount`
```bash
#!/bin/bash
 
l="/usr/bin/logger -s -t \"Astra-mount:\""
path="/sys$1"
 
while true ; do
    if [[ "$path" == "/sys/devices" ]] ; then
        $l "Remove option not found"
        exit 1
    fi
    if [ -f "$path/remove" ] ; then
        $l "Removing $path/remove"
        echo 1 > "$path/remove" || $l "Can not remove $path/remove"
        break
    fi
    path=`dirname "$path"`
done
```
Данный сценарий:
 - Получает в качестве единственного аргумента путь к устройству;
 - Последовательно ищет по полученному пути к устройству родительское устройство, поддерживающее операцию удаления;
 - Выполняет операцию удаления;

Пример работы:
 - Создать файл /usr/sbin/astra-mount со содержимым выше.
 - Ограничить доступ к созданному файлу и сделать созданный файл исполняемым:
```bash
sudo chmod +x,go-w /usr/sbin/astra-mount
```

## Создание правила блокировки
```bash
vim /etc/udev/rules.d/99-usb-block.rules
```

Текст файла /etc/udev/rules.d/99-usb-block.rules: 

```
ACTION!="add", GOTO="dont_remove_usb"

ENV{ID_SERIAL_SHORT}=="<СЕРИЙНЫЙ НОМЕР РАЗРЕШЕННОГО УСТРОЙСТВА>", GOTO="dont_remove_usb"

ENV{ID_TYPE}=="cd", RUN+="/usr/sbin/astra-mount $devpath"
ENV{ID_BUS}=="usb", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"
ENV{ID_BUS}=="ata", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"

LABEL="dont_remove_usb"

```

## Определение подключаемого устройства

Для определения имени подключаемого устройства (такое как `/dev/sdb`) используется команда:
```bash
udevadm monitor --udev --subsystem-match=block
``` 
Это запустит скрипт-мониторинг. При подключении устройства будет выводиться информация о подключении и данные устройства.
Для определения серийного номера (например для /dev/sdb):
```
udevadm info --query=property --name=/dev/sdb | grep ID_SERIAL_SHORT
```