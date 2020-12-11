function processed_world_data = process_world_data(raw_world_data)
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
% function processed_world_data = process_world_data(raw_world_data)
%
% Convert the Python code's MATLAB output to a MATLAB-workable format.
%
% Input argument:
%
%   +   name: raw_world_data
%
%       description: this is the direct output of a single call to the
%                    Python code.
%
% Output argument:
%
%   +   name: processed_world_data
%
%       description: a structure array containing the MATLAB output; length
%       of array is number of worlds simulated

temp = cell(raw_world_data);
for i = 1:numel(temp)
    processed_world_data(i) = struct(temp{i}.matlab);     %#ok<AGROW>
    fns = string(fieldnames(processed_world_data(i)));
    for j = 1:numel(fns)
        processed_world_data(i).(fns(j)) = ...
            cellfun(@(x)(double(x)),(cell(processed_world_data(i).(fns(j)))));
    end
end

% Make a column vector to support data organization
processed_world_data = processed_world_data(:);
