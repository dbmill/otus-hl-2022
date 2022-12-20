## Урок 5. MySQL-кластер

#### Д/з:
Цель:
развернуть InnoDB или PXC (Percona XtraDB Cluster).

Для сдачи:
* terraform манифесты
* ansible роль
* README файл

#### Pre-requisites
* В ~/.ssh/ должен быть ключ, тип не важен.
* ansible-core 2.14.1, ansible 7.0.0
#### Проблемы и их решение, в порядке возникновения
1. Для выполнения задания выбран Percona XtraDB Cluster.
1. Чтобы dnf увидел пакет percona-xtradb-cluster, требуется отключить modular filtering для репозитария pxc-80.
2. Для подключения к MySQL через ProxySQL: sbuser/Otus321$
3. Создаётся БД otus и таблица cust с одной записью.
