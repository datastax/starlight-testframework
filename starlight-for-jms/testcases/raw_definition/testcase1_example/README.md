- [1. Overview](#1-overview)
- [2. Test Case Details](#2-test-case-details)
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
