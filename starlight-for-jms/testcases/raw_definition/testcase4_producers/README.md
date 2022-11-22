
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

Start all producers
```
# Example Producer to a topic, 50 clients, 10 connections, 5 sessions per connection, defaults on msg props and content
pstal01,P,false,T,persistent://MYTENANT4/NS4/TEST.JMS.TOPIC.P3......
# Another producer
pstal02,P,false,T,persistent://MYTENANT4/NS4/TEST.JMS.TOPIC.P3......
```

## 2.1 Running the Test Case

This testcase is executed by the schedule script.  Command:
```
./02.run_testcase_by_schedule.sh
```

# 3. Test Case Results
After the test case completes execution, retrieve all testcase related logs to your localhost.  In logfile, nbtf_pulsar_jms/logs/by_schedule/<<"datetime">>/testcase4_producers_scnN**/scenario_<"date">_<"time">_<"num">.log, you see the results of the consumer execution.  In this log, search for **"connected"** to verify the consumer is connected and processing nessages.  You should see results like below:
```
<datetime> INFO : [[id: 0xe7cd15d9, L:/10.166.93.178:49308 - R:10.166.91.141/10.166.91.141:6650]] Connected to server
```

## 3.1 Further Results
Using Pulsar Admin, you can verify that producers, aka "publishers" are connected.  Start a pulsar-admin session to the Pulsar Cluster and enter the command:
```
topics partitioned-stats MYTENANT3/NS3/TEST.JMS.TOPIC.P3
{
  "msgRateIn" : 0.0,
  "msgThroughputIn" : 0.0,
  "msgRateOut" : 0.0,
  . . .
  "publishers" : [ ],
  . . .
        
```
