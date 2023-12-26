## Cценарий для удаления устройства
Тестовый скрипт для отказа в подключении устройства

В примере использовался 
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
- Создать udev-правило проверки параметров устройств для вызова сценария удаления устройства, например, в файле /etc/udev/rules.d/99-local.rules:
```
ACTION=="add", ENV{ID_BUS}=="usb", ENV{DEVTYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"
```
Данное правило при добавлении (ACTION=="add") устройств USB (ENV{ID_BUS}=="usb") типа disk (ENV{DEVTYPE}=="disk") вызывает сценарий удаления (/usr/sbin/astra-mount), передавая вызываемому сценарию путь к устройству ($devpath).


## Создание правила блокировки
```bash
vim /etc/udev/rules.d/99-usb-block.rules
```
~ Старый вариант
```
ACTION!="add", GOTO="dont_remove_usb"
ENV{ID_BUS}!="usb", GOTO="dont_remove_usb"
ENV{ID_TYPE}=="cd", RUN+="/usr/sbin/astra-mount $devpath"
ENV{ID_TYPE}!="disk", GOTO="dont_remove_usb"
ENV{ID_BUS}=="usb", RUN+="/usr/sbin/astra-mount $devpath"
LABEL="dont_remove_usb"
```

Новый вариант

```
ACTION!="add", GOTO="dont_remove_usb"

ENV{ID_TYPE}=="cd", RUN+="/usr/sbin/astra-mount $devpath"
ENV{ID_BUS}=="usb", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"
ENV{ID_BUS}=="ata", ENV{ID_TYPE}=="disk", RUN+="/usr/sbin/astra-mount $devpath"

LABEL="dont_remove_usb"
```