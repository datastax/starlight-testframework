#! /bin/bash
# Note - Define PATH to localhost Pulsar software binaries
## Nothing to do for pre_task in this testcase4, just start the producers
export PATH=~/current/bin:$PATH
#pulsar-shell -c $PWD/pulsar_conn/client.conf \
#   -f $PWD/testcases/raw_definition/testcase4_producers/create_topics.txt -np
sleep 2
