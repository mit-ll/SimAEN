function out = loadResults(app, varargin)
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
% function out = loadResults(app, varargin)
%
% varargin: 
%
%   +   parameter: use_lookup
%
%       value: logical
%
%       default: false

% Handle input
opts = inputParser;
opts.addParameter('use_lookup', false, @islogical);
opts.parse(varargin{:});
use_lookup = opts.Results.use_lookup;

% Get file indices
[new_config_ids_nrpc, new_config_ids_unique] = ...
    simaen_app.params2ids(app.configs, app.data.params, app.runConfig.NRPC);
if use_lookup
    config_ids = new_config_ids_unique;
else
    config_ids = new_config_ids_nrpc;
end

if isempty(config_ids)
    error('Unable to identify config ids');
end

% Preallocate output
C = cell(size(config_ids));    

% Populate output
for i = 1:numel(C)
    if use_lookup
        temp = load(app.metricsFiles(config_ids(i)), 'lookup');
        C{i} = temp.lookup;        
    else
        temp = load(app.arrayFiles(config_ids(i)), 'arrays');
        C{i} = temp.arrays;        
    end
end

out = cell2mat(C);
