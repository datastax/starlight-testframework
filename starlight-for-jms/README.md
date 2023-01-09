- [1. Overview](#1-overview)
  - [1.1. Ansible, bash, and python version](#11-ansible-bash-and-python-version)
  - [1.2 Local variable setup](#12-local-variable-setup)
- [2. Highlevel Steps and Requirements](#2-highlevel-steps-and-requirements)
  - [2.1 Requirements for Pulsar Admin](#21-requirements-for-pulsar-admin)
  - [2.3 Group\_vars "all" file](#23-group_vars-all-file)
- [3. Test Case Raw Definition and Execution Schedule](#3-test-case-raw-definition-and-execution-schedule)
  - [3.1. Test Case Execution Schedule](#31-test-case-execution-schedule)
  - [3.2. Pre- and Post- Task Scripts](#32-pre--and-post--task-scripts)
  - [3.3. Test Case Raw Definition File](#33-test-case-raw-definition-file)
  - [3.4. JMS Message Properties template](#34-jms-message-properties-template)
- [4. Set up Testing Framework Environment on remote hosts](#4-set-up-testing-framework-environment-on-remote-hosts)
  - [4.1 Step - **bash/buildAnsiHostInvFile.sh**](#41-step---bashbuildansihostinvfilesh)
    - [4.1.1 bash/buildAnsiHostInvFile.sh Inputs and Outputs](#411-bashbuildansihostinvfilesh-inputs-and-outputs)
  - [4.2 Step - **00.setup\_environment.sh**](#42-step---00setup_environmentsh)
- [5. Translate Test Case Raw Definition to NB S4J Testing Files](#5-translate-test-case-raw-definition-to-nb-s4j-testing-files)
  - [5.1. Test Scenario Matching Host ID (TODO updates needed below)](#51-test-scenario-matching-host-id-todo-updates-needed-below)
- [6. Execute Test Cases](#6-execute-test-cases)
  - [6.1 Execute Test Cases by Schedule](#61-execute-test-cases-by-schedule)
  - [6.2 Execute Test Case By Name](#62-execute-test-case-by-name)
- [7. Stop and Cleanup of Test Execution](#7-stop-and-cleanup-of-test-execution)
- [8. Test Case logfiles - Retrieve remote logfiles from testing hosts](#8-test-case-logfiles---retrieve-remote-logfiles-from-testing-hosts)
- [9. Example Testcases](#9-example-testcases)
- [10. Metrics and Monitoring of Test Clients](#10-metrics-and-monitoring-of-test-clients)

---

# 1. Overview

This repo contains bash scripts and Ansible scripts that are used as a fully **automated** testing framework to run a series Apache Pulsar oriented **test cases** that mimic a set of existing JMS test cases. Each test case has as set of its own **test scenarios**. The execution of all the test cases follow an execution schedule.  It allows for simulating many different JMS workloads, like # of Producers, Consumers, Message Size and rates, "slow downs of consumers", "burst of messages, consumer backlogs, etc.

Within this testing framework (aka "***NBTF S4J***"), a **test scenario** is the smallest testing execution unit that is based on the [NoSQLBench (NB)](https://github.com/nosqlbench/nosqlbench) utility, [Starlight for JMS (S4J) driver](https://github.com/nosqlbench/nosqlbench/tree/nb4-maintenance).
This testing framework is responsible for translating the *raw* test scenario definitions (will be explained with more details below) into NB S4J based testing files and then use the NB engine to execute them accordingly.

Please ***NOTE*** that:
* The [S4J API](https://github.com/datastax/pulsar-jms) is a DataStax library that allows existing JMS applications to connect to an Apache Pulsar cluster and send or receive messages natively following the JMS protocol.
* The NB S4J driver is the NB driver specifically for using the DataStax S4J API to simulate  JMS message publishing and/or receiving workloads against an Apache Pulsar cluster.

## 1.1. Ansible, bash, and python version
The following software version needs to be met in order to run the scripts successfully.

Ansible: 2.10+ (tested with version 2.12.x and 2.13.x)
Bash: 4.0+ (tested with GNU bash version 5.2.2)
Python: 3.x (tested with version 3.7.10)

## 1.2 Local variable setup
Serveral localhost environments variables are needed for BASH and Ansible scripts to running correctly.  Bash script **setenv_automation.sh** defines these variables.  It is "sourced-in" to most other scripts in this repo.  Update the script with proper valuse before running other NB S4J scripts.

**setenv_automation.sh** contents:
```
ANSI_SSH_PRIV_KEY="<ssh_private_key_file_path>"
ANSI_SSH_USER="<ssh_user_name>"
ANSI_DEBUG_LVL="[ |-v|-vv|-vvv]"
TEST_HOSTNAMES_DIR="<test_hostname_example>"
```

# 2. Highlevel Steps and Requirements
Here are the highlevel steps for using this framework for executing Testcases.
* Define Testcases, see Step [3.](#3-test-case-raw-definition-and-execution-schedule)
* Define the testing environment, where the NBTF S4J clients will run.  This is usually many VMs, each running specific NBTF S4J clients.  See Step N
  * Update files to connect the Pulsar Cluster:
    * **group_vars/all** file parameters [ in the "all" file](#23-group_vars-all-file)
      * **pulsar_web_url:** and **pulsar_svc_url:**
    * **pulsar_conn/client.conf** file if Pulsar Admin access is needed from your localhost
* Use Setup Environment scripts to setup each VMs with NBTF S4J binaries, directories, and base files.
* Use Deploy NBTF S4J clients scripts, to load the testcase scenerio files to the VMs as defined in the testcases raw files.
* Execute and run Testcases using *run* scripts.  This starts the execution of testcases.

Also, scripts are provided to obtain logs from NBTF S4J VMs to be stored for analysis on a localhost.  See Step N.

After test execution is completed:
* Use Purge remote scripts to stop all running NBTF S4J clients, and/or stop and purge the testcase files, including all logs, scenerios, and binaries.  See Step [7](#7-stop-and-cleanup-of-test-execution)
## 2.1 Requirements for Pulsar Admin
This framework can use Pulsar Admin in the testcases, potentially in the Pre and Post testcase scripts. The installation of Pulsar software on the localhost running the Ansible and Bash scripts is required for this function.  For example a Pre testcase script may:  Setup Pulsar Namespaces, Topics, and Subscriptions.

Pulsar is not required to **run** on the localhost where the Ansible and Bash script execute, only the installation of the Pulsar software is required if Pulsar Admin is be used.

The testcase examples use **Pulsar Shell** which can be much faster to run a seqence of commands, like add 100s of Topics.  For details on it and installation, see https://github.com/datastax/pulsar/releases and https://pulsar.apache.org/docs/next/administration-pulsar-shell/


## 2.3 Group_vars "all" file
The file **group_vars/all** contains dafaults and definitions used by this framework.  See the file for specific details.
```
group_vars
├── all

```
NOTE - Please review and update parameters in this file to ensure they are correct for your environment and testing plans.
# 3. Test Case Raw Definition and Execution Schedule

Within this testing framework, both the test case execution schedule and the test case raw definition are defined in the folder **testcases/raw_definition**.

In this folder,
* There are a set of sub-folders that each represents a unique test case.
  * The sub-folder name represents the test case name
* There is a file named **tc_exec_schedule** that defines the execution among all test cases.
* Within each test case sub-folder,
  * There is one test scenario definition file, **definition**. The test scenario definition file includes a series of lines following a certain format (more on this later).
  * Each line represents a unique testing scenario within this test case.
  * Optionally, there may also have two bash scripts named **pre_task.sh** and **post_task.sh** respectively

```
% tree testcases
testcases
├── _generated_nbscn_files_
│   ├── ...
│   └── ...
└── raw_definition
  ├── tc_exec_schedule
  ├── testcase1
  │   ├── definition
  │   ├── post_task.sh
  │   └── pre_task.sh
  ├── testcase2
  │   └── definition
  │
  ... ...
```
The `_generated_nbscn_files_` folder is created by BASH scripts during setup the of testing environment.  Generally you do not use or edit files in this folder.
## 3.1. Test Case Execution Schedule

The test case execution schedule is defined in file **testcases/raw_definition/tc_exec_schedule**. An example of this file is as below:

```
testcase1,30m,tc_default,
testcase2,10m,,glb_default
```

This file is composed of multiple lines with each line having four comma-separated fields:
* test case name
* test case pause time
* pre-task script file
* post-task script file

When running the testcase via the scheduling script, **02.run_testcase_by_schedule.sh**,
1) The test cases included in this file are executed in serial mode.
   1) IMPORTANT - the specified test case name (the **1st** field of each line) must have a corresponding sub-folder under **testcases/raw_definition** folder.
   2) Otherwise, it is treated as an invalid test case and will be skipped.
2) Since the actual execution of each test case (via NB S4J driver) can be asynchronous, the scheduling script must pause the scheduled execution of the current task long enough before moving on to executing the next test case.
   1) The pause time is scheduled by the 2nd field of each line
3) For each test case, if the pre-task script file and the post-task script file (the 3rd and 4th fields of each line) are valid bash script file paths, they'll be executed before and after the execution of the current test case.

---

The test case schedule execution main log file is **nbs4j_exec_logs/by_schedule/<current_time_in_YYYYmmddHHMMSS>/tcExecScheduleMain.log**

## 3.2. Pre- and Post- Task Scripts

As mentioned above, the pre-task and post-task scripts define what is to be executed before and after executing the test case itself. They can be useful for proper resource initialization and cleanup. The actual contents of these 2 scripts are up to the tester's own requirements. As long as they are valid bash scripts and their file paths are properly provided, they will be executed as per the schedule.

**NOTE**- Post-task scripts run immediately after the "pause time" of the testcase, as defined in the **tc_exec_schedule file** or the **-pauseTime** parameter of the **03.run_testcase_by_name.sh** script.  If Post-tasks do cleanup, ensure the testcase clients have finished execution.

There are **3 ways** that you can specify how the pre-task and post-task scripts are provided
1) You can specify a valid file path in each line of **testcases/raw_definition/tc_exec_schedule** file
2) You can also specify '**tc_default**' to point to the default test case specific scripts as
   1) **testcases/raw_definition/<testcase_name>/pre_task.sh**, and
   2) **testcases/raw_definition/<testcase_name>/post_task.sh**
3) You can also specify '**glb_default**' to point to the default global test case scripts as
   1) **bash/pre_task.sh**, and
   2) **bash/post_task.sh**

If the script file path in the line is either empty or not a valid path,
1) The scheduling script will automatically check if there are default test case specific scripts. If there are, execute them.
2) Otherwise, the scheduling script will check if there are global default scripts. If there are, execute them.
3) Otherwise, the scheduling script considers there are no valid pre-task and post-task scripts for the test case and will skip them.

The pre-task and post-task scripts for each test case have their own log files as:
* **nbs4j_exec_logs/by_schedule/<current_time_in_YYYYmmddHHMMSS>/<testcase_name>_preTask.log**
* **nbs4j_exec_logs/by_schedule/<current_time_in_YYYYmmddHHMMSS>/<testcase_name>_postTask.log**

## 3.3. Test Case Raw Definition File

Each test case may include multiple test scenarios. Each test scenario represents a unique testing objective within the test case. The test scenarios are collectively defined in a raw test case definition file, **testcases/<testcase_name>/definition**.
This file is composed of many lines. Each line defines a test scenario and contains a comma-separated field. An example of a test case raw definition file is illustrated below:

```
IDALL,P,,T,myTestDestName1,,,8,2,2,,,,1000,0,default,default,LZ4,,,,,
ID33192,C,,Q,persistent://public/default/myTestDestName1,dns,mySub2,4,2,2,individual_ack,,,2M,0,1m,,,,3,2,maxRedeliverCount:5+deadLetterTopic:some_dlq_topic+initialSubscriptionName:my_initial_dlq_sub,minDelayMs:10+maxDelayMs:50+multiplier:1.5,
```

The description of the fields of each line is as below.

```
#    0) Test execution flag: 
#         - this determines which test scenario is going to be executed on which host
#         - empty value means to be executed on all hosts
#    1) Client type flag:  P (producer) or C(consumer)
#    2) Producer batching enabled:  false (default) or true (Only applicable to Producer)
#    3) Destination type: T(topic) or Q(queue)
#    4) Destination name
#    5) Subscription type (Consumer ONLY!)
#         valid values: 
#         - ndns (non-durable non-shared)
#         - dns (durable non-shared) 
#         - nds (non-durable shared) 
#         - ds (durable shared)
#    6) Subscription name (Consumer ONLY!)
#    7) Number of clients
#    8) Number of connections
#    9) Number of sessions per connection
#   10) JMS session mode
#         valid values: 
#         - auto_ack
#         - client_ack
#         - dups_ok_ack
#         - individual_ack
#         - transact_ack
#   11) Number of messages per transaction
#         only applicable when the JMS session mode is 'transact_ack'
#   12) Message acknowledgement ratio
#         valid values: [0,1]
#   13) NB cycle count - the number of total messages to send or receive
#   14) Cycle rate (empty value or 0 means no rate limit)
#   15) Controlled execution: whether or not to run NB execution for a specific amount of time
#         valid values: <number>[s|m|h] (value 0 means NO controlled execution)
#   16) Message property json template file (Only applicable to Producer)
#         "default" means to read from the default template file
#   17) Message property payload distribution string (Producer ONLY!)
#         "default" means to use the default payload distribution string
#   18) Compression type of the message payload (Producer ONLY!) 
#         - Empty value means no compression. 
#         - Other possible values: LZ4, ZLIB, ZSTD, SNAPPY
#   19) Simulation for slow acknowledgement (Consumer ONLY!) 
#         - valid values: non-negative number 
#           * 0 means no simulation
#           * positive number means how many seconds to pause before making acknowledgement
#   20) Acknowledgement Timeout (Consumer ONLY!)
#         - valid values: non-negative number 
#           * 0 means no ack timeout
#           * positive number means ack timeout in seconds
#   21) DLQ Policy (Consumer ONLY!)
#         value must be in the following format
#         - maxRedeliverCount:<int_value>[+deadLetterTopic:<dlq_topic_name>[+initialSubscriptionName:<initial_sub_name>]]
#   22) Ack Timeout Redelivery Policy (Consumer ONLY!)
#         value must be in the following format
#         - minDelayMs:<int_value>+maxDelayMs:<int_value>+multiplier:<float_value>
#   23) Neg Ack Redelivery Policy (Consumer ONLY!)
#         same format as "ack timeout redelivery policy"
#         for NBS4J testing, this is not really needed and always leave it empty
```
## 3.4. JMS Message Properties template
JMS Message properties can be defined by using a template file.  A default template flie is provided, with example JMS properties.  The S4J driver then sets these JMS properties on all messages published.

The default properties file is called **templates/msg_prop/default.json**

Any JMS message property can be defined, per the JMS Spec.  The **default.json** values are examples only.

**NOTE**  In the default.json file, parameter **"TEST_MSG_BUCKET(int)": "{nbb_msg_prop_test_bucket}",** shows howto set a property with a random value, in order to create varying message property values.

You can setup multiple message property files for your testcases and reference them in the testcase **defnition** file, as noted above in comment/item 16.

# 4. Set up Testing Framework Environment on remote hosts
Setup of the Testing Framework requires 2 steps to be executed as defined below.

## 4.1 Step - **bash/buildAnsiHostInvFile.sh**

This repo has a script to build the basic Server Inventory file needed for other scripts.  This inventory file is defined in the following folder on the localhost.

```
test_hostnames
├── <test_hostname_example>
│   └── hostnamesDefRaw
└── <test_hostname_example_2>
   └── hostnamesDefRaw
```
Multiple "test hostname inventory lists" can be defined and created using this folder.  See the **hostnamesDefRaw** file for details on the contents of this file.

### 4.1.1 bash/buildAnsiHostInvFile.sh Inputs and Outputs
After the **hostnamesDefRaw** file is defined, run **bash/buildAnsiHostInvFile.sh** to generate the required files for environment setup.

```
$ bash/buildAnsiHostInvFile.sh -testHostNamesDir <test_hostname_example> -hostDns [true|false]
```
The output from this script will be a file:
```
hosts_<test_hostname_example>.ini
```

## 4.2 Step - **00.setup_environment.sh**

Next step, continue setup of the testing framework environment via script **00.setup_environment.sh**, which does the following things on each of the specified remote testing machines:

* Set up the test automation framework folder structure (as below) on the each of the remote testing host machine
  * The *bin* sub-folder that contains
    * NB utility binary
    * Several helper bash scripts that will be used during the test case schedule execution
  * The *config/pulsar_conn* sub-folder contains the files needed to connect to the Pulsar cluster, e.g. those needed when Pulsar authentication or TLS encryption is enabled
  * The *logs* sub-folder will be used to host the NB execution log files for each of the test scenario to be executed
    * This folder has one sub-folder per test scenario with the name as "**<testcase_name>_<scn#>**"
  * The *scenarios* sub-folder will include the NB S4J testing files that are translated from the raw definition files and are assigned to this testing machine
    * The NB related files in this folder are organized further into the following sub-folders
      * *nb_cfg*: NB S4J configuration property file for each test scenario of every test case
      * *nb_yaml*: NB S4J scenario yaml definition file for each test scenario of every test case
      * *run_<testcase_name>_<scn#>.sh*: a helper bash script file to trigger the NB execution for each test scenario of every test case

* Copy relevant files from the Ansible controller machine to each remote testing host machine
  * These files include:
    * NB utility binary file
    * JWT authentication token
    * Trusted ca certificate file


# 5. Translate Test Case Raw Definition to NB S4J Testing Files

Step - **01.deploy_nbs4j_tf.sh**

After setting up the environment, the next step is to **translate** the test case *raw* *definition* into NB S4J related files. Script **01.deploy_nbs4j_tf.sh** does this translation.  The translated NB S4J testing files will be 1st put in the local folder **testcases/_generated_nbscn_files_**; and the script copies the relevant files to each remote testing host machine with matching "HOST_ID" (more on this later).

The raw definition line (in **testcases/raw_definition/<testcase_name>/definition**) that corresponds to each test scenario of a test case will be translated to 3 NB related files with the following names:
* <HOST_ID>-<testcase_name>_scn#.yaml
* <HOST_ID>-<testcase_name>_scn#.properties
* <HOST_ID>-run_<testcase_name>_scn#.sh

Please *NOTE* that
- The "<HOST_ID>" part is the host machine identifier that determines on which host machine to execute a NB test scenario.  It is setup in the (**TODO** cluster topology section).
- The "<testcase_name>" part corresponds to the test case name as explained in the previous section.
- The "scn#" part represents a test scenario that corresponds to one line in the raw test scenario file (*testcases/<testcase_name>/definition).
- "*.yaml" file defines a NB S4J scenario yaml file
- "*.properties" file defines the configuration parameters as needed by the NB S4J yaml file
- "*.sh" file defines the actual NB CLI command to execute the NB S4J yaml file

## 5.1. Test Scenario Matching Host ID (TODO updates needed below)

In the Ansible playbook host inventory file, each host has a scenario identifier string (**scn_id_str**), aka *HOST_ID*.

```
[nbtf_hosts]
<host_ip> private_ip=<host_ip> scn_id_str=ID33192
```

Meanwhile in the test scenario raw definition line, each test scenario also has an associated scenario identifier string (the **1st**  field in the definition string)

```
ID33192,C,,Q,persistent://public/default/myTestDestName1,dns,mySub2,4,2,2,individual_ack,,,2M,0,1m,,,,3,2,maxRedeliverCount:5+deadLetterTopic:some_dlq_topic+initialSubscriptionName:my_initial_dlq_sub,minDelayMs:10+maxDelayMs:50+multiplier:1.5,
# Last line must be line 
```

The generated NB S4J testing files will only be copied to the remote testing host machines with matching HOST_IDs.
Please **NOTE** that in the test scenario definition line, you can specify the matching HOST_IDs (as the last field of the line) in multiple ways
* If the field is empty, it matches all testing host machines. The generated NB S4J files start with "IDALL-"
* If the field is a single HOST_ID, it matches the specified host machine
* The field can match multiple host machines if the field is in the form **"HOST_ID1+HOST_ID2+..."**

**Important** The last line in the **"definition"** file MUST BE a blank line to ensure proper translation.  

# 6. Execute Test Cases 

## 6.1 Execute Test Cases by Schedule
Step - **02.run_testcase_by_schedule.sh**

After the NB S4J files are deployed on the remote testing host machines, we can run script **02.run_testcase_by_schedule.sh** to execute the test cases according to the schedule.

Script Inputs are:
```
  Usage: run_tc_by_schedule.sh [-h]
                               [-logHomeDir <tc_exec_log_dir>
                               [-ansiPrivKey <ansi_private_key>
                               [-ansiSshUser <ansi_ssh_user>
         -h   : Show usage info
         [-tcExecScheduleFile]  : The filename of the testcase execution schedule file]
         [-logHomeDir]  : The direcotry of the test case execution log file]
         [-ansiPrivKey] : The private SSH key file used to connect to Ansible hosts
         [-ansiSshUser] : The SSH user used to connect to Ansible hosts
```
 
Each execution has its own set of logs under localhost folder (by default) of **nbs4j_exec_logs/by_schedule/<time_in_YYYYmmddHHMMSS>**, which include the following log files:
* The main execution log file, **tcExecScheduleMain.log**
* For each test case, there are the following log files
 * *<testcase_name>-preTask.log* : Pre-task script execution log file
 * *<testcase_name>-run_nbs4j_testcase_byname_yaml.log* : Test case execution Ansible playbook execution log file
 * *<testcase_name>-collect_remote_runlogs_bytc_yaml.log* : Test case remote log collection Ansible playbook execution log file
 * *<testcase_name>-postTask.log* : Post-task script execution log file
 
The following is an example of one test case schedule execution
```
nbs4j_exec_logs
└── by_schedule
   └── 20220806192728
       ├── tcExecScheduleMain.log
       ├── test_scn_logs
       ├── testcase1-collect_remote_runlogs_bytc_yaml.log
       ├── testcase1-run_nbs4j_testcase_byname_yaml.log
       ├── testcase1_postTask.log
       ├── testcase1_preTask.log
       ├── testcase2-collect_remote_runlogs_bytc_yaml.log
       ├── testcase2-run_nbs4j_testcase_byname_yaml.log
       ├── testcase2_postTask.log
       └── testcase2_preTask.log
```
Example usage assuming testcase raw definition files are located in folder **testcases/raw_definition/**
```
./02.run_testcase_by_schedule.sh -tcExecScheduleFile tc_exec_schedule.backlog-catchup-simulation
``` 
## 6.2 Execute Test Case By Name
Alt Step - **03.run_testcase_by_name.sh**

Testcase can also be executed directly by name.  This script executes similar to the above script but differs by:
* Logs are under localhost to (by default) **nbs4j_exec_logs/by_name/**
* Runs Pre and/or Post Task scripts as defined by "tc_default" (default) or "glb_default"

Script Inputs are:
```
Usage: run_testcase_by_name.sh [-h]
                  -testCaseName <name of Testcase folder>
                  [-taskFlagPrePost] <tc_default or glb_default>
                  [-logHomeDir] <tc_exec_log_dir>
       -h   : Show usage info
       -testCaseName      : Required param, the name of the testcase to run.
       [-taskFlagPrePost] : Pre and Post Testcase scripts, either tc_default or glb_default only.  Default is tc_default
       [-logHomeDir]      : The direcotry of the test case execution log file
```

Example usage assuming testcase raw definition files are located in folder **testcases/raw_definition/testcase1**
```
./03.run_testcase_by_name.sh -testCaseName testcase1
```
The script will use defaults for parameters not defined or inputed.

# 7. Stop and Cleanup of Test Execution

The script **99.purge_remote_nbs4j_exec.sh** can be used to stop/kill running NB S4J clients anytime.  Additionally, it can purge and remove all NB S4J files on the testing remote hosts.  There are input options for this script

* "pid" to only stop/kill running NB S4J processes (default)
* "all" to stop/kill and purge all files related to NB S4J.

**IMPORTANT-**  
Once the script is running, it will stop for command-line input before continuing, to confirm the operation.  User must "return" to continue or "Ctrl+c" and "a" to abort the execution.

Example:
```
./99.purge_remote_nbs4j_exec.sh pid 
...
...
TASK [pause] **************************************************************************************************************
[pause]
<< CAUTION >> This will kill remote NB executions and clean up history logs. Please confirm you want to proceed! Press return to continue. Press Ctrl+c and then "a" to abort:
```
# 8. Test Case logfiles - Retrieve remote logfiles from testing hosts
Scripts are provided to retrieve all testcase related logfiles from the remote hosts which ran the NB S4J clients.  Logfiles can be retrieved and stored on your localhost anytime, on demand or after a testcase execution run.

**04.collect_logs_by_testcase_name.sh** retrieves all logfiles related to the testcase provided as input.
```
Usage: 04.collect_logs_by_testcase_name.sh [-h] [<operation type>]
                             -testCaseName <name of Testcase folder>
                             [-logHomeDir] <tc_exec_log_dir>

       -h : show usage info
       -testCaseName  : The name of the testcase to retreive logs
       [-logHomeDir]  : The direcotry of the test case execution log file
```
Example to retrieve logfiles for "testcase1"
```
./04.collect_logs_by_testcase_name.sh -testCaseName testcase1
```
# 9. Example Testcases
Several testcase examples are provided to show howto use the framework to create workload and various conditions.  See the README under each testcase folder for details and explanation of the testcase, including how to verify results.

[Test Case 1 Simple Example](testcases/raw_definition/testcase1_example/README.md)

[Test Case 2 DQL](testcases/raw_definition/testcase2_dlq/README.md)

[Test Case 3 JMS Filtering](testcases/raw_definition/testcase3_jmsfilter/README.md)

**Test Case 4** demos using the tc_exec_schedule file and scripts to run a sequence of testcases to simulate offline, then online Clients.  
[Test Case 4 Raw Definition file defines the scenarios ](testcases/raw_definition/tc_exec_schedule.backlog-catchup-simulation) 
[Test Case 4 JMS Offline Consumer with Backlog](testcases/raw_definition/testcase4_consumers_backlog/README.md)  
[Test Case 4 JMS Online Consumer with Backlog and Catchup](testcases/raw_definition/testcase4_consumers_catchup/README.md)  
[Test Case 4 JMS Producers](testcases/raw_definition/testcase4_producers/README.md)  

# 10. Metrics and Monitoring of Test Clients
This test framework includes an option to capture limited metrics from running Starlight for JMS clients during testing.  This option installs Prometheus, Graphite-exporter and Grafana via Docker Compose images, and configuration of clients to forward metrics.  The metrics are based on [NoSQL Bench S4J client](https://github.com/nosqlbench/nosqlbench/tree/nb4-maintenance/driver-s4j) as documented [here](https://docs.nosqlbench.io/docs/getting_started/03-reading-metrics/).

**Setup Metrics** 
In the group_vars/all file, enable monitoring as shown below:
```
enable_builtin_monitoring: true
```

Next, add a test hostname and label it "monitoring" in the [test_hostnames](test_hostnames/test_hostname_example/hostnamesDefRaw) definition file
```
mymonitor,,monitoring,hostmonitor
```
Then run script **00.setup_environment.sh** to setup the test hosts, including the components for capturing metrics.

**Note:**  Metrics capture and current configuration is limited to clients running on the "monitoring" node.  Manual updates are required to capture metrics on multiple test hosts.  This option is included to show/demo **how** it can be accomplished.  It is not meant to replace Pulsar Cluster metrics and reporting options.
