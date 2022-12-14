
**NOTE**: 

1) This branch only has the S4J test framework and it is based on [NoSQLBench version 4 (NB4)](https://github.com/nosqlbench/nosqlbench/tree/nb4-maintenance) which is deprecated. Please use the main branch for the latest [NoSQLBench version 5 (NB5)](https://github.com/nosqlbench/nosqlbench) which also covers S4K and S4R frameworks.

2) The NB testing scenario yaml file havs some format difference between NB4 and NB5. Because of that, the NB4- and NB5- based S4J test frameworks are not compatible with each other.

---

# Overview

This repo contains a framework and tools that can be used to fully **automated** testing of Starlight clients.  Using this framework, a developer can run a series Apache Pulsar oriented **test cases** that mimic real-world workloads on a Pulsar Cluster. Each test case has as set of its own **test scenarios**. The execution of all the test cases can follow an execution schedule.  It allows for simulating many different workloads, like # of Producers, Consumers, Message Size and rates, "slow downs of consumers", "burst of messages", consumer backlogs, etc.

This test framework is based on the [NoSQLBench (NB)](https://github.com/nosqlbench/nosqlbench) utility, with specific drivers for each Starlight client, like [Starlight for JMS (S4J) driver](https://github.com/nosqlbench/nosqlbench/tree/nb4-maintenance).

# Starlight Client Tests
See **[Starlight-for-Jms](starlight-for-jms/)** for info on JMS workload testing.  Ready to use [testcases](starlight-for-jms/testcases/raw_definition/) to simulate JMS workloads on Pulsar.  See [README](starlight-for-jms/README.md) for details.

Coming soon, additional Starlight Client test frameworks, [Starlight-for-RabbitMQ](starlight-for-rabbitmq/) and [Starlight-for-Kafka](starlight-for-kafka/).

