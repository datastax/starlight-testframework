#! /bin/bash
# Note - this BASH run on your localhost
#
# If needed, it can run Pulsar Admin command like below
# Note - Define PATH to localhost Pulsar software binaries
export PATH=~/current/bin:$PATH
pulsar-shell -c ~/newproject/nbs4j_test_jms_framework/pulsar_conn/client.conf \
  -f ~/newproject/nbs4j_test_jms_framework/testcases/raw_definition/testcase2_dlq/clean_up.txt -np
