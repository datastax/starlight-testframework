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

DEBUG=false
OUTPUT_TO_LOG=true

source $(pwd)/setenv_automation.sh

DFT_LOG_HOMEDIR="nbs4j_exec_logs"

usage() {
   echo
   echo "Usage: run_testcase_by_name.sh [-h]"
   echo "                             -testCaseName <name of Testcase folder>"
   echo "                             [-taskFlagPrePost] <tc_default or glb_default>"
   echo "                             [-logHomeDir] <tc_exec_log_dir>"
   echo "       -h   : Show usage info"
   echo "       -testCaseName  : The name of the testcase to run"
   echo "       [-taskFlagPrePost] : Pre and Post Testcase scripts, either tc_default or glb_default only.  Default is tc_default"
   echo "       [-logHomeDir]  : The direcotry of the test case execution log file"
   echo
}

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

if [[ $# -gt 6 ]]; then
   usage
   exit 10
fi

while [[ "$#" -gt 0 ]]; do
   case $1 in
      -h) usage; exit 0 ;;
      -logHomeDir)  logHomeDir=$2; shift ;;
      -ansiPrivKey) ansiPrivKey=$2; shift ;;
      -ansiSshUser) ansiSshUser=$2; shift ;;
      -testCaseName) testCaseName=$2; shift ;;
      -taskFlagPrePost) taskFlagPrePost=$2; shift ;;
      *) echo "Unknown parameter passed: $1"; exit 20 ;;
   esac
   shift
done
if [[ -z "$testCaseName" ]]; then
    echo "No testCaseName was defined.  Use -testCaseName <name of testcase folder> to set the name."
    exit 10
fi
if [[ -z "$taskFlagPrePost" ]]; then
    echo "No taskFlagPrePost was defined.  Using default of tc_default."
    taskFlagPrePost="tc_default"
fi
# Check if the required environment variables are set
if [[ -z "${ANSI_SSH_PRIV_KEY// }" || -z "${ANSI_SSH_USER// }" || -z "${ANSI_DEBUG_LVL// }" || -z "${SERVER_TOPOLOGY_NAME// }" ]]; then
    echo "Required environment variables are not set in 'setenv_automation.sh' file!"
    exit 10
fi
# Check if the required host inventory file exists
ANSI_HOSTINV_FILE="$(pwd)/hosts_${SERVER_TOPOLOGY_NAME}.ini"
if ! [[ -f "${ANSI_HOSTINV_FILE}" ]]; then
    echo "The corresponding host inventory file for server topology name \"${SERVER_TOPOLOGY_NAME}\". Please run 'bash/buildAnsiHostInvFile.sh' file to generate it!"
    exit 20
fi
# 2022-08-19 11:40:23
startTime=$(date +'%Y-%m-%d %T')
# 20220819114023
startTime2=${startTime//[: -]/}
# 202208191140 (no second)
startTime3=${startTime2/%??/}

debugMsg "startTime=${startTime}"
debugMsg "startTime2=${startTime2}"
debugMsg "startTime3=${startTime3}"

if [[ -z "${logHomeDir// }" ]]; then
    logHomeDir=${DFT_LOG_HOMEDIR}
fi

if [[ -z "${ansiPrivKey// }" ]]; then
    ansiPrivKey=${ANSI_SSH_PRIV_KEY}
fi

if [[ -z "${ansiSshUser// }" ]]; then
    ansiSshUser=${ANSI_SSH_USER}
fi

debugMsg "logHomeDir=${logHomeDir}"
debugMsg "ansiPrivKey=${ansiPrivKey}"
debugMsg "ansiSshUser=${ansiSshUser}"

if ! [[ -f ${ansiPrivKey// } ]]; then
    echo "[ERROR] The specified private SSH key file doesn't exit!"
    exit 30
fi

scheduleLogHomeDir="${logHomeDir}/by_name/${startTime2}"
scheduleExecMainLogFile="${scheduleLogHomeDir}/tcExecScheduleMain.log"
testScnNBExecLogFolder="${scheduleLogHomeDir}/test_scn_logs"

mkdir -p "${testScnNBExecLogFolder}"

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

# Four parameters
# - 1st parameter: the return value of the current step
# - 2nd parameter: the log file name of the current step
# - 3nd parameter: error exit code
# - 4th parameter (optional): whether to error exit
stepExecErrorHandling() {
    outputMsg "retun value: $1; log file: $2" 14 ${OUTPUT_TO_LOG}
    if [[ $1 -ne 0 ]]; then
        if [[ -z "$4" || "$4" == "true" ]]; then
            fatal=true
            msgPrefix="ERROR"
        else
            fatal=false
            msgPrefix="WARN"
        fi
        outputMsg "[${msgPrefix}] Execution failed (fatal: ${fatal}) and quit/skip processing ..." 14 ${OUTPUT_TO_LOG}
        if [[ "${fatal}" == "true" ]]; then
            exit $3
        fi
    fi
}

re1='^[0-9]+$'
re3='^[0-9]+(s|m|h|d)?$'

glbDftPreTaskScript="bash/tc_exec_dft/pre_task.sh"
glbDftPostTaskScript="bash/tc_exec_dft/post_task.sh"

outputMsg ">> Task case schedule execution main log file: ${scheduleExecMainLogFile}" 0 false
outputMsg ">> Detailed task scenario NB execution log folder : ${testScnNBExecLogFolder}/" 0 false
outputMsg "" 0 false

outputMsg ">> Start time: ${startTime}" 0 ${OUTPUT_TO_LOG}
outputMsg "================================================" 0 ${OUTPUT_TO_LOG}


debugMsg "tcName=${testCaseName}"
tcName=${testCaseName}
tcPuaseTimeStr=${pauseTimeInSec}
debugMsg "tcPuaseTimeStr=${tcPuaseTimeStr}"
tcPreTaskScriptFlag=${taskFlagPrePost}
tcPostTaskScriptFlag=${taskFlagPrePost}
# Ignore the test case execution schedule if there
#   is no corresponding test case raw definition.
if [[ -d "testcases/raw_definition/${tcName}" ]]; then 
    # tcPuaseTimeStr=$(echo ${FIELDS[1]} | tr '[:upper:]' '[:lower:]')
    # tcPreTaskScriptFlag=$(echo ${FIELDS[2]} | tr '[:upper:]' '[:lower:]')
    # tcPostTaskScriptFlag=$(echo ${FIELDS[3]} | tr '[:upper:]' '[:lower:]')

    debugMsg "tcPuaseTimeStr=${tcPuaseTimeStr}"
    debugMsg "tcPreTaskScriptFlag=${tcPreTaskScriptFlag}"
    debugMsg "tcPostTaskScriptFlag=${tcPostTaskScriptFlag}"

    tcPauseTimeInSec=0
        # testcase pause time string has the following format: [0-9]*(s|m|h|d)
        # - Unit options: 
        #   * s: second (default if not specified)
        #   * m: minute 
        #   * h: hours 
        #   * d: day
        # - Other unit value is invalid and errors out
#        if ! [[ ${tcPuaseTimeStr} =~ $re3 ]]; then
#            echo "[ERROR] Invalid value testcase pause time string. It must be of format ${re3}"
#            exit 40
#        else
#            strLen=${#tcPuaseTimeStr}
#
#            if [[ ${strLen} -eq 1 ]]; then
#                tcPauseTimeInSec=$tcPuaseTimeStr
#            else 
#                unitChar=$(echo "${tcPuaseTimeStr: -1}")
#
#                if [[ ${unitChar} =~ $re1 ]]; then
#                    tcPauseTimeInSec=$tcPuaseTimeStr
#                else
#                    TC_PAUSE_TIME_INPUT_VAL=${tcPuaseTimeStr:0:$((strLen-1))}
#                    
#                    if [[ "$unitChar" == "s" ]]; then
#                        tcPauseTimeInSec=$((TC_PAUSE_TIME_INPUT_VAL))
#                    elif [[ "$unitChar" == "m" ]]; then
#                        tcPauseTimeInSec=$((TC_PAUSE_TIME_INPUT_VAL*60))
#                    elif [[ "$unitChar" == "h" ]]; then
#                        tcPauseTimeInSec=$((TC_PAUSE_TIME_INPUT_VAL*60*60))
#                    elif [[ "$unitChar" == "d" ]]; then
#                        tcPauseTimeInSec=$((TC_PAUSE_TIME_INPUT_VAL*60*60*24))
#                    else
#                        echo "[ERROR] Invalid input value unit of testcase pause time for line \"${LINE}\". It must be one of (s,m,h,d)."
#                        exit 50
#                    fi
#                fi
#            fi
#        fi

        tcDftPreTaskScript="testcases/raw_definition/${tcName}/pre_task.sh"
        tcDftPostTaskScript="testcases/raw_definition/${tcName}/post_task.sh"

        preTaskScriptArr=()
        postTaskScriptArr=()

        # Get the right pre-task script(s) to execute
        # Ignore invalid input values
        if [[ "${tcPreTaskScriptFlag// }" == "tc_default" ]]; then
            if [[ -f "${tcDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${tcDftPreTaskScript}")
            fi
        elif [[ "${tcPreTaskScriptFlag// }" == "glb_default" ]]; then
            if [[ -f "${glbDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${glbDftPreTaskScript}")
            fi
        elif [[ "${tcPreTaskScriptFlag// }" == "all" ]]; then
            if [[ -f "${glbDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${glbDftPreTaskScript}")
            fi
            if [[ -f "${tcDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${tcDftPreTaskScript}")
            fi
        elif [[ -z "${tcPreTaskScriptFlag// }" ]]; then
            if [[ -f "${tcDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${tcDftPreTaskScript}")
            elif [[ -f "${glbDftPreTaskScript// }" ]]; then
                preTaskScriptArr+=("${glbDftPreTaskScript}")
            fi
        fi
        effectiveTcPreTaskScript=${#preTaskScriptArr[@]}

        # Get the right post-task script(s) to execute
        # Ignore invalid input values
        if [[ "${tcPostTaskScriptFlag// }" == "tc_default" ]]; then
            if [[ -f "${tcDftPostTaskScript// }" ]]; then
                postTaskScriptArr+=("${tcDftPostTaskScript}")
            fi
        elif [[ "${tcPostTaskScriptFlag// }" == "glb_default" ]]; then
            if [[ -f "${glbDftPostTaskScript// }" ]]; then
                postTaskScriptArr+=("${glbDftPostTaskScript}")
            fi
        elif [[ "${tcPostTaskScriptFlag// }" == "all" ]]; then
            if [[ -f "${glbDftPostTaskScript// }" ]]; then
                postTaskScriptArr+=("${glbDftPostTaskScript}")
            fi
            if [[ -f "${tcDftPreTaskScript// }" ]]; then
                postTaskScriptArr+=("${tcDftPostTaskScript}")
            fi
        elif [[ -z "${tcPostTaskScriptFlag// }" ]]; then
            if [[ -f "${tcDftPostTaskScript// }" ]]; then
                postTaskScriptArr+=("${tcDftPostTaskScript}")
            elif [[ -f "${glbDftPostTaskScript// }" ]]; then
                postTaskScriptArr+=("${glbDftPostTaskScript}")
            fi
        fi
        effectiveTcPostTaskScript=${#postTaskScriptArr[@]}

        outputMsg "Process test case: ${tcName} (time: $(date +'%Y-%m-%d %T'))..." 3 ${OUTPUT_TO_LOG}
        outputMsg "> execution raw definition: ${LINE}" 3 ${OUTPUT_TO_LOG}
        outputMsg "------------------------------------------------" 3 ${OUTPUT_TO_LOG}

        # Execute the pre-task if it is a valid file
        if [[ ${effectiveTcPreTaskScript} -eq 0 ]]; then
            outputMsg "[$(date +'%T')] No effective pre-task script(s) and ignore the execution!" 3 ${OUTPUT_TO_LOG}
        else
            arrIdx=0
            for script in "${preTaskScriptArr[@]}"; do
                arrIdx=$((arrIdx + 1))
                outputMsg "[$(date +'%T')] pre-task execution ${arrIdx} - script: ${script}" 3 ${OUTPUT_TO_LOG}
                tcPreTaskLog="${scheduleLogHomeDir}/${tcName}_preTask_${arrIdx}.log"
                eval '"${script}" ${tcName}' > ${tcPreTaskLog} 2>&1
                stepExecErrorHandling $? ${tcPreTaskLog} 60 
            done
        fi

        # Call Ansible script to start executing, in an asyncrhonous way, the test scenarios under the current test case
        outputMsg "[$(date +'%T')] Start executing test scenarios under the test case ..." 3 ${OUTPUT_TO_LOG}
        ansiPlaybookName=run_nbs4j_testcase_byname.yaml
        ansiTcExecLog="${scheduleLogHomeDir}/${tcName}-${ansiPlaybookName//./_}.log"
        ansible-playbook -i ${ANSI_HOSTINV_FILE} ${ansiPlaybookName} \
            --extra-vars="testcase_name=${tcName}" \
            --private-key=${ansiPrivKey} \
            -u ${ansiSshUser} -v > ${ansiTcExecLog} 2>&1
        stepExecErrorHandling $? ${ansiTcExecLog} 70

        # Pause the specified time
#        if [[ $tcPauseTimeInSec -gt 0 ]]; then
#            outputMsg "[$(date +'%T')] Pause for ${tcPuaseTimeStr} before finishing the current test case ..." 3 ${OUTPUT_TO_LOG}
#            sleep ${tcPauseTimeInSec}
#        fi

        # Get the remote test scenario execution logs
        ansiPlaybookName=collect_remote_runlogs_bytc.yaml
        ansiFetchTcLog="${scheduleLogHomeDir}/${tcName}-${ansiPlaybookName//./_}.log"
        ansible-playbook -i ${ANSI_HOSTINV_FILE} ${ansiPlaybookName} \
            --extra-vars="testcase_name=${tcName} local_log_dir=${testScnNBExecLogFolder} time_threshold=${startTime3}" \
            --private-key=${ansiPrivKey} \
            -u ${ansiSshUser} -v > ${ansiFetchTcLog} 2>&1
        stepExecErrorHandling $? ${ansiFetchTcLog} 80 false
        
        # Execute the Post-task if it is a valid file
        if [[ ${effectiveTcPostTaskScript} -eq 0 ]]; then
            outputMsg "[$(date +'%T')] No effective post-task script(s) and ignore the execution!" 3 ${OUTPUT_TO_LOG}
        else
            arrIdx=0
            for script in "${postTaskScriptArr[@]}"; do
                outputMsg "[$(date +'%T')] post-task execution ${arrIdx} - script: ${script}" 3 ${OUTPUT_TO_LOG}
                tcPostTaskLog="${scheduleLogHomeDir}/${tcName}_postTask_${arrIdx}.log"
                eval '"${script}" ${tcName}' > ${tcPostTaskLog} 2>&1
                stepExecErrorHandling $? ${tcPostTaskLog} 90 false
            done
        fi
        outputMsg "------------------------------------------------" 3 ${OUTPUT_TO_LOG}
    else
        outputMsg "[WARN] Can't find corresponding test case raw definition! Skipping ... " 3 ${OUTPUT_TO_LOG}
        outputMsg "------------------------------------------------" 3 ${OUTPUT_TO_LOG}
        outputMsg "> offending line: ${LINE}" 3 ${OUTPUT_TO_LOG}
        outputMsg "------------------------------------------------" 3 ${OUTPUT_TO_LOG}
fi

outputMsg " " 3 ${OUTPUT_TO_LOG}
