#!/bin/bash
# This script automates the running of several programs which are required for
# simulating high energy particle collisions.
# Requires input_template.dat in the same directory
# For details, please see the documentation PDF
#
#
# Set paths for necessary programs
SoftSUSYDIR=/home/bob/softsusy-3.5.2
CalcDIR=/home/bob/Calculators/mssm
MG5PROCDIR=/home/bob/MG5_aMC_v2_2_3/SquarkGluino
# 
HOME=`pwd`
OUTDIR=$HOME/OUTPUT
mkdir $OUTDIR
# Output files will be stored in $PWD/OUTPUT
#
#
# Define parameter grid. At leading order, M0 = Squark mass, M3 = Gluino mass. 
# Grid scans over M0 from M0i to M0i + (imax - 1) * dM0, in increments of dM0
# Similarly for M3 (replacing i with j)
M0i=500
M3i=500
dM0=100
dM3=100
imax=10
jmax=10
#
#
# Begin parameter scan. i iterates over M0, j iterates over M3
i=0
while [ "$i" -lt "$imax" ] ;
do
	j=0
	while [ "$j" -lt "$jmax" ] ;
	do
		M0=`expr $M0i + $i \* $dM0`
		M3=`expr $M3i + $j \* $dM3`
# 		MDec is mass for all decoupled superpartners
		MDec=`expr $M0 \* 2`
		echo "Starting parameter point: M0 = $M0  ,  M3 = $M3"
#
#		Update parameter values in input.dat, which contains input for spectrum generator (SOFTSUSY)
#		input_template.dat contains template for input file
		cp input_template.dat input.dat
		sed -i "s/ #G/ $M3#G/" $HOME/input.dat
		sed -i "s/ #S/ $M0#S/" $HOME/input.dat
		sed -i "s/ #!/ $MDec#!/" $HOME/input.dat
#
#		Run Spectrum generator (SOFTSUSY) to obtain mass spectrum in output.dat
		$SoftSUSYDIR/softpoint.x leshouches < $HOME/input.dat > $HOME/output.dat
#
#		Copy spectrum output to decay calculator directory
		cp $HOME/output.dat $CalcDIR/LH.dat
		cd $CalcDIR
# 		Calculate decay rates. Output spectrum and decay rates into $CalcDir/param_card.dat 
		echo "Calculating Decay Rates..."
		./MSSMCalc >/dev/null
#		Copy output into Madgraph directory
		cp param_card.dat $MG5PROCDIR/Cards/
		cd $HOME
#
#		Run Madgraph, Pythia and Delphes pipeline
		echo "Running Madgraph..."
		$MG5PROCDIR/bin/generate_events -f  >/dev/null
#
#		Copy simulated events (.root) and spectrum info (.txt) to output directory
		cp $MG5PROCDIR/Events/run_01/*delphes_events.root $OUTDIR/M0"$M0"-M3"$M3".root
		cp $MG5PROCDIR/Events/run_01/*tag_1_banner.txt $OUTDIR/M0"$M0"-M3"$M3".txt
#		Clean MG5PROCDIR  for next run
		rm -r $MG5PROCDIR/Events/*
		j=`expr $j + 1`
	done
	i=`expr $i + 1`
done
exit 0
