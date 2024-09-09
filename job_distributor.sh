#!/bin/bash

func_echo_help() {
    echo "Please provide joblist file like following"
    echo "bash job_distributor.sh <joblist file path>"
}

# check if file is provided
if [[ $# == 0 ]]; then
    echo -e "\nJoblist file path not provided. Provide the joblist file path as cmd line args\n"
    func_echo_help
    exit
fi

# the joblist file will be provided as cmd line arg
JOBLISTFILE=$1

# check if file is provided
if [ ! -f $JOBLISTFILE ]; then
    echo -e "\nJoblist file not found. Please recheck the file path\n"
    exit
fi

echo -e "\nSTARTING SCRIPT COPY\n"

jobcount=0
# read the job list file
# create a worker file which will run the inteneded script with intended args on intended host
# first pass create a script which call the actual job script with cmd line args
# then copy it to intended place
while read -r line; do
    # read the cmd
    jobargs=()
    for arg in $line; do
        jobargs+=($arg)
    done
    jobcount=$((jobcount+1))

    # create the cmd
    cmd="bash"
    for arg in ${jobargs[@]:3}; do
        cmd=$cmd" "$arg
    done
    # redirect the cmd output and error to different log
    cmd=$cmd" 1>output_"$jobcount".log 2>output_"$jobcount".err"

    # create the glue script which calls the actual script
    # why it's needed?
    # the idea was that we can execute both script or cmd on the intended host
    # although later we have coded only for bash script execution (notice that cmd in glue script starts with "bash")
    echo $cmd>workerdep_${jobcount}.sh

    # transfer the script
    ip=${jobargs[0]}
    port=${jobargs[1]}
    workdir=${jobargs[2]}
    script=${jobargs[3]}
    scp -P $port workerdep_${jobcount}.sh $script $ip:$workdir

    echo -e "\ncopied script to $ip:$workdir\n"

    rm workerdep_${jobcount}.sh
done < $JOBLISTFILE

# another pass to run the copied script
jobcount=0
while read -r line; do
    jobargs=()
    for arg in $line; do
        jobargs+=($arg)
    done
    jobcount=$((jobcount+1))

    # create the cmd which will be executed on ssh session
    ip=${jobargs[0]}
    port=${jobargs[1]}
    workdir=${jobargs[2]}
    cmdstr='cd '${workdir}';bash 'workerdep_${jobcount}.sh

    # forking otherwise will be stuck
    ssh -p $port $ip $cmdstr &
    PID=$!

    echo -e "\nissued job start on $ip:$workdir, ssh session running on process $PID\n"
done < $JOBLISTFILE

# assumption is all job will complete near same time
# therefore checking only one's pid is good enough
while ps -p ${PID} > /dev/null
do
    sleep 1
done

echo "The last started job is finished, will wait for 30s to be safe"
# 30s sleep for extra safety
sleep 30
