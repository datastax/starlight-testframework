- [1. Overview](#1-overview)
- [2. Test Case Details](#2-test-case-details)
  - [2.1 Running the Test Case](#21-running-the-test-case)
- [3. Test Case Results](#3-test-case-results)
# 1. Overview
This testcase is very simple, showing how to create JMS topic producer and a JMS topic consumer, with multiple connections and sessions

# 2. Test Case Details
See the **"definition"** file under the testcase folder for full details on the setup of the clients.

**Producer definition** 
In the definition file, we see the producer is created with this line:
```
pstal01,P,false,T,persistent://MYTENANT/NS1/PERF.TEST.TOPIC.P2,,,50,10,5,,10,1,1000M,1,2m,default,default,,,,,,
```
This producer will run on hostid "pstal01" as defined in the [test_hostnames](../../../README.md) file.  See the testcase raw definition file section for explanation of the parameters.  Note the comma "," for empty values in the string.

The consumer is created with this line:
```
pstal02,C,false,T,persistent://MYTENANT/NS1/PERF.TEST.TOPIC.P2,nds,mySub,50,10,5,individual_ack,10,1,1000M,1,3m,,,,0,10,,,minDelayMs:10+maxDelayMs:10+multiplier:2.0,
```
This consumer will run on hostid "pstal02".  

## 2.1 Running the Test Case

Follow the steps to setup the [Test Framework env](../../../README.md) as stated.  Then run these commands:
```
./01.deploy_nbs4j_tf.sh testcase1_example true false
./03.run_testcase_by_name.sh -testCaseName testcase1_example
```
# 3. Test Case Results
After the test case completes execution, retrieve all testcase related logs to your localhost.  In logfile, nbtf_pulsar_jms/logs/**testcase1_example_scn1**/scenario_<"date">_<"time">_<"num">.log, you see the results of the consumer execution.  In this log, search for **"ack"** to verify messages were received and acknowledged.