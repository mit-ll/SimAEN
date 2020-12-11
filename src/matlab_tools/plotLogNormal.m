function plotLogNormal(mus, sigs, varargin)
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
% function plotLogNormal(mus, sigs, varargin)

% Handle input
opts = inputParser;
opts.addParameter('parent', []);
opts.addParameter('upper_limit', 150, @isscalar);
opts.addParameter('N', 1e6, @isscalar);
opts.parse(varargin{:});
parent = opts.Results.parent;
upper_limit = opts.Results.upper_limit;
N = opts.Results.N;

% Handle input
if isempty(parent)
    parent = figure;
end

% Weighted mean formula
wmean = @(x,w)(sum(x.*w)/sum(w));    

% Establish dummy figure
dfig = figure;

q = 0;
for i = 1:numel(mus)
    
    % Get this Gaussian mu and sigma
    mu = mus(i);
    sig = sigs(i);
    
    % Get X and Y for Gaussian
    xg = linspace(mu - 5 * sig, mu + sig * 5, 1e5);
    yg = normpdf(xg, mu, sig);

    % Plot Gaussian
    q = q + 1;
    ax = subplot(numel(mus), 2, q, 'Parent', dfig); 
    ax.Parent = parent;
    plot(ax, xg, yg); 
    grid(ax, 'on');
    ylabel(ax, 'P(X)');
    if i == 1
        title(ax, ['Gaussian', newline, '\mu = ', num2str(mu),'; \sigma = ', num2str(sig)]);
    else
        title(ax, ['\mu = ', num2str(mu),'; \sigma = ', num2str(sig)]);
    end
    
    if i == numel(mus)
        xlabel(ax, 'X');
    end
    
    %%% Plot log normal with weighted mean
    q = q + 1; % Increment counter
    ax = subplot(numel(mus), 2, q, 'Parent', dfig); % Generate subplot
    ax.Parent = parent;
    xln = linspace(0, upper_limit, N);
    yln = lognpdf(xln, mu, sig);
    plot(ax, xln, yln); 
        grid(ax, 'on');
        hold(ax, 'on');
    ax.XLim = [0 upper_limit];
    
    wm = wmean(xln, yln);
%     plot(ax, [wm, wm], ax.YLim, 'linestyle', '--', 'color', 'r');
    %%%
    
    ylabel(ax, 'P(X) (normalized)');
    
    % Get amount left above upper limit
    aul = 1 - logncdf(upper_limit, mu, sig);
    
    if i == 1
        title(ax, ['Log-Normal', newline, 'E[X] = ', num2str(wm), '; AUL = ', num2str(aul)]);
    else
        title(ax, ['E[X] = ', num2str(wm), '; AUL = ', num2str(aul)]);
    end
    
    if i == numel(mus)
        xlabel(ax, 'X');
    end
end
% Link axes
% linkaxes(findobj(parent, 'Tag', 'lognormal'));
close(dfig);

