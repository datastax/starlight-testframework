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

source $(pwd)/setenv_automation.sh
usage() {
   echo
   echo "Usage: deploy_nbs4j_tf.sh [-h] [<tc_name_pattern>] [<remove_local_nb_files>] [<skip_local_raw_tc_processing>]"
   echo
   echo "       -h : show usage info"
   echo '       $1 : Test case name pattern'
   echo '       $2 (true|false) : Whether to remove locally generated test case NB files before processing the raw definition files'
   echo '       $3 (true|false) : Whether to skip the step of locally processing test case raw definition files'
   echo
}

if [[ "$@" =~ .*"-h".* ]]; then
    usage
    exit 0;
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

#####
# The test case name pattern
# - the raw test case whose names matching the pattern are processed
tcNamePattern=$1
echo "TestCase pattern: $tcNamePattern"
if [[ -z "${tcNamePattern}// }" ]]; then
    tcNamePattern="*"
fi

#####
# Whether to clean up the locally generated test case files (if they exist) before processing the test case raw definition files.
# - Default is "false"
# - If true, the locally generated test case files (from the previous run) will be first deleted
rmLocalNBFiles=$(echo $2 | tr '[:lower:]' '[:upper:]')
echo "Cleanup local files: $rmLocalNBFiles"
if [[ -z "${rmLocalNBFiles// }" ]]; then
    rmLocalNBFiles="false"
fi

##### 
# Whether to skip the first step of processing test case raw definition files locally. 
# - Default is "false"
# - If true, this will only copy the locally generated test case NB files to the remote testing machines
skipRawTcProc=$(echo $3 | tr '[:lower:]' '[:upper:]')
echo "Skip first step: $skipRawTcProc"
if [[ -z "${skipRawTcProc// }" ]]; then
    skipRawTcProc="false"
fi

#re='(true|false)'
#if ! [[ ${rmLocalNBFiles} =~ $re && ${skipRawTcProc} =~ $re ]]; then
#    echo "[ERROR] Boolean value of 'true' or 'false' is expected for the 2nd and/or 3rd parameters if provided." 
#    exit 40
#fi
#PlaceHolder msgPayloadDistroDft="5120:80;6200:10;100030:10"
#ansible-playbook -i ${ANSI_HOSTINV_FILE} deploy_nbs4j_tf.yaml --extra-vars "tcNamePattern=${tcNamePattern} rmLocalNBFiles=${rmLocalNBFiles} skipRawTcProc=${skipRawTcProc} msg_payload_distro_dft=${msgPayloadDistroDft}" --private-key=${ANSI_SSH_PRIV_KEY} -u ${ANSI_SSH_USER} -v
ansible-playbook -i ${ANSI_HOSTINV_FILE} deploy_nbs4j_tf.yaml --extra-vars "tcNamePattern=${tcNamePattern} rmLocalNBFiles=${rmLocalNBFiles} skipRawTcProc=${skipRawTcProc}" --private-key=${ANSI_SSH_PRIV_KEY} -u ${ANSI_SSH_USER} -v
