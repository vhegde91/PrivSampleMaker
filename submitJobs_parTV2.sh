#!/bin/sh
# ./submitJobs_parTV2.sh DarkHiggs_WW_Zp2000_s200_Chi100 1000 50
# 
model=$1
nEventsPerJob=$2
nJobs=$3
exeAtWorker="worker_parTV2NanoV9.sh"
filesToTransfer="Summer20UL18_SampleMaker_parTV2NanoV9.sh,NanoTuples_Run2UL18_partTV2.tar,Template_DarkHiggs-fragment.py,step_2_cfg.py,step_3_cfg.py,step_4_cfg.py,step_5_cfg.py,step_6_cfg.py,step_7_cfg.py"
jdl_file="condor_${model}.submit"
log_prefix="condor_${model}"

echo "universe = vanilla">$jdl_file
echo "Executable = ${exeAtWorker}">>$jdl_file
echo "Arguments = $model \$(Item) $nEventsPerJob">>$jdl_file
echo "Requirements = HAS_SINGULARITY == True">>$jdl_file
echo "+SingularityImage = \"/cvmfs/singularity.opensciencegrid.org/opensciencegrid/osgvo-el7:latest\"">>$jdl_file
echo "use_x509userproxy = true">>$jdl_file
echo "Should_Transfer_Files = YES">>$jdl_file
echo "WhenToTransferOutput = ON_EXIT_OR_EVICT">>$jdl_file
echo "RequestCpus = 8">>$jdl_file
echo "RequestMemory = 15600">>$jdl_file
echo "Transfer_Input_Files = ${filesToTransfer}">>$jdl_file
echo "Output = ${log_prefix}_job\$(Item).stdout">>$jdl_file
echo "Error = ${log_prefix}_job\$(Item).stderr">>$jdl_file
echo "Log = ${log_prefix}_job\$(Item).condor">>$jdl_file
echo "notification = never">>$jdl_file
echo "queue from seq 1 $nJobs |">>$jdl_file
