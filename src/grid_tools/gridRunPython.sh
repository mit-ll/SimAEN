#!/bin/bash

# Input arguments
#
# 1. Directory containing config files
# 2. Base output directory
# 3. Number of nodes
# 4. Number of processes per node

# Set default variable values
defaultNodes=5
defaultNPPN=30

# Handle input
indexFile=$1
baseDirectory=$2
nodes=${3:-$defaultNodes}
NPPN=${4:-$defaultNPPN}

# NPPN must be less than or equal to 32
if (( $NPPN > 32 ));
then
	echo Specify NPPN less than or equal to 32
	exit 1
fi

# Print choices to terminal
echo indexFile = $indexFile
echo baseDirectory = $baseDirectory
echo nodes = $nodes
echo NPPN = $NPPN

# Initialize module command
source /etc/profile

# Load module needed for Python code to work
# module load anaconda/2020b
module load anaconda3-2019b

# Ensure that scripts are executable
# chmod u+x $SIMAEN_HOME/src/grid_tools/gridMapPython.sh
# chmod u+x $SIMAEN_HOME/src/grid_tools/gridReduce.sh

# Run LLMapReduce protocol
LLMapReduce --mapper=$SIMAEN_HOME/src/grid_tools/gridMapPython.sh --np=[$nodes,$NPPN,1] --input=$indexFile --output=$baseDirectory --ext=noext --keep=true --distribution=cyclic