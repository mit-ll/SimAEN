function lookup = processMetrics(map_file, varargin)
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
% function lookup = processMetrics(map_file, varargin)

% Handle input
opts = inputParser;
opts.addParameter('save', true, @islogical);
opts.parse(varargin{:});
save_output = opts.Results.save;

% Log the map file being used
fprintf('Map file: %s\n', map_file);

% Get indices and output file names
txt = fileread(map_file); % get text
sl = splitlines(string(txt)); % convert to string and split by lines
sl(sl == "") = []; % get rid of empty lines

% Preallocate
indices = zeros(numel(sl), 1);
output_files = string.empty;

q = 0; % Start counter
for i = 1:numel(sl) % For each line...
    pair = split(sl(i)); % Split down the middle (assumes only one space)

    q = q + 1; % increment counter
    assert(numel(pair) == 2, 'error splitting pair');
    indices(q) = str2double(pair(1)); 
    output_files(q) = pair(2); 
end

% Run assertion
assert(numel(indices) == numel(output_files), ...
    'numbers of indices %d and output MAT files %d are not equal.', numel(indices), numel(output_files));

% Get the runConfig file
p = pcf(fileparts(output_files(1))); %pcf: convert to pc file name for local development
runConfigFile = p + filesep + "../../config/runConfig.mat";
assert(exist(runConfigFile, 'file') == 2, ...
    'runConfigFile %s does not exist', runConfigFile);

% Load runConfig
runConfig = load(runConfigFile);

% Get the number of digits for output files
ndig = ceil(log10(runConfig.NuC + 1));

% Get all array filenames
array_dir = pcf(runConfig.folders.m_arrays);
w = what(array_dir);
array_mats = string(w.path) + filesep + w.mat;

% Get default list of metrics
dm = metric.defaultList();
    
% Work on each index
for i = 1:numel(indices)
    
    % Get this index
    index = indices(i);
    
    % Update user    
    fprintf('Working on index %d (%d / %d)...\n', index, i, numel(indices));
    fprintf('-------------------------------------\n');
    
    % Convert to config_indices
    first = (index * runConfig.NRPC) + 1;
    last = (index + 1) * runConfig.NRPC;
    config_indices = first : last;
    
    % Update user
    fprintf('Configuration indices %d : %d\n', config_indices(1), config_indices(end));
    
    % Get files
    array_files = array_mats(config_indices);
    
    %%% Load the files
    L = cell(numel(array_files), 1);
    for j = 1:numel(array_files)
        
        % Get this file and load it while updating user
        file = array_files(j);
        fprintf('\tLoading file %d of %d... ', j, numel(array_files));
        L{j} = load(file);
        fprintf('loaded!\n');
        
        % Ensure that the config matches
        cgn = L{j}.config.config_group_num;
        assert(cgn == index + 1, ...
            'mismatch between file %s config_group_num %d and specified index %d', ...
            file, cgn, index);
    end
    %%%
    
    % Get the arrays as single struct array assembled from all loaded
    % results files.  Dimension of struct array is NRPC x 1.
    arr = cellfun(@(x)(x.arrays), L);
    
    % Get a representative config
    config = L{1}.config;
    config.config_num_in_group = 1:runConfig.NRPC;
    
    % Get total number of individuals across all repetitions
    num_total = sum(arrayfun(@(x)(numel(x.people.individual)), arr));
    fprintf('Number of elements to be resampled: %d\n', num_total);
    
    % Preallocate output structure
    lookup = struct(...
        'bootstrap_N', runConfig.bootstrap_N);
    
    for j = 1:runConfig.bootstrap_N % For each bootstrap iteration...
        % Inform user of progress
        fprintf('\tBootstrap iteration %d of %d...\n', j, runConfig.bootstrap_N);
        
        % Get bootstrap indices (bsi) for iteration j
        if j == 1
            bsi = (1:num_total)';
        else
            bsi = datasample((1:num_total)', num_total);
        end
        
        for k = 1:numel(dm) % For each metric...
            % Get this_metric
            this_metric = dm(k);
            
            % Preallocate in output structure if this is iteration 1
            if j == 1
                lookup.(this_metric.Tag) = zeros(runConfig.bootstrap_N, 1);
            end
            
            % Inform user
            fprintf('\t\tCalculating metric %s... ', this_metric.Tag);
            
            % Perform calculation
            tic
            lookup.(this_metric.Tag)(j) = this_metric.Calculator(arr, bsi);        
            te = toc; %time elapsed
            
            % Inform user
            fprintf('calculated! (%0.1f seconds) \n', te);
        end
        
    end
    
    % Save output
    if save_output
        fileout = sprintf('%slookup_config_%0*d.mat', [runConfig.folders.m_metrics, filesep], ndig, index + 1);
        fprintf('\tSaving output to %s... ', fileout);
        save(fileout, 'lookup', 'config', '-v7.3');
        fprintf('saved!\n');
    end
end

function out = pcf(in)
% function out = pcf(in)

if ispc && strcmpi(getenv('username'), 'ed22162')
    out = strrep(in, "/home/gridsan/ED22162/", "Z:/");
else
    out = in;
end
