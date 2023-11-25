#!/bin/bash
echo $VOLUME_ID 
HOST_IP=`cat /hostmetadata/hostlocalip | xargs`
echo $HOST_IP
echo "running reconfig"
mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "cf=rs.conf();cf.members[$RS_INDEX].priority=0;rs.reconfig(cf,{force:true})" 
echo 'set priority to 0, sleep 60s..'
sleep 30
echo "running shutdown server"
mongo "mongodb://$MONGO_INITDB_ROOT_USERNAME:$MONGO_INITDB_ROOT_PASSWORD@$DB_HOST/admin?authSource=admin" --eval "db.shutdownServer({force:true})"
# sleep 15
# ssh -i /sshdb-key.pem -oStrictHostKeyChecking=no ec2-user@$HOST_IP "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws ec2 detach-volume --force --volume-id $VOLUME_ID"
# sleep 15
currentInstanceType=`cat /hostmetadata/instanceType | xargs`
if [  "$currentInstanceType" = "$INSTANCE_TYPE" ];
then
    echo "Using same instance type $currentInstanceType $INSTANCE_TYPE";
else
    echo "Using new instance type $currentInstanceType $INSTANCE_TYPE, Replacing first";
    ssh -i /sshdb-key.pem -oStrictHostKeyChecking=no ec2-user@$HOST_IP "sudo shutdown now";
    exit 1
fi

ssh -i /sshdb-key.pem -oStrictHostKeyChecking=no ec2-user@$HOST_IP "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws ec2 attach-volume --volume-id $VOLUME_ID --instance-id \`ec2-metadata --instance-id | cut -d: -f2 | xargs \` --region $AWS_DEFAULT_REGION --device /dev/sdf || true && sleep 5 && sudo mount /dev/sdf /data/db";
# sleep 15
# check if volume is mouted correctly
InsatnceID=`ssh -i /sshdb-key.pem -oStrictHostKeyChecking=no ec2-user@$HOST_IP "ec2-metadata --instance-id | cut -d: -f2 | xargs"`;
AttachedInstanceID=`ssh -i /sshdb-key.pem -oStrictHostKeyChecking=no ec2-user@$HOST_IP "AWS_ACCESS_KEY_ID=$AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY=$AWS_SECRET_ACCESS_KEY aws ec2 describe-volumes --volume-ids $VOLUME_ID --output text --query 'Volumes[0].Attachments[0].InstanceId'"`
echo $InsatnceID $AttachedInstanceID
if [ "$AttachedInstanceID" =  "$InsatnceID" ];
then
    source reconfigrs.sh &
    source docker-entrypoint.sh "$@";
else
    echo "Volume not attached exit"
    exit 1
fi