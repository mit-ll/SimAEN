function plotvenn(venn)
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
% function plotvenn(venn)
%
% Plot infected-MCT-AEN diagram.
%
% Input argument:
%
%   +   venn: this comes from the following --
%               >> out = arrays(processed_events, max_day);
%               >> venn = out.people.venn;

warning('This function is deprecated!  Use the Venn class instead.');

% Set up plot
th = linspace(0, 2 * pi);
xc = cos(th);
yc = sin(th);

offset = 0.65;
mult = 1.65;

figure;
ax = axes;
plot(ax, xc - offset, yc, 'Color', 'k'); % Infected (top left)
    hold on; 
plot(ax, xc + offset, yc, 'Color', 'k'); % MCT (top right)
plot(ax, xc, yc - offset * mult, 'Color', 'k'); % AEN (bottom)

ax.DataAspectRatio = [1 1 1];
ax.YLim = [-1 - offset*mult, 1];
ax.XTick = [];
ax.YTick = [];

% Add numbers to plot
for i = 1:size(venn.combos, 1)
    
    num = string(venn.counts(i));
    if sum(venn.combos(i, :)) == 1
        if venn.combos(i, 1) % Infected
            circle_name = 'Infected';
        elseif venn.combos(i, 2) % MCT
            circle_name = 'MCT';
        elseif venn.combos(i, 3) % AEN
            circle_name = 'AEN';
        end
        num = sprintf('%s\n%s', circle_name, num);
    end
    
    if     isequal(venn.combos(i, :), [ true  true  true]) % I, MCT, AEN (middle)                
        text(0, -(offset * mult) * 0.25, num, 'HorizontalAlignment', 'center');        
    
    elseif isequal(venn.combos(i, :), [false  true  true]) % ~I, MCT, AEN (mid-right)        
        text(0.45, -(offset * mult) * 0.5, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(venn.combos(i, :), [ true false  true]) % I, ~MCT, AEN (mid-left)       
        text(-0.45, -(offset * mult) * 0.5, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(venn.combos(i, :), [ true  true false]) % I, MCT, ~AEN (top)      
        text(0, (offset * mult) * 0.25, num, 'HorizontalAlignment', 'center');        
    
    elseif isequal(venn.combos(i, :), [false false  true]) % ~I, ~MCT, AEN (bottom)          
        text(0, -(offset * mult) * 1.25, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(venn.combos(i, :), [false  true false]) % ~I, MCT, ~AEN (top-right)       
        text(0.9, 0.2, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(venn.combos(i, :), [ true false false]) % I, ~MCT, ~AEN (top-left)       
        text(-0.9, 0.2, num, 'HorizontalAlignment', 'center');
    
    elseif isequal(venn.combos(i, :), [false false false]) % ~I, ~MCT, ~AEN (bottom-right)       
        text(1.5, -1.5, num, 'HorizontalAlignment', 'center');
    
    else
        error('Invalid combination.');
    
    end
end
