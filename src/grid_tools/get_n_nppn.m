function [num_nodes, nppn] = get_n_nppn(NC)
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
% function [num_nodes, nppn] = get_n_nppn(NC)

% Get max_nodes
slots_per_node = 32;
max_slots = 512;
max_nodes = max_slots / slots_per_node;

if NC >= max_nodes * slots_per_node
    num_nodes = 16; nppn = 32;
else
    %1
    nppn = slots_per_node;

    %2
    num_nodes = NC / nppn;

    %3
    num_nodes = min([max_nodes ceil(num_nodes)]);

    %4
    nppn = NC / num_nodes;

    %5
    nppn = min([slots_per_node floor(nppn)]);
end
