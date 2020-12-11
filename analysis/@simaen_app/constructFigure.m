function constructFigure(app)
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
% function constructFigure(app)

% Set original name
app.ui.original_name = 'SimAEN Analysis App';

% Create figure window
app.ui.fig = uifigure(...
    'Position', [960 375 1425 720], ...
    'Name', app.ui.original_name, ...
    'WindowKeyPressFcn', {@figKeyPress, app}, ...
    'WindowKeyReleaseFcn', {@figKeyRelease, app});

% Create parameters panel
app.ui.param_pnl = uipanel(app.ui.fig, ...
    'Position', [0, 0, app.ui.fig.Position(3) * 0.35, app.ui.fig.Position(4)], ...
    'Title', 'Parameter Selection');

% Create axes panel
app.ui.axes_pnl = uipanel(app.ui.fig, ...
    'Position', [...
    app.ui.param_pnl.Position(1) + app.ui.param_pnl.Position(3), ...
    0, ...
    app.ui.fig.Position(3) - (app.ui.param_pnl.Position(1) + app.ui.param_pnl.Position(3)), ...
    app.ui.fig.Position(4)], ...
    'Title', 'Results Visualization');

% Create axes
app.ui.axes = uiaxes(app.ui.axes_pnl, ...
    'Position', [...
    app.ui.axes_pnl.Position(3) * 0.1, ...
    app.ui.axes_pnl.Position(4) * 0.1, ...
    app.ui.axes_pnl.Position(3) * 0.8, ...
    app.ui.axes_pnl.Position(4) * 0.8]);

% Turn grid on
grid(app.ui.axes, 'on');

% Get setup fields with more than one value (indicates something that
% changed in sim)
fns = string(fieldnames(app.runConfig.setup));
fns = fns(:);
fns_change = fns(structfun(@(x)(numel(x) > 1), app.runConfig.setup));

% Put field names in alphabetical order and then moves groups into separate
% string array elements
fns_change = {sort(fns_change)};

for i = 1:numel(app.runConfig.groups)
    if any(ismember(fns_change{1}, app.runConfig.groups{i}))
        fns_change{end + 1} = fns_change{1}(ismember(fns_change{1}, app.runConfig.groups{i})); %#ok<AGROW>
        fns_change{1} = fns_change{1}(~ismember(fns_change{1}, app.runConfig.groups{i}));
    end        
end

% Create sliders within parameters panel
q = 0; % object counter
vpos = app.ui.param_pnl.Position(4) - 75; % vertical position of objects
sep_width = 0.8; % width of group separator bars
for fci = 1:numel(fns_change)
    
    for i = 1:numel(fns_change{fci})
        q = q + 1;                
        
        fn = fns_change{fci}(i); % get this field name (fn)
        
        % Create slider and set properties
        app.ui.sliders(q) = uislider(app.ui.param_pnl);
        app.ui.sliders(q).Position(1:3) = [app.ui.param_pnl.Position(3) * 0.4, vpos, app.ui.param_pnl.Position(3) * 0.5];                    
        app.ui.sliders(q).MajorTicks = 1:numel(app.runConfig.setup.(fn));
%         app.ui.sliders(q).MajorTicks = app.runConfig.setup.(fn);
        app.ui.sliders(q).MajorTickLabels = string(app.runConfig.setup.(fn));
%         app.ui.sliders(q).Limits = [min(app.runConfig.setup.(fn)), max(app.runConfig.setup.(fn))];
        app.ui.sliders(q).Limits = [1, numel(app.runConfig.setup.(fn))];
        app.ui.sliders(q).MinorTicks = [];
        app.ui.sliders(q).Tag = fn;
        app.ui.sliders(q).ValueChangedFcn = {@sliderChangeFcn, app}; 
        
        app.ui.sliders(q).UserData = struct('Values', app.runConfig.setup.(fn));

        % Create accompanying label
        app.ui.labels(q) = uilabel(app.ui.param_pnl);
            app.ui.labels(q).Position(1:3) = [app.ui.param_pnl.Position(3) * 0.025, app.ui.sliders(q).Position(2), app.ui.param_pnl.Position(3) * 0.3];
            app.ui.labels(q).Text = fn;
            app.ui.labels(q).VerticalAlignment = 'Bottom';                    
            app.ui.labels(q).HorizontalAlignment = 'Right';
            
        if i < numel(fns_change{fci})
            vpos = vpos - 75;
        else
            vpos = vpos - 60;
        end
    end
    
    if fci < numel(fns_change)
        % Create separator between groups
        uilabel(app.ui.param_pnl, ...
            'Position', [app.ui.param_pnl.Position(3) * (1 - sep_width)/2, vpos, app.ui.param_pnl.Position(3) * sep_width, 2], ...
            'BackgroundColor', [0.75 0.75 0.75]);
        
        vpos = vpos - 45;
    end
    
end

% Create y-window control
app.ui.checkbox = uicheckbox(app.ui.axes_pnl, ...
    'Position', [sum(app.ui.axes.Position([1,3])), sum(app.ui.axes.Position([2,4])), app.ui.axes_pnl.Position(3) - app.ui.axes.Position(3)/2, 30], ...
    'Text', 'Lock Y Axis', ...
    'Value', 0, ...
    'ValueChangedFcn', {@checkboxChangeFcn, app});

% Create lookup checkbox
app.ui.checkbox_lookup = uicheckbox(app.ui.axes_pnl, ...
    'Position', [15, 10, 200, 30], ...
    'Text', 'Use Lookup Data', ...
    'Value', 0, ...
    'ValueChangedFcn', {@checkbox_lookupChangeFcn, app});

max_lbl = uilabel(app.ui.axes_pnl, ...
    'Position', [app.ui.checkbox.Position(1), app.ui.checkbox.Position(2) - app.ui.checkbox.Position(4), 30, 30], ...
    'Text', 'Max');
min_lbl = uilabel(app.ui.axes_pnl, ...
    'Position', [app.ui.checkbox.Position(1), max_lbl.Position(2) - max_lbl.Position(4), 30, 30], ...
    'Text', 'Min');

app.ui.maxSpinner = uispinner(app.ui.axes_pnl, ...
    'Position', [sum(max_lbl.Position([1, 3])), max_lbl.Position(2), 60, 30], ...
    'Tag', 'max', ...
    'ValueChangedFcn', {@spinnerChangeFcn, app}, ...
    'Limits', [0.5 inf], ...
    'LowerLimitInclusive', 'off', ...
    'Value', 1, ...
    'ValueDisplayFormat', '%11.2g');

app.ui.minSpinner = uispinner(app.ui.axes_pnl, ...
    'Position', [sum(min_lbl.Position([1, 3])), min_lbl.Position(2), 60, 30], ...
    'Tag', 'min', ...
    'ValueChangedFcn', {@spinnerChangeFcn, app}, ...
    'Limits', [-inf 0.5], ...
    'UpperLimitInclusive', 'off', ...
    'Value', 0, ...
    'ValueDisplayFormat', '%11.2g');

% Populate axes labels
xlabel(app.ui.axes, strrep(app.ui.sliders(1).Tag, '_', ' '));
ylabel(app.ui.axes, app.metrics(1).Name);

% Disable 1st slider, set it as current slider
app.ui.sliders(1).Enable = 'off';
app.data.thisSlider = app.ui.sliders(1);

% Set xlabel context menu that allows user to switch x axis
app.ui.xcm = uicontextmenu(app.ui.fig);
for i = 1:numel(app.ui.sliders)
    app.ui.menu(i) = uimenu(app.ui.xcm, 'Text', app.ui.sliders(i).Tag, 'Tag', app.ui.sliders(i).Tag);
    app.ui.menu(i).MenuSelectedFcn = {@xLabelContextMenuFcn, app};
end
app.ui.axes.XLabel.ContextMenu = app.ui.xcm;

% Set ylabel context menu that allows user to switch y axis
app.ui.ycm = uicontextmenu(app.ui.fig);
for i = 1:numel(app.metrics)
    app.ui.menu(i) = uimenu(app.ui.ycm, 'Text', app.metrics(i).Name, 'Tag', app.metrics(i).Tag);
    app.ui.menu(i).MenuSelectedFcn = {@yLabelContextMenuFcn, app};
end
app.ui.axes.YLabel.ContextMenu = app.ui.ycm;

% Set figure menu
app.ui.figMenu_about = uimenu(app.ui.fig, 'Text', 'About');
app.ui.figMenu_analysis = uimenu(app.ui.fig, 'Text', 'Analysis');
app.ui.figMenu_control = uimenu(app.ui.fig, 'Text', 'Control');

% About menus
uimenu(app.ui.figMenu_about, 'Text', 'Contact Distributions', 'Tag', 'Contact Distributions', 'MenuSelectedFcn', {@menuAboutThisSim, app});
uimenu(app.ui.figMenu_about, 'Text', 'Simulation Parameters', 'Tag', 'Simulation Parameters', 'MenuSelectedFcn', {@menuAboutThisSim, app});

% Analysis menus
uimenu(app.ui.figMenu_analysis, 'Text', 'AEN Histogram', 'Tag', 'AEN Histogram', 'MenuSelectedFcn', {@menuPlots, app});
uimenu(app.ui.figMenu_analysis, 'Text', 'Call Statistics', 'Tag', 'Call Statistics', 'MenuSelectedFcn', {@menuPlots, app});
uimenu(app.ui.figMenu_analysis, 'Text', 'Dispersion', 'Tag', 'Dispersion', 'MenuSelectedFcn', {@menuPlots, app});

% Control menus
uimenu(app.ui.figMenu_control, 'Text', 'Send Data to Base', 'Tag', 'Send Data to Base', 'MenuSelectedFcn', {@menuControl, app});

% Set Bootstrap control
w = 40;
app.ui.bootstrap = uieditfield(app.ui.axes_pnl, 'Value', '25', ...
    'Position', [app.ui.axes_pnl.Position(3) - w - 10, 10, w, 30], ...
    'ValueChangedFcn', {@bootstrapChangeFcn, app});

w = 80;
uilabel(app.ui.axes_pnl, 'Text', 'Bootstrap N', ...
    'Position', [app.ui.bootstrap.Position(1) - w - 10, app.ui.bootstrap.Position(2), w, app.ui.bootstrap.Position(4)], ...
    'HorizontalAlignment', 'right');

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%     UI CHANGE FUNCTIONS     %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function bootstrapChangeFcn(~, ~, app)
    app.update();
end

function menuControl(src, ~, app)

    switch src.Tag
        case 'Send Data to Base'
            %%% Load data and send to base    
            app.ui.fig.Name = [app.ui.original_name, ' (loading arrays...)'];
                drawnow;                        
                arrays = app.loadResults('use_lookup', false);            
            app.ui.fig.Name = [app.ui.original_name, ' (loading lookup...)'];
                drawnow;
                lookup = app.loadResults('use_lookup', true);
            assignin('base', 'appData', struct('arrays', arrays, 'lookup', lookup));
            app.ui.fig.Name = app.ui.original_name;
        otherwise
            error('Invalid tag %s', src.Tag);
    end    
end

function menuPlots(src, ~, app)        

    %%% Load data to work with
    if isempty(app.data.arrays)
        app.ui.fig.Name = [app.ui.original_name, ' (loading...)'];
            drawnow;
            arrays = app.loadResults('use_lookup', false);
            app.ui.fig.Name = app.ui.original_name;
    else
        arrays = app.data.arrays;
    end
    %%%
    
    % Get number of parameter combinations to plot
    N = size(arrays, 2); 

    switch src.Tag
        case 'Dispersion'
            
            % Assemble data
            out = metric.assemble(arrays, 'people', 'subflds', ["num_infected_descendants", "infected", "recovered"]);
            
            figure; % Generate figure
            xtl = string(app.ui.axes.XTickLabel); % x tick labels from box plot
            
            for oi = 1:N
                
                nid = double(out.num_infected_descendants{oi});
                infected = out.infected{oi};
                recovered = out.recovered{oi};
                
                nid_ir = nid(infected & recovered);
                nid_ir_sorted = sort(nid_ir, 'descend');
                
                x = (1:numel(nid_ir_sorted)) / numel(nid_ir_sorted);
                y = cumsum(nid_ir_sorted);
                    y = y / y(end);
                
                plot(x, y, 'linewidth', 2, 'displayname', xtl(oi));          
                
                hold on;
            end
            grid on;
            xlabel('Percentage of Infectious Agents');
            ylabel('Percentage of Infections');
            legend;
            
        case 'AEN Histogram'
            
            % Assemble data
            out = metric.assemble(arrays, 'people', 'subflds', ["aen_num", "hasApp", "generatorHasApp"]);            
            
            figure; % Generate figure
            for oi = 1:N % For each parameter combination
                ax = subplot(1, N, oi); % Create subplot

                % Get data                   
                out.generatorHasApp{oi}(isnan(out.generatorHasApp{oi})) = false;
                condition = out.hasApp{oi} & out.generatorHasApp{oi};
                data = out.aen_num{oi}(condition);                    

                % Plot
                histogram(ax, data, 'normalization', 'probability', 'binmethod', 'integers');
                grid(ax, 'on');
                xlabel(ax, '# AENs Received');
                ylabel(ax, 'Probability');
                
                x_tick_labels = string(app.ui.axes.XTickLabel);
                title_text = sprintf('%s: %s', app.ui.axes.XLabel.String, x_tick_labels(oi));
                title(ax, title_text);
            end
            
        case 'Call Statistics'            
            
            f = uifigure('Name', 'Call Statistics');
            uitg = uitabgroup(f);
                uitg.Position = [0 0 f.Position(3:4)];            
            xtl = string(app.ui.axes.XTickLabel);            
            
            tabs = struct(...
                'Name', {'Total Added to Call List', 'Total Attempted Calls', 'Total Successful Calls', 'Total Dropped from Call List', 'Length of Call List', 'Number of Attempted Calls Per Day', 'Number of Successful Calls Per Day'}, ...
                'ylabel', {'Total Added', 'Total Attempted', 'Total Successful', 'Total Dropped', 'Length', 'Number of Calls', 'Number of Successful Calls'});
            
            
            for ti = 1:numel(tabs)
                
                uit = uitab(uitg, 'Title', tabs(ti).Name);
                t = tiledlayout(uit, 'flow');
                
                for col = 1:size(arrays, 2)
                    ax = nexttile(t);
                    for row = 1:size(arrays, 1)
                        
                        switch tabs(ti).Name
                            case 'Total Added to Call List'
                                Y = cumsum(arrays(row, col).days.additions_to_call_list);                                
                            case 'Total Attempted Calls'
                                Y = cumsum(arrays(row, col).days.calls);                                
                            case 'Total Successful Calls'
                                Y = cumsum(arrays(row, col).days.successful_calls);                                
                            case 'Total Dropped from Call List'
                                Y = cumsum(arrays(row, col).days.dropped_from_call_list);                                
                            case 'Length of Call List'
                                Y = cumsum(arrays(row, col).days.additions_to_call_list) - ...
                                    cumsum(arrays(row, col).days.successful_calls) - ...
                                    cumsum(arrays(row, col).days.dropped_from_call_list);
                            case 'Number of Attempted Calls Per Day'
                                Y = arrays(row, col).days.calls;
                            case 'Number of Successful Calls Per Day'
                                Y = arrays(row, col).days.successful_calls;
                            otherwise
                                error('Invalid tab name %s', tabs(ti).Name);
                        end
                        
                        plot(ax, arrays(row, col).days.day, Y, 'color', 'b', 'linewidth', 1);
                        hold(ax, 'on');
                    end
                    grid(ax, 'on');                
                    xlabel(ax, 'Day');
                    ylabel(ax, tabs(ti).ylabel);
                    title(ax, xtl(col));
                end
                linkaxes(findobj(uit, '-depth', inf, 'Type', 'axes'));
            end
            
        otherwise
            error('Unrecognized menu tag %s', src.Tag);
    end
end

function menuAboutThisSim(src, ~, app)

    switch src.Tag
        case 'Simulation Parameters'
            setup_fns = fieldnames(app.runConfig.setup);
            mnchar = max(cellfun(@(x)(numel(x)), setup_fns));
            for fnsi = 1:numel(setup_fns)            
                fprintf('%*s: %s\n', mnchar, setup_fns{fnsi}, mat2str(app.runConfig.setup.(setup_fns{fnsi})));
            end
            
        case 'Contact Distributions'            
            
            warning('Assumes grouping of mus and sigmas.');
            
            uif = uifigure;
            uitg = uitabgroup('Parent', uif); 
            
            pos = uif.Position;
            uitg.Position = [0 0 pos(3) pos(4)];
            
            % Normal
            uit = uitab(uitg, 'Title', 'Normal');
            mus = app.runConfig.setup.mean_new_cases;
            sigs = app.runConfig.setup.sigma_new_cases;
            plotLogNormal(mus, sigs, 'parent', uit);
            
            % Minimal
            uit = uitab(uitg, 'Title', 'Minimal');
            mus = app.runConfig.setup.mean_new_cases_minimal;
            sigs = app.runConfig.setup.sigma_new_cases_minimal;
            plotLogNormal(mus, sigs, 'parent', uit);
            
            % Moderate
            uit = uitab(uitg, 'Title', 'Moderate');
            mus = app.runConfig.setup.mean_new_cases_moderate;
            sigs = app.runConfig.setup.sigma_new_cases_moderate;
            plotLogNormal(mus, sigs, 'parent', uit);
            
            % Maximal
            uit = uitab(uitg, 'Title', 'Maximal');
            mus = app.runConfig.setup.mean_new_cases_maximal;
            sigs = app.runConfig.setup.sigma_new_cases_maximal;
            plotLogNormal(mus, sigs, 'parent', uit);
            
        otherwise
            error('Invalid source tag %s', src.Tag);
    end
end

function figKeyRelease(~, ev, app)
    if ismember('shift', ev.Modifier) && ismember('control', ev.Modifier)
        app.ui.maxSpinner.Step = 0.01;
        app.ui.minSpinner.Step = 0.01;
    elseif ismember('shift', ev.Modifier)
        app.ui.maxSpinner.Step = 0.1;
        app.ui.minSpinner.Step = 0.1;
    else
        app.ui.maxSpinner.Step = 1;
        app.ui.minSpinner.Step = 1;
    end 
end

function figKeyPress(~, ev, app)
    if ismember('shift', ev.Modifier) && ismember('control', ev.Modifier)
        app.ui.maxSpinner.Step = 0.01;
        app.ui.minSpinner.Step = 0.01;
    elseif ismember('shift', ev.Modifier)
        app.ui.maxSpinner.Step = 0.1;
        app.ui.minSpinner.Step = 0.1;
    else
        app.ui.maxSpinner.Step = 1;
        app.ui.minSpinner.Step = 1;
    end 
end

function spinnerChangeFcn(src, ~, app)        
    if strcmpi(src.Tag, 'max')
        app.ui.minSpinner.Limits = [-inf src.Value];
        if app.ui.checkbox.Value; app.ui.axes.YLim(2) = src.Value; end            
    elseif strcmpi(src.Tag, 'min')
        if app.ui.checkbox.Value; app.ui.axes.YLim(1) = src.Value; end
        app.ui.maxSpinner.Limits = [src.Value inf];
    end
end

function checkboxChangeFcn(src, ~, app)
    if src.Value
        app.ui.axes.YLimMode = 'manual';
%             app.ui.minSpinner.Value = app.ui.axes.YLim(1);
%             app.ui.maxSpinner.Value = app.ui.axes.YLim(2);
        app.ui.axes.YLim = [app.ui.minSpinner.Value app.ui.maxSpinner.Value];
    else
        app.ui.axes.YLimMode = 'auto';
    end
end

function checkbox_lookupChangeFcn(~, ~, app)                        
    app.update('force_update', true);
end

function xLabelContextMenuFcn(src, ~, app)
    % Enable all sliders
    [app.ui.sliders.Enable] = deal('on');

    % Set xlabel string
    app.ui.axes.XLabel.String = strrep(src.Tag, '_', ' ');        

    % Set current slider
    h_this_slider = findobj(app.ui.sliders, 'Tag', src.Tag);
    app.data.thisSlider = h_this_slider;

    % Disable corresponding slider(s)        
    h_this_slider.Enable = 'off';

    for gni = 1:numel(app.runConfig.groups)
        thisGroup = app.runConfig.groups{gni};
        if ismember(src.Tag, thisGroup)
            for tgi = 1:numel(thisGroup)
                h = findobj(app.ui.sliders, 'Tag', thisGroup(tgi));
                h.Enable = 'off';
            end
        end
    end

    % Update app
    app.update('force_update', true);

end

function yLabelContextMenuFcn(src, ~, app)

    % Set ylabel string
    app.ui.axes.YLabel.String = src.Text;

    % Set current metric
    app.data.metric = findobj(app.metrics, 'Tag', src.Tag);

    % Update app
    app.update('force_update', true);

end

function sliderChangeFcn(src, ~, app)

    % Slider can only occupy the major tick marks and nothing in
    % between them
    [~, I] = min(abs(src.MajorTicks - src.Value));
    src.Value = src.MajorTicks(I);

    % If this slider is a member of a group, enforce the change
    % in all other group members
    grps = app.runConfig.groups;
    for gn = 1:numel(grps)
        this_grp = grps{gn};
        if ismember(src.Tag, this_grp)
            for k = 1:numel(this_grp)
                if src.Tag == this_grp(k)
                    continue
                else
                    h = findobj(app.ui.sliders, 'Tag', this_grp(k));
                    h.Value = h.MajorTicks(I);
                end
            end
        end
    end

    % Update app
    app.update('force_update', true);
end
