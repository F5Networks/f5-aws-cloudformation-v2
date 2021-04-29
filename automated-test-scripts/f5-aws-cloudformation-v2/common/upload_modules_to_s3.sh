#  expectFailValue = "UPLOAD_FAILED"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 5

echo "UPLOADING MODULES/DEPENDECIES TO S3 BUCKET"
bucket_name=`echo <STACK NAME>|cut -c -60|tr '[:upper:]' '[:lower:]'| sed 's:-*$::'`

# update this path once we move to a separate repo
artifact_location=$(cat /$PWD/examples/quickstart/quickstart.yaml | yq -r .Parameters.artifactLocation.Default)
echo "artifact_location=$artifact_location"

aws s3 cp --region <REGION> /$PWD/examples/ s3://"$bucket_name"/"$artifact_location" --recursive --exclude "/$PWD/f5-aws-cloudformation-v2/images/" --acl public-read 2>&1
