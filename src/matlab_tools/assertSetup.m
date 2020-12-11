function assertSetup(setup, groups)
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
% function assertSetup(setup, groups)

% Number of worlds
assert(setup.num_worlds == 1, 'num_worlds must be equal to 1.');

% False discovery rate
assert(all(setup.false_discovery_rate < 1), ...
    'false discovery rate must be less than 1');

% Starting in various behavior states
% assert(setup.p_start_min + setup.p_start_mod + setup.p_start_max <= 1, ...
%     'p_start_(min, mod, and max) cannot sum to more than 1');

% Validity of fields
fns_defaultSetup = fieldnames(defaultConfig());
fns_thisSetup = fieldnames(setup);

sd = setdiff(fns_thisSetup, fns_defaultSetup);
if ~isempty(sd)
    error(...
        'Variables exist in specified ''setup'' that do not exist in default parameter set: %s', ...
        join(string(sd(:)'), ', '));
end

%%% Group assertions
% 1. No repeat values among groups
% 2. Every group parameter name specified exists in 'setup'
% 3. All groups consist of string arrays
% 4. All parameters specified within each group have the same number of
%    elements
if nargin == 2
   num_groups = numel(groups);

    res = string.empty(1,0); 
    for i = 1:num_groups

        % Get this group
        group = groups{i};

        % Ensure that group is a string array
        assert(isstring(group), ...
            'All groups must be string arrays.  Group %d is not.', i);

        for j = 1:numel(group)
            param = group(j);        

            assert(isfield(setup, param), ...
                'specified group parameter %s does not exist in setup.', ...
                param);

            res(end + 1) = param; %#ok<AGROW>

            % Ensure that all members have same sized arrays
            num_el_in_field = numel(setup.(group(j)));
            if j == 1
                num_el_in_grp = num_el_in_field;
            else
                assert(num_el_in_grp == num_el_in_field, ...
                    'members of group %d do not have same number of elements.', i);
            end

        end
    end
    assert(numel(unique(res)) == numel(res), ...
        'one or more parameters are repeated in groups'); 
end
%%%
