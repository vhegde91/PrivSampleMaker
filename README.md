# Private MC samples for CMS

## Setting up
Copy required fragment file to the current working area. An example fragment file is `SUS-RunIISummer20UL18wmLHEGEN-DarkHiggs-fragment.py`.
```
git clone https://github.com/vhegde91/PrivSampleMaker.git
cmssw-el7
```

Make cfg file for step 1 using `-testGEN` option:

```
./Summer20UL18_SampleMaker.sh -testGEN SUS-RunIISummer20UL18wmLHEGEN-DarkHiggs-fragment.py
```
You can run the file generated using `cmsRun SUS-RunIISummer20UL18wmLHEGEN-DarkHiggs-fragment_step_1_cfg.py`. You may want to change the number of events to a small number.

Alternatively, prepare condor submission scripts and submit jobs:

```./submitJobs.sh DarkHiggs_WW_Zp2000_s200_Chi100 2000 50
condor_submit condor_DarkHiggs_WW_Zp2000_s200_Chi100.submit
```
This submits 50 jobs with 2000 events per job. The first argument `DarkHiggs_WW_Zp2000_s200_Chi100` refers to the gridpack file name. Jobs run based on the template file `Template_DarkHiggs-fragment.py` and not the actual fragment file. Take a look at `worker.sh` file for all the steps including gridpack location and output file transfer location.






