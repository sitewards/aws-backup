Automatic backups for AWS instances
===================================

This script provides functionality to create automatic snapshots of AWS EC2 instances and to rotate them by deleting the snapshots older than a given amount of days.

Usage:
------

1. Create an ec2 iam role (https://console.aws.amazon.com/iam/) having at least the following inline policy:
```
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "Stmt1403767721000",
            "Effect": "Allow",
            "Action": [
                "ec2:CopySnapshot",
                "ec2:CreateSnapshot",
                "ec2:DeleteSnapshot",
                "ec2:DescribeSnapshotAttribute",
                "ec2:DescribeSnapshots",
                "ec2:DescribeVolumeAttribute",
                "ec2:DescribeVolumeStatus",
                "ec2:DescribeVolumes",
                "ec2:DescribeInstances",
                "ec2:CreateTags"
            ],
            "Resource": [
                "*"
            ]
        }
    ]
}
```

2. Assign the role created above to the target server, alternative (this is way worse approach cause it might expose your AWS credential to general public):
Define following environment variables containing the credentials of the new user:
     - $AWS_BACKUP_ACCESS_KEY, i.e. AKIAIOSFODNN7EXAMPLE
     - $AWS_BACKUP_SECRET_KEY, i.e. ****************************************

3. Install the `aws cli` on the target server

4. By default the snapshots older than 30 days are deleted. If you want to change it, you can adjust the variable $daysToKeep at  the beginning of the script

5. Run and enjoy

6. If you want to run this script as a cron job, please add following line to the root's cronjobs (with your path to the script):

````
       01 01 * * * /bin/bash /home/ec2-user/aws-backup/aws-backup.sh
````
