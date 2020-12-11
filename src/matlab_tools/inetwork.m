function [G, P] = inetwork(pe, max_day)
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
% function [G, P] = inetwork(pe, max_day)

%Get gen
gen = pe.generation;

G = graph(); %create directed graph
G = addnode(G, numel(gen));

G.Nodes.name = (1:numel(gen))';
G.Nodes.hasApp = arrayfun(@(x)(x.hasApp), gen);
G.Nodes.infected = arrayfun(@(x)(strcmp(x.infectionStatus, 'Exposed')), gen);

% Get initial nodes
initial_nodes = find(arrayfun(@(x)(isempty(x.generator)), gen));

% Get number of edges
NE = nnz(arrayfun(@(x)(isempty(x.generator)), gen));

% Preallocate color data vectors
node_cdata = zeros(numel(gen), 1); 
edge_cdata = zeros(NE, 1); 

% Create edges and adjust color of nodes
for i = 1:numel(gen)    
    
    if ~isempty(gen(i).generator)
        G = addedge(G, gen(i).generator, gen(i).individual);
    end
    
    node_cdata(i, :) = double(G.Nodes.infected(i));    
end

% Change color of edges
for i = 1:numel(G.Edges)
    
    gi = G.Edges.EndNodes(i, 2);
    
    if G.Nodes.infected(gi) && ~isempty(gen(gi).generator)
        edge_cdata(i, :) = 1;
    elseif ~G.Nodes.infected(gi) && ~isempty(gen(gi).generator)
        edge_cdata(i, :) = 0;
    end
end

% Plot
figure;
P = G.plot(...
    'Layout', 'layered', ...
    'direction', 'right', ...
    'sources', initial_nodes, ...
    'NodeCData', node_cdata, ...
    'EdgeCData', edge_cdata);

% Adjust colors of infected and non-infected nodes
colormap(gcf, [125 125 125; 255 127 0]/255);

% Move nodes so that their x position is on the day they were created
for i = 1:numel(gen)
    P.XData(i) = gen(i).day;
end

% Plot cosmetic adjustments
P.Parent.XTick = (0:5:max_day);
grid(P.Parent, 'on');
xlabel(P.Parent, 'Day');
