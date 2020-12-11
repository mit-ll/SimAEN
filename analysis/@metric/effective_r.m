function out = effective_r(arr, bsi)
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
% function out = effective_r(arr, bsi)

% Make sure we're working on a column vector
assert(iscolumn(arr), 'arr must be a column vector.');

% Assemble combined datasets
aOut = metric.assemble(arr, 'people', 'subflds', ["infected", "recovered", "removed", "num_infected_descendants"], 'bsi', bsi);

% Figure out which individuals were both infected and (recovered or
% removed)
recovered_or_removed = cellfun(@(x,y)(x | y), aOut.recovered, aOut.removed, 'UniformOutput', false);
infected_and_RorR = cellfun(@(x,y)(x & y), aOut.infected, recovered_or_removed, 'UniformOutput', false);

% Get nid
nid = cellfun(@(x,y)(x(y(:))), aOut.num_infected_descendants, infected_and_RorR, 'UniformOutput', false);

% Get output
out = mean(nid{1});

% % Bootstrap
% [~, nid] = metric.bootstrap(N, nid);
% 
% % Preallocate
% M = cell(1, size(arr, 2));
% 
% for i = 1:size(arr, 2)    
%     % Populate output
%     M{i} = cellfun(@(x)(mean(x)), nid{i});    
% end
% 
% % Process output
% M = cell2mat(M);
