function runConfig = gridRunPython(setup, NRPC, varargin)
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
% function runConfig = gridRunPython(setup, NRPC, varargin)
%
% Initialize and run Python processing on Grid.
%
% Input arguments:
%
%   +   setup: structure capturing range of configurations to run.  A
%              default setup structure is output by defaultConfig()
%
%   +   NRPC: number of runs per configuration
%
%   +   varargin: parameter/value pairs
%
%           +   parameter: 'groups'
%
%               value: see help documentation for multiConfig.m
%
%               default: {}
%
%           +   parameter: 'folders'
%
%               value: structure capturing where output files will be
%               written to. Leave this unspecified to use the default
%               configuration (recommended).
%
%               default: []
%
%           +   parameter: 'writeEvents'
%
%               value: logical
%
%               default: true
%
%           +   parameter: 'writeArrays'
%
%               value: logical
%
%               default: true
%
%           +   parameter: 'index_file'
%
%               value: char
%
%               default: ''.  Will change to 'index_file.txt' in config
%                        directory
%
%           +   parameter: 'index_file_metrics'
%
%               value: char
%
%               default: ''.  Will change to 'index_file_metrics.txt' in
%                        config directory.
%
%           +   parameter: 'bootstrap_N'
%
%               value: numeric scalar
%
%               default: 25
%
% Output arguments:
%
%   +   runConfig: structure capturing the configuration of the Grid run.
%                  This output will be the input into the next step:
%                  gridRunMatlab.m.

% Assertions on setup
assertSetup(setup);

% Handle input
opts = inputParser;
opts.addParameter('groups', {}, @iscell);
opts.addParameter('folders', []);
opts.addParameter('writeEvents', true, @islogical);
opts.addParameter('writeArrays', true, @islogical);
opts.addParameter('index_file', '', @ischar);
opts.addParameter('index_file_metrics', '', @ischar);
opts.addParameter('bootstrap_N', 25, @isscalar);
opts.parse(varargin{:})
groups = opts.Results.groups;
folders = opts.Results.folders;
writeEvents = opts.Results.writeEvents;
writeArrays = opts.Results.writeArrays;
index_file = opts.Results.index_file;
index_file_metrics = opts.Results.index_file_metrics;
bootstrap_N = opts.Results.bootstrap_N;

% Handle input
if nargin == 1
    NRPC = 1;
    folders = [];
elseif nargin == 2
    folders = [];
end

% Create writeLog structure
writeLog = struct(...
    'events', writeEvents, ...
    'arrays', writeArrays);

% Handle if user forgets to specify output
if nargout == 0
    error('Collect function output to enable next step of processing (gridRunMatlab.m).');
end

if isempty(folders)
    % Get timestamp
    timestamp = datestr(now, 'YYmmDD-HHMMSS');
    
    % Get src directory location
    simaen_home = getenv('SIMAEN_HOME');

    % Specify directory names, if not specified as input
    folders = struct(...
        'base', sprintf('%s/grid_results/%s', simaen_home, timestamp), ...
        'config', sprintf('%s/grid_results/%s/config', simaen_home, timestamp), ...
        'logs', sprintf('%s/grid_results/%s/logs', simaen_home, timestamp), ...
        'mats', sprintf('%s/grid_results/%s/mats', simaen_home, timestamp));
    
    folders.p_events = [folders.logs, filesep, 'events'];
    folders.p_arrays = [folders.logs, filesep, 'arrays'];
    
    folders.m_events = [folders.mats, filesep, 'events'];
    folders.m_arrays = [folders.mats, filesep, 'arrays'];
    folders.m_metrics = [folders.mats, filesep, 'metrics'];
end

% Make sure directories don't already exist.  If they don't create them.
fprintf('Creating folders... ');
% 1) Config
folder = folders.config;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 2) MATS
folder = folders.mats;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 3a) Python logs - events
folder = folders.p_events;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 3b) Python logs - arrays
folder = folders.p_arrays;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 4a) MATLAB logs - events
folder = folders.m_events;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 4b) MATLAB logs - arrays
folder = folders.m_arrays;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

% 4c) MATLAB logs - metrics
folder = folders.m_metrics;
assert(~exist(folder, 'dir'), 'directory %s already exists', folder);
mkdir(folder);

fprintf('created!\n');

%%% Write config number .txt file
fprintf('Writing config number .txt file... ');
baseConfigs = multiConfig(setup, 'groups', groups); % get number of base config files (does not include NRPC)
NC = numel(baseConfigs) * NRPC; % NC: number of configurations

if isempty(index_file)
    index_file = [folders.config, filesep, 'index_file.txt'];
end

fid = fopen(index_file, 'w');
if fid == -1
    error('Unable to open index_file %s', index_file);
end

try
    for i = 1:NC
        fprintf(fid, '%d\n', i - 1); % config.ind2config assumes 0 indexing
    end
    fclose(fid);
catch
    fclose(fid);
    error('Problem with writing to index_file %s.', index_file);
end
fprintf('written!\n');
%%%

%%% Write config number .txt file for metrics
fprintf('Writing config number .txt file for metrics... ');
NuC = numel(baseConfigs); % NC: number of unique configurations

if isempty(index_file_metrics)
    index_file_metrics = [folders.config, filesep, 'index_file_metrics.txt'];
end

fid = fopen(index_file_metrics, 'w');
if fid == -1
    error('Unable to open index_file_metrics %s', index_file_metrics);
end

try
    for i = 1:NuC
        fprintf(fid, '%d\n', i - 1); % config.ind2config assumes 0 indexing
    end
    fclose(fid);
catch
    fclose(fid);
    error('Problem with writing to index_file_metrics %s.', index_file_metrics);
end
fprintf('written!\n');
%%%

% Populate input directory with setup JSON file and config number .txt file
fprintf('Populating config directory with setup JSON... ');

setupStruct = ...
    struct(...
    'setup', setup, ...
    'NRPC', NRPC, ...
    'writeLog', writeLog, ...
    'num_configs', NC);
setupStruct.groups = groups;

% Write setup JSON file
json_to_write = jsonencode(setupStruct);
fido = fopen([folders.config, filesep, 'setup.json'], 'w');
fwrite(fido, json_to_write);
fclose(fido);
fprintf('populated!\n');

% Determine number of nodes and number of processes per node (NPPN)
fprintf('Determining number of nodes and NPPN... ');
[num_nodes, nppn] = get_n_nppn(NC);
np = struct(...
    'num_nodes', num_nodes, ...
    'nppn', nppn);
fprintf('determined!\n');

% Assemble runConfig output
runConfig = struct(...
    'folders', folders, ...
    'setup', setup, ...
    'np', np, ...
    'timestamp', timestamp, ...
    'NuC', NuC, ...
    'NRPC', NRPC, ...
    'bootstrap_N', bootstrap_N);
runConfig.groups = groups; % have to do this to avoid creating array of structs when groups is a cell array

% Save output to configs folder
fprintf('Saving runConfig to config folder... ');
runConfigFileOut = [runConfig.folders.config, filesep, 'runConfig.mat'];
save(runConfigFileOut, '-struct', 'runConfig');
fprintf('saved!\n');

% Make run script executable
% system(sprintf('chmod u+x %s/gridRunPython.sh', [simaen_home, filesep, 'src/grid_tools']));

% Create command
cmd = sprintf('%s/src/grid_tools/gridRunPython.sh %s %s %d %d', simaen_home, index_file, folders.base, np.num_nodes, np.nppn);

% Run command
fprintf('Starting Grid job...\n');
system(cmd);
fprintf('Grid job started!\n');
