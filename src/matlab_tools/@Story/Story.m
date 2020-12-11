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
classdef Story < handle
    properties
        ev        
        ui
    end
    
    methods(Static)
        
        ordered_events = getOrderedEvents(ev, ind);
        
        [txt, fe] = tell(ev, ind) %tell a story
        
    end
    
    methods
        function app = Story(ev, ind)
            app.ev = ev;
            
            % Generate figure, tab group, first tab
            app.ui.fig = uifigure('Position', [1812 100 1365 1000], 'Name', 'SimAEN Storyteller');
            app.ui.tabgroup = uitabgroup(app.ui.fig, 'Position', [0 0 app.ui.fig.Position(3:4)]);
            app.show(ind);            
        end
        
        function idx = newTab(app)
            
            tab = struct;
            tab.tab_handle = uitab(app.ui.tabgroup);
            
            % Axes
            tab.axes = uiaxes(tab.tab_handle);
            tab.axes.InnerPosition([1, 3]) = [0.1 0.85] * tab.tab_handle.Position(3);
            tab.axes.InnerPosition([2, 4]) = [0.3 0.65] * tab.tab_handle.Position(4);
            tab.axes.NextPlot = 'add';
            box(tab.axes, 'on');
                                    
            % Status            
            tab.status = uitextarea(tab.tab_handle);
            tab.status.Position([1, 3]) = tab.axes.InnerPosition([1, 3]);
            tab.status.Position(2) = 50;
            tab.status.Position(4) = tab.axes.Position(2) - 50 - tab.status.Position(2);
            tab.status.FontName = 'Courier New';
            tab.status.Editable = 'off';
            
            if isfield(app.ui, 'tabs')
                app.ui.tabs(end + 1) = tab;                
            else
                app.ui.tabs = tab;
            end
            
            idx = numel(app.ui.tabs);
        end
        
        % Show a story
        app = show(app, ind) 
    end
end
