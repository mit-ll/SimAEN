function [processed_world_output, eventsOut, arraysOut] = runPython(configs, NRPC, varargin)
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
% function [processed_world_output, eventsOut, arraysOut] = runPython(configs, NRPC, varargin)
%
% varargin: writeLogs (true/false)

% Ensure running from correct directory
assert(exist('./src', 'dir') == 7, ...
    'run from highest directory of repo--the one containing the src directory.');

% Handle input
if nargin == 1
    NRPC = 1;
elseif nargin == 0
    error('Supply configs input.');
elseif ischar(NRPC) % NRPC not specified but varargin specified
    varargin = [NRPC, varargin{:}];
    NRPC = 1;
end
opts = inputParser;
opts.addParameter('writeLogs', true, @islogical);
opts.parse(varargin{:});
writeLogs = opts.Results.writeLogs;

if ~writeLogs
    warning('Turning off writeLogs does not work.  Logs will be written.');
end

% Establish cleanup function
cleanupObj = onCleanup(@cleanupFun);

% Preallocate data
%   Rows: runs per config (worlds)
%   Columns: config number
processed_events = cell(NRPC, numel(configs));
processed_arrays = cell(NRPC, numel(configs));
processed_world_output = cell(NRPC, numel(configs));

% Get number of simulations
NS = NRPC * numel(configs);

% Set up progress bar
pb = waitbar(0, sprintf('Running simulation %d of %d', 0, NS), ...
    'CreateCancelBtn', @cancelprogbar, ...
    'Name', 'Simulation Progress');

% Set canceling status to false
setappdata(pb, 'canceling', 0);

% Control user cancellation
cancelled = false;
q = 0; %counter

for i = 1:numel(configs)
    
    % Handle progress bar
    if getappdata(pb, 'canceling')
        waitbar(q/NS, pb, 'Cancelling...');
        cancelled = true;
        break;
    end
    
    if cancelled
        break;
    end
    
    % Run this configuration NRPC times
    for w = 1:NRPC
        
        % Encode configuration i and write as a JSON file that captures
        % which run this is in its group
        thisConfig = configs(i);
        thisConfig.config_group_num = i;
        thisConfig.config_num_in_group = w;
        
        json_to_write = jsonencode(thisConfig);
        fido = fopen('config.json', 'w');
        fwrite(fido, json_to_write);
        fclose(fido);
        fprintf('Configuration JSON file written.\n');
        
        % Increment counter
        q = q + 1;
        
        % Handle progress bar
        if getappdata(pb, 'canceling')      
            waitbar(q/NS, pb, 'Cancelling...');
            cancelled = true;
            break;
        else
            waitbar(q/NS, pb, ...
                sprintf('Running simulation %d of %d', q, NS));
        end
    
        % Reload module - it's not clear why this is necessary, but it
        % seems to fix issues with the Python script running the correct
        % configuration.
        clear mod;
        mod = py.importlib.import_module('src.WorkflowModel');
        py.importlib.reload(mod);

        % Run Python code
        drawnow;
        raw_world_data = mod.main();
        fprintf('Processing world data... '); drawnow('update');
        processed_world_output{w, i} = process_world_data(raw_world_data);
        fprintf('processed!\n'); drawnow('update');
        
        % Load and decode JSON output
        fprintf('Reading events JSON file and decoding... ');
            processed_events{w, i} = processOutput('events_world.json', [], 'save', false);
            fprintf('read and decoded!\n');
            
        fprintf('Reading arrays JSON file and decoding... ');
            processed_arrays{w, i} = processOutput('arrays_world.json', [], 'save', false);
            fprintf('read and decoded!\n');        
    end
end

% Convert from cell to mat
if ~cancelled
    eventsOut = cell2mat(processed_events);
    processed_world_output = cell2mat(processed_world_output);
    arraysOut = cell2mat(processed_arrays);
%         arraysOut = appendTotals(arraysOut);
else
    eventsOut = [];
    processed_world_output = [];
    arraysOut = [];
end

end

function cancelprogbar(~, ~)
    setappdata(gcbf, 'canceling', 1);
end

function cleanupFun
    % Delete progress bar when program ends
    F = findall(0, 'type', 'figure', 'tag', 'TMWWaitbar');
    delete(F);
end
