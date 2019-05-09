#!/bin/bash

###################################
# script's configuration
###################################

# how long to keep the snapshots
daysToKeep=14
# standard prefix for auto-generated snapshots
prefix="auto-generated-snapshot"

# please do not change the lines below!

# access information for the backup user
accessKey="$AWS_BACKUP_ACCESS_KEY"
secretKey="$AWS_BACKUP_SECRET_KEY"
region="$AWS_BACKUP_REGION"

if [[ -z  $region  ]]; then
    availabilityZone=$(wget -q -O - http://169.254.169.254/latest/meta-data/placement/availability-zone/);
    region=$(echo "$availabilityZone" | grep -oP "[a-z]{1,}-[a-z]{1,}-\\d{1,}");
fi

export JAVA_HOME="/usr/lib/jvm/jre"
export EC2_HOME="/opt/aws/apitools/ec2"
PATH=$PATH:/opt/aws/bin/

###################################
# generate a new snapshot
###################################

# get the instance id of the current machine
instance=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id);

# get the full information about the current instance
fullDescription=$(aws ec2 describe-instances --instance-ids "$instance" --region "$region" --output text);

# print the information
printf "Instance info:\n----------------------\n%s\n----------------------\n" "$fullDescription";
# get the name of the current instance
instanceDescription=$(echo "$fullDescription" | grep Name);
while read ignore1 ignore2 name; do
    instanceName="$name"
done <<< "$instanceDescription"

# get the volume ids
volumeIds=$(echo "$fullDescription" | awk '/vol-*/ {print $5}');

#get instance tags
instanceTags=$(echo "$fullDescription" | grep TAG);

# generate a timestamp
date=$(date +"%Y-%m-%d %H:%M:%S");
# create snapshots
while read -r volumeId; do

    # concatenate all information into one description
    description="$prefix - instanceName: $instanceName, instanceId: $instance, volumeId: $volumeId, time: $date";
    # create a new snapshot
    snapshotData=$(aws ec2 create-snapshot --description "$description" --region "$region" --volume-id "$volumeId" --output json);
    printf "Created snapshot:\n---------\n%s\n--------\n" "$snapshotData";

    #assign instance tags to the snapshot
    snapshotId=$(echo "$snapshotData" | grep -oP 'snap-[a-z0-9]+');

    tagsArgs="";
    while read -r ignore1 tagName tagValue; do
        if [ "$tagName" != "Name" ]; then # this is weird but name tagging doesn't work quite nice.
           tagsArgs="Key=$tagName,Value=$tagValue   $tagsArgs";
        fi
    done <<< "$instanceTags"

    eval aws ec2 create-tags --resources "$snapshotId" --region "$region" --tags "$tagsArgs";
done <<< "$volumeIds"

###################################
# remove old snapshots
###################################

# get all automatically generated snapshots
snapshots=$(aws ec2 describe-snapshots --region "$region" --output text --query 'Snapshots[*].{ID:SnapshotId,Time:StartTime,ZDesc:Description}'  --filters Name=description,Values="$prefix*");
# iterate through all snapshots
while read -r snapshot; do
    while read snapshotId timestamp snapshotDesc; do
        timestampSnapshot=$(date -d "$timestamp" "+%s");
        timestampCurrent=$(date +"%s");
        timestampDiff=$(( $timestampCurrent - $timestampSnapshot ));
        timestampDiffMax=$(( 60 * 60 * 24 * $daysToKeep  ));
        snapshotInstanceId=$(echo "$snapshotDesc" | grep -oP 'instanceId: (i-[a-z0-9]+),' | grep -oP 'i-[a-z0-9]+');

        # if the current snapshot is older than timestampDiffMax, delete it
        if [ "$instance" == "$snapshotInstanceId" ] && [ "$timestampDiff" -gt "$timestampDiffMax" ]
        then
            aws ec2 delete-snapshot --region "$region" --snapshot-id="$snapshotId"
        fi

    done <<< "$snapshot"
done <<< "$snapshots"
