#!/bin/bash

ref_rep=PATH_TO_REFERECE_REPLICA_TRAJECTORY_XTC
# specify also the HILLS file in plumed.dat!


#clear
rm  weights.dat weights_norm.dat  eRMSDoutWeights.dat hairpinsweights.dat  bias.dat eRMSDout.dat hairpins.dat

#plumed - print eRMSD and bias to separate files
plumed driver --plumed plumed.dat --mf_xtc $ref_rep --kt 2.494339

#get max value of bias:
bmax=`awk 'BEGIN{max=0.}{if($1!="#!" && $2>max)max=$2}END{print max}' bias.dat`
echo $bmax
#calculate weights
awk '{if($1!="#!") print $1,(exp(($2-bmax)/kbt))}' kbt=2.494339 bmax=$bmax bias.dat > weights.dat
#get sum of weights to normalize them to 1
norm=`awk -F' ' '{sum+=$2;} END{print sum;}' weights.dat`
echo $norm
#calculate normalized weights
awk '{print $1,$2/norm}' norm=$norm  weights.dat > weights_norm.dat
awk -F' ' '{sum+=$2;} END{print sum;}' weights_norm.dat
#add header to the file
sed -i '1s/^/#time weights\n/' weights_norm.dat
#megre the eRMSD and weight files
paste eRMSDout.dat weights_norm.dat >> eRMSDoutWeights.dat

#caclulate dG_fold in kcal/mol based on eRMSD criteria 
awk '{if($3<0.7) q1+=$5; else q2+=$5} END{print q1, q2, -0.289*8.3144598*(log(q1/q2))/4.184}' eRMSDoutWeights.dat

#individual hairpins:
#! FIELDS time hairpin12 hairpin23 hairpin34
paste hairpins.dat weights_norm.dat >> hairpinsweights.dat
awk '{if($2<0.7) q1+=$6; else q2+=$6} END{print q1, q2, -0.289*8.3144598*(log(q1/q2))/4.184}' hairpinsweights.dat
awk '{if($3<0.7) q1+=$6; else q2+=$6} END{print q1, q2, -0.289*8.3144598*(log(q1/q2))/4.184}' hairpinsweights.dat
awk '{if($4<0.7) q1+=$6; else q2+=$6} END{print q1, q2, -0.289*8.3144598*(log(q1/q2))/4.184}' hairpinsweights.dat

