#!/bin/sh
model=$1
jobID=$2
nEvents=$3

unset PERL5LIB
echo "At condor node..."
pwd
currDir=$(pwd)
echo "ls........"
ls

cp Template_DarkHiggs-fragment.py ${model}_fragment.py

sed -i "s|CURR_DIRECTORY|${currDir}|" ${model}_fragment.py
sed -i "s|MODELNAME|$model|" ${model}_fragment.py

echo "..........set fragment file"

xrdcp root://cmseos.fnal.gov//store/user/vhegde/Physics/DarkHiggsPrivSamples/gridpacks/${model}_slc7_amd64_gcc700_CMSSW_10_6_19_tarball.tar.xz .

echo ".........copied gridpack...."
ls
# ./Summer20UL18_SampleMaker_parTV2NanoV9.sh -test ${model}_fragment.py
echo "..........starting step1 cmsDriver.py......"
./Summer20UL18_SampleMaker_parTV2NanoV9.sh -testGEN ${model}_fragment.py
ls

./Summer20UL18_SampleMaker_parTV2NanoV9.sh -prod ${model}_fragment.py $nEvents PrivSample_${model}_Summer20UL18.root $jobID

echo ".......... finished production and copying. Delete .root and .py from local area..........."
rm *.root
rm *.py
rm *tar.xz
echo "DONE"
