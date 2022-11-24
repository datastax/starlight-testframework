#! /bin/bash
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

OUTPUT_TO_LOG=true
source $(pwd)/setenv_automation.sh

DFT_LOG_HOMEDIR="nbs4j_exec_logs"

usage() {
   echo
   echo "Usage: 04.collect_logs_by_testcase_name.sh [-h] [<operation type>]"
   echo "                             -testCaseName <name of Testcase folder>"
   echo "                             [-logHomeDir] <tc_exec_log_dir>"
   echo
   echo "       -h : show usage info"
   echo "       -testCaseName  : The name of the testcase to retreive logs"
   echo "       [-logHomeDir]  : The direcotry of the test case execution log file"
   echo
}

if [[ "$@" =~ .*"-h".* ]]; then
    usage
    exit 0;
fi

# Check if the required environment variables are set
if [[ -z "${ANSI_SSH_PRIV_KEY// }" || -z "${ANSI_SSH_USER// }" || -z "${ANSI_DEBUG_LVL// }" || -z "${TEST_HOSTNAMES_DIR// }" ]]; then
    echo "Required environment variables are not set in 'setenv_automation.sh' file!"
    exit 10
fi

# Check if the required host inventory file exists
ANSI_HOSTINV_FILE="$(pwd)/hosts_${TEST_HOSTNAMES_DIR}.ini"
if ! [[ -f "${ANSI_HOSTINV_FILE}" ]]; then
    echo "The corresponding host inventory file for server topology name \"${TEST_HOSTNAMES_DIR}\". Please run 'bash/buildAnsiHostInvFile.sh' file to generate it!"
    exit 20
fi
while [[ "$#" -gt 0 ]]; do
   case $1 in
      -h) usage; exit 0 ;;
      -logHomeDir)  logHomeDir=$2; shift ;;
      -testCaseName) testCaseName=$2; shift ;;
      *) echo "Unknown parameter passed: $1"; exit 20 ;;
   esac
   shift
done
if [[ -z "$testCaseName" ]]; then
    echo "No testCaseName was defined.  Use -testCaseName <name of testcase folder> to set the name."
    exit 10
fi
if [[ -z "${logHomeDir// }" ]]; then
    logHomeDir=${DFT_LOG_HOMEDIR}
fi
if [[ -z "${ansiPrivKey// }" ]]; then
    ansiPrivKey=${ANSI_SSH_PRIV_KEY}
fi

if [[ -z "${ansiSshUser// }" ]]; then
    ansiSshUser=${ANSI_SSH_USER}
fi
repeatSpace() {
    head -c $1 < /dev/zero | tr '\0' ' '
}
# Three parameter: 
# - 1st parameter is the message to print for execution status purpose
# - 2nd parameter is the number of the leading spaces
# - 3nd parameter is whether to append the message to the main log file
outputMsg() {
    if ! [[ $# -eq 3 ]]; then
        echo "[Error] Incorrect usage of outputMsg()."
    else
        leadingSpaceStr=""
        if [[ $2 -gt 0 ]]; then
            leadingSpaceStr=$(repeatSpace $2)            
        fi
        if [[ "$3" == "true" ]]; then
            echo "$leadingSpaceStr$1" >> ${scheduleExecMainLogFile}
        else
            echo "$leadingSpaceStr$1"
        fi
    fi
}
tcName=${testCaseName}

# 2022-08-19 11:40:23
startTime=$(date +'%Y-%m-%d %T')
# 20220819114023
startTime2=${startTime//[: -]/}
# 202208191140 (no second)
startTime3=${startTime2/%??/}

scheduleLogHomeDir="${logHomeDir}/by_name/${startTime2}"
scheduleExecMainLogFile="${scheduleLogHomeDir}/tcExecScheduleMain.log"
testScnNBExecLogFolder="${scheduleLogHomeDir}/test_scn_logs"

mkdir -p "${testScnNBExecLogFolder}"

# Get the remote test scenario execution logs
outputMsg ">> Retrieving logs - main execution log file: ${scheduleExecMainLogFile}" 0 false
outputMsg ">> Testcase ${tcName} logs at ${testScnNBExecLogFolder}" 0 false

ansiPlaybookName=collect_remote_runlogs_bytc.yaml
ansiFetchTcLog="${scheduleLogHomeDir}/${tcName}-${ansiPlaybookName//./_}.log"
ansible-playbook -i ${ANSI_HOSTINV_FILE} ${ansiPlaybookName} \
    --extra-vars="testcase_name=${tcName} local_log_dir=${testScnNBExecLogFolder} time_threshold=${startTime3}" \
    --private-key=${ansiPrivKey} \
    -u ${ansiSshUser} -v > ${ansiFetchTcLog} 2>&1
