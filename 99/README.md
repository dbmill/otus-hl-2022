## Курсовой проект
### Отказоустойчивый сайт Mediawiki
#### Задача:
* Спроектировать отказоустойчивый сайт на движке Mediawiki;
* Построить его в Yandex Cloud;
* Автоматизировать развёртывание сайта с помощью манифестов Terraform и плейбуков Ansible.
#### Архитектура сайта
* Web-балансировщик Yandex Cloud с публичным адресом;
* 2 балансировщика HAProxy;
* 2 web-сервера nginx c приложением на php-fpm;
* кластер GlusterFS на 3 нодах - для кода и статики сайта;
* SQL-балансировщик Yandex Cloud (эту роль исполняли бы HAProxy, если бы YC поддерживал VRRP);
* 2 балансировщика ProxySQL;
* БД на Percona XtraDB Cluster из 3 нод;
* bastion-нода с публичным IP - для доступа к внутренним серверам извне.
Такая архитектура позволяет сайту сохранять работоспособность при отключении любого одного сервера на каждом уровне.
#### Pre-requisites
* В ~/.ssh/ должен быть ключ, тип не важен.
* Параметризовать WIKI-BAK/LocalSettings.php ($wgServer, $wgDBuser, $wgDBpassword).
* Репозитарий PHP: https://vault.centos.org/centos/8/AppStream/x86_64/os/Packages/, пакеты (см. 4web.yml) положить в ./PHP/
* Дистрибутив mediawiki-*.tar.gz положить в ./WIKI/
#### Проблемы и их решение, в порядке возникновения
2. Чтобы обойти ошибку "bash: No such file or directory" от 'ssh -o ProxyJump=...' из-под screen, прописать "shell /bin/bash" в ~/.screenrc (вместо "shell -bash"). (https://stackoverflow.com/questions/64893355/the-hard-way-to-debug-the-mysterious-gitsshproxy-failure-bash-no-such-file-o)
3. Inventory полагается на DNS в Yandex Cloud (x.y.z.2).
3. Не следует создавать здесь папки mysqlX, т.к. они будут удалены вместе с соответствующей нодой.