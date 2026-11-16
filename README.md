# reinstall-linux

Переустановка ОС на VPS в РФ через [bin456789/reinstall](https://github.com/bin456789/reinstall).
Оригинальный скрипт ходит на GitHub raw, `*.ubuntu.com`, `dl-cdn.alpinelinux.org` и `qualcomm.cn`,
а из РФ эти адреса режутся или открываются через раз. Патч переводит всё на зеркала, которые
из РФ отвечают: `mirror.yandex.ru` и `cnb.cool` (официальное зеркало автора).

Проверено 2026-11-16 на VPS в VK Cloud: Ubuntu 24.04 → Ubuntu 24.04, cloud image.

## Файлы

- `upstream/` — оригинальные `reinstall.sh` и `trans.sh` (commit `603ba80`, SCRIPT_VERSION `4BACD833-…0005`)
- `patch-ru.sh` — накладывает правки по шаблонам и падает, если какой-то шаблон не нашёлся
- `dist/` — готовые пропатченные `reinstall.sh` + `trans.sh`

## Использование

```bash
scp dist/reinstall.sh dist/trans.sh root@SERVER:/root/
ssh root@SERVER 'bash /root/reinstall.sh ubuntu 24.04'   # пустой пароль → сгенерирует случайный
ssh root@SERVER reboot
```

`trans.sh` должен лежать рядом с `reinstall.sh`: он вшивается в initrd из этой папки, а не скачивается.
Во время установки лог доступен по `http://SERVER/<web_path>`, путь скрипт печатает в конце.
Вся установка занимает около 5 минут. После неё поменяется ключ хоста (`ssh-keygen -R SERVER`),
а SSH-ключи в новую систему не переносятся: вход по паролю или через `--ssh-key`.

## Обновить на новую версию upstream

```bash
curl -fLo upstream/reinstall.sh https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
curl -fLo upstream/trans.sh     https://raw.githubusercontent.com/bin456789/reinstall/main/trans.sh
./patch-ru.sh
```

Патч рассчитан на Ubuntu (x86_64) и на сам загрузчик Alpine. Для других дистрибутивов
зеркала остаются оригинальными, их придётся добавить в `patch-ru.sh` отдельно.

## Лицензия

Скрипты из `upstream/` и `dist/` взяты из [bin456789/reinstall](https://github.com/bin456789/reinstall)
и распространяются под GPL-3.0 (см. `LICENSE`). Файлы в `dist/` изменены скриптом `patch-ru.sh`:
изменения перечислены в его шапке. Сам `patch-ru.sh` тоже распространяется под GPL-3.0.
