function out = assemble(arr, fld, varargin)
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
% function out = assemble(arr, fld, varargin)
%
% Assemble results based on configuration.  This function combines
% the results for each unique configuration.  For example, if NRPC
% was specified to be 10 during a simulation, then there will be 10
% sets of results for each unique configuration.  This function
% combines those results.
%
% Input arguments:
%
%   +   arr: arrays
%
%   +   fld: field of arrays: people, days, or ISM
%
%   +   varargin:
%
%       +   parameter: 'subflds'
%
%           value: string
%
%           default: "" (must change if fld is not ISM)
%
%       +   parameter: 'bsi'
%
%           value: numeric
%
%           default: []

% Handle input
opts = inputParser;
opts.addParameter('subflds', "", @isstring);
opts.addParameter('bsi', [], @isnumeric);
opts.parse(varargin{:});
subflds = opts.Results.subflds;
bsi = opts.Results.bsi;

%%% ISM
if subflds == ""
    assert(strcmpi(fld, 'ISM'), ...
        'unless specified field is ''ISM'', must specify subfields.');

    temp = reshape({arr.ISM}, size(arr));

    % Preallocate output
    out = cell(1, size(arr, 2));             

    for j = 1:size(arr, 2) % For each configuration...
        out{j} = cell2mat(temp(:, j)); %...combine all iterations (NRPC) for this configuration
        
        if ~isempty(bsi) % Shuffle/resample results based on bsi (bootstrap indices)
            out{j} = out{j}(bsi, :);
        end
    end
    
    return
end
%%%

% Reshape results to capture original shape of data
field = reshape([arr.(fld)], size(arr));

% Combine data based on unique configuration
for i = 1:numel(subflds)
    for j = 1:size(arr, 2)
        cell_of_subfld = reshape({field.(subflds(i))}, size(arr));
        out.(subflds(i)){j} = cell2mat(cell_of_subfld(:, j));
        
        if ~isempty(bsi)
            out.(subflds(i)){j} = out.(subflds(i)){j}(bsi);
        end
    end            
end
end
