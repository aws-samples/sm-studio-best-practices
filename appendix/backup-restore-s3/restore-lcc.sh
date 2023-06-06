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