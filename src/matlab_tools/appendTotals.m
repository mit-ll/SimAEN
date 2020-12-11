function output = appendTotals(arr)
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
% function output = appendTotals(arr)
%
% The 'arrays' output of SimAEN captures only the number of
% occurrences of various events (new infections, etc.) on specific days; it
% does not capture totals such as the total number of infected cases or the
% current number of infected cases.  This function appends these totals to
% the 'arrays' output.

for i = 1:numel(arr)
    if isfield(arr(i), 'arrays')
        arr(i).arrays.days = append(arr(i).arrays.days);
    elseif isfield(arr(i), 'days')
        arr(i).days = append(arr(i).days);
    elseif isfield(arr(i), 'day')
        arr(i) = append(arr(i));
    else
        error('Invalid input.');
    end    
end

output = arr;

function appended = append(in)

in.total_cases = cumsum(in.new_cases);
in.total_infected_cases = cumsum(in.new_infected_cases);
in.total_recovered_cases = cumsum(in.recovered_cases);
in.total_removed_cases = cumsum(in.removed_cases);
in.total_flashes = cumsum(in.flashes);
in.total_calls = cumsum(in.calls);
in.total_successful_calls = cumsum(in.successful_calls);
in.total_dropped_from_call_list = cumsum(in.dropped_from_call_list);


in.current_cases = cumsum(in.new_cases - in.removed_cases);
in.current_infected_cases = cumsum(in.new_infected_cases - in.recovered_cases);

appended = in;
