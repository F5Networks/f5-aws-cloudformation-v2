#  expectValue = "PASS"
#  scriptTimeout = 2
#  replayEnabled = true
#  replayTimeout = 5

flag=PASS
buckets=$(aws s3api list-buckets --query "Buckets[].Name" | jq -r .[] | grep -w "<DEWPOINT JOB ID>")
for bucket_name in $buckets
do
    OUTPUT=$(aws s3 rm --region <REGION> s3://"$bucket_name" --recursive 2>&1)
    echo '------'
    echo "OUTPUT = $OUTPUT"
    echo '------'
    if grep -q delete: <<< "$OUTPUT" ; then
         flag=PASS
    else
         echo FAILED
    fi
done
echo $flag
