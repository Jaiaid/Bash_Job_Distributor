# Bash Job SSH Distributor Script

## Overview
This is a utility bash script which comes as a outcome from another research project. The objective is to distribute and run multiple jobs on multiple remote nodes through SSH. 
The usecase was to distribute deep learning jobs from a node to bunch of remote nodes

The assumptions are followings 
1. The hosts have ssh server and can be accessed from the node which will run job_distributor.sh
2. The last started job will finish last.
3. There is a 30s grace period after the last job finish to allow other hosts job to wrap up ()
4. The local node ``job_distributor.sh`` will be kept alive. Otherwise all ssh session will be stopped and consequently the remote ssh job(s)
5. The remote nodes are using key based authentication (Otherwise for every copy and cmd execution you have to give password)

To execute,
```
bash job_distributor.sh <joblist file path>
```

### Test Environment
* Ubuntu
* Openssh

### Job list file structure 
The bash script expects a job list file where each line ending with a new line contains a job description like following
```
<remote node IP> <remote node ssh port> <workdir of remote node where the script will be executed> <path of the script which will be copied to remote node for execution> <script cmd line arg. list>
```

**IMPORTANT:** The script expects each line to end with a newline which requires the file end with a new line. If the last job line does not end with new line it will not be executed. On the other hand if there is extra empty line at end, an empty cmd execution will be attempted which will be considered the last job. Based on assumption 1 it may cause all other job to early exit.

An example ``joblist.txt`` is provided. Notice there is a newline at the end, so in an editor (as per vscode, nano) there will be 4 line with the last line being empty.
```
192.168.0.11 901 ~/Desktop example_job1.sh 1 2
192.168.0.12 22 ~/ example_job2.sh 3 4 5 6 7 8 9
192.169.0.250 65535 ~/workdir example_job3.sh 3 4 5 6 7 8 9
```

For example, on the remote 192.168.0.1.12 following cmd will be executed from ~ directory
```
bash workerdep_2_{PID of bash execution}.sh
```

``workerdep_2_{PID of bash execution}.sh`` will contain this cmd
```
bash example_job2.sh 3 4 5 6 7 8 9 1>output_2.log 2>output_2.err
```
The 2 in log file is from the job sequence number in ``joblist.txt``


