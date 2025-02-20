#!/bin/sh
# ./submitJobs_NanoOnly.sh MiniAOD_DarkHiggs_WW_Zp2000_s200_Chi100.txt 
# 
txtFile=$1
model=$(echo "$txtFile" | sed 's/^MiniAOD_//;s/\.txt$//')
exeAtWorker="worker_MiniToNano.sh"
filesToTransfer="NanoTuples_Run2UL18_partTV2.tar"

counter=0
while IFS= read -r line; do
    ((counter++))
    outFname="NanoAODv9_job${counter}_${model}.root"
    inFname=$line
    jdl_file="condor_${model}_job${counter}.jdl"
    log_prefix="condor_${model}_job${counter}"

    echo "universe = vanilla">$jdl_file
    echo "Executable = worker_MiniToNano.sh">>$jdl_file
    echo "Arguments = $inFname $outFname">>$jdl_file
    echo "Requirements = HAS_SINGULARITY == True">>$jdl_file
    echo "+SingularityImage = \"/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7:latest\"">>$jdl_file
    echo "use_x509userproxy = true">>$jdl_file
    echo "Should_Transfer_Files = YES">>$jdl_file
    echo "WhenToTransferOutput = ON_EXIT_OR_EVICT">>$jdl_file
    echo "RequestCpus = 4">>$jdl_file
    # echo "RequestMemory = 15600">>$jdl_file
    echo "Transfer_Input_Files = ${filesToTransfer}">>$jdl_file
    echo "Output = ${log_prefix}.stdout">>$jdl_file
    echo "Error = ${log_prefix}.stderr">>$jdl_file
    echo "Log = ${log_prefix}.condor">>$jdl_file
    echo "notification = never">>$jdl_file
    echo "Queue 1">>$jdl_file
    condor_submit $jdl_file
done < "$txtFile"
