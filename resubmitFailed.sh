#!/bin/sh
for i in DarkHiggs_ZZ_Zp1000_s200_Chi150 DarkHiggs_ZZ_Zp1000_s200_Chi300 DarkHiggs_ZZ_Zp1000_s250_Chi150 DarkHiggs_ZZ_Zp1000_s250_Chi300 DarkHiggs_ZZ_Zp1500_s200_Chi150 DarkHiggs_ZZ_Zp1500_s200_Chi300 DarkHiggs_ZZ_Zp1500_s250_Chi150 DarkHiggs_ZZ_Zp1500_s250_Chi300 DarkHiggs_ZZ_Zp2000_s200_Chi150 DarkHiggs_ZZ_Zp2000_s200_Chi300 DarkHiggs_ZZ_Zp2000_s250_Chi150 DarkHiggs_ZZ_Zp2000_s250_Chi300 DarkHiggs_ZZ_Zp2000_s300_Chi200
do
    # ./submitJobs_parTV2.sh $i 1000 50
    # condor_submit condor_${i}.submit
    echo $i
    num="queue in ("
    for j in $(seq 1 50)
    do
	if ! grep -q -L 'Closed file file:OutRoot_6.root' condor_${i}_job${j}.stderr ; then
	    num="${num} ${j}"
	fi
    done
    num="${num})"
    python -c "import fileinput; import sys; [sys.stdout.write(line.replace(line, '$num\n') if line.startswith('queue') else line) for line in fileinput.input('condor_${i}.submit', inplace=True)]"
done
