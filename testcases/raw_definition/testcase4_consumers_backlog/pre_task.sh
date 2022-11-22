#! /bin/bash
# Note - Define PATH to localhost Pulsar software binaries
export PATH=~/current/bin:$PATH
pulsar-shell -c ~/newproject/nbs4j_test_jms_framework/pulsar_conn/client.conf \
   -f ~/newproject/nbs4j_test_jms_framework/testcases/raw_definition/testcase4_consumers_backlog/create_topics.txt -np
sleep 1
