#  expectValue = "LINK MATCH"
#  scriptTimeout = 3
#  replayEnabled = false
#  replayTimeout = 10


# verify that the template we are launching matches the template we are testing
test_link=<TEMPLATE URL>
if echo "<TEMPLATE URL>" | grep -q "existing-nework"; then
    launch_link=$(cat examples/quickstart/README.md | grep -Eo 'href="[^\"]+"' |  grep -Eo '(https)://f5-cft-v2[^"]+')
else 
    launch_link=$(cat examples/quickstart/README.md | grep -Eo 'href="[^\"]+"' |  grep -Eo '(https)://f5-cft-v2[^"]+')
fi

echo "Test link: $test_link"
echo "Launch link: $launch_link"

curl $test_link -o <DEWPOINT JOB ID>-test-template
curl $launch_link -o <DEWPOINT JOB ID>-launch-template

if diff -q <DEWPOINT JOB ID>-test-template <DEWPOINT JOB ID>-launch-template &>/dev/null; then
    echo "LINK MATCH"
fi