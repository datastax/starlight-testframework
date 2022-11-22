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
   echo "Usage: 99.purge_remote_nbs4j_exec.sh [-h] [<operation type>]"
   echo
   echo "       -h : show usage info"
   echo '       $1 : operation type, one of the following "pid" or "all"'
   echo '       if no input then default is "pid"'
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
# extra-vars 
# - the op_types for this playbook 
#   "pid" to stop all NB processes
#   "all" to stop all pids and purge all NB files 
operationType=$1
echo "Operation Type: $operationType"
#if [[ -z "${operationType}// }" ]]; then
if [[ -z "${operationType}" ]]; then
    operationType="pid"
    echo "Operation Type: pid"
fi
#ansible-playbook -i hosts.ini purge_remote_nbs4j_exec.yaml --private-key=~/.ssh/id_rsa_ymtest2 -u automaton -v
ansible-playbook -i ${ANSI_HOSTINV_FILE} purge_remote_nbs4j_exec.yaml --extra-vars "op_types=${operationType}" --private-key=${ANSI_SSH_PRIV_KEY} -u ${ANSI_SSH_USER} -v