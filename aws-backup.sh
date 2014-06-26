#!/bin/bash

# configuration
region="eu-west-1"
daysToKeep=30

# please do not change the ilnes below!

# access information for the backup user
accessKey="AKIAJH5BOPZATIIDIMWA"
secretKey="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"

###################################
# generate a new snapshot
###################################

# get the instance id of the current machine
instance=`wget -q -O - http://169.254.169.254/latest/meta-data/instance-id`

# get the name of the current instance
instanceDescription=`ec2-describe-instances -O $accessKey -W $secretKey --region $region $instance | grep Name`
while read ignore1 ignore2 ignore3 ignore4 name; do
  instanceName="$name";
done <<< $instanceDescription

# get the volume id
volume=`ec2-describe-instances -O $accessKey -W $secretKey --region $region $instance | awk '/vol-*/ {print $3}'`

# define a standard prefix
prefix="auto-generated-snapshot"

# generate a timestamp
date=`date +"%Y-%m-%d %H:%M:%S"`

# concatenate all information into one description
description="$prefix - instanceName: $instanceName, instanceId: $instance, volumeId: $volume, time: $date"

# stop mysql, create a snapshop and start it again
sudo /etc/init.d/mysqld stop
ec2-create-snapshot -O $accessKey -W $secretKey -d "$description" --region $region $volume
sudo /etc/init.d/mysqld start

###################################
# remove old snapshots
###################################

# get all automatically generated snapshots
snapshots="`ec2-describe-snapshots -O $accessKey -W $secretKey --region $region | grep "$prefix"`"

# iterate through all snapshots
while read -r snapshot; do
  while read ignore1 snapshotId ignore2 ignore3 timestamp ignore4; do
    timestampSnapshot=`date -d "$timestamp" "+%s"`;
    timestampCurrent=`date +"%s"`;
    timestampDiff=$(( $timestampCurrent - $timestampSnapshot ));
    timestampDiffMax=$(( 60 * 60 * 24 * $daysToKeep  ));

	# if the current snapshot is older than timestampDiffMax, delete it
    if [ "$timestampDiff" -gt "$timestampDiffMax" ]
    then
      ec2-delete-snapshot -O $accessKey -W $secretKey --region $region $snapshotId
    fi

  done <<< "$snapshot"
done <<< "$snapshots"