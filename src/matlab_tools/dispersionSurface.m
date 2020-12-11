function dispersionSurface(mus, sigs, varargin)
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
% function dispersionSurface(mus, sigs, varargin)

% Handle input
opts = inputParser;
opts.addParameter('cval', 0.8, @isscalar);
opts.addParameter('method', 'sim', @ischar);
opts.addParameter('N', 1e6, @isscalar);
opts.addParameter('xmax', 1e4, @isscalar);
opts.parse(varargin{:});
cval = opts.Results.cval;
method = opts.Results.method;
N = opts.Results.N;
xmax = opts.Results.xmax;

% x: number of contacts/infections
x = fliplr(0:0.1:xmax);

% Preallocate Z
Z = zeros(numel(mus), numel(sigs));

f = waitbar(0, 'Generating plot...');
for i = 1:numel(mus)
    mu = mus(i);
    
    for j = 1:numel(sigs)        
        waitbar((j + (i - 1) * numel(sigs)) / (numel(mus) * numel(sigs)), f, 'Generating plot...');
        
        sig = sigs(j);
        
        switch method
            case {'calc', 'calculation', 'c'}

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
                
            case {'sim', 'simulation', 's'}

                rln = exp(mu + sig * randn(N, 1)); % get random numbers drawn from log normal distribution
                rlns = sort(rln, 'descend');

                plotx = linspace(0, 1, numel(rlns));
                ploty = cumsum(rlns) / max(cumsum(rlns));

                % Get the percentage of index cases causing cval infections
                
            otherwise
                error('Invalid method %s', method);
        end
        ind = find(ploty <= cval, 1, 'last');
        Z(i, j) = plotx(ind);
    end
end
close(f);

figure('Name', method);
surface(sigs, mus, Z);
colorbar;
xlabel('\sigma'); ylabel('\mu'); zlabel('Dispersion');
grid on;
