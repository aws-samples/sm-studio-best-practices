#!/bin/bash
set -e
# This script copies files in a user-specific directory in S3 to the user's root directory.
# If the user does not have a prefix in S3, the LCC skips the s3 sync and starts Studio for the user.
# For instructions and use case, see Option 2: Back up from existing EFS using S3 and lifecycle configuration in the best practices documentation here: https://docs.aws.amazon.com/whitepapers/latest/sagemaker-studio-admin-best-practices/appendix.html#sagemaker-studio-domain-backup-and-recovery
# Note: This should be created as a JupyterServer LCC configuration. If created as a KernelGateway LCC, the script will fail.
# S3 sync creates a snapshot of the data when the LCC is run, and is not a real time backup. Run the sync.sh as a cron job if you wish to keep the s3 bucket synced in near real-time.
mkdir -p .backup
cat << "EOF1" > /home/sagemaker-user/.backup/restore.sh
#!/bin/bash
# replace bucket name with your unique bucket
BUCKET=sagemaker-domain-backup
PREFIX=domain-backup
cat > get-user-profile.py << EOF
import json
with open("/opt/ml/metadata/resource-metadata.json", "r") as f:
    app_metadata = json.loads(f.read())
    sm_user_profile_name = app_metadata["UserProfileName"]
    print(sm_user_profile_name)
EOF
USER_PROFILE_NAME=`python get-user-profile.py`
echo "Checking if s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME} exists..."
aws s3 ls s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME} || (echo "Snapshot s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME} does not exist. Proceed without the sync."; exit 0)
TIMESTAMP=`date +%F-%H-%M-%S`
/opt/conda/bin/aws s3 sync s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME}/ /home/sagemaker-user/
echo "Data copied from S3"
EOF1

chmod +x /home/sagemaker-user/.backup/restore.sh

nohup /home/sagemaker-user/.backup/restore.sh >>  /home/sagemaker-user/.backup/nohup.out 2>&1 &