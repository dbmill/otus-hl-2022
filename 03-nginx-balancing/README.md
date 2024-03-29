## Д/з 3. Nginx - балансировка и отказоустойчивость

#### Цель:
Terraform и Ansible роль для развёртывания серверов веб-приложения под высокую нагрузку и отказоустойчивость.
В работе должны применяться:
* keepalived,
* nginx,
* uwsgi/unicorn/php-fpm
* некластеризованная БД MySQL/MongoDB/Postgres/Redis

#### Для сдачи:
* terraform манифесты
* ansible роль
* README файл

### Архитектура решения
* 2 front-end сервера (nginx) с VIP на keepalived;
* 2 back-end сервера (php-fpm)
* 1 сервер СУБД MySQL

#### Проверка
`curl http://192.168.56.4`
```
Front-end: fe1
Back-end: be1
MySQL version: 8.0.26
Connection id: 15
```

При повторных вызовах чередуется Back-end, при переключении VIP меняется Front-end.

#### Проблемы и их решение, в порядке возникновения
1. Vagrant вместо Terraform, т.к. Yandex Cloud не поддерживает VRRP.
2. Нужно предварительно скачать в $HOME образ generic-centos8-virtual-4.2.6.box.
3. Работе VRRP мешает firewall, поэтому его отключаем. Иначе оба keepalived переходят в режим MASTER.
4. SELinux препятствует запуску php-fpm на порту 11211, поэтому отключён.
