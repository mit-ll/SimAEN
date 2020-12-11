#!/bin/bash
#
# $1 is index of simulation configuration
# $2 is output file (will be modified in WorkflowModel based on fixed directory tree and naming scheme)

# Initialize module command
source /etc/profile

# Load module needed for Python code to work
module load anaconda/2020b

# Run Python code
python $SIMAEN_HOME/src/WorkflowModel.py $1 $2