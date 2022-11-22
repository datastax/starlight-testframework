
- [1. Overview](#1-overview)
- [2. Test Case Details](#2-test-case-details)
  - [2.1 Running the Test Case](#21-running-the-test-case)
- [3. Test Case Results](#3-test-case-results)
  - [3.1 Further Results](#31-further-results)
# 1. Overview
This testcase simulates "unacknowledged" messages and "redirect" into a Dead Letter queue (DLQ) after the set # of redelivery attempts.  Use specific NB S4J parameters, as explained below, will cause this result.

# 2. Test Case Details
See the **"definition"** file under the testcase folder for full details on the setup of the clients.

Note the use of NB S4J parameters to cause message unacknowledge conditions, as well as slow acknowledgements.  Also note the setup of DLQ.
```
msg ack ratio "0", slow acks "3", DLQ queue and redelivery setup
```
## 2.1 Running the Test Case

(TODO add steps)

# 3. Test Case Results
After the test case completes execution, retrieve all testcase related logs to your localhost.  In logfile, nbtf_pulsar_jms/logs/**testcase2_dlq_scn1**/scenario_<"date">_<"time">_<"num">.log, you see the results of the consumer execution.  In this log, search for **"unack"** to verify messages were unacknowledged.  You should see results like below:
```
<datetime> INFO : [ConsumerBase{subscription='PERF.TEST.TOPIC.P3:PERF.TEST.Q.CON-168697', consumerName='1b85d', topic='persistent://MYTENANT2/NS2/PERF.TEST.TOPIC.P3'}] 2 messages will be re-delivered
<datetime> DEBUG: [PERF.TEST.TOPIC.P3:PERF.TEST.Q.CON-168697] [persistent://MYTENANT/NS1/PERF.TEST.TOPIC.P3-partition-0] [1b85d] Redeliver unacked messages and increase 0 permits
<datetime> DEBUG: [PERF.TEST.TOPIC.P3:PERF.TEST.Q.CON-168697] [persistent://MYTENANT/NS1/PERF.TEST.TOPIC.P3-partition-1] [1b85d] Redeliver unacked messages and increase 0 permits
```
This confirms the test case simulated "unacknowledged" messages and redelivery.
## 3.1 Further Results
Using Pulsar Admin, you can verify that messages were delivered to the Dead Letter Queue (DLQ).  Start a pulsar-admin session to the Pulsar Cluster and enter the command:
```
topics stats MYTENANT2/DLQ/PERF.TEST.Q.CON-168697.DLQ
{
  "msgRateIn" : 0.0,
  "msgThroughputIn" : 0.0,
  "msgRateOut" : 0.0,
  . . .
  "subscriptions" : {
    "PERF.TEST.Q.CON-168697.DLQ" : {
      "msgRateOut" : 0.0,
      "msgThroughputOut" : 0.0,
      "bytesOutCounter" : 0,
      "msgOutCounter" : 0,
      "msgRateRedeliver" : 0.0,
      "messageAckRate" : 0.0,
      "chunkedMessageRate" : 0,
      "msgBacklog" : 8877,
      . . .
```
NOTE - The **msgBacklog** value shows pending messages in the subscription, aka queue.  This confirms messages in the DLQ.
