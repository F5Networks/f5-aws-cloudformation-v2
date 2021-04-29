#!/usr/bin/env bash
#  expectValue = "ROUTE TABLE CREATION PASSED"
#  scriptTimeout = 3
#  replayEnabled = true
#  replayTimeout = 10

# Script Requires min BASH Version 4
# Script verifies route tables are created and subnets are appropratley associated
# usage: verify_rt vpc_id array
# Array: array=([subnet name]="index number for subnet in output array")
function verify_rt() {
    local -n _arr=$2
    for r in "${!_arr[@]}";
    do
        if echo "$r" | grep -q "subnet0"; then
            rt_output_key="publicSubnetRouteTableId"
        elif echo "<SUBNET1 PUBLIC>" | grep -q "true" && echo "$r" | grep -q "subnet1"; then
            rt_output_key="publicSubnetRouteTableId"
        elif echo "$r" | grep -q "A"; then
            rt_output_key="privateRouteTableIdA"
        elif echo "$r" | grep -q "B"; then
            rt_output_key="privateRouteTableIdB"
        elif echo "$r" | grep -q "C"; then
            rt_output_key="privateRouteTableIdC"
        elif echo "$r" | grep -q "D"; then
            rt_output_key="privateRouteTableIdD"
        else
            echo "Nothing matches for rt outputkey"
            break
        fi
        if echo "$r" | grep -q "A"; then
            subnet_output_key="subnetsA"
        elif echo "$r" | grep -q "B"; then
            subnet_output_key="subnetsB"
        elif echo "$r" | grep -q "C"; then
            subnet_output_key="subnetsC"
        elif echo "$r" | grep -q "D"; then
            subnet_output_key="subnetsD"
        else
            echo "Nothing Matches for subnet outputkey"
            break
        fi
        local rt_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> --query "Stacks[0].Outputs[?OutputKey=='${rt_output_key}'].OutputValue" | jq -r .[] )
        
        local subnet_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> --query "Stacks[0].Outputs[?OutputKey=='${subnet_output_key}'].OutputValue" | jq -r .[] | cut -d',' -f${_arr[$r]})

        local rt_response=$(aws ec2 describe-route-tables --region <REGION> --filters "Name=vpc-id,Values=${1}" | jq --arg tableId "${rt_id}" '.RouteTables[].Associations[] | select(.RouteTableId==$tableId) | .SubnetId')

        if echo "$rt_response" | grep -q "$subnet_id"; then
            rt_result="Table:${rt_output_key}:Subnet:${subnet_id}:PASSED"
        else
            rt_result="Table:${rt_output_key}:Subnet:${subnet_id}:FAILED:Response:${rt_response}"
        fi
        spacer=$'\n============\n'
        local results="${results}${rt_result}${spacer}"
    done
    echo "$results"
}

# Variables
## Verify vpc is the same as output id, then use it later
output_vpc_id=$(aws cloudformation describe-stacks --region <REGION> --stack-name <STACK NAME> --query "Stacks[0].Outputs[?OutputKey=='vpcId'].OutputValue" | jq -r .[])
vpc_id=$(aws ec2 describe-vpcs --region <REGION> --vpc-ids ${output_vpc_id} --filters "Name=tag:aws:cloudformation:logical-id,Values=vpc" | jq -r .Vpcs[].VpcId)
# Build associative subnet arrays
# Array: [subnet name]="index number for subnet in output array"
case <NUMBER AZS> in
1)
    case <NUMBER SUBNETS> in
    1)
        declare -A rt_created=( [subnet0A]="1" ) ;;
    2)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" ) ;;
    3)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" ) ;;
    4)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" ) ;;
    5)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" ) ;;
    6)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" ) ;;
    7)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" ) ;;
    8)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet7A]="8" ) ;;
    esac ;;
2)
    case <NUMBER SUBNETS> in
    1)
        declare -A rt_created=( [subnet0A]="1" [subnet0B]="1" ) ;;
    2)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet0B]="1" [subnet1B]="2" ) ;;
    3)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet0B]="1" [subnet1B]="2" \
        [subnet2B]="3" ) ;;
    4)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet0B]="1" \
        [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" ) ;;
    5)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet0B]="1" [subnet1B]="2" \
        [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" ) ;;
    6)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet0B]="1" \
        [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" [subnet5B]="6" ) ;;
    7)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" \
        [subnet5B]="6" [subnet6B]="7" ) ;;
    8)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet7A]="8" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" \
        [subnet4B]="5" [subnet5B]="6" [subnet6B]="7" [subnet7B]="8" ) ;;
    esac ;;
3)
    case <NUMBER SUBNETS> in
    1)
        declare -A rt_created=( [subnet0A]="1" [subnet0B]="1" [subnet0C]="1" ) ;;
    2)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet0B]="1" [subnet1B]="2" [subnet0C]="1" [subnet1C]="2" ) ;;
    3)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet0C]="1" \
        [subnet1C]="2" [subnet2C]="3"  ) ;;
    4)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" \
        [subnet3B]="4" [subnet0C]="1" [subnet1C]="2" [subnet2C]="3" [subnet3C]="4" ) ;;
    5)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet0B]="1" [subnet1B]="2" \
        [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" ) ;;
    6)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet0B]="1" \
        [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" [subnet5B]="6" \
        [subnet0C]="1" [subnet1C]="2" [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" \
        [subnet5C]="6" ) ;;
    7)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" \
        [subnet5B]="6" [subnet6B]="7" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" [subnet5C]="6" [subnet6C]="7" ) ;;
    8)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet7A]="8" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" \
        [subnet4B]="5" [subnet5B]="6" [subnet6B]="7" [subnet7B]="8" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" [subnet5C]="6" [subnet6C]="7" \
        [subnet7C]="8") ;;
    esac ;;
4)
    case <NUMBER SUBNETS> in
    1)
        declare -A rt_created=( [subnet0A]="1" [subnet0B]="1" [subnet0C]="1" \
        [subnet0D]="1" ) ;;
    2)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet0B]="1" [subnet1B]="2" [subnet0C]="1" [subnet1C]="2" \
        [subnet0D]="1" [subnet1D]="2" ) ;;
    3)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet0C]="1" \
        [subnet1C]="2" [subnet2C]="3" [subnet0D]="1" [subnet1D]="2" \
        [subnet2D]="3" ) ;;
    4)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" \
        [subnet3B]="4" [subnet0C]="1" [subnet1C]="2" [subnet2C]="3" [subnet3C]="4" \
        [subnet0D]="1" [subnet1D]="2" [subnet2D]="3" [subnet3D]="4" ) ;;
    5)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet0B]="1" [subnet1B]="2" \
        [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" [subnet0D]="1" [subnet1D]="2" \
        [subnet2D]="3" [subnet3D]="4" [subnet4D]="5" ) ;;
    6)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet0B]="1" \
        [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" [subnet5B]="6" \
        [subnet0C]="1" [subnet1C]="2" [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" \
        [subnet5C]="6" [subnet0D]="1" [subnet1D]="2" [subnet2D]="3" [subnet3D]="4" \
        [subnet4D]="5" [subnet5D]="6" ) ;;
    7)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" [subnet4B]="5" \
        [subnet5B]="6" [subnet6B]="7" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" [subnet5C]="6" [subnet6C]="7" \
        [subnet0D]="1" [subnet1D]="2" [subnet2D]="3" [subnet3D]="4" [subnet4D]="5" \
        [subnet5D]="6" [subnet6D]="7" ) ;;
    8)
        declare -A rt_created=( [subnet0A]="1" [subnet1A]="2" \
        [subnet2A]="3" [subnet3A]="4" [subnet4A]="5" [subnet5A]="6" [subnet6A]="7" \
        [subnet7A]="8" [subnet0B]="1" [subnet1B]="2" [subnet2B]="3" [subnet3B]="4" \
        [subnet4B]="5" [subnet5B]="6" [subnet6B]="7" [subnet7B]="8" [subnet0C]="1" [subnet1C]="2" \
        [subnet2C]="3" [subnet3C]="4" [subnet4C]="5" [subnet5C]="6" [subnet6C]="7" \
        [subnet7C]="8" [subnet0D]="1" [subnet1D]="2" [subnet2D]="3" [subnet3D]="4" \
        [subnet4D]="5" [subnet5D]="6" [subnet6D]="7" [subnet7D]="8" ) ;;
    esac ;;
esac

# Run array's through function
spacer=$'\n============\n'
response=$(verify_rt "${vpc_id}" "rt_created")
if echo $response | grep -q "FAILED"; then
    echo "TEST FAILED ${spacer}${response}"
else
    echo "ROUTE TABLE CREATION PASSED ${spacer}${response}"
fi