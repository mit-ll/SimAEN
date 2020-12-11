function [parents, ids] = itree(RGen, idx)
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
% function [parents, ids] = itree(RGen, idx)

if nargin == 1
    idx = 1:numel(RGen);
end

RGen = RGen(idx);

% Pre-set nodes vector
parents = zeros(numel(RGen), 1)';
ids = zeros(numel(RGen), 1)';
XD = zeros(numel(RGen), 1)';

for i = 1:numel(RGen)    
    if isempty(RGen(i).generator)
        parents(i) = 0;        
        ids(i) = RGen(i).individual;
    else
        parents(i) = find(ids == RGen(i).generator);
        ids(i) = RGen(i).individual;
    end
    XD(i) = RGen(i).day;
end

close all;
treeplot(parents(idx));
hax = gca;
for i = 1:numel(hax.Children)
    x = hax.Children(i).XData; y = hax.Children(i).YData;
    hax.Children(i).XData = -y + 1; hax.Children(i).YData = x;
end
