#! /bin/bash
# Note - Define PATH to localhost Pulsar software binaries
export PATH=~/current/bin:$PATH
pulsar-shell -c $PWD/pulsar_conn/client.conf \
   -f $PWD/testcases/raw_definition/testcase4_consumers_backlog/create_topics.txt -np
sleep 1
