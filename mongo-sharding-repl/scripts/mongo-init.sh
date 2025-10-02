#!/bin/bash

docker compose exec -T mongos_router mongosh --port 27020 <<EOF

try {
    use somedb;
    db.dummy.insertOne({created: new Date()});
} catch (e) {
    print('Error creating database: ' + e.message);
}

try {
    sh.enableSharding("somedb");
} catch (e) {
    print('Error enabling sharding: ' + e.message);
}

try {
    db.createCollection("helloDoc");
} catch (e) {
    print('Collection may already exist: ' + e.message);
}

try {
    sh.shardCollection("somedb.helloDoc", { "age": 1 });
} catch (e) {
    try {
        db.adminCommand({ shardCollection: "somedb.helloDoc", key: { age: 1 } });
    } catch (e2) {
        print('Alternative method also failed: ' + e2.message);
    }
}
EOF

docker compose exec -T mongos_router mongosh --port 27020 <<EOF

use somedb;

try {
    var stats = db.helloDoc.stats();
} catch (e) {
    try {
        db.createCollection("helloDoc");
    } catch (e2) {
        print('Cannot create collection: ' + e2.message);
        quit(1);
    }
}

for(var batch = 0; batch < 10; batch++) {
    var bulkOps = [];
    for(var i = batch * 100; i < (batch + 1) * 100; i++) {
        bulkOps.push({
            insertOne: {
                document: {
                    age: i,
                    name: "user_" + i,
                    timestamp: new Date(),
                    data: "Sample data for user " + i,
                    batch: batch
                }
            }
        });
    }

    try {
        db.helloDoc.bulkWrite(bulkOps);
    } catch (e) {
        print('Error inserting batch ' + (batch + 1) + ': ' + e.message);
    }
}

var totalCount = db.helloDoc.countDocuments();
print('Total documents inserted: ' + totalCount);

print('Data insertion completed!');
EOF

echo "MongoDB sharded cluster initialization finished!"