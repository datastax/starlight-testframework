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

#
# Find out the latest files per subdirectory (if any) within a directory
#

DEBUG=false

usage() {
   echo
   echo "Usage: find_latestfiles.sh [-h]"
   echo "                            -fileExtType <file_extention_type>"
   echo "                            -tgtDirToScan <target_directory_to_scan>"
   echo "                            [-tgtTestCase] <target_testcase_name>"
   echo "                            [-timeThresh <older_than_time>]"
   echo
   echo "       -h   : show usage info"
   echo "       -fileExtType   : file extention type to scan"
   echo "       -tgtDirToScan  : the target directory to scan"
   echo "       [-tgtTestCase] : only scan files belonging to the target test case"
   echo "       [-timeThresh]  : only scan files older than or equal to the specified time"
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

if [[ $# -eq 0 || $# -gt 8 ]]; then
   usage
   exit 10
fi

while [[ "$#" -gt 0 ]]; do
   case $1 in
      -h) usage; exit 0 ;;
      -fileExtType) fileExtType=$2; shift ;;
      -tgtDirToScan) tgtDirToScan=$2; shift ;;
      -tgtTestCase) tgtTestCase=$2; shift ;;
      -timeThresh) timeThresh=$2; shift ;;
      *) echo "Unknown parameter passed: $1"; exit 20 ;;
   esac
   shift
done

debugMsg "fileExtType=${fileExtType}"
debugMsg "tgtDirToScan=${tgtDirToScan}"
debugMsg "tgtTestCase=${tgtTestCase}"
debugMsg "timeThresh=${timeThresh}"

timThreshSpecified=0
if [[ -n "${timeThresh// }" && "${timeThresh// }" != "*" ]]; then
    if ! [[ ${timeThresh// } =~ ^[[:digit:]]{12}$ ]] && date -d "${timeThresh// }" >/dev/null 2>&1; then
        echo "[ERROR] Invalid value for the input parameter of '-timeThresh'. It must be a valid date/time with format 'YYYYmmddHHMM'." 
        exit 30;
    else
        timThreshSpecified=1
    fi
fi

# create a temporary file with the specified time threshold
if [[ ${timThreshSpecified} -gt 0 ]]; then
    timeThreshFile="/tmp/nbs4j_mytmp_$(date +'%Y-%m-%d-%H:%M:%S')"
    touch -t ${timeThresh// } ${timeThreshFile}
fi

subFolderSet=$(find ${tgtDirToScan} -maxdepth 1 -mindepth 1 -type d)
if [[ -n "${subFolderSet}" ]]; then
    filesFoundList=()

    while IFS= read -r tctsFolder; do
        # if the test case is specified, only scan the files related with the test case
        if [[ -z ${tgtTestCase// } || "${tgtTestCase// }" == "*" ]] || echo ${tctsFolder} | grep -q ${tgtTestCase}; then
            fileToList="${tctsFolder}/*"
            if [[ -n ${fileExtType// } || "${fileExtType// }" == "*" ]]; then
                fileToList="${fileToList}.${fileExtType}"
            fi

            mostRcntFile=$(ls -tlr ${fileToList} 2> /dev/null | tail -1 | awk '{print $9}')

            if [[ -n "${mostRcntFile}" ]]; then
                if [[ ${timThreshSpecified} -eq 0  || "${mostRcntFile}" -nt "${timeThreshFile}" ]]; then
                    echo $mostRcntFile
                    filesFoundList+=${mostRcntFile}
                fi 
            fi
        fi
    done <<< "${subFolderSet}"

    if [[ ${timThreshSpecified} -gt 0 ]]; then
        rm -rf ${timeThreshFile}
    fi
fi