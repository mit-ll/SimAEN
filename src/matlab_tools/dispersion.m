function dispersion(mu, sig, varargin)
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
% function dispersion(mu, sig, varargin)

% Handle input
opts = inputParser;
opts.addParameter('N', 1e6, @isscalar);
opts.addParameter('xmax', 1e7, @isscalar);
opts.addParameter('cval', 0.8, @isscalar);
opts.parse(varargin{:});
N = opts.Results.N;
xmax = opts.Results.xmax;
cval = opts.Results.cval;

%%% Calculated
% x: number of contacts/infections
x = fliplr(0:0.1:xmax);

% px: probability of x contacts/infections OR index case falling into each
% bin
px = lognpdf(x, mu, sig);    

% PX: running total of "number" of index cases falling into each bin
PX = cumsum(px);

% y: "number" of instances of each number of contacts/infections
y = px .* x;
Y = cumsum(y); % Cumulative "number" of contacts/infections coming from each bin        

plotx = PX / max(PX);
ploty = Y / max(Y);

figure;
plot(plotx, ploty, 'displayname', 'calculated', 'linewidth', 2);
xlabel('% of Index Cases');
ylabel('% of Infections');
grid on;
hold on;

ind = find(ploty <= cval, 1, 'last');

cval_x = diff(plotx([ind, ind + 1])) / diff(ploty([ind, ind + 1])) * (cval - ploty(ind)) + plotx(ind);

plot([0 cval_x cval_x], [cval cval 0], 'linestyle', '--', 'color', 'k');
text(cval_x, cval, sprintf('%0.1f%% of infections caused by %0.1f%% of index cases', cval * 100, cval_x * 100), 'HorizontalAlignment', 'left', 'VerticalAlignment', 'top')
%%%

%%% Simulated
rln = exp(mu + sig * randn(N, 1)); % get random numbers drawn from log normal distribution
rlns = sort(rln, 'descend');
plot(linspace(0, 1, numel(rlns)), cumsum(rlns) / max(cumsum(rlns)), 'displayname', 'simulated', 'linewidth', 1);
%%%

legend;

