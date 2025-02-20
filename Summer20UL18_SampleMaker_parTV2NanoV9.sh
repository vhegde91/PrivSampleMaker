#!/bin/bash

# Examples
# ./SampleMaker.sh -test SUS-RunIISummer20UL18wmLHEGEN-DarkHiggs-fragment.py
# ./SampleMaker.sh -prod SUS-RunIISummer20UL18wmLHEGEN-DarkHiggs-fragment.py 10 MyOut.root 1

# User-defined variables
ProcType=$1		  # -test-> For testing. -prod -> For actual mass production
FragFile=$2	       	  # fragment file path
EVENTS=10		  # No. of events to process. (10 for testing)
CMSSWList=("CMSSW_10_6_30_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_6_17_patch1" "CMSSW_10_2_16_UL" "CMSSW_10_6_17_patch1" "CMSSW_10_6_20" "CMSSW_10_6_31")

# Extracting the sample name from the frag file name
FragBase=$(basename $FragFile)
FragKey="${FragBase%.*}"

# Print info for debugging
echo Parameters passed: $*

# Set CMSSW-related env
export SCRAM_ARCH=slc7_amd64_gcc700
source /cvmfs/cms.cern.ch/cmsset_default.sh

StepCount=0			# counter to keep track of the steps
GetCMSSW () {
    echo Starting the step $((StepCount+1))

    if [ -d ${CMSSWList[StepCount]}/src ] ; then
	echo release ${CMSSWList[StepCount]} already exists
    else
	echo Setting up ${CMSSWList[StepCount]}
	scram p CMSSW ${CMSSWList[StepCount]}
    fi
    
    cd ${CMSSWList[StepCount]}/src
    eval `scram runtime -sh`

    scram b
    cd ../..

    ((StepCount++))
    if [[ "$StepCount" -gt "2" ]];then
	rm -f OutRoot_$(( StepCount-2 )).root
    fi
    echo "Step" $StepCount ":" ${CMSSWList[StepCount]} "built."
}

if [ "$1" = "-test" ] || [ "$1" = "-testGEN" ] ; then
    echo Test mode.

    LocFragFile=$(basename $FragFile)

    # Step 1
    GetCMSSW CMSSW_10_6_30_patch1
    if [ ! -d CMSSW_10_6_30_patch1/src/Configuration/GenProduction/python/ ] ; then
	mkdir -p CMSSW_10_6_30_patch1/src/Configuration/GenProduction/python/
    fi
    cp $FragFile CMSSW_10_6_30_patch1/src/Configuration/GenProduction/python/
    cd CMSSW_10_6_30_patch1/src/
    scram b
    cd -

    cmsDriver.py Configuration/GenProduction/python/${LocFragFile} --python_filename ${FragKey}_step_${StepCount}_cfg.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands "process.source.numberEventsInLuminosityBlock = cms.untracked.uint32(10000)\nprocess.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)" --step LHE,GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n 5000 || exit $? ;
    echo "from IOMC.RandomEngine.RandomServiceHelper import RandomNumberServiceHelper" >> ${FragKey}_step_${StepCount}_cfg.py
    echo "randSvc = RandomNumberServiceHelper(process.RandomNumberGeneratorService)" >> ${FragKey}_step_${StepCount}_cfg.py
    echo "randSvc.populate()" >> ${FragKey}_step_${StepCount}_cfg.py
    
    # cmsDriver.py Configuration/GenProduction/python/${LocFragFile} --python_filename ${FragKey}_step_${StepCount}_cfg.py --eventcontent RAWSIM,LHE --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN,LHE --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands "process.source.numberEventsInLuminosityBlock = cms.untracked.uint32(10000)\nprocess.RandomNumberGeneratorService.externalLHEProducer.initialSeed=int(0)" --step LHE,GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n 5000 || exit $? ;
    # Random seed between 1 and 100 for externalLHEProducer
    # SEED=$(($(date +%s) % 100 + 1))
    # cmsDriver.py Configuration/GenProduction/python/boostedHWWfragment.py --python_filename HWW_boostednov11.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN --fileout file:HWW_boostedFilter_GEN.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --step LHE,GEN --geometry DB:Extended --era Run2_2018 --mc -n 20 --no_exec --customise_commands process.RandomNumberGeneratorService.externalLHEProducer.initialSeed="int(${SEED})"\\nprocess.source.numberEventsInLuminosityBlock="cms.untracked.uint32(100)"

    #    cmsDriver.py Configuration/GenProduction/python/${LocFragFile} --python_filename ${FragKey}_step_${StepCount}_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v4 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands process.source.numberEventsInLuminosityBlock="cms.untracked.uint32(200)" --step GEN --geometry DB:Extended --era Run2_2018 --no_exec --mc -n $EVENTS || exit $? ;

    if [ "$1" = "-testGEN" ] ; then
	exit
    fi

    # Step 2
    GetCMSSW CMSSW_10_6_17_patch1

    cmsDriver.py  --python_filename step_${StepCount}_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --beamspot Realistic25ns13TeVEarly2018Collision --customise_commands "process.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)" --step SIM --geometry DB:Extended --filein file:OutRoot_$(( StepCount-1 )).root --era Run2_2018 --runUnscheduled --no_exec --mc -n -1 || exit $? ;

    # Step 3
    GetCMSSW CMSSW_10_6_17_patch1

    cmsDriver.py  --python_filename step_${StepCount}_cfg.py --eventcontent PREMIXRAW --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-DIGI --fileout file:OutRoot_${StepCount}.root --pileup_input "dbs:/Neutrino_E-10_gun/RunIISummer20ULPrePremix-UL18_106X_upgrade2018_realistic_v11_L1v1-v2/PREMIX" --conditions 106X_upgrade2018_realistic_v11_L1v1 --customise_commands "process.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)" --step DIGI,DATAMIX,L1,DIGI2RAW --procModifiers premix_stage2 --geometry DB:Extended --filein file:OutRoot_$(( StepCount-1 )).root --datamix PreMix --era Run2_2018 --runUnscheduled --no_exec --mc -n -1 || exit $? ;

    # Step 4
    GetCMSSW CMSSW_10_2_16_UL

    cmsDriver.py  --python_filename step_${StepCount}_cfg.py --eventcontent RAWSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier GEN-SIM-RAW --fileout file:OutRoot_${StepCount}.root --conditions 102X_upgrade2018_realistic_v15 --customise_commands 'process.source.bypassVersionCheck = cms.untracked.bool(True)\nprocess.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)' --step HLT:2018v32 --geometry DB:Extended --filein file:OutRoot_$(( StepCount-1 )).root --era Run2_2018 --no_exec --mc -n -1 || exit $? ;

    # Step 5
    GetCMSSW CMSSW_10_6_17_patch1

    cmsDriver.py  --python_filename step_${StepCount}_cfg.py --eventcontent AODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier AODSIM --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v11_L1v1 --customise_commands "process.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)" --step RAW2DIGI,L1Reco,RECO,RECOSIM,EI --geometry DB:Extended --filein file:OutRoot_$(( StepCount-1 )).root --era Run2_2018 --runUnscheduled --no_exec --mc -n -1 || exit $? ;

    # Step 6
    GetCMSSW CMSSW_10_6_20

    cmsDriver.py  --python_filename step_${StepCount}_cfg.py --eventcontent MINIAODSIM --customise Configuration/DataProcessing/Utils.addMonitoring --datatier MINIAODSIM\
 --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --customise_commands "process.options.numberOfThreads=cms.untracked.uint32(8)\nprocess.options.numberOfStreams=cms.untracked.uint32(0)" --step PAT --procModifiers run2_miniAOD_UL --geometry DB:Extended\
 --filein file:OutRoot_$((StepCount-1)).root --era Run2_2018 --runUnscheduled --no_exec --mc -n -1 || exit $? ;

    # Step 7
    GetCMSSW CMSSW_10_6_31
    cd $CMSSW_BASE/src
    echo "Step 7: untaring parTV2 model files...."
    tar xf ../../NanoTuples_Run2UL18_partTV2.tar
    ./PhysicsTools/NanoTuples/scripts/install_onnxruntime.sh
    echo "Step 7: Done untaring parTV2 model files...."
    scram b
    echo "Step 7: recompiled..."
    pwd
    cd ../..
    
    cmsDriver.py --python_filename step_${StepCount}_cfg.py --eventcontent NANOAODSIM --customise PhysicsTools/NanoTuples/nanoTuples_cff.nanoTuples_customizeMC --datatier NANOAODSIM --fileout file:OutRoot_${StepCount}.root --conditions 106X_upgrade2018_realistic_v16_L1v1 --step NANO --filein file:OutRoot_$(( StepCount-1 )).root --era Run2_2018,run2_nanoAOD_106Xv2 --mc -n -1 --no_exec || exit $? ;

    # # Uncomment to produce a small test sample.
    # StepCount=0
    # for i in {{1..7}};do
    # 	GetCMSSW
    # 	cmsRun step_${StepCount}_cfg.py || exit $? ;
    # done

elif [ "$1" = "-prod" ]; then
    echo Production mode.

    EVENTS=$3		  # No. of events
    FinalRootFile=$4		  # Final output root file name
    jobID=$5		  # Job ID. (For condor jobs)

    StepCount=0

    search3="input = cms.untracked.int32(5000)"
    replace3="input = cms.untracked.int32($EVENTS)"
    sed -i "s/$search3/$replace3/" ${FragKey}_step_1_cfg.py

    search3="nEvents = cms.untracked.uint32(5000)"
    replace3="nEvents = cms.untracked.uint32($EVENTS)"
    sed -i "s/$search3/$replace3/" ${FragKey}_step_1_cfg.py

    # export firstEvent=$(python3 -c "print(($jobID)+1)")
    # search3="process.source.firstEvent = cms.untracked.uint32(1)"
    # replace3="process.source.firstEvent = cms.untracked.uint32($firstEvent)"
    # sed -i "s/$search3/$replace3/" ${FragKey}_step_1_cfg.py
    
    # search3="process.RandomNumberGeneratorService.externalLHEProducer.initialSeed=int(0)"
    # replace3="process.RandomNumberGeneratorService.externalLHEProducer.initialSeed=int(${jobID})"
    # sed -i "s/$search3/$replace3/" ${FragKey}_step_1_cfg.py
    

    cp ${FragKey}_step_1_cfg.py step_1_cfg.py

    for i in {{1..6}};do
	GetCMSSW
	echo "Will cmsRun " step_${StepCount}_cfg.py
	cmsRun step_${StepCount}_cfg.py || exit $? ;
	# rm -f step_${StepCount}_cfg.py
    done
    
    GetCMSSW CMSSW_10_6_31
    cd $CMSSW_BASE/src
    echo "Step 7: untaring parTV2 model files...."
    tar xf ../../NanoTuples_Run2UL18_partTV2.tar
    ./PhysicsTools/NanoTuples/scripts/install_onnxruntime.sh
    echo "Step 7: Done untaring parTV2 model files...."
    scram b
    echo "Step 7: recompiled..."
    pwd
    cd ../..
    echo "Will cmsRun " step_7_cfg.py
    cmsRun step_7_cfg.py || exit $? ;

    echo "Copying Mini and Nano files"
    mv OutRoot_6.root MiniAODv2_job${jobID}_${FinalRootFile}
    mv OutRoot_7.root NanoAODv9_job${jobID}_${FinalRootFile}
    xrdcp --retry 3 -f MiniAODv2_job${jobID}_${FinalRootFile} root://cmseos.fnal.gov//store/user/vhegde/Physics/DarkHiggsPrivSamples/MiniAODv2_Summer20UL/
    xrdcp --retry 3 -f NanoAODv9_job${jobID}_${FinalRootFile} root://cmseos.fnal.gov//store/user/vhegde/Physics/DarkHiggsPrivSamples/NanoV9_with_partTV2/
    rm OutRoot*.root
    # rm -f OutRoot_$(( StepCount-1 )).root OutRoot_${StepCount}.root
fi
