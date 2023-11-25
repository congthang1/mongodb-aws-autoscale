#!/bin/bash
echo "RSINDEX";
if [ "$RS_INDEX" == "0" ]; then 
    echo "rs index catched";
    sleep 90
    echo "rs start initialize";
    mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf={_id:\"rs01\", version:1, members:[{_id:0, priority:3},{_id:1, priority:2},{_id:2, priority:1}]}; cf.members[0].host=\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME:27017\"; cf.members[1].host=\"$DB_NAME-02.$SERVICE_DISCOVERY_NAME:27017\"; cf.members[2].host=\"$DB_NAME-03.$SERVICE_DISCOVERY_NAME:27017\"; rs.initiate(cf);"
fi

