#!/bin/sh
miniFile=$1
nanoFile=$2
######### cmsconnect specific
unset PYTHONPATH
######### cmsconnect specific ends
gfal-copy $miniFile miniAODFile.root
# xrdcp --retry 3 $miniFile miniAODFile.root
if [ -f miniAODFile.root ] ; then
    echo ".........copied MiniAOD file...."
else
    echo "ERROR_xrdcp_in"
    exit 1
fi
ls
#############

CMSSWver=CMSSW_10_6_31
eosAddr="root://cmseos.fnal.gov"
eosPath="/store/user/lpchadwxmet/Run2Run3/BG_NanoV9ParTV2/"
# outFileLoc="root://cmseos.fnal.gov//store/user/vhegde/Physics/DarkHiggsPrivSamples/NanoV9_with_partTV2/"
outFileLoc="${eosAddr}/${eosPath}"
###############
unset PERL5LIB # cmsconnect specific
echo "At condor node..."
pwd
currDir=$(pwd)
echo "ls........"
ls
echo "Setting up CMSSW......"
source /cvmfs/cms.cern.ch/cmsset_default.sh
cmsrel $CMSSWver
cd $CMSSWver/src
eval `scram runtime -sh`
tar xf ../../NanoTuples_Run2UL18_partTV2.tar
./PhysicsTools/NanoTuples/scripts/install_onnxruntime.sh
scram b
cd ../..
echo ".............Done CMSSW...."
##############
cmsDriver.py --python_filename nanoTuples_mc2018.py --eventcontent NANOAODSIM --customise PhysicsTools/NanoTuples/nanoTuples_cff.nanoTuples_customizeMC --datatier NANOAODSIM --fileout file:nanoAODFile.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --step NANO --filein file:miniAODFile.root --era Run2_2018,run2_nanoAOD_106Xv2 --mc -n -1 --no_exec

echo ".........Done cmsDriver. Running cmsRun nanoTuples_mc2018.py"
cmsRun nanoTuples_mc2018.py

echo "......... Done cmsRun. Copying output file"
mv nanoAODFile.root $nanoFile

######### cmsconnect specific; undo cmsenv to use gfal-copy
export PATH=$(echo $PATH | tr ':' '\n' | grep -v cmssw | tr '\n' ':' | sed 's/:$//')
export LD_LIBRARY_PATH=$(echo $LD_LIBRARY_PATH | tr ':' '\n' | grep -v cmssw | tr '\n' ':' | sed 's/:$//')
unset -f cmsenv
unset -f cmsrel
######### cmsconnect specific ends
function repeated_copy() {
    local nanoFile=$1
    local outFileLoc=$2
    local n=$3
    for ((i=1; i<=$n; i++))
    do
	echo "Copy trial ${i}"
	gfal-copy -f $nanoFile $outFileLoc
	if [ $? == 0 ] ; then
	    gfal-ls $outFileLoc$nanoFile
	    if [ $? == 0 ] ; then
		return 0
	    fi
	else
	    echo "gfal-copy failed. Trying xrdcp"
	    sleep 10
	    xrdcp --retry 3 -f $nanoFile $outFileLoc
	fi
	sleep 2
	gfal-ls $outFileLoc$nanoFile
	if [ $? == 0 ] ; then
	    return 0
	fi
	sleep 60
    done
    echo "All copy attempts failed."
    return 1
}

exitCode=0
if repeated_copy $nanoFile $outFileLoc 5; then
    echo "FULLSUCCESS"
else
    echo "Failed to copy n times"
    exitCode=1
fi

#########
# gfal-copy -f $nanoFile $outFileLoc
# if [ $? != 0 ] ; then
#     echo "gfal-copy failed. Trying xrdcp"
#     xrdcp --retry 3 -f $nanoFile $outFileLoc
# fi
# ls
# ##########
# echo "DONE. Checking output file's existance."
# exitCode=0
# #xrdfs $eosAddr ls --retry 3 $eosPath/$nanoFile
# gfal-ls $outFileLoc$nanoFile
# if [ $? != 0 ] ; then
#     echo "ERROR_cp_out1" >&2
#     sleep 60
#     gfal-copy -f $nanoFile $outFileLoc
#     if [ $? != 0 ] ; then
# 	echo "Tried gfal-copy after some time. No success"
# 	exitCode=1
#     fi
# else
#     echo "FULLSUCCESS"
# fi
###########
echo ".......... finished production and copying. Delete .root and .py from local area..........."
rm *.root
rm *.py
rm *.tar
rm -rf $CMSSWver
exit $exitCode
