#!/bin/sh
miniFile=$1
nanoFile=$2

CMSSWver=CMSSW_10_6_31
outFileLoc="root://cmseos.fnal.gov//store/user/vhegde/Physics/DarkHiggsPrivSamples/NanoV9_with_partTV2/"
###############
unset PERL5LIB
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
xrdcp $miniFile miniAODFile.root
echo ".........copied MiniAOD file...."
ls

cmsDriver.py --python_filename nanoTuples_mc2018.py --eventcontent NANOAODSIM --customise PhysicsTools/NanoTuples/nanoTuples_cff.nanoTuples_customizeMC --datatier NANOAODSIM --fileout file:nanoAODFile.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --step NANO --filein file:miniAODFile.root --era Run2_2018,run2_nanoAOD_106Xv2 --mc -n -1 --no_exec

echo ".........Done cmsDriver. Running cmsRun nanoTuples_mc2018.py"
cmsRun nanoTuples_mc2018.py

echo "......... Done cmsRun. Copying output file"
mv nanoAODFile.root $nanoFile
xrdcp -f $nanoFile $outFileLoc
ls
echo ".......... finished production and copying. Delete .root and .py from local area..........."
rm *.root
rm *.py
rm *.tar
rm -rf $CMSSWver
echo "DONE"
