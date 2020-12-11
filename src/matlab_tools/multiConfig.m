function configs = multiConfig(setup, varargin)
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
% function configs = multiConfig(setup, varargin)
%
% This function outputs a struct array 'configs' with each element
% capturing a unique SimAEN configuration as specified by the input
% argument 'setup'. To vary a parameter in 'setup', specify it as an array
% of values.  The output of this function, 'configs', will capture every
% unique combination of all parameters specified in 'setup'.
%
% For example, say that in 'setup' you specified the following parameters:
%
% setup.param1 = [1 2 3];
% setup.param2 = [4 5];
% setup.param3 = 6;
%
% In this instance, 'configs' would be a 6-element (3 times 2 times 1)
% struct array where your params varied as follows:
%
% param 1   param 2   param 3
% ---------------------------
%       1         4         6
%       1         5         6
%       2         4         6
%       2         5         6
%       3         4         6
%       3         5         6
%
% You can also bind parameters together so that their elements vary in
% lock-step with each other instead of being allowed to vary independently.
% For example, say that you had the following parameters in 'setup':
%
% setup.param4 = [ 1  2  3];
% setup.param5 = [ 4  5  6];
% setup.param6 = [ 7  8];
% setup.param7 = [ 9 10]
% setup.param8 = [11 12]
%
% Now, say that you bind params 4 and 5 into a group and you also bind
% params 6, 7, and 8 into a separate group.  Then, 'configs' would be a
% 6-element struct array (3 times 2) where your params varied as follows:
%
% param 4   param 5   param 6   param7   param8
% ---------------------------------------------
%       1         4         7        9       11
%       2         5         7        9       11
%       3         6         7        9       11
%       1         4         8       10       12
%       2         5         8       10       12
%       3         6         8       10       12
%
% Note that to bind params into a group, each param must have the same
% number of elements.  In the example above, params 4 and 5 each have 3
% elements and params 6, 7, and 8 each have 2 elements.
%
% Specify groups by forming a cell array of string arrays.  You would form
% the groups in the example above as follows:
%
% >> groups = {["param4", "param5"], ["param6", "param7", "param8"]};
%
% Next, input your cell array into this function as follows:
%
% >> configs = multiConfig(setup, 'groups', groups);

% Handle input
opts = inputParser;
opts.addParameter('groups', {}, @iscell);
opts.parse(varargin{:});
groups = opts.Results.groups;

% Get number of groups
num_groups = numel(groups);

% Save original setup for later
originalSetup = setup;

% Run assertions
assertSetup(setup, groups);

% Handle groups
for i = 1:num_groups % For each group...
    group = groups{i};
    
    % Get number of elements for parameters of this group
    num_els_in_group = numel(setup.(group(1)));
    
    for j = 1:numel(group)
        % Remove members from structure
        setup = rmfield(setup, group(j));
    end
    
    % Add a temporary field with number of elements the same as this group
    tempFieldName = sprintf('temporaryMultiConfigField_%d', i);
    
    % Make sure this field doesn't already exist in the input structure
    assert(~isfield(setup, tempFieldName), ...
        'field %s already exists in input structure', tempFieldName);
    
    setup.(tempFieldName) = 1:num_els_in_group;    
end

% Get field names of input structure
fns = fieldnames(setup);

% Ensure all arrays in input structure are horizontal
for i = 1:numel(fns)
    setup.(fns{i}) = setup.(fns{i})(:)';
end

% Get configs output -- will still need to be modified if groups were
% specified
s2c = struct2cell(setup);
comb = combvec(s2c{:});
C = num2cell(comb);
configs = cell2struct(C, fns, 1);

% Modify configs based on specified groups
for i = 1:num_groups
    
    % Get this group
    group = groups{i};
    
    % Get the temporary field name corresponding to this group
    tempFieldName = sprintf('temporaryMultiConfigField_%d', i);
    
    for j = 1:numel(group)
        
        % Get field j of group i
        field = group(j);
        
        % Preallocate
        fieldCell = cell(1, numel(configs));
        
        % Populate the cell array with values based on those in the
        % temporary field
        for k = 1:numel(configs)
            fieldCell{k} = originalSetup.(field)(configs(k).(tempFieldName));
        end
        
        % Assign to configs
        [configs.(field)] = fieldCell{:};        
    end
    
    % Remove temporary field
    configs = rmfield(configs, tempFieldName);
end

% Alphabetize configs
configs = orderfields(configs);

% Ensure that probabilities of starting in various behavior starts do not
% sum to greater than 1
for i = 1:numel(configs)
    if configs(i).p_start_min + configs(i).p_start_mod + configs(i).p_start_max > 1
        error('Probabilities of starting in restricted states sum to greater than 1');
    end
end
