# mongo-sharding

## Как запустить

Запускаем config server и шарды:

```shell
docker compose up configSrv shard1 shard2
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

Инициализируйте шарды:

```shell
docker exec -it shard1 mongosh --port 27018

> rs.initiate(
{
_id : "shard1",
members: [
{ _id : 0, host : "shard1:27018" },
// { _id : 1, host : "shard2:27019" }
]
}
);
> exit();

docker exec -it shard2 mongosh --port 27019

> rs.initiate(
{
_id : "shard2",
members: [
// { _id : 0, host : "shard1:27018" },
{ _id : 1, host : "shard2:27019" }
]
}
);
> exit();
```

Запускаем роутер:

```shell
docker-compose up mongos_router -d
```

Проверяем статус:

```shell
docker logs mongos_router
```

Инцициализируйте роутер и наполните его тестовыми данными:

```shell
docker exec -it mongos_router mongosh --host localhost --port 27020

> sh.addShard( "shard1/shard1:27018");
> sh.addShard( "shard2/shard2:27019");

> sh.enableSharding("somedb");
> sh.shardCollection("somedb.helloDoc", { "name" : "hashed" } )

> use somedb

> for(var i = 0; i < 1000; i++) db.helloDoc.insert({age:i, name:"ly"+i})

> db.helloDoc.countDocuments()
> exit();
```

Получится результат — 1000 документов.
Сделайте проверку на шардах:

```shell
docker exec -it shard1 mongosh --port 27018
> use somedb;
> db.helloDoc.countDocuments();
> exit();
```

Получится результат — 492 документа.
Сделайте проверку на втором шарде:

```shell
docker exec -it shard2 mongosh --port 27019
> use somedb;
> db.helloDoc.countDocuments();
> exit();
```

Получится результат — 508 документов.

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
