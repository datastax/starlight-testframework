# Overview

This repo contains a framework and tools that can be used to fully **automated** testing of Starlight clients.  Using this framework, a developer can run a series Apache Pulsar oriented **test cases** that mimic real-world workloads on a Pulsar Cluster. Each test case has as set of its own **test scenarios**. The execution of all the test cases can follow an execution schedule.  It allows for simulating many different workloads, like # of Producers, Consumers, Message Size and rates, "slow downs of consumers", "burst of messages", consumer backlogs, etc.

This test framework is based on the [NoSQLBench (NB)](https://github.com/nosqlbench/nosqlbench) utility, with specific drivers for each Starlight client, like [Starlight for JMS (S4J) driver](https://github.com/nosqlbench/nosqlbench/tree/nb4-maintenance).

# Starlight Client Tests
See **[Starlight-for-Jms](starlight-for-jms/)** for info on JMS workload testing.

