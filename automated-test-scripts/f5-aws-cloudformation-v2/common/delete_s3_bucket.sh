#  expectValue = "PASS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 5

flag=PASS
buckets=$(aws s3api list-buckets --query "Buckets[].Name" | jq -r .[] | grep -w "<DEWPOINT JOB ID>")
for bucket_name in $buckets
do
    OUTPUT=$(aws s3 rb --region <REGION> s3://"$bucket_name" --force 2>&1)
    echo '------'
    echo "OUTPUT = $OUTPUT"
    echo '------'
    if grep -q remove_bucket: <<< "$OUTPUT" ; then
         flag=PASS
    else
         echo FAILED
    fi
done
echo $flag
