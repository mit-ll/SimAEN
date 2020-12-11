function out = num_max_restricted_days_per_individual(arr, bsi, varargin)
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
% function out = num_max_restricted_days_per_individual(arr, bsi, varargin)

% Make sure we're working on a column vector
assert(iscolumn(arr), 'arr must be a column vector.');

% Handle input
opts = inputParser;
opts.addParameter('infected', false, @islogical);
opts.addParameter('min_days', 5, @isscalar);
opts.parse(varargin{:});
infected = opts.Results.infected;
min_days = opts.Results.min_days; % Minimum number of days agent has to be in sim for it to count

% Get ISM
ISM = metric.assemble(arr, 'ISM', 'bsi', bsi);

% Get generators
aOut = metric.assemble(arr, 'people', 'subflds', ["generator", "infected"], 'bsi', bsi);
generator = aOut.generator;

% Get logical array capturing which individuals were in the sim during the
% min number of days or more and were not OGs (original generators)
min_days_in_sim = cellfun(@(x)(sum(~~x, 2) >= min_days), ISM, 'UniformOutput', false);
original_generators = cellfun(@(x)(isnan(x)), generator, 'UniformOutput', false);

% Combine (AND) to get valid individuals
valid = cellfun(@(x,y)(~x & y), original_generators, min_days_in_sim, 'UniformOutput', false);

% Add another condition if only tracking infected individuals
if infected
    valid = cellfun(@(x,y)(x & y), valid, aOut.infected, 'UniformOutput', false);
end

% Get number of max restriction days and divide by number of valid
% individuals
nums = 31:36;
num_mrd = cellfun(@(x, y)(sum(ismember(x(y, :), nums), 2)), ISM, valid, 'UniformOutput', false);

% % Bootstrap results
% [~, num_mrd] = metric.bootstrap(N, num_mrd);

% For each bootstrapped result, sum number of days and divide by number of
% valid individuals

out = sum(num_mrd{1}) / numel(num_mrd{1});

% count = @(x)(sum(x)/numel(x)); % Divide counts
% 
% M = cell(1, size(arr, 2));
% for i = 1:numel(M)
%     M{i} = cellfun(count, num_mrd{i});
% end
% 
% % Process output
% M = cell2mat(M);
