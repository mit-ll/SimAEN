function gridCompletePython(runConfig)
% DISTRIBUTION STATEMENT A. Approved for public release. Distribution is unlimited.

% This material is based upon work supported under Air Force Contract No. FA8702-15-D-0001.
% Any opinions,findings, conclusions or recommendations expressed in this material are those
% of the author(s) and do not necessarily reflect the views of the Centers for Disease Control.

% (c) 2020 Massachusetts Institute of Technology.

% The software/firmware is provided to you on an As-Is basis

% Delivered to the U.S. Government with Unlimited Rights, as defined in DFARS Part 252.227-7013
% or 7014 (Feb 2014). Notwithstanding any copyright notice, U.S. Government rights in this work
% are defined by DFARS 252.227-7013 or DFARS 252.227-7014 as detailed above. Use of this work
% other than as specifically authorized by the U.S. Government may violate any copyrights that
% exist in this work.

% Copyright (c) 2020 Massachusetts Institute of Technology
% SPDX short identifier: MIT

%Developed as part of: SimAEN, 2020
%Authors: DI25756, JO26228, ED22162
% function gridCompletePython(runConfig)
%
% This function completes a partial Python run of SimAEN.  It is restricted
% to the processed arrays JSON output.  It determines which runs were
% incomplete based on the file names present in the corresponding folder.
% This means that this function will not recognize JSON files that were
% only partially written as a problem.
%
% For this function to work, the JSON output file names must look like the
% following example:
%
% config0001_01.json

% Get src directory location
simaen_home = getenv('SIMAEN_HOME');

%%% Write new config number .txt file based on runs that were not completed
% Get current JSON files in arrays folder
D = dir([runConfig.folders.p_arrays, filesep, '*.json']);
names = string({D.name});
R = regexp(names, '[0-9]+', 'match');

% Determine indices of run(s) that did not complete
complete = sortrows(combvec(1:runConfig.NuC, 1:runConfig.NRPC)', [1 2]);
present = zeros(numel(R), 2);
for i = 1:numel(R)
    present(i, :) = str2double(R{i});
end
missing = setdiff(complete, present, 'rows');
missing_indices = (missing(:,1) - 1) * runConfig.NRPC + missing(:,2) - 1; % assumes 0-indexing for index file

% Update user
fprintf('Original run(s) missing %d indices.\n', numel(missing_indices));

%%% Write new index_file
index_file = [runConfig.folders.config, filesep, 'index_file_completePython.txt'];

fid = fopen(index_file, 'w');
if fid == -1
    error('Unable to open index_file %s', index_file);
end

try
    for i = 1:numel(missing_indices)
        fprintf(fid, '%d\n', missing_indices(i)); 
    end
    fclose(fid);
catch
    fclose(fid);
    error('Problem with writing to index_file %s.', index_file);
end
fprintf('written!\n');
%%%

% Determine number of nodes and number of processes per node (NPPN)
fprintf('Determining number of nodes and NPPN... ');
[num_nodes, nppn] = get_n_nppn(numel(missing_indices));
np = struct(...
    'num_nodes', num_nodes, ...
    'nppn', nppn);
fprintf('determined!\n');

% Make run script executable
% system(sprintf('chmod u+x %s/gridRunPython.sh', [simaen_home, filesep, 'src/grid_tools']));

% Create command
cmd = sprintf('%s/src/grid_tools/gridRunPython.sh %s %s %d %d', simaen_home, index_file, runConfig.folders.base, np.num_nodes, np.nppn);

% Run command
fprintf('Starting Grid job...\n');
system(cmd);
fprintf('Grid job started!\n');
