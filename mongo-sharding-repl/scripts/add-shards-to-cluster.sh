#!/bin/bash

echo "Checking mongos availability..."
until docker compose exec mongos_router mongosh --port 27020 --eval "db.adminCommand('ping')" > /dev/null 2>&1; do
    echo "Waiting for mongos..."
    sleep 5
done

echo "Mongos is available"

docker compose exec -T mongos_router mongosh --port 27020 <<EOF
try {
    var currentShards = sh.status();
} catch (e) {
    print('No shards status yet: ' + e.message);
}

try {
    var shardsList = db.adminCommand('listShards');
    if (shardsList.shards && shardsList.shards.length > 0) {
        shardsList.shards.forEach(function(shard) {
            print(' - ' + shard._id + ': ' + shard.host);
        });
        quit(0);
    }
} catch (e) {
    print('No shards found, proceeding with addition');
}

try {
    var result1 = sh.addShard("shard1/shard1-master:27018,shard1-slave1:27018,shard1-slave2:27018");
} catch (e) {
    try {
        var result1 = db.adminCommand({
            addShard: "shard1/shard1-master:27018"
        });
    } catch (e2) {
        print('Alternative method failed: ' + e2.message);
    }
}

sleep(5000);

try {
    var result2 = sh.addShard("shard2/shard2-master:27019,shard2-slave1:27019,shard2-slave2:27019");
} catch (e) {
    try {
        var result2 = db.adminCommand({
            addShard: "shard2/shard2-master:27019"
        });
    } catch (e2) {
        print('Alternative method failed: ' + e2.message);
    }
}

sleep(5000);

try {
    var finalShards = db.adminCommand('listShards');
    if (finalShards.shards && finalShards.shards.length > 0) {
        finalShards.shards.forEach(function(shard) {
            print(' - ' + shard._id + ': ' + shard.host);
        });
    } else {
        print('No shards found after addition');
    }
} catch (e) {
    print('Error listing shards: ' + e.message);
}

try {
    print('Cluster status:');
    sh.status();
} catch (e) {
    print('Error getting cluster status: ' + e.message);
}

print('Shard addition process completed');
EOF
