function plot(V)
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
% function plot(V)
%
% Plot Venn diagram from processed event stats.
%
% Input argument:
%
%   +   V: object of Venn class with properties 'values' and 'names'
%          specified.

% Set up plot
th = linspace(0, 2 * pi);
xc = cos(th);
yc = sin(th);
offset = 0.65;
mult = 1.65;

figure;
ax = axes;
hp(1) = plot(ax, xc - offset, yc, 'Color', 'k'); % Infected (top left)
    hold on; 
hp(2) = plot(ax, xc + offset, yc, 'Color', 'k'); % MCT (top right)
hp(3) = plot(ax, xc, yc - offset * mult, 'Color', 'k'); % AEN (bottom)

ax.DataAspectRatio = [1 1 1];
ax.YLim = [-1 - offset*mult, 1.2] * 1.2;
ax.XTick = [];
ax.YTick = [];

% Get combos and counts
[combos, counts] = Venn.val2cc(V.values);

% Assertions
assert(size(combos, 2) == 3, ...
    'this function assumes three sets of logical values have been specified.  You have specified %d.', ...
    size(combos, 2));

assert(numel(V.names) == size(combos, 2), ...
    'must specify one name per input variable.');

% Add numbers and labels for major circles to plot
% Top left
count = sum(counts(combos(:, 1)));
text(-0.9, max(hp(1).YData), sprintf('%s:\n%d', V.names(1), count), ...
    'horizontalalignment', 'center', ...
    'verticalalignment', 'bottom');
% Top right
count = sum(counts(combos(:, 2)));
text(0.9, max(hp(2).YData), sprintf('%s:\n%d', V.names(2), count), ...
    'horizontalalignment', 'center', ...
    'verticalalignment', 'bottom');
% Bottom
count = sum(counts(combos(:, 3)));
text(mean(hp(3).XData), min(hp(3).YData), sprintf('%s:\n%d', V.names(3), count), ...
    'horizontalalignment', 'center', ...
    'verticalalignment', 'top');


% Add numbers for unique intersections to plot
for i = 1:size(combos, 1)
    
    num = string(counts(i));
    
    % Unique intersections
    if     isequal(combos(i, :), [ true  true  true]) % (middle)                
        text(0, -(offset * mult) * 0.25, num, 'HorizontalAlignment', 'center');        
    
    elseif isequal(combos(i, :), [false  true  true]) % (mid-right)        
        text(0.45, -(offset * mult) * 0.5, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(combos(i, :), [ true false  true]) % (mid-left)       
        text(-0.45, -(offset * mult) * 0.5, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(combos(i, :), [ true  true false]) % (top)      
        text(0, (offset * mult) * 0.25, num, 'HorizontalAlignment', 'center');        
    
    elseif isequal(combos(i, :), [false false  true]) % (bottom)          
        text(0, -(offset * mult) * 1.25, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(combos(i, :), [false  true false]) % (top-right)       
        text(0.9, 0.2, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(combos(i, :), [ true false false]) % (top-left)       
        text(-0.9, 0.2, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(combos(i, :), [false false false]) % (bottom-right)       
        text(1.5, -1.5, num, 'HorizontalAlignment', 'center');
    
    else
        error('Invalid combination.');
    
    end
end
