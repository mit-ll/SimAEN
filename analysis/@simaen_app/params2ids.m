function [ids_nrpc, ids_unique] = params2ids(configs, params, NRPC)
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
% function [ids_nrpc, ids_unique] = params2ids(configs, params, NRPC)
%
% Get ID numbers of results files based on configs (created by
% multiConfig.m), specified parameters (params), and, optionally, NRPC.
%
% Outputs:
%
%   +   ids_nrpc: ids taking NRPC into account
%
%   +   ids_unique: ids assuming NRPC is 1; useful for lookup results

% Handle input
if nargin == 2
    NRPC = 1;
end

% Handle configs
configs = configs(:)'; % make sure a row vector
configs = repmat(configs, NRPC, 1);

% Starting point
bool = true(size(configs));

% Get field names specified in params
fns = string(fieldnames(params));

% Reduce bool until we match every condition specified in params
for i = 1:numel(fns)
    configVals = [configs.(fns(i))];
        configVals = reshape(configVals, size(configs, 1), size(configs, 2));
    bool = bool & ismember(configVals, params.(fns(i)));
end

% Use find to return ids
ids_nrpc = find(bool);
ids_unique = find(bool(1, :));

% Reshape based on NRPC
ids_nrpc = reshape(ids_nrpc, NRPC, numel(ids_nrpc) / NRPC);



