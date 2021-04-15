#  expectValue = "EIP CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = false

# Script Requires min BASH Version 4
# usage: verify_public_eip dag_stack_output associative_array
function verify_public_eip() {
    local -n _arr=$2
    for r in "${_arr[@]}";
    do
        if echo "$1" | grep -q "$r"; then
            eip_result="EIP:${r}:PASSED"
        else
            eip_result="EIP:${r}:FAILED"
        fi
        spacer=$'\n============\n'
        local results="${results}${eip_result}${spacer}"
    done
    echo "$results"
}


dag_stack_output=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> | jq .Stacks[0].Outputs)

case <NUM SECONDARY PRIVATE IP> in
1)
    declare -a publicEip=("bigIpManagementEipAddress01" "bigIpExternalEipAddress00" "bigIpExternalEipAddress01") ;;
2)
    declare -a publicEip=("bigIpManagementEipAddress01" "bigIpManagementEipAddress02" "bigIpExternalEipAddress00" "bigIpExternalEipAddress01" "bigIpExternalEipAddress02") ;;
3)
    declare -a publicEip=("bigIpManagementEipAddress01" "bigIpManagementEipAddress02" "bigIpManagementEipAddress03" "bigIpExternalEipAddress00" "bigIpExternalEipAddress01" "bigIpExternalEipAddress02" "bigIpExternalEipAddress03") ;;
4)
    declare -a publicEip=("bigIpManagementEipAddress01" "bigIpManagementEipAddress02" "bigIpManagementEipAddress03" "bigIpManagementEipAddress04" "bigIpExternalEipAddress00" "bigIpExternalEipAddress01" "bigIpExternalEipAddress02" "bigIpExternalEipAddress03" "bigIpExternalEipAddress04") ;;
*)
    declare -a publicEip ;;
esac


# Run array's through function
spacer=$'\n============\n'
response=$(verify_public_eip "${dag_stack_output}" "publicEip")
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "EIP CREATION PASSED ${spacer}${response}"
fi