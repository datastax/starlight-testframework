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
ansible-playbook -i ${ANSI_HOSTINV_FILE} setup_environment.yaml --private-key=${ANSI_SSH_PRIV_KEY} -u ${ANSI_SSH_USER} -v