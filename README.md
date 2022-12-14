**NOTE**: 

This test framework is based on the lastest [NoSQLBench utility version 5 (NB5, or simply NB)](https://github.com/nosqlbench/nosqlbench). Older versions of NB won't work with this test framework.

---

# Overview

This repo contains a framework and tools that can be used to fully **automated** testing of Starlight clients.  Using this framework, a developer can run a series Apache Pulsar oriented **test cases** that mimic real-world workloads on a Pulsar Cluster. Each test case has as set of its own **test scenarios**. The execution of all the test cases can follow an execution schedule.  It allows for simulating many different workloads, like # of Producers, Consumers, Message Size and rates, "slow downs of consumers", "burst of messages", consumer backlogs, etc.

# Starlight Client Tests
See **[Starlight-for-Jms](starlight-for-jms/)** for info on JMS workload testing.  Ready to use [testcases](starlight-for-jms/testcases/raw_definition/) to simulate JMS workloads on Pulsar.  See [README](starlight-for-jms/README.md) for details.

Coming soon, additional Starlight Client test frameworks, [Starlight-for-RabbitMQ](starlight-for-rabbitmq/) and [Starlight-for-Kafka](starlight-for-kafka/).

