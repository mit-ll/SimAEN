function [baseConfigs, numUniqueConfigs] = writeConfigs(setup, NRPC, varargin)
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
% function [baseConfigs, numUniqueConfigs] = writeConfigs(setup, NRPC, varargin)
%
% Create config JSON files based on specified setup and Number of Runs Per
% Config (NRPC)
%
% Input arguments:
%
%   +   setup: structure detailing the setup of the runs (see run.m for
%              example)
%
%   +   NRPC: scalar capturing the number of simulations to run for each
%             config
%
%   +   varargin: parameter/value pairs
%
%           +   parameter: 'fileroot'
%   
%               value: char or string capturing the root name of each file
%                      to which numbers will be appended based on
%                      configuration number
%
%               default: 'config'
%
%           +   parameter: 'directory'
%
%               value: char or string capturing the name of the directory
%               to output JSON files to
%
%               default: current directory (pwd)
%
%           +   parameter: 'groups'
%
%               value: see help documentation for multiConfig.m
%
%               default: {}
%
%           +   parameter: 'show_progress'
%
%               value: logical
%
%               default: false

% Handle input
opts = inputParser;
opts.addParameter('directory', pwd, (@(x)(ischar(x) | isstring(x))));
opts.addParameter('fileroot', 'config', (@(x)(ischar(x) | isstring(x))));
opts.addParameter('groups', {}, @iscell);
opts.addParameter('show_progress', false, @islogical);
opts.parse(varargin{:});
fileroot = opts.Results.fileroot;
directory = opts.Results.directory;
groups = opts.Results.groups;
show_progress = opts.Results.show_progress;

% Generate separate configs for each combination of variables
baseConfigs = multiConfig(setup, 'groups', groups);
numUniqueConfigs = numel(baseConfigs);

% Get number of digits to output for configuration number and
% number-in-config-group in JSON file names
ndig_config = ceil(log10(numel(baseConfigs) + 1));
ndig_NRPC = ceil(log10(NRPC + 1));

% Get total number of configs
totalConfigs = numel(baseConfigs) * NRPC;

% Get number of digits in total
ndig_total = ceil(log10(totalConfigs + 1));

q = 0;
for i = 1:numel(baseConfigs)    
    for j = 1:NRPC
        
        q = q + 1;
        
        % Encode configuration
        thisConfig = baseConfigs(i);
        thisConfig.config_group_num = i;
        thisConfig.config_num_in_group = j;    
        
        % Alphabetize thisConfig
        thisConfig = orderfields(thisConfig);
        
        json_to_write = jsonencode(thisConfig);
        
        % Specify file name
        fileout = sprintf('%s%s%s%0*d_%0*d.json', ...
            directory, filesep, fileroot, ndig_config, i, ndig_NRPC, j);

        % Write file
        if show_progress
            fprintf('%*d / %d', ndig_total, q, totalConfigs);
        end
        fido = fopen(fileout, 'w');
        fwrite(fido, json_to_write);
        fclose(fido);
        if show_progress
            fprintf(repmat(sprintf('\b'), (ndig_total * 2) + 3, 1))
        end
    end
end
