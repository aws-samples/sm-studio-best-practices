#!/bin/bash
set -e
# This script creates a snapshot of the user's root directory to a specific S3 bucket and the user profile name as the prefix. 
# For instructions and use case, see Option 2: Back up from existing EFS using S3 and lifecycle configuration in the best practices documentation here: https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/appendix.html#sagemaker-studio-domain-backup-and-recovery
# Note: This should be created as a JupyterServer LCC configuration. If created as a KernelGateway LCC, the script will fail.
# S3 sync creates a snapshot of the data when the LCC is run, and is not a real time backup. Run the sync.sh as a cron job if you wish to keep the s3 bucket synced in near real-time.
# You can use the restore-lcc.sh to copy the S3 bucket contents to each user profile's home directory in a newly created domain.
mkdir -p .backup
cat << "EOF1" > /home/sagemaker-user/.backup/sync.sh
#!/bin/bash
BUCKET=sagemaker-domain-backup
PREFIX=domain-backup
cat > get-user-profile.py << EOF
import json
with open("/opt/ml/metadata/resource-metadata.json", "r") as f:
    app_metadata = json.loads(f.read())
    sm_user_profile_name = app_metadata["UserProfileName"]
    print(sm_user_profile_name)
EOF
echo "Checking if s3://${BUCKET} exists..."
aws s3api wait bucket-exists --bucket $BUCKET || (echo "s3://${BUCKET} does not exist, creating..."; aws s3 mb s3://${BUCKET})

USER_PROFILE_NAME=`python get-user-profile.py`
TIMESTAMP=`date +%F-%H-%M-%S`
/opt/conda/bin/aws s3 sync --exclude "*/lost+found/*" /home/sagemaker-user/ s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME}
echo "data synced at ${TIMESTAMP}"
EOF1

chmod +x /home/sagemaker-user/.backup/sync.sh

nohup /home/sagemaker-user/.backup/sync.sh >>  /home/sagemaker-user/.backup/nohup.out 2>&1 &