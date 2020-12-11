#!/bin/bash

# Input arguments
#
# 1. Directory containing Python logs
# 2. Directory to output MAT files to
# 3. Number of nodes
# 4. Number of processes per node
# 5. Mapping option (logs or metrics)

# Set default variable values
defaultInputDirectory="./grid/python_logs"
defaultOutputDirectory="./grid/mat_files"
defaultNodes=5
defaultNPPN=30
defaultOption=none

# Handle input
inputDirectory=${1:-$defaultInputDirectory}
outputDirectory=${2:-$defaultOutputDirectory}
nodes=${3:-$defaultNodes}
NPPN=${4:-$defaultNPPN}
option=${5:-$defaultOption}

# NPPN must be less than or equal to 32
if (( $NPPN > 32 ));
then
	echo Specify NPPN less than or equal to 32
	exit 1
fi

# Print choices to terminal
echo inputDirectory = $inputDirectory
echo outputDirectory = $outputDirectory
echo nodes = $nodes
echo NPPN = $NPPN
echo option = $option

# Run LLMapReduce
if [ $option == logs ] # Process events or arrays
then
	# Ensure that scripts are executable
	# chmod u+x $SIMAEN_HOME/src/grid_tools/gridMapMatlab_EA.sh

	# Run LLMapReduce protocol
	LLMapReduce --mapper=$SIMAEN_HOME/src/grid_tools/gridMapMatlab_EA.sh --np=[$nodes,$NPPN,1] --input=$inputDirectory --output=$outputDirectory --ext=mat --keep=true --apptype=mimo
elif [ $option == metrics ] # Process metrics
then
	# Ensure that scripts are executable
	# chmod u+x $SIMAEN_HOME/src/grid_tools/gridMapMatlab_M.sh

	# Run LLMapReduce protocol
	LLMapReduce --mapper=$SIMAEN_HOME/src/grid_tools/gridMapMatlab_M.sh --np=[$nodes,$NPPN,1] --input=$inputDirectory --output=$outputDirectory --ext=mat --keep=true --apptype=mimo	
else
	echo Invalid option $option
	exit 2
fi
