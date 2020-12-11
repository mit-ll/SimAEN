#!/bin/bash
#
# $1 is input MATLAB output files
# $2 is name of reduced MATLAB file

# Reduce  results in MATLAB
cat << MATM | /usr/local/bin/matlab2020a -nodisplay -nosplash -singleCompThread

% Start MATLAB script

disp('Reducing multiple MATLAB files to one...');

% Get SIMAEN_HOME
simaen_home = getenv('SIMAEN_HOME');

% Add to MATLAB path
addpath(LLGrid_genpath([simaen_home, filesep, 'src']));

try
	gridReduce('$1', '$2'); 
catch e
	fprintf('There was an error!  Message:\n\t%s\n', e.message);
	quit;
end

% End MATLAB script

MATM