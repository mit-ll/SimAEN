function out = pct_max_restricted_infected(arr, bsi)
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
% function out = pct_max_restricted_infected(arr, bsi)
%
% Calculate the percentage of individuals who entered maximum restricted
% that are infected.

% Minimum number of days agent has to be in sim for it to count
min_days = 1;

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

% % Get the infected condition
% infected = cellfun(@(x)(x), aOut.infected, 'UniformOutput', false);

% Get logical that is TRUE for individuals who spent time in max
% restriction and FALSE for individuals who did not
nums = 31:36;
spent_time_in_max = cellfun(@(x)(any(ismember(x, nums), 2)), ISM, 'UniformOutput', false);

% Get valid individuals who spent time in max
valid_in_max = cellfun(@(x,y)(x & y), valid, spent_time_in_max, 'UniformOutput', false);

% Get valid, infected individuals who spent time in max
valid_infected_in_max = cellfun(@(x, y)(x & y), valid_in_max, aOut.infected, 'UniformOutput', false);

out = nnz(valid_infected_in_max{1}) / nnz(valid_in_max{1});

% % Establish anonymous function to calculate percentages
% calc = @(x, y)(nnz(x) / nnz(y));
% 
% M = cell(1, size(arr, 2));
% for i = 1:numel(M)
%     M{i} = cellfun(calc, b_valid_infected_in_max{i}, b_valid_in_max{i});
% end
% 
% % Process output
% M = cell2mat(M);
