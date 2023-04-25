## Курсовой проект
### Отказоустойчивый сайт Mediawiki

#### Задача:
Цель:
* реализовать терраформ для разворачивания одной виртуалки в yandex-cloud
* запровиженить nginx с помощью ansible

Для сдачи:
* репозиторий с терраформ манифестами
* README файл
#### Pre-requisites
В ~/.ssh/ должен быть ключ, тип не важен.
#### Проблемы и их решение, в порядке возникновения
1. Репозитарий PHP: https://vault.centos.org/centos/8/AppStream/x86_64/os/Packages/
2. Чтобы обойти ошибку "bash: No such file or directory" от 'ssh -o ProxyJump=...' из-под screen, прописать "shell /bin/bash" в ~/.screenrc (вместо "shell -bash"). (https://stackoverflow.com/questions/64893355/the-hard-way-to-debug-the-mysterious-gitsshproxy-failure-bash-no-such-file-o)
3. Inventory полагается на DNS в Yandex Cloud (x.y.z.2).