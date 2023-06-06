mkdir -p .backup
cat << "EOF1" > /home/sagemaker-user/.backup/sync.sh
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
echo "Checking if s3://${BUCKET} exists..."
aws s3api wait bucket-exists --bucket $BUCKET || (echo "s3://${BUCKET} does not exist, creating..."; aws s3 mb s3://${BUCKET})

USER_PROFILE_NAME=`python get-user-profile.py`
TIMESTAMP=`date +%F-%H-%M-%S`
/opt/conda/bin/aws s3 sync --exclude "*/lost+found/*" /home/sagemaker-user/ s3://${BUCKET}/${PREFIX}/${USER_PROFILE_NAME}
echo "data synced at ${TIMESTAMP}"
EOF1

chmod +x /home/sagemaker-user/.backup/sync.sh

nohup /home/sagemaker-user/.backup/sync.sh >>  /home/sagemaker-user/.backup/nohup.out 2>&1 &