#!/bin/bash

###################################
# script's configuration
###################################

# how long to keep the snapshots
daysToKeep=30
# standard prefix for auto-generated snapshots
prefix="auto-generated-snapshot"

# please do not change the lines below!

# access information for the backup user
accessKey="$AWS_BACKUP_ACCESS_KEY"
secretKey="$AWS_BACKUP_SECRET_KEY"
region="$AWS_BACKUP_REGION"

export JAVA_HOME="/usr/lib/jvm/jre"
export EC2_HOME="/opt/aws/apitools/ec2"
PATH=$PATH:/opt/aws/bin/

###################################
# generate a new snapshot
###################################

# get the instance id of the current machine
instance=$(wget -q -O - http://169.254.169.254/latest/meta-data/instance-id);

# get the full information about the current instance
fullDescription=$(ec2-describe-instances -O "$accessKey" -W "$secretKey" --region "$region" "$instance");

# print the information
printf "Instance info:\n----------------------\n%s\n----------------------\n" "$fullDescription";

# get the name of the current instance
instanceDescription=$(echo "$fullDescription" | grep Name);
while read ignore1 ignore2 ignore3 ignore4 name; do
    instanceName="$name"
done <<< "$instanceDescription"

# get the volume ids
volumeIds=$(echo "$fullDescription" | awk '/vol-*/ {print $3}');

#get instance tags
instanceTags=$(echo "$fullDescription" | grep TAG);

# generate a timestamp
date=$(date +"%Y-%m-%d %H:%M:%S");

# create snapshots 
while read -r volumeId; do

    # concatenate all information into one description
    description="$prefix - instanceName: $instanceName, instanceId: $instance, volumeId: $volumeId, time: $date";
    # create a new snapshot
    snapshotData=$(ec2-create-snapshot -O "$accessKey" -W "$secretKey" -d "$description" --region "$region" "$volumeId");
    printf "Created snapshot:\n---------\n%s\n--------\n" "$snapshotData";

    #assign instance tags to the snapshot
    snapshotId=$(echo "$snapshotData" | awk '/snap-*/ {print $2}');
    tagsArgs="";
    while read -r ignore1 ignore2 ignore3 tagName tagValue; do
        if [ "$tagName" != "Name" ]; then # this is weird but name tagging doesn't work quite nice.
           tagsArgs="--tag \"$tagName=$tagValue\" $tagsArgs";
	fi
    done <<< "$instanceTags"
    ec2-create-tags "$snapshotId" -O "$accessKey" -W "$secretKey" --region "$region" $tagsArgs;
done <<< "$volumeIds"

###################################
# remove old snapshots
###################################

# get all automatically generated snapshots
snapshots=$(ec2-describe-snapshots -O "$accessKey" -W "$secretKey" --region "$region" | grep "$prefix");

# iterate through all snapshots
while read -r snapshot; do
    while read ignore1 snapshotId ignore2 ignore3 timestamp ignore4; do

        timestampSnapshot=$(date -d "$timestamp" "+%s");
        timestampCurrent=$(date +"%s");
        timestampDiff=$(( $timestampCurrent - $timestampSnapshot ));
        timestampDiffMax=$(( 60 * 60 * 24 * $daysToKeep  ));

        # if the current snapshot is older than timestampDiffMax, delete it
        if [ "$timestampDiff" -gt "$timestampDiffMax" ]
        then
            ec2-delete-snapshot -O "$accessKey" -W "$secretKey" --region "$region" "$snapshotId"
        fi

    done <<< "$snapshot"
done <<< "$snapshots"
