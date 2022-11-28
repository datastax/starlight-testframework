
- [1. Overview](#1-overview)
- [2. Test Case Details](#2-test-case-details)
  - [2.1 Running the Test Case](#21-running-the-test-case)
- [3. Test Case Results](#3-test-case-results)
  - [3.1 Further Results](#31-further-results)
# 1. Overview
This testcase simulates JMS filtering using Server-side JMS Selectors.  

**Important** - This testcase uses a pre-task.sh script to setup the required Pulsar subscriptions and JMS Selectors. See pre-task.sh file for details.

**NOTE** - This testcase requires the "pulsar-jms" plugin to enable JMS server-side filtering in Pulsar. See https://github.com/datastax/pulsar for details.

# 2. Test Case Details
See the **"definition"** file under the testcase folder for full details on the setup of the clients.

Note the use of NB S4J parameters show "ack ratio 1" to acknowledge all messages, and also note the setup of DLQ.
```
msg ack ratio "1", slow acks "0", Ack timeout "10", DLQ queue and redelivery setup
```
## 2.1 Running the Test Case

Follow the steps to setup the [Test Framework env](../../../README.md) as stated.  Then run these commands:
```
./01.deploy_nbs4j_tf.sh testcase3_jmsfilter true false
./03.run_testcase_by_name.sh -testCaseName testcase3_jmsfilter
```

# 3. Test Case Results
After the test case completes execution, retrieve all testcase related logs to your localhost.  In logfile, nbtf_pulsar_jms/logs/**testcase3_jmsfilter_scn1**/scenario_<"date">_<"time">_<"num">.log, you see the results of the consumer execution.  In this log, search for **"jms.selector"** to verify the JMS selector is setup.  You should see results like below:
```
<datetime> DEBUG: subscriptionPropertiesFromBroker {jms.filtering=true, jms.selector= TriggerEventType IN ('AA','AL','01','02','06','07','08','10','12','13','CE') OR ( TEST_MSG_BUCKET <= 73) }
<datetime> INFO : Detected selector  TriggerEventType IN ('AA','AL','01','02','06','07','08','10','12','13','CE') OR ( TEST_MSG_BUCKET <= 73)  on Subscription TEST.JMS.TOPIC.P3:TEST.JMS.Q on topic persistent://MYTENANT3/NS3/TEST.JMS.TOPIC.P3
```
This confirms the test case simulated "unacknowledged" messages and redelivery.
## 3.1 Further Results
Using Pulsar Admin, you can verify that messages were **filtered** shown by the command output **filterAcceptedMsgCount**.  Start a pulsar-admin session to the Pulsar Cluster and enter the command:
```
topics partitioned-stats MYTENANT3/NS3/TEST.JMS.TOPIC.P3
{
  "msgRateIn" : 0.0,
  "msgThroughputIn" : 0.0,
  "msgRateOut" : 0.0,
  . . .
  "subscriptions" : {
    "TEST.JMS.TOPIC.P3:TEST.JMS.Q" : {
      "msgRateOut" : 0.0,
      "msgThroughputOut" : 0.0,
      "bytesOutCounter" : 67801885,
      . . .
      "subscriptionProperties" : {
        "jms.filtering" : "true",
        "jms.selector" : " TriggerEventType IN ('AA','AL','01','02','06','07','08','10','12','13','CE') OR ( TEST_MSG_BUCKET <= 73) "
      },
      "filterProcessedMsgCount" : 6000,
      "filterAcceptedMsgCount" : 4437,
      "filterRejectedMsgCount" : 1563,
      "filterRescheduledMsgCount" : 0,      
```
NOTE - The **filterAcceptedMsgCount** value shows messages processed by the JMS filter.
