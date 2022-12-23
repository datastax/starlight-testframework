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
# NOTE: GNU sed must be used. On Mac, this script may fail due to BSD sed is used. 
#       Install GNU sed on mac using homebrew
#       1) brew install gnu-sed
#       2) brew info gnu-sed (add PATH)
# 

DEBUG=false
SHOW_OUTPUT=false

usage() {
   echo
   echo "Usage: process_tc_rawdef.sh [-h]"
   echo "                            -tcNamePattern <tc_name_list>"
   echo "                            -useAsync <use_async_s4j_api>"
   echo "                            -blockingMsgRecv <use_blocking_msg_recv>"
   echo "                            -simuUserPwd <auth_user_password_simulation>"
   echo "                            -useTransStickyPart <use_sticky_partition_for_transaction>"
   echo "                            -jmsPriorityEnable <enable_JMS_priority>"
   echo "                            -jmsPriorityMapping <JMS_priority_mapping>"
   echo "                            -brkrSvcUrl <pulsar_svc_url>"
   echo "                            -webSvcUrl <pulsar_web_url>"
   echo "                            -tgtNbtfHomeDir <tgt_nbtf_homedir>"
   echo "                            -dftNbStrdNum <nb_strides_num_deft>"
   echo "                            -dftCmprsType <msg_compression_dft>"
   echo "                            -dftPrdBatching <prd_batching_dft>"
   echo "                            -dftMsgPayloadStr <msg_payload_distro_dft>"
   echo "                            -dftMsgRespCntTracking <msg_response_cnt_tracking>"
   echo "                            -dftStrictMsgErrHandling <strict_msgerr_handling>"
   echo "                            -dftSlowAckInSec <slow_ack_in_sec>"
   echo "                            -dftAckTimeoutInSec <ack_timeout>"
   echo "                            -dftDlqPolicy <dlq_policy_dft>"
   echo "                            -dftAckTimeoutRedePolicy <ack_timeout_redelivery_policy_dft>"
   echo "                            [-dftNegAckRedePolicy <neg_ack_redelivery_policy_dft>]"
   echo "                            -nbLogLvl <nb_log_lvl>"
   echo "                            -jwtTokenFileNoPath <pulsar_clnt_jwt_token_name>"
   echo "                            -tlsCaCertFileNoPath <pulsar_clnt_trusted_cert_name>"
   echo "                            -pgeMetricsSrv <prometheus_graphite_metrics_server_address>"
   echo
   echo "       -h   : show usage info"
   echo "       -tcNamePattern : Comma seperated list test case names. '*' means to process all test cases."
   echo "       -useAsync (true|false) : Whether to use the async S4J API?"
   echo "       -blockingMsgRecv (true|false) : Whether to use blocking message receiving?"
   echo "       -simuUserPwd (true|false) : Whether to use S4J API feature for username/password simulation?"
   echo "       -useTransStickyPart (true|false) : Whether to use S4J API feature for using sticky partition in transaction?"
   echo "       -jmsPriorityEnable (true|false): Whether to enable S4J JMS priority"
   echo "       -jmsPriorityMapping : S4J JMS priority mapping (only relevant when JMS priority is enabled)"
   echo "       -brkrSvcUrl : Pulsar broker service url"
   echo "       -webSvcUrl : Pulsar web service url"
   echo "       -tgtNbtfHomeDir : Target NBTF home directory"
   echo "       -dftNbStrdNum : Default NB stride number"
   echo "       -dftCmprsType : Default compression type"
   echo "       -dftPrdBatching : Default setting of producer batching"
   echo "       -dftMsgRespCntTracking : Default setting of message response tracking"
   echo "       -dftStrictMsgErrHandling : Default setting of strict message processing error handling "
   echo "       -dftSlowAckInSec : Simulate slow acknowldgement (time in second)"
   echo "       -dftAckTimeoutInSec : Ack timeout value (time in second)"
   echo "       -dftDlqPolicy : Default dead letter topic policy"
   echo "       -dftAckTimeoutRedePolicy : Default ack timeout redelivery policy"
   echo "       [-dftNegAckRedePolicy] : (Ootional) Default negative ack redelivery policy"
   echo "       -nbLogLvl : NB log level"
   echo "       -jwtTokenFileNoPath : JWT token file name (no path)"
   echo "       -tlsCaCertFileNoPath : TLS ca cert file name (no path)"
   echo "       -pgeMetricsSrv : Prometheus graphite exporter server address (for receiving metrcis from NB)"
   echo
}

# only 1 parameter: the message to print for execution status purpose
outputMsg() {
    if [[ "${SHOW_OUTPUT}" == "true" ]]; then
        if [[ $# -eq 0 ]]; then
            echo
        else
            echo $1
        fi
    fi
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

if [[ $# -eq 0 || $# -gt 50 ]]; then
   usage
   exit 10
fi

useAsync=false
blockingMsgRecv=false
simuUserPwd=false
while [[ "$#" -gt 0 ]]; do
   case $1 in
      -h) usage; exit 0 ;;
      -tcNamePattern) tcNamePattern=${2// }; shift ;;
      -useAsync) useAsync=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -blockingMsgRecv) blockingMsgRecv=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -simuUserPwd) simuUserPwd=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -useTransStickyPart) useTransStickyPart=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -jmsPriorityEnable) jmsPriorityEnable=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -jmsPriorityMapping) jmsPriorityMapping=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -brkrSvcUrl) brkrSvcUrl=$2; shift ;;
      -webSvcUrl) webSvcUrl=$2; shift ;;
      -tgtNbtfHomeDir) tgtNbtfHomeDir=$2; shift ;;
      -dftNbStrdNum) dftNbStrdNum=$2; shift ;;
      -dftCmprsType) dftCmprsType=$2; shift ;;
      -dftPrdBatching) dftPrdBatching=$2; shift ;;
      -dftMsgPayloadStr) dftMsgPayloadStr=$2; shift ;;
      -dftMsgRespCntTracking) dftMsgRespCntTracking=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -dftStrictMsgErrHandling) dftStrictMsgErrHandling=$(echo $2 | tr '[:upper:]' '[:lower:]'); shift ;;
      -dftSlowAckInSec) dftSlowAckInSec=$2; shift ;;
      -dftAckTimeoutInSec) dftAckTimeoutInSec=$2; shift ;;
      -dftDlqPolicy) dftDlqPolicyRaw=$2; shift ;;
      -dftAckTimeoutRedePolicy) dftAckTimeoutRedePolicyRaw=$2; shift ;;
      -dftNegAckRedePolicy) dftNegAckRedePolicyRaw=$2; shift ;;
      -nbLogLvl) nbLogLvl=$2; shift ;;
      -jwtTokenFileNoPath) jwtTokenFileNoPath=$2; shift ;;
      -tlsCaCertFileNoPath) tlsCaCertFileNoPath=$2; shift ;;
      -pgeMetricsSrv) pgeMetricsSrv=$2; shift ;;
      *) echo "Unknown parameter passed: $1"; exit 20 ;;
   esac
   shift
done

convertRawDlqPolicyToValidJson () {
    rawPolicy=$1
    jsonPolicy="{ \"${rawPolicy//+/\", \"}\" }"
    jsonPolicy="${jsonPolicy//:/\": \"}"

    # special handling for ':' contained in the topic name
    jsonPolicy="${jsonPolicy//persistent\": \"/persistent:}"

    echo "${jsonPolicy}"
}

if [[ -z "${tcNamePattern// }" ]]; then
    tcNamePattern="*"
fi


if [[ ${dftAckTimeoutInSec} -eq 0 ]]; then
    dftDlqPolicy=""
    dftAckTimeoutRedePolicy=""
    dftNegAckRedePolicy=""
else
    if [[ -n "${dftDlqPolicyRaw}" ]]; then
        dftDlqPolicy=$(convertRawDlqPolicyToValidJson ${dftDlqPolicyRaw})
    fi

    if [[ -n "${dftAckTimeoutRedePolicyRaw}" ]]; then
        dftAckTimeoutRedePolicy=$(convertRawDlqPolicyToValidJson ${dftAckTimeoutRedePolicyRaw})
    fi
    
    if [[ -n "${dftNegAckRedePolicyRaw}" ]]; then
        dftNegAckRedePolicy=$(convertRawDlqPolicyToValidJson ${dftNegAckRedePolicyRaw})
    fi
fi

debugMsg "tcNamePattern=${tcNamePattern}"
debugMsg "useAsync=${useAsync}"
debugMsg "blockingMsgRecv=${blockingMsgRecv}"
debugMsg "simuUserPwd=${simuUserPwd}"
debugMsg "useTransStickyPart=${useTransStickyPart}"
debugMsg "jmsPriorityEnable=${jmsPriorityEnable}"
debugMsg "jmsPriorityMapping=${jmsPriorityMapping}"
debugMsg "brkrSvcUrl=${brkrSvcUrl}"
debugMsg "webSvcUrl=${webSvcUrl}"
debugMsg "tgtNbtfHomeDir=${tgtNbtfHomeDir}"
debugMsg "dftNbStrdNum=${dftNbStrdNum}"
debugMsg "dftCmprsType=${dftCmprsType}"
debugMsg "dftPrdBatching=${dftPrdBatching}"
debugMsg "dftMsgPayloadStr=${dftMsgPayloadStr}"
debugMsg "dftMsgRespCntTracking=${dftMsgRespCntTracking}"
debugMsg "dftStrictMsgErrHandling=${dftStrictMsgErrHandling}"
debugMsg "dftSlowAckInSec=${dftSlowAckInSec}"
debugMsg "dftAckTimeoutInSec=${dftAckTimeoutInSec}"
debugMsg "dftDlqPolicyRaw=${dftDlqPolicyRaw}"
debugMsg "dftDlqPolicy=${dftDlqPolicy}"
debugMsg "dftAckTimeoutRedePolicyRaw=${dftAckTimeoutRedePolicyRaw}"
debugMsg "dftAckTimeoutRedePolicy=${dftAckTimeoutRedePolicy}"
debugMsg "dftNegAckRedePolicyRaw=${dftNegAckRedePolicyRaw}"
debugMsg "dftNegAckRedePolicy=${dftNegAckRedePolicy}"
debugMsg "nbLogLvl=${nbLogLvl}"
debugMsg "jwtTokenFileNoPath=${jwtTokenFileNoPath}"
debugMsg "tlsCaCertFileNoPath=${tlsCaCertFileNoPath}"
debugMsg "pgeMetricsSrv=${pgeMetricsSrv}"


if [[ -z ${tcNamePattern} || -z ${useAsync} || -z ${blockingMsgRecv} || -z ${simuUserPwd} || -z ${useTransStickyPart} || 
      -z ${jmsPriorityEnable} || -z ${jmsPriorityMapping} || -z ${brkrSvcUrl} || -z ${webSvcUrl} || -z ${tgtNbtfHomeDir} || 
      -z ${dftNbStrdNum} || -z ${dftPrdBatching} || -z ${dftMsgPayloadStr} || -z ${dftMsgRespCntTracking} || 
      -z ${dftStrictMsgErrHandling} ||-z ${dftSlowAckInSec} || -z ${dftAckTimeoutInSec} || 
      -z ${dftDlqPolicyRaw} || -z ${dftAckTimeoutRedePolicyRaw} || -z ${jwtTokenFileNoPath} || -z ${tlsCaCertFileNoPath} ]]; 
then
    echo "[ERROR] Invalid empty value for the following mandatory input parameters." 
    echo "        ('-tcNamePattern', '-useAsync', '-blockingMsgRecv', '-simuUserPwd', '-useTransStickyPart', '-jmsPriorityEnable', "
    echo "         '-jmsPriorityMapping', '-brkrSvcUrl', '-webSvcUrl', '-tgtNbtfHomeDir', -dftNbStrdNum', '-dftPrdBatching', "
    echo "         '-dftMsgPayloadStr', '-dftMsgRespCntTracking', '-dftStrictMsgErrHandling', '-dftSlowAckInSec', '-dftAckTimeoutInSec', "
    echo "         '-dftDlqPolicy', '-dftAckTimeoutRedePolicy', '-jwtTokenFileNoPath', '-tlsCaCertFileNoPath')"
    exit 30
fi

re='(true|false)'
if ! [[ ${useAsync} =~ $re && ${blockingMsgRecv} =~ $re && ${simuUserPwd} =~ $re && 
        ${useTransStickyPart} =~ $re && ${jmsPriorityEnable} && ${dftPrdBatching} =~ $re && 
        ${dftMsgRespCntTracking} =~ $re && ${dftStrictMsgErrHandling} =~ $re ]]; then
    echo "[ERROR] Invalid value for the following input parameters. Value 'true' or 'false' is expected." 
    echo "        ('-useAsync', '-blockingMsgRecv', '-simuUserPwd', '-useTransStickyPart', '-jmsPriorityEnable', "
    echo "         '-dftPrdBatching', '-dftMsgRespCntTracking', '-dftStrictMsgErrHandling')"
    exit 40
fi

TESTCASE_RAWDEF_HOMEDIR=testcases/raw_definition
if ! [[ -d ${TESTCASE_RAWDEF_HOMEDIR} ]]; then
    echo "[ERROR] Test case raw definition folder doesn't exist!." 
    exit 50
fi

GEN_FILE_HOMEDIR=testcases/_generated_nbscn_files_
if ! [[ -d ${GEN_FILE_HOMEDIR} ]]; then
    mkdir -p ${GEN_FILE_HOMEDIR}
fi


outputMsg
outputMsg "Generate NB S4J test cases (and test scenarios) from the raw definition file... "
outputMsg

# Process each test case represented as a sub-directory under ${TESTCASE_RAWDEF_HOMEDIR}
find ${TESTCASE_RAWDEF_HOMEDIR}/* -prune -type d -name "*${tcNamePattern}*" | while IFS= read -r TC_NAME_L; do 
    # TC_NAME_L : testcases/raw_definition/testcase1
    debugMsg "***DIRNAME=${TC_NAME_L}"
    if [[ -n "${TC_NAME_L}" ]]; then
        # TC_NAME_S : testcase1
        TC_NAME_S=$(echo "${TC_NAME_L}" | awk -F/ '{print $NF}')
        debugMsg "FILENAME=${TC_NAME_S}"
        # Process each line of the testcase raw definition file, which represents
        #   a unique test scenario with the current test case
        lineCnt=0
        outputMsg ">> Process test scenarios for test case: ${TC_NAME_S} ..."
        outputMsg
        while read LINE; do
            # Ignore comments
            case "$LINE" in \#*) continue ;; esac

            if [[ -n "${LINE// }" ]]; then

                #
                # TODO: add field validity check
                # 

                TCS_NAME=${TC_NAME_S}_scn${lineCnt}

                lineCnt=$((lineCnt+1))
                IFS=',' read -r -a FIELDS <<< "${LINE#/}"

                test_exec_idstr=${FIELDS[0]}

                client_type=$(echo ${FIELDS[1]} | tr '[:upper:]' '[:lower:]')
                
                prd_batching_enabled=${FIELDS[2]}
                if [[ -z "${prd_batching_enabled}" ]]; then
                    prd_batching_enabled=${dftPrdBatching}
                fi
                prd_batching_enabled=$(echo ${prd_batching_enabled} | tr '[:upper:]' '[:lower:]')

                dstype=$(echo ${FIELDS[3]} | tr '[:upper:]' '[:lower:]')
                if [[ "t" == "${dstype}" ]]; then
                    dest_type=topic
                elif [[ "q" == "${dstype}" ]]; then
                    dest_type=queue
                else
                    dest_type=invalid_dest_type
                fi
                ## Topic/Queue name, which could be the following format
                #  - persistent://tenant/namespace/topic
                #    * NO explicit subscription name
                #    * subscription name must be specified as FIELDS[6]
                #  - persistent://tenant/namespace/topic:subscription
                #    * WITH explicit subscription name
                #    * FIELDS[6] must be empty (and will be ignored if not empty)
                #  - multi:persistent://tenant1/namespace1/topic1+persistent://tenant2/namespace2/topic2:subscription
                #    * explicit topic list with a subscription name
                #  - regex:persistent://tenant/namespace/<topic_pattern>:subscription
                #    * explicit topic pattern with a subscription name 
                dest_name=${FIELDS[4]}
                subcrb_type=$(echo ${FIELDS[5]} | tr '[:upper:]' '[:lower:]')
                # subscription name
                subcrb_name=${FIELDS[6]}
                num_client=${FIELDS[7]}
                num_conn=${FIELDS[8]}
                num_sess=${FIELDS[9]}
                sess_mode=${FIELDS[10]}
                txn_num=${FIELDS[11]}
                msg_ack_ratio=${FIELDS[12]}
                cycle_cnt=${FIELDS[13]}
                cycle_rate=${FIELDS[14]}
                
                ctrl_exec=${FIELDS[15]}
                if [[ -z "${ctrl_exec}" ]]; then
                    ctrl_exec=0
                fi
                
                msg_prop_defstr=$(echo ${FIELDS[16]} | tr '[:upper:]' '[:lower:]')
                msg_payload_defstr=$(echo ${FIELDS[17]} | tr '[:upper:]' '[:lower:]')
                
                msg_comprs_type=$(echo ${FIELDS[18]} | tr '[:upper:]' '[:lower:]')
                if [[ -z "${msg_comprs_type}" ]]; then
                    msg_comprs_type=${dftCmprsType}
                fi
                msg_comprs_type=$(echo ${msg_comprs_type} | tr '[:lower:]' '[:upper:]')
                # "n/a" is an arbitraily set value that represents "no value"
                if [[ "${msg_comprs_type}" == "NA" ]]; then
                    msg_comprs_type=" "
                fi

                # Simulate slow acknowledgement
                # - must be >= 0
                # - 0 means no simulation
                # - positive value means how many seconds to pause before doing ack
                slow_ack_in_sec=${FIELDS[19]}
                if [[ -z "${slow_ack_in_sec}" ]]; then
                    slow_ack_in_sec=${dftSlowAckInSec}
                    if [[ ${slow_ack_in_sec} -lt 0 ]]; then
                        slow_ack_in_sec=0
                    fi
                fi          

                # Test scenario level Ack Timeout
                # - must be >= 0
                # - 0 means no timeout
                tc_ack_timeout_in_sec=${FIELDS[20]}
                if [[ -z "${tc_ack_timeout_in_sec}" ]]; then
                    tc_ack_timeout_in_sec=${dftAckTimeoutInSec}
                    if [[ ${tc_ack_timeout_in_sec} -lt 0 ]]; then
                        tc_ack_timeout_in_sec=0
                    fi
                fi
                tc_ack_timeout_in_ms=$((tc_ack_timeout_in_sec*1000))

                # Test scenario level DLQ related policies
                tc_dlq_policy_raw=${FIELDS[21]}
                tc_ack_timeout_in_sec_redelivery_policy_raw=${FIELDS[22]}
                tc_neg_ack_redelivery_policy_raw=${FIELDS[23]}

                if [[ ${tc_ack_timeout_in_sec} -eq 0 ]]; then
                    tc_dlq_policy_raw=""
                    tc_ack_timeout_in_sec_redelivery_policy_raw=""
                    tc_neg_ack_redelivery_policy_raw=""
                # Only apply DLQ polices when ack timeout value is set
                else
                    if [[ -n "${tc_dlq_policy_raw}" ]]; then
                        tc_dlq_policy=$(convertRawDlqPolicyToValidJson ${tc_dlq_policy_raw})
                    fi

                    if [[ -n "${tc_ack_timeout_in_sec_redelivery_policy_raw}" ]]; then
                        tc_ack_timeout_in_sec_redelivery_policy=$(convertRawDlqPolicyToValidJson ${tc_ack_timeout_in_sec_redelivery_policy_raw})
                    fi
                    
                    if [[ -n "${tc_neg_ack_redelivery_policy_raw}" ]]; then
                        tc_neg_ack_redelivery_policy=$(convertRawDlqPolicyToValidJson ${tc_neg_ack_redelivery_policy_raw})
                    fi
                fi

                # template NB yaml file name
                if [[ "p" == "${client_type}" ]]; then
                    template_yaml_file=nb_yaml_msnd.tmpl
                elif [[ "ndns" == "${subcrb_type}" ]]; then
                    template_yaml_file=nb_yaml_mrd_ndns.tmpl
                elif [[ "dns" == "${subcrb_type}" ]]; then
                    template_yaml_file=nb_yaml_mrd_dns.tmpl
                elif [[ "nds" == "${subcrb_type}" ]]; then
                    template_yaml_file=nb_yaml_mrd_nds.tmpl
                else
                    template_yaml_file=nb_yaml_mrd_ds.tmpl
                fi

                # message property json template file
                # - only relevant when clint_type is 'p' (producer)
                if [[ "p" == "${client_type}" ]]; then
                    if [[ -z "${msg_prop_defstr}" || "default" == "${msg_prop_defstr}" ]]; then
                        msg_proper_json_template_file=templates/msg_prop/default.json
                    else
                        msg_proper_json_template_file=templates/msg_prop/${msg_prop_defstr}
                    fi
                    # message property json data into a variable
                    msg_proper_jsondata=$(cat ${msg_proper_json_template_file})
                    # - this text format is ready to be embbed within a string with double quote
                    # msg_proper_textdata=$(echo ${msg_proper_jsondata} | tr '\r' ' ' |  tr '\n' ' ' | sed "s/[']/\\\'/g" | sed 's/\"/\\"/g' | sed 's/ \{3,\}/ /g' | sed 's/   / /g')
                    msg_proper_textdata=$(echo ${msg_proper_jsondata} | tr '\r' ' ' |  tr '\n' ' ' | sed 's/ \{3,\}/ /g' | sed 's/   / /g' | sed -e 's/\ *$//g')
                fi

                # message playload definition string
                # - only relevant when clint_type is 'p' (producer)
                if [[ "p" == "${client_type}" ]]; then
                    if [[ -z "${msg_payload_defstr}" || "default" == "${msg_payload_defstr}" ]]; then
                        msg_payload_defstr="${dftMsgPayloadStr}"
                    fi
                fi           

                # generated NB file names - yaml, config, and nb cmd
                if [[ -z "${test_exec_idstr// }" ]]; then
                    nodeIdntfr=IDALL
                else 
                    nodeIdntfr=$(echo ${test_exec_idstr} | tr '[:lower:]' '[:upper:]')
                fi

                generated_nb_yaml_file_name=${nodeIdntfr}-${TCS_NAME}.yaml
                generated_nb_cfg_file_name=${nodeIdntfr}-${TCS_NAME}.properties
                generated_nb_cmd_file_name=${nodeIdntfr}-run_${TCS_NAME}.sh

                debugMsg "test_exec_idstr=${test_exec_idstr}"
                debugMsg "nodeIdntfr=${nodeIdntfr}"
                debugMsg "client_type=${client_type}"
                debugMsg "prd_batching_enabled=${prd_batching_enabled}"
                debugMsg "dest_type=${dest_type}"
                debugMsg "dest_name=${dest_name}"
                debugMsg "subcrb_type=${subcrb_type}"
                debugMsg "subcrb_name=${subcrb_name}"
                debugMsg "num_client=${num_client}"
                debugMsg "num_conn=${num_conn}"
                debugMsg "num_sess=${num_sess}"
                debugMsg "sess_mode=${sess_mode}"
                debugMsg "txn_num=${txn_num}"
                debugMsg "msg_ack_ratio=${msg_ack_ratio}"
                debugMsg "cycle_cnt=${cycle_cnt}"
                debugMsg "cycle_rate=${cycle_rate}"
                debugMsg "ctrl_exec=${ctrl_exec}"
                debugMsg "msg_prop_defstr=${msg_prop_defstr}"
                debugMsg "msg_payload_defstr=${msg_payload_defstr}"
                debugMsg "msg_comprs_type=${msg_comprs_type}"
                debugMsg "slow_ack_in_sec=${tc_ack_timeout_in_sec}"
                debugMsg "tc_ack_timeout_in_sec=${tc_ack_timeout_in_sec}"
                debugMsg "tc_dlq_policy_raw=${tc_dlq_policy_raw}"
                debugMsg "tc_dlq_policy=${tc_dlq_policy}"
                debugMsg "tc_ack_timeout_in_sec_redelivery_policy_raw=${tc_ack_timeout_in_sec_redelivery_policy_raw}"
                debugMsg "tc_ack_timeout_in_sec_redelivery_policy=${tc_ack_timeout_in_sec_redelivery_policy}"
                debugMsg "tc_neg_ack_redelivery_policy_raw=${tc_neg_ack_redelivery_policy_raw}"
                debugMsg "tc_neg_ack_redelivery_policy=${tc_neg_ack_redelivery_policy}"
                debugMsg "template_yaml_file=${template_yaml_file}"
                debugMsg "msg_proper_json_template_file=${msg_proper_json_template_file}"
                debugMsg "msg_proper_jsondata=${msg_proper_jsondata}"
                debugMsg "generated_nb_yaml_file_name=${generated_nb_yaml_file_name}"
                debugMsg "generated_nb_cfg_file_name=${generated_nb_cfg_file_name}"
                debugMsg "generated_nb_cmd_file_name=${generated_nb_cmd_file_name}"

                outputMsg "${TCS_NAME}: ${LINE}"
                #
                # Create NB S4J yaml file from the template
                # ----------------------------------------------------
                #            
                if ! [[ -f templates/nb_yaml/${template_yaml_file} ]]; then
                    echo "[ERROR] The expected NB yaml template file (templates/nb_yaml/${template_yaml_file}) doesn't exist!" 
                    exit 60
                fi

                GEND_YAML_FILE=${GEN_FILE_HOMEDIR}/${generated_nb_yaml_file_name}
                debugMsg "GEND_YAML_FILE=${GEND_YAML_FILE}"

                outputMsg "++ creating NB yaml file: ${GEND_YAML_FILE}"

                cp -f templates/nb_yaml/${template_yaml_file} ${GEND_YAML_FILE}
                
                ## NOTE: requiers GNU sed. The default MacOS sed has syntax error
                sed -i "s/<TMPL-ASYNC_API>/${useAsync}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-DEST_TYPE>/${dest_type}/g" ${GEND_YAML_FILE}

                # dest_name may contain '/' (e.g persistent:/public/default/topic),
                #   which will mess up sed operation
                dest_name2=$(echo ${dest_name} | sed 's/\//\\\//g')
                debugMsg "dest_name2=${dest_name2}"
                
                # dest_name may also contain '+' in static multi-topic list,
                #   need to replace '+' to ',' so the S4J API can use it properly
                dest_name3=$(echo ${dest_name2} | sed 's/+/,/g')
                debugMsg "dest_name3=${dest_name3}"
                sed -i "s/<TMPL-DEST_NAME>/${dest_name3}/g" ${GEND_YAML_FILE}
                
                sed -i "s/<TMPL-TXN_BATCH_NUM>/${txn_num}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-BLOCKING_MSG_RECV>/${blockingMsgRecv}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-MSG_ACK_RATIO>/${msg_ack_ratio}/g" ${GEND_YAML_FILE}

                # subscr_name may contain '/' as well
                subcrb_name2=$(echo ${subcrb_name} | sed 's/\//\\\//g')
                debugMsg "subcrb_name2=${subcrb_name2}" 
                sed -i "s/<TMPL-SUB_NAME>/${subcrb_name2}/g" ${GEND_YAML_FILE}
                
                sed -i "s/<TMPL-MSG_PAYLOAD_DISTRO_STRING>/${msg_payload_defstr}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-MSG_PROP_JSON_STR>/${msg_proper_textdata}/g" ${GEND_YAML_FILE}

                sed -i "s/<TMPL-SLOW_ACK_IN_SEC>/${slow_ack_in_sec}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-ACK_TIMEOUT>/${tc_ack_timeout_in_ms}/g" ${GEND_YAML_FILE}
                # tc_dlq_policy may contain '/' as well
                tc_dlq_policy2=$(echo ${tc_dlq_policy} | sed 's/\//\\\//g')
                sed -i "s/<TMPL-DLQ_POLICY>/${tc_dlq_policy2}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-ACK_TIMEOUT_REDELIVERY>/${tc_ack_timeout_in_sec_redelivery_policy}/g" ${GEND_YAML_FILE}
                sed -i "s/<TMPL-NEG_ACK_REDELIVERY>/${tc_neg_ack_redelivery_policy}/g" ${GEND_YAML_FILE}

                #
                # Create NB S4J config property file from the template
                # ----------------------------------------------------
                #
                if ! [[ -f templates/nb_cfg/s4j_config.tmpl ]]; then
                    echo "[ERROR] The expected NB config template file (templates/nb_cfg/s4j_config.tmpl) doesn't exist!" 
                    exit 70
                fi

                GEND_CFG_FILE=${GEN_FILE_HOMEDIR}/${generated_nb_cfg_file_name}
                debugMsg "GEND_CFG_FILE=${GEND_CFG_FILE}"

                outputMsg "++ creating NB config file: ${GEND_CFG_FILE}"
                cp -f templates/nb_cfg/s4j_config.tmpl ${GEND_CFG_FILE}
                if [[ "queue" == "$dest_type" ]]; then
                     debugMsg "S4J Config Template file for dest_type=${dest_type}"
                     cp -f templates/nb_cfg/s4j_config_queue.tmpl ${GEND_CFG_FILE}
                     sed -i "s/<TMPL-SUB_NAME>/${subcrb_name2}/g" ${GEND_CFG_FILE}
                fi
   
                sed -i "s/<TMPL-USER_PASSWORD_SIMULATION>/${simuUserPwd}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-USE_TRANSCT_STICKY_PARTITION>/${useTransStickyPart}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-COMPRESSION_TYPE>/${msg_comprs_type}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-BATCHING_ENABLED>/${prd_batching_enabled}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-CFG_ACK_TIMEOUT>/${dftAckTimeoutInSec}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-CFG_DLQ_POLICY>/${dftDlqPolicy}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-CFG_ACK_TIMEOUT_REDELIVERY_POLICY>/${dftAckTimeoutRedePolicy}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-CFG_NEG_ACK_REDELIVERY_POLICY>/${dftNegAckRedePolicy}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-ENABLE_JMS_PRIORITY>/${jmsPriorityEnable}/g" ${GEND_CFG_FILE}
                sed -i "s/<TMPL-PRIORITY_MAPPING>/${jmsPriorityMapping}/g" ${GEND_CFG_FILE}

                # TLS ca cert file full path
                TLS_CACERT_FILE="${tgtNbtfHomeDir}/config/pulsar_conn/${tlsCaCertFileNoPath}"
                TLS_CACERT_FILE2=$(echo ${TLS_CACERT_FILE} | sed 's/\//\\\//g')
                debugMsg "TLS_CACERT_FILE2=${TLS_CACERT_FILE2}"
                sed -i "s/<TMPL-TLS_TRUST_CERT_FILE>/${TLS_CACERT_FILE2}/g" ${GEND_CFG_FILE}
                
                # JWT token
                if [[ "false" == "${simuUserPwd}" ]]; then
                    JWT_TOKEN_FILE="file://${tgtNbtfHomeDir}/config/pulsar_conn/${jwtTokenFileNoPath}"
                    JWT_TOKEN_FILE2=$(echo ${JWT_TOKEN_FILE} | sed 's/\//\\\//g')
                    debugMsg "JWT_TOKEN_FILE2=${JWT_TOKEN_FILE2}"
                    sed -i "s/<TMPL-AUTH_TOKEN>/${JWT_TOKEN_FILE2}/g" ${GEND_CFG_FILE}
                else
                    TOKEN_VAL=$(cat pulsar_conn/${jwtTokenFileNoPath})
                    debugMsg "TOKEN_VAL=${TOKEN_VAL}"
                    sed -i "s/<TMPL-AUTH_TOKEN>/token:${TOKEN_VAL}/g" ${GEND_CFG_FILE}
                fi
                
                #
                # Create NB S4J cmd bash file from the template
                # ----------------------------------------------------
                #
                GEND_CMD_FILE=${GEN_FILE_HOMEDIR}/${generated_nb_cmd_file_name}
                outputMsg "++ creating NB cmd bash file: ${GEND_CMD_FILE}"

                echo "" > ${GEND_CMD_FILE}
                echo "#! /bin/bash" >> ${GEND_CMD_FILE}
                echo "" >> ${GEND_CMD_FILE}
                echo "${tgtNbtfHomeDir}/bin/nbs4j_cmd.sh \\" >> ${GEND_CMD_FILE}
                echo "    -nbCfg ${tgtNbtfHomeDir}/scenarios/nb_cfg/${TCS_NAME}.properties \\" >> ${GEND_CMD_FILE}
                echo "    -webUrl ${webSvcUrl} \\" >> ${GEND_CMD_FILE}
                echo "    -svcUrl ${brkrSvcUrl} \\" >> ${GEND_CMD_FILE}
                echo "    -scnFile ${tgtNbtfHomeDir}/scenarios/nb_yaml/${TCS_NAME}.yaml \\" >> ${GEND_CMD_FILE}
                echo "    -cycNum ${cycle_cnt} \\" >> ${GEND_CMD_FILE}
                echo "    -thrNum ${num_client} \\" >> ${GEND_CMD_FILE}
                echo "    -strdNum ${dftNbStrdNum} \\" >> ${GEND_CMD_FILE}
                echo "    -numConn ${num_conn} \\" >> ${GEND_CMD_FILE}
                echo "    -numSess ${num_sess} \\" >> ${GEND_CMD_FILE}
                if [[ -n "${sess_mode// }" ]]; then
                    echo "    -sessMod ${sess_mode} \\" >> ${GEND_CMD_FILE}                    
                fi
                if [[ -n "${dftMsgRespCntTracking// }" ]]; then
                    echo "    -trackMsgRespCnt ${dftMsgRespCntTracking} \\" >> ${GEND_CMD_FILE}                    
                fi
                if [[ -n "${dftStrictMsgErrHandling// }" ]]; then
                    echo "    -strictMsgErrHandling ${dftStrictMsgErrHandling} \\" >> ${GEND_CMD_FILE}                    
                fi
                echo "    -logDir ${tgtNbtfHomeDir}/logs/${TCS_NAME} \\" >> ${GEND_CMD_FILE}
                if [[ -n "${nbLogLvl// }" ]]; then
                    echo "    -logLvl ${nbLogLvl} \\" >> ${GEND_CMD_FILE}
                fi
                if [[ -n "${cycle_rate// }" && ${cycle_rate} -gt 0 ]]; then
                    echo "    -cycRateThread ${cycle_rate} \\" >> ${GEND_CMD_FILE}
                fi
                if [[ -n "${pgeMetricsSrv// }" ]]; then
                    echo "    -pgeMetricsSrv ${pgeMetricsSrv} \\" >> ${GEND_CMD_FILE}
                fi
                # echo "    -tcsName ${TCS_NAME} \\" >> ${GEND_CMD_FILE}
                echo "    -ctrlExec ${ctrl_exec}" >> ${GEND_CMD_FILE}
                outputMsg
            fi
        done < ${TC_NAME_L}/definition
        outputMsg
    fi
done