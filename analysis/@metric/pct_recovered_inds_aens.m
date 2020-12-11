function out = pct_recovered_inds_aens(arr, bsi)
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
% function out = pct_recovered_inds_aens(arr, bsi)
%
% Count the number of AENs sent out and divide by the number of infected
% individuals.  Note that only those individuals who recover from their
% infection are counted as 'infected' for the purpose of this calculation.

% Make sure we're working on a column vector
assert(iscolumn(arr), 'arr must be a column vector.');

% Assemble combined datasets
aOut = metric.assemble(arr, 'people', 'subflds', ["aen", "recovered"], 'bsi', bsi);

% Get fields
aen = aOut.aen{1};
recovered = aOut.recovered{1};

% % Divide counts
% count = @(x,y)(sum(x)/sum(y));

% Calculate output
out = sum(aen) / sum(recovered);

% M = cell(1, size(arr, 2));
% 
% for i = 1:numel(M)
%     M{i} = cellfun(count, aen{i}, recovered{i});
% end
% 
% % Process output
% M = cell2mat(M);
