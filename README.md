Automatic backups for AWS instances
===================================

This script provides functionality to create automatic snapshots of AWS EC2 instances and to rotate them by deleting the snapshots older than a given amount of days.

Usage:
------

1. Create a new user (https://console.aws.amazon.com/iam/?#users) having at least following permissions:
     - CreateSnapshot
     - DeleteSnapshot
     - DescribeSnapshotAttribute
     - DescribeSnapshots
     - DescribeVolumeAttribute
     - DescribeVolumeStatus
     - DescribeVolumes
     - DescribeInstances
     - CreateTags

2. Define following environment variables containing the credentials of the new user:
     - $AWS_BACKUP_ACCESS_KEY, i.e. AKIAIOSFODNN7EXAMPLE
     - $AWS_BACKUP_SECRET_KEY, i.e. wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY

3. Define a new environment variable $AWS_BACKUP_REGION containing the region of your machine, i.e. "eu-west-1"

4. By default the snapshots older than 30 days are deleted. If you want to change it, you can adjust the variable $daysToKeep at  the beginning of the script

5. Run and enjoy

6. If you want to run this script as a cron job, please add following line to the root's cronjobs (with your path to the script):

````
       01 01 * * * export AWS_BACKUP_ACCESS_KEY="AKIAIOSFODNN7EXAMPLE" && export AWS_BACKUP_SECRET_KEY="wJalrXUtnFEMI/K7MDENG/bPxRfiCYEXAMPLEKEY" && export AWS_BACKUP_REGION="eu-west-1" &&  /bin/bash /home/ec2-user/aws-backup/aws-backup.sh
````
