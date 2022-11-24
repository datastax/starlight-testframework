#! /usr/bin/bash
###
# Copyright DataStax, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
###

###
# NOTE 1: the default MacOS /bin/bash version is 3.x and doesn't have the feature of 
#         associative arrary. Homebrew installed bash is under "/usr/local/bin/bash"
#
# Change to default "/bin/bash" if your system has the right version (4.x and above)
#

# This script is used for generating the Ansible host inventory file from
#   the cluster topology raw definition file
# 
#   this script only works for bash 4 and above
#   * by default, MacOs bash version is 3.x (/bin/bash)
#   * use custom-installed bash using homebrew (/usar/local/bin/bash) at version 5.x
#

DEBUG=false

bashVerCmdOut=$(bash --version)
re='[0-9].[0-9].[0-9]'
bashVersion=$(echo ${bashVerCmdOut} | grep -o "version ${re}" | grep -o "${re}")
bashVerMajor=$(echo ${bashVersion} | awk -F'.' '{print $1}' )

if [[ ${bashVerMajor} -lt 4 ]]; then
    echo "[ERROR] Unspported bash version (${bashVersion}). Must be version 4.x and above!";
    exit 1
fi

# only 1 parameter: the message to print for debug purpose
debugMsg() {
    if [[ "${DEBUG}" == "true" ]]; then
        if [[ $# -eq 0 ]]; then
            echo
        else
            echo "[Debug] $1"
        fi
    fi
}

clstrToplogyRawDefHomeDir="./test_hostnames"
validPulsarClntHostTypeArr=(${validPulsarSrvHostTypeArr[@]} "standAloneClient")
validPulsarClntHostTypeListStr="${validPulsarClntHostTypeArr[@]}"
debugMsg "validPulsarClntHostTypeListStr=${validPulsarClntHostTypeListStr}"

validHostTypeArr+=( ${validPulsarClntHostTypeArr[@]} "monitoring")
validHostTypeListStr="${validHostTypeArr[@]}"
debugMsg "validHostTypeListStr=${validHostTypeListStr}"

usage() {
   echo
   echo "Usage: buildAnsiHostInvFile.sh [-h]"
   echo "                                -testHostNamesDir <test_hostnames>"
   echo "                                -hostDns <whehter_using_dnsname>"
   echo "       -h : Show usage info"
   echo "       -testHostNamesDir : Test Hostnames folder/directory name"
   echo "       -hostDns   : Whehter using host DNS name (true) or host IP (faslse)"
   echo
}

if [[ $# -eq 0 || $# -gt 4 ]]; then
   usage
   exit 10
fi

while [[ "$#" -gt 0 ]]; do
   case $1 in
      -h) usage; exit 0 ;;
      -testHostNamesDir) testHostNamesDir=$2; shift ;;
      -hostDns) hostDns=$2; shift ;;
      *) echo "[ERROR] Unknown parameter passed: $1"; exit 20 ;;
   esac
   shift
done

clstTopFile="${clstrToplogyRawDefHomeDir}/${testHostNamesDir}/hostnamesDefRaw"
lastClstTopFile="${clstrToplogyRawDefHomeDir}/${testHostNamesDir}/hostnamesDefRaw_last"

debugMsg "clstTopFile=${clstTopFile}"
debugMsg "lastClstTopFile=${lastClstTopFile}"
debugMsg "hostDns=${hostDns}"

# Check if the corrsponding Pulsar cluster definition file exists
if ! [[ -f "${clstTopFile}" ]]; then
    echo "[ERROR] The spefified test hostnames directory doesn't have the corresponding definition file: ${clstTopFile}";
    exit 30
fi

re='(true|false)'
if ! [[ ${hostDns} =~ $re ]]; then
  echo "[ERROR] Invalid value for the input parameter '-hostDns'. Boolean value (true or false) is expected." 
  exit 40
fi

tgtAnsiHostInvFileName="hosts_${testHostNamesDir}.ini"
echo > ${tgtAnsiHostInvFileName}

# Map of server type to an array of internal IPs/HostNames
declare -A internalHostIpMap
declare -A externalHostIpMap
declare -A testhostMap

while read LINE || [ -n "${LINE}" ]; do
    # Ignore comments
    case "${LINE}" in \#*) continue ;; esac
    IFS=',' read -r -a FIELDS <<< "${LINE#/}"

    if [[ -n "${LINE// }" ]]; then
        internalIp=${FIELDS[0]}
        externalIp=${FIELDS[1]}
        if [[ -z "${externalIp// }" ]]; then
            externalIp=${internalIp}
        fi 
        
        providedHostTypeListStr=${FIELDS[2]}
        IFS='+' read -r -a providedHostTypeArr <<< "${providedHostTypeListStr}"
        
        testhost=${FIELDS[3]}
        aZone=${FIELDS[4]}
        brokerCP=${FIELDS[5]}
        deployStatus=${FIELDS[6]}

        debugMsg "internalIp=${internalIp}"
        debugMsg "externalIp=${externalIp}"
        debugMsg "hostTypeListStr=${providedHostTypeListStr}"
        debugMsg "hostTypeListArr=${providedHostTypeArr[*]}"
        
        if [[ -z "${internalIp// }"||  -z "${providedHostTypeListStr// }" || -z "${testhost// }" ]]; then
            echo "[ERROR] Invalid server host defintion line: \"${LINE}\". Mandatory fields must not be empty!" 
            exit 50
        fi

        for hostType in "${providedHostTypeArr[@]}"; do
            debugMsg  "hostType in forloop ${hostType}"
            internalHostIpMap[${hostType}]+="${internalIp} "
            externalHostIpMap[${hostType}]+="${externalIp} "
            testhostMap[${hostType}]+="${testhost} "
        done
    fi
done < ${clstTopFile}

repeatSpace() {
    head -c $1 < /dev/zero | tr '\0' ' '
}

# Two parameter: 
# - 1st parameter is the message to print for execution status purpose
# - 2nd parameter is the number of the leading spaces
outputMsg() {
    if [[ $# -eq 0 || $# -gt 2 ]]; then
        echo "[Error] Incorrect usage of outputMsg()."
    else
        leadingSpaceStr=""
        if [[ $# -eq 2 && $2 -gt 0 ]]; then
            leadingSpaceStr=$(repeatSpace $2)            
        fi
        echo "$leadingSpaceStr$1" >> ${tgtAnsiHostInvFileName}
    fi
}

outputMsg "[all:vars]"
outputMsg "test_hostnames=${testHostNamesDir}"
outputMsg "use_dns_name=\"${hostDns}\""
outputMsg ""
outputMsg "[pulsarClient:children]"
outputMsg "standAloneClient"
outputMsg ""

for hostType in "${validHostTypeArr[@]}"; do
    debugMsg "hostType in forloop at 235 ${hostType}"
    internalIpSrvTypeList="${internalHostIpMap[${hostType}]}"
    externalIpSrvTypeList="${externalHostIpMap[${hostType}]}"
    testhostSrvTypeList="${testhostMap[${hostType}]}"

    IFS=' ' read -r -a internalIpSrvTypeArr <<< "${internalIpSrvTypeList}"
    IFS=' ' read -r -a externalIpSrvTypeArr <<< "${externalIpSrvTypeList}"
    IFS=' ' read -r -a testhostSrvTypeArr <<< "${testhostSrvTypeList}"
    IFS=' ' read -r -a azSrvTypeArr <<< "${azSrvTypeList}"

    if [[ "${validPulsarClntHostTypeListStr}" =~ "${hostType}" ]]; then
        outputMsg "[${hostType}:vars]"
        outputMsg "srv_component=\"$(echo ${hostType})\""

        if [[ "${validPulsarSrvHostTypeListStr}" =~ "${hostType}" ]]; then
            srv_component_internal="${hostType}"
            outputMsg "srv_component_internal=\"$(echo ${srv_component_internal})\""
        fi
    fi
    outputMsg "[${hostType}]"

    for index in "${!internalIpSrvTypeArr[@]}"; do
        hostInvLine="${externalIpSrvTypeArr[$index]} private_ip=${internalIpSrvTypeArr[$index]}"
        hostInvLine="${hostInvLine} scn_id_str=${testhostSrvTypeArr[$index]}"
        if [[ "${validPulsarClntHostTypeListStr}" =~ "${hostType}" ]]; then
            hostInvLine="${hostInvLine}"
        fi 
        outputMsg "$hostInvLine"
    done
    outputMsg ""
done