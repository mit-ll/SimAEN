#!/bin/bash
#
# MIMO:
#
# $1 is file containing list of indices to process and names of output files (will be modified based on fixed directory tree and naming scheme)

# Process results in MATLAB
cat << MATM | /usr/local/bin/matlab2020a -nodisplay -nosplash -singleCompThread

% Start Matlab script
disp('Adding matlab_tools and subfolders to path...');

% Get SIMAEN_HOME
simaen_home = getenv('SIMAEN_HOME');

% Add to MATLAB path
addpath(LLGrid_genpath([simaen_home, filesep, 'src']));

disp('Path modified.');
try
	disp('Starting processMetrics...');
	processMetrics('$1');
catch e;
	fprintf('There was an error!\n');
	fprintf('\tMessage: %s\n', e.message);
	fprintf('\tFile: %s\n', e.stack.file);
	fprintf('\tName: %s\n', e.stack.name);
	fprintf('\tLine: %d\n', e.stack.line);
	quit;
end
% End Matlab script

MATM