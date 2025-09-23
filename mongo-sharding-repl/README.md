# mongo-sharding-repl

## Как запустить

Запускаем config server и шарды:

```shell
docker compose up configSrv shard1-master shard1-slave1 shard1-slave2 shard2-master shard2-slave1 shard2-slave2 pymongo_api
```

Проверяем config server:

```shell
docker exec -it configSrv mongosh --port 27017 --eval "rs.status()"
```

Если replica set не инициализирован (в логе будет сообщение - MongoServerError: no replset config has been received), выполняем:

```shell
docker exec -it configSrv mongosh --port 27017 --eval "
rs.initiate({
_id: \"config_server\",
configsvr: true,
members: [{ _id: 0, host: \"configSrv:27017\" }]
})
"
```

Подключаемся к shard1:

```shell
docker exec -it shard1-master mongosh --port 27018
```

Создаём набор реплик в командной оболочке mongosh:
```shell
> rs.initiate({_id: "shard1", members: [
{_id: 0, host: "shard1-master:27018"},
{_id: 1, host: "shard1-slave1:27018"},
{_id: 2, host: "shard1-slave2:27018"}
]})
> exit();
```

Подключаемся к shard2:

```shell
docker exec -it shard2-master mongosh --port 27019
```

Создаём набор реплик в командной оболочке mongosh:

```shell
> rs.initiate({_id: "shard2", members: [
{_id: 0, host: "shard2-master:27019"},
{_id: 1, host: "shard2-slave1:27019"},
{_id: 2, host: "shard2-slave2:27019"}
]})
> exit();
> ```

Даем права на выполнение:

```shell
chmod +x scripts/add-shards-to-cluster.sh scripts/mongo-init.sh
```

Инициализируйте шарды:

```shell
./scripts/add-shards-to-cluster.sh
```

Заполняем mongodb данными:

```shell
./scripts/mongo-init.sh
```

## Как проверить

### Если вы запускаете проект на локальной машине

Откройте в браузере http://localhost:8080

### Если вы запускаете проект на предоставленной виртуальной машине

Узнать белый ip виртуальной машины

```shell
curl --silent http://ifconfig.me
```

Откройте в браузере http://<ip виртуальной машины>:8080

## Доступные эндпоинты

Список доступных эндпоинтов, swagger http://<ip виртуальной машины>:8080/docs
