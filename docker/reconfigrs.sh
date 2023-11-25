#!/bin/bash
echo "RECONFIG";
echo "RSINDEX":$RS_INDEX;
sleep 30
counter=0;
currentInstanceType=`cat /hostmetadata/instanceType | xargs`
lastInstanceType=`cat /data/db/lastInstanceType | xargs || echo noinstance`
until [ $counter -gt 30 ]
do
    echo "Checking ready $counter";
    mongoready=`mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "db.runCommand(\"ping\").ok";`;
    readyText='UUID';
    if [[ "$mongoready" == *"$readyText"* ]]; then
        echo "Mongo is ready! Configuring replica";
        counter=100
        if [[ "$RS_INDEX" == "0" ]]; then 
            echo "rs index catched";
            if [[ "$NUMBER_REPLICA_INSTANCE" = "3" ]]; then 
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf={_id:\"rs01\", version:1, members:[{_id:0, priority:3},{_id:1, priority:2},{_id:2, priority:1}]}; cf.members[0].host=\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME:27017\"; cf.members[1].host=\"$DB_NAME-02.$SERVICE_DISCOVERY_NAME:27017\"; cf.members[2].host=\"$DB_NAME-03.$SERVICE_DISCOVERY_NAME:27017\"; rs.initiate(cf);";
                sleep 5
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();  cf.members[0].priority=3;cf.members[0].host=\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME\"; cf.members[1].priority=2;cf.members[1].host=\"$DB_NAME-02.$SERVICE_DISCOVERY_NAME\"; cf.members[2].priority=1;cf.members[2].host=\"$DB_NAME-03.$SERVICE_DISCOVERY_NAME\";rs.reconfig(cf,{force:true});";
            fi
            if [[ "$NUMBER_REPLICA_INSTANCE" = "2" ]]; then 
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf={_id:\"rs01\", version:1, members:[{_id:0, priority:3},{_id:1, priority:2},{_id:2, priority:1}]}; cf.members[0].host=\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME:27017\"; cf.members[1].host=\"$DB_NAME-02.$SERVICE_DISCOVERY_NAME:27017\"; rs.initiate(cf);";
                sleep 5
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();  cf.members=[{_id:0, host:\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME\", priority:3},{_id:1, host: \"$DB_NAME-02.$SERVICE_DISCOVERY_NAME\"  priority:2}]; rs.reconfig(cf,{force:true});";
            fi 
            if [[ "$NUMBER_REPLICA_INSTANCE" = "1" ]]; then 
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf={_id:\"rs01\", version:1, members:[{_id:0, priority:3}]}; cf.members[0].host=\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME:27017\"; rs.initiate(cf);";
                sleep 5
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf(); cf.members=[{_id:0, host:\"$DB_NAME-01.$SERVICE_DISCOVERY_NAME\", priority:3}]; rs.reconfig(cf,{force:true});";
            fi
        fi
        if [[ "$RS_INDEX" == "1" ]]; then 
            if [[ "$currentInstanceType" != "$lastInstanceType"  ]]; then
                echo $currentInstanceType > /data/db/lastInstanceType;
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();cf.members[$RS_INDEX].priority=5;rs.reconfig(cf,{force:true})";
                # sleep 30m
                # mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();cf.members[$RS_INDEX].priority=2;rs.reconfig(cf,{force:true})";
            else 
                mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();cf.members[$RS_INDEX].priority=$RS_PRIORITY;rs.reconfig(cf,{force:true})";
            fi
        else 
            mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();cf.members[$RS_INDEX].priority=$RS_PRIORITY;rs.reconfig(cf,{force:true})";
        fi  
    fi
  ((counter++));
  sleep 10
done

