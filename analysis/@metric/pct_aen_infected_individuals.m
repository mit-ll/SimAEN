function out = pct_aen_infected_individuals(arr, bsi)
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
% function out = pct_aen_infected_individuals(arr, bsi)

% Assemble combined datasets
aOut = metric.assemble(arr, 'people', 'subflds', ["infected", "aen"], 'bsi', bsi);

vec = cellfun(@(x)(false(nnz(x), 1)), aOut.aen, 'UniformOutput', false);

for i = 1:numel(vec)
    vec{i}(aOut.infected{i}(aOut.aen{i})) = true;
end

out = nnz(vec{1}) / numel(vec{1});

% % Bootstrap
% [~, vec] = metric.bootstrap(N, vec);
% 
% % Preallocate
% M = cell(1, size(arr, 2));
% 
% for i = 1:size(arr, 2)
%     
%     % Populate output
%     M{i} = cellfun(@(x)(nnz(x)/numel(x)), vec{i});
% end
% 
% % Process output
% M = cell2mat(M);
