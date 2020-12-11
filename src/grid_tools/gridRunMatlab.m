function gridRunMatlab(runConfig, scope)
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
% function gridRunMatlab(runConfig, scope)
%
% Input arguments:
%
%   +   runConfig: structure output by gridRunPython
%
%   +   scope: choose 'events', 'arrays', or 'metrics'

% Get src directory location
simaen_home = getenv('SIMAEN_HOME');

% Make run script executable
% system(sprintf('chmod u+x %s/gridRunMatlab.sh', [simaen_home, filesep, 'src/grid_tools']));

% Check that scope has been specified
if nargin == 1
    error('Specify a value for input argument ''scope''.  Options include ''events'' and ''arrays''.');
end

switch lower(scope)
    case 'events'

        % Get full path name of output file
%         W = what(runConfig.folders.mats);
%         outputName = [W.path, filesep, 'reducedEvents.mat'];

        % Create command
        cmd = sprintf('%s/src/grid_tools/gridRunMatlab.sh %s %s %d %d %s', ...
            simaen_home, ...
            runConfig.folders.p_events, runConfig.folders.m_events, runConfig.np.num_nodes, runConfig.np.nppn, 'logs'); %, outputName

    case 'arrays'
        
        % Get full path name of output file
%         W = what(runConfig.folders.mats);
%         outputName = [W.path, filesep, 'reducedArrays.mat'];

        % Create command
        cmd = sprintf('%s/src/grid_tools/gridRunMatlab.sh %s %s %d %d %s', ...
            simaen_home, ...
            runConfig.folders.p_arrays, runConfig.folders.m_arrays, runConfig.np.num_nodes, runConfig.np.nppn, 'logs'); %, outputName
        
    case 'metrics'
        
        % Get number of nodes and processors per node
        [num_nodes, nppn] = get_n_nppn(runConfig.NuC);
        
        % Create command
        cmd = sprintf('%s/src/grid_tools/gridRunMatlab.sh %s %s %d %d %s', ...
            simaen_home, ...
            [runConfig.folders.config, filesep, 'index_file_metrics.txt'], runConfig.folders.m_metrics, num_nodes, nppn, 'metrics');
        
        
    otherwise
        error('Invalid choice for scope: %s.  Chooose ''events'', ''arrays'', or ''metrics''.', scope);
end

% Run command
system(cmd);
