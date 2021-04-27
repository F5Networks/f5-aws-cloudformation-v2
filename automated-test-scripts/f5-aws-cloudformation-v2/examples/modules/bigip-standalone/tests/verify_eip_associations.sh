#  expectValue = "EIP ASSOCIATIONS PASSED"
#  scriptTimeout = 3
#  replayEnabled = false

# Script Requires min BASH Version 4
# usage: verify_eip_association eip_stack_output associative_array
function verify_eip_association() {
    local -n _arr=$2
    for r in "${_arr[@]}";
    do
        if echo "$1" | grep -q "$r"; then
            eip_result="eipAssociation:${r}:PASSED"
        else
            eip_result="eipAssociation:${r}:FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${eip_result}${spacer}"
    done
    echo "$results"
}


eip_stack_output=$(aws cloudformation describe-stack-resources --region <REGION> --stack-name <STACK NAME> | jq -c .StackResources[].LogicalResourceId)
echo $eip_stack_output

case <PRIVATE IP TYPE> in
STATIC)
    declare -a eipAssociation=("BigipVipEipAssociation" "BigipVipEipAssociation1")  ;;
DYNAMIC)
    case <NUM SECONDARY PRIVATE IP> in
    1)
        declare -a eipAssociation=("BigipVipEipAssociation" "BigipVipEipAssociation1") ;;
    2)
        declare -a eipAssociation=("BigipVipEipAssociation" "BigipVipEipAssociation1" "BigipVipEipAssociation2") ;;
    3)
        declare -a eipAssociation=("BigipVipEipAssociation" "BigipVipEipAssociation1" "BigipVipEipAssociation2" "BigipVipEipAssociation3") ;;
    4)
        declare -a eipAssociation=("BigipVipEipAssociation" "BigipVipEipAssociation1" "BigipVipEipAssociation2" "BigipVipEipAssociation3" "BigipVipEipAssociation4") ;;
    *)
        declare -a eipAssociation ;;
    esac ;;
esac

if [[ '<PUBLIC IP>' == 'true' ]]; then
    eipAssociation+=("BigipManagementEipAssociation")
fi
# Run array's through function
spacer=$'\n============\n'
response=$(verify_eip_association "${eip_stack_output}" "eipAssociation")
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "EIP ASSOCIATIONS PASSED ${spacer}${response}"
fi