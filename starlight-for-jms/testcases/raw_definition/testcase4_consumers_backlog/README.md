
- [1. Overview](#1-overview)
- [2. Test Case Details](#2-test-case-details)
  - [2.1 Running the Test Case](#21-running-the-test-case)
- [3. Test Case Results](#3-test-case-results)
  - [3.1 Further Results](#31-further-results)
# 1. Overview
This testcase simulates JMS consumers "offline" initially then started.  This testcase should be executed by schedule, to ensure the proper order of the testcase executions, testcase4_consumers_backlog, testcase4_producers, testcase4_consumers_catchup.

This testcase simiulates a backlogging condition and then catch-up of the offline consumers.

**NOTE** - This testcase requires the "pulsar-jms" plugin to enable JMS server-side filtering in Pulsar. See https://github.com/datastax/pulsar for details.

# 2. Test Case Details
See the **"definition"** file under the testcase folder for full details on the setup of the clients.

Note the use of NB S4J parameters show "ack ratio 1" to acknowledge all messages, and also note the setup of DLQ.
Start all consumers except for "Q2"
```
# Another Consumer  Comment out to simulate "offline"
# pstal03,C,false,Q,persistent://MYTENANT4/NS4/TEST.JMS.TOPIC.P3:TEST.JMS.Q2,.....
```
**Important** - This testcase uses a pre-task.sh script to setup the required Pulsar subscriptions and JMS Selectors. See pre-task.sh file for details.

## 2.1 Running the Test Case

This testcase is executed by the schedule script.  Command:
```
./02.run_testcase_by_schedule.sh
```

# 3. Test Case Results
After the test case completes execution, retrieve all testcase related logs to your localhost.  In logfile, nbtf_pulsar_jms/logs/by_schedule/<<"datetime">>/testcase4_consumers_backlog_scnN**/scenario_<"date">_<"time">_<"num">.log, you see the results of the consumer execution.  In this log, search for **"connected"** to verify the consumers is connected and processing nessages.  You should see results like below:
```
<datetime> INFO : [[id: 0xe7cd15d9, L:/10.166.93.178:49308 - R:10.166.91.141/10.166.91.141:6650]] Connected to server
```

## 3.1 Further Results
Using Pulsar Admin, you can verify consumers are connected.  Start a pulsar-admin session to the Pulsar Cluster and enter the command:
```
topics partitioned-stats MYTENANT4/NS4/TEST.JMS.TOPIC.P3
{
  "msgRateIn" : 0.0,
  "msgThroughputIn" : 0.0,
  "msgRateOut" : 0.0,
  . . .
  "consumers" : [ {
        "msgRateOut" : 0.0,
        "msgThroughputOut" : 0,
        "bytesOutCounter" : 0,
        "msgOutCounter" : 0,
        "msgRateRedeliver" : 0.0,
        "messageAckRate" : 0,
        "chunkedMessageRate" : 0.0,
        "availablePermits" : 0,
        "unackedMessages" : 0,
        "avgMessagesPerEntry" : 0,
        "blockedConsumerOnUnackedMsgs" : false,
        "lastAckedTimestamp" : 0,
        "lastConsumedTimestamp" : 0
      }, {
        "msgRateOut" : 0.0
    . . .
  
```

