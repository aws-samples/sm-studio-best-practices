domain_arn=arn:aws:sagemaker:<REGION>:<ACCOUNT_ID>:domain/<DOMAIN_ID>
experiments=`aws --region $REGION \
sagemaker list-experiments`
for row in $(echo "${experiments}" | jq -r '.ExperimentSummaries[] | @base64'); do
    _jq() {
     echo ${row} | base64 --decode | jq -r ${1}
    }

    exp_name=$(_jq '.ExperimentName')
    exp_arn=$(_jq '.ExperimentArn')

    echo "Tagging resource name: $exp_name and arn: $exp_arn with \"sagemaker:domain-arn=$domain_arn\""
    echo `aws sagemaker \
        add-tags \
        --resource-arn $exp_arn \
        --tags "Key=sagemaker:domain-arn,Value=$domain_arn" \
        --region $REGION`
    echo "Tagging done for: $exp_name"
    sleep 1
done