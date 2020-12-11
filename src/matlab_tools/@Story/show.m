function show(app, ind)
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
% function show(app, ind)

% Create new tab
tab_idx = app.newTab;
app.ui.tabs(tab_idx).tab_handle.Title = "Agent " + commas(ind);
ax = app.ui.tabs(tab_idx).axes;

% Get events
ev = app.ev;

% Filter events for this individual
fev = filter_events(ev, ind);

% Get individual's first day
first_day = fev.generation.day;

% Get individual's last day
if ~isempty(fev.removal)
    last_day = fev.removal.day;
else
    last_day = ev.simulationEnd.day;
end

% Get all close contact events
[gen_day, gen_infStatus, gen_generator, individual, hasApp, appDetectsGenerator, falseDiscovery] = exf(ev.generation, ["day", "infectionStatus", "generator", "individual", "hasApp", "appDetectsGenerator", "falseDiscovery"], 'UniformOutput', [true false false true true false false]);
appDetectsGenerator = e2nan(appDetectsGenerator);
gen_generator = e2nan(gen_generator);
falseDiscovery = e2nan(falseDiscovery);
gen_idx = find(gen_generator == ind); % Get events where this individual is the generator

% Create genEvents struct consisting of generation events where this
% individual is generator
ec = cell(numel(gen_idx), 1);
genEvents = struct('day', ec, 'infected', ec, 'individual', ec, 'appDetectsGenerator', ec, 'falseDiscovery', ec);
for i = 1:numel(genEvents)
    genEvents(i).day = gen_day(gen_idx(i));
    genEvents(i).infected = ~strcmpi(gen_infStatus(gen_idx(i)), 'uninfected');
    genEvents(i).individual = individual(gen_idx(i));
    genEvents(i).hasApp = hasApp(gen_idx(i));
    genEvents(i).appDetectsGenerator = appDetectsGenerator(gen_idx(i));
    genEvents(i).falseDiscovery = falseDiscovery(gen_idx(i));
end

% Get all flash events
[f_day, f_individual, f_count] = exf(ev.flash, ["day", "individual", "count"]);
f_idx = find(f_individual == ind);

% Create flashEvents struct consisting of flash events where this
% individual is the inciting agent
ec = cell(numel(f_idx), 1);
flashEvents = struct('day', ec, 'count', ec);
for i = 1:numel(flashEvents)
    flashEvents(i).day = f_day(f_idx(i));
    flashEvents(i).count = f_count(f_idx(i));
end

% Get infection status changes for this individual
[isc_day, isc_is] = exf(fev.infectionStatusChange, ["day", "infectionStatus"], 'UniformOutput', [true false]);

% Get this individual's behavior changes and corresponding x/y lines
behavior_x = (first_day : last_day);
y = behavior2num(fev.generation.behavior) * ones(size(behavior_x));
for i = 1:numel(fev.behaviorChange)
    day = fev.behaviorChange(i).day;
    behavior = fev.behaviorChange(i).behavior;
    level = behavior2num(behavior);
    
    idx = find(behavior_x == day);
    y = [y(1:idx), level, level * ones(size(behavior_x(idx + 1 : end)))];
    behavior_x = [behavior_x(1:idx), behavior_x(idx), behavior_x(idx + 1 : end)];    
end

% Plot behavior with colors based on infection status
X = [behavior_x nan];
Y = [y nan];
Z = [zeros(size(behavior_x)) nan];

C = ones(size(behavior_x)) * is2colornum(fev.generation.infectionStatus);

nisc = numel(isc_day);
    
for i = 1:nisc
    idx = find(behavior_x == isc_day(i), 1, 'first');
    C(idx:end) = is2colornum(isc_is{i});
end
cm = [ 91 155 213; % uninfected      
      254 192   0; % exposed       
      237 125  49; % presymptomatic
      255 145 145; % asymptomatic
      255   0   0; % symptomatic
       91 155 213] / 255; % recovered
caxis(ax, [0 5]);

patch(X, Y, Z, [C nan], 'edgecolor', 'flat', 'Parent', ax, 'LineWidth', 8); 
colormap(ax, cm);

% Put together data package for buttonDownFcn callbacks
app.ui.tabs(tab_idx).data = struct(...
    'fev', fev, ...
    'genEvents', genEvents, ...
    'ev', ev);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Above the line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Preallocate cc_events structure
cc_x = (first_day : last_day);
z = zeros(1, numel(cc_x));
cc_events = struct('igen', z, 'uigen', z, 'flash', z);

% Populate cc_events structure
for i = 1:numel(genEvents)
    
    day_index = find(cc_x == genEvents(i).day);
    
    if genEvents(i).infected
        cc_events.igen(day_index) = cc_events.igen(day_index) + 1;
    else
        cc_events.uigen(day_index) = cc_events.uigen(day_index) + 1;
    end
end

for i = 1:numel(flashEvents)
    
    day_index = find(cc_x == flashEvents(i).day);
    
    cc_events.flash(day_index) = cc_events.flash(day_index) + flashEvents(i).count;
end
   
%%% Make bubble charts
% Infected
bx = find(cc_events.igen ~= 0) - 1 + first_day;
by = ones(size(bx)) * 2;
sz = cc_events.igen(cc_events.igen ~= 0);
c = '#FFC000';
bc1 = bubblechart(ax, bx, by, sz, c, 'ButtonDownFcn', {@buttonDown, app.ui.tabs(tab_idx)}, 'Tag', 'cc_infected');

% Not infected
bx = find(cc_events.uigen ~= 0) - 1 + first_day;
by = ones(size(bx)) * 4;
sz = cc_events.uigen(cc_events.uigen ~= 0);
c = '#5B9BD5';
bc2 = bubblechart(ax, bx, by, sz, c, 'ButtonDownFcn', {@buttonDown, app.ui.tabs(tab_idx)}, 'Tag', 'cc_uninfected');

% Flash
bx = find(cc_events.flash ~= 0) - 1 + first_day;
by = ones(size(bx)) * 6;
sz = cc_events.flash(cc_events.flash ~= 0);
bc3 = bubblechart(ax, bx, by, sz, 'markerfacecolor', 'none', 'markeredgecolor', [.6 .6 .6], 'ButtonDownFcn', {@buttonDown, app.ui.tabs(tab_idx)}, 'Tag', 'cc_flash');
%%%

%     keyboard;
%     % Get event day
%     day = genEvents(i).day;
%     
%     % Get the level for this day based on how many events have been already
%     % logged for this day
%     [levels_above, inc] = gl(day, levels_above);
%     
%     % Plot the line connecting individual and contact
%     idx = find(x == day, 1, 'first');
%     plot([day day], [y(idx) inc], 'LineStyle', '--', 'Color', 'k');
%     
%     % Create a text label for the contact
%     textLabel(ax, day, inc, genEvents(i).individual, genEvents(i).infected, genEvents(i).hasApp, genEvents(i).appDetectsGenerator, genEvents(i).falseDiscovery);
% end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% On the line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Plot behavior guide lines
for i = -3:0
    plot(ax.XLim, [i i], 'LineStyle', ':', 'Color', [0.8 0.8 0.8]);
end

% Plot generator
if ~isempty(fev.generation.generator)
    data = struct(...
        'x', first_day - 1, ...
        'y', y(1), ...
        'num', commas(fev.generation.generator), ...
        'infected', true, ...
        'appUser', fev.generation.generatorHasApp, ...
        'appDetectsGenerator', false, ...
        'falseDiscovery', false, ...
        'tag', 'generatorLabel');
    
    textLabel(ax, data, app.ui.tabs(tab_idx));
end

% Plot individual
data = struct(...
        'x', first_day, ...
        'y', y(1) + 0.8, ...
        'num', commas(fev.generation.individual), ...
        'infected', ~strcmpi(fev.generation.infectionStatus, 'Uninfected'), ...
        'appUser', fev.generation.hasApp, ...
        'appDetectsGenerator', fev.generation.appDetectsGenerator, ...
        'falseDiscovery', fev.generation.falseDiscovery, ...
        'tag', 'individualLabel');
    
textLabel(ax, data, app.ui.tabs(tab_idx));

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Below the line
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Control where icons are plotted below the behavior line
levels_below = struct(...
    'days', (first_day:last_day), ...
    'increments', zeros(size(first_day:last_day)));

% Get ordered events
oe = Story.getOrderedEvents(ev, ind);

for en = 1:numel(oe)
    levels_below = plotEvent(app.ui.tabs(tab_idx), oe{en}, behavior_x, y, levels_below);    
end

% Set axes properties
ax.XLim = [first_day - 2 last_day + 2];
% ax.YLim = [-4 - max(levels_below.increments), ax.YLim(2)];
ax.YLim(1) = min([ax.YLim(1), -5]);
ax.YLim(2) = max([ax.YLim(2), 8]);
ax.YTick = (-3:0);
ax.YTickLabel = {'Max Restriction', 'Mod Restriction', 'Min Restriction', 'Normal'};
xlabel(ax, 'Day');
title(ax, "The Story of Agent " + commas(ind));
grid(ax, 'on');

% Add legends
% blgd = bubblelegend('Close Contact Events');
% blgd.Layout.Tile = 'east';
% lgd = legend([bc1 bc2 bc3], 'Infected', 'Not Infected', 'Flash');
% lgd.Layout.Tile = 'east';

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%    Helper Functions     %%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

function buttonDown(src, event, tab)

data = tab.data;

% Get day of clicked event
day = round(event.IntersectionPoint(1));
assignin('base', 'sdata', data);

% Get tab character
tab_char = sprintf('\t');

switch src.Tag
    case 'cc_infected'
        
        % Get counts, bool, agents
        [counts, ~, agents] = cba(data, day);
        
        txt = [                
                "Infected Close Contacts"
                "Day: " + day
                "Counts:"
                tab_char + "Total: " + counts.infected.total
                tab_char + "App Users: " + counts.infected.appUser
                tab_char + "App Detects Generator: " + counts.infected.appDetectsGenerator
                "Agents:"
                tab_char + "App Users, Detected Generator: " + agents.infected.app_detected
                tab_char + "App Users, Did Not Detect Generator: " + agents.infected.app_noDetected
                tab_char + "Non-app Users: " + agents.infected.noapp
                ];
                
        tab.status.Value = sprintf('%s\n', txt.join(newline));
    case 'cc_uninfected'
        % Get counts, bool, agents
        [counts, ~, agents] = cba(data, day);
        
        txt = [                
                "Uninfected Close Contacts"
                "Day: " + day
                "Counts:"
                tab_char + "Total: " + counts.uninfected.total
                tab_char + "App Users: " + counts.uninfected.appUser
                tab_char + "App Detects Generator: " + counts.uninfected.appDetectsGenerator
                tab_char + "False Discovery: " + counts.uninfected.falseDiscovery
                "Agents:"
                tab_char + "App Users, Detected Generator: " + agents.uninfected.app_detected
                tab_char + "App Users, Did Not Detect Generator: " + agents.uninfected.app_noDetected
                tab_char + "Non-app Users: " + agents.uninfected.noapp
                tab_char + "False Discovery: " + agents.uninfected.falseDiscovery
                ];
                
        tab.status.Value = sprintf('%s\n', txt.join(newline));
        
    case 'cc_flash'
        
        flash_event = ...
            data.fev.flash([data.fev.flash.day] == day);
        
        assert(numel(flash_event) == 1, ...
            'invalid flash event count.');
        
        txt = [
            "Flash Close Contacts"
            "Day: " + day
            "Number: " + flash_event.count
            ];
        
        tab.status.Value = sprintf('%s\n', txt.join(newline));
        
    case {'individualLabel', 'generatorLabel'}
        if strcmpi(src.Tag, 'individualLabel')
            ge = tab.data.fev.generation;
        else
            ge = data.ev.generation(e2nan({tab.data.ev.generation.individual}) == tab.data.fev.generation.generator);
        end        
        
        % Agent
        txt = "Agent " + ge.individual;
        
        % Separator line
        nd = 6 + floor(log10(ge.individual)) + 1;
        line = join(repmat("-", 1, nd), '');
        txt = txt.append(newline + line);
        
        % First day
        txt = txt.append(newline + "First Day: " + ge.day);
        
        % Generator
        if ~isempty(ge.generator)
            gen = ge.generator;
        else
            gen = "None";
        end
        txt = txt.append(newline + "Generator: " + gen);
        
        % Infected
        if ~ismember(ge.infectionStatus, {'Uninfected', 'Recovered'})
            txt = txt.append(newline + "Infected: Yes");
            txt = txt.append(newline + string(tab_char) + "Starting state: " + ge.infectionStatus);
            
            % Latent and incubation period
            txt = txt.append(newline + string(tab_char) + "Latent Period: " + ge.latentPeriod);
            txt = txt.append(newline + string(tab_char) + "Incubation Period: " + ge.incubationPeriod);
            
        else
            txt = txt.append(newline + "Infected: No");
        end
        
        % Close contact descendants
        ind_is_gen = e2nan({data.ev.generation.generator}) == ge.individual;
        infected = ~strcmpi({data.ev.generation.infectionStatus}, 'Uninfected');
        
        ni = nnz(ind_is_gen & infected);
        nui = nnz(ind_is_gen & ~infected);
        if ~isempty(data.ev.flash)
            nf = sum([data.ev.flash([data.ev.flash.individual] == ge.individual).count]);
        else
            nf = 0;
        end
        ncc = ni + nui + nf;
        
        txt = txt.append(newline + "Number of New Close Contacts: " + ncc);
        if ncc > 0
            txt = txt.append(newline + string(tab_char) + "Infected: " + ni);
            txt = txt.append(newline + string(tab_char) + "Uninfected: " + nui);
            txt = txt.append(newline + string(tab_char) + "Flash: " + nf);
        end
        
        %%% App information
        if ge.hasApp
            txt = txt.append(newline + "App User: Yes");
            
            if ge.generatorHasApp
                txt = txt.append(newline + string(tab_char) + "Generator Has App: Yes");
                txt = txt.append(newline + string(tab_char) + "App Detects Generator: " + btt(ge.appDetectsGenerator));
                txt = txt.append(newline + string(tab_char) + "False Discovery: " + btt(ge.falseDiscovery));
            else
                txt = txt.append(newline + string(tab_char) + "Generator Has App: No");
            end
                
        else
            txt = txt.append(newline + "App User: No");
            txt = txt.append(newline + string(tab_char) + "Generator Has App: " + btt(ge.generatorHasApp));
        end        
        %%%
        
        % Starting behavior
        txt = txt.append(newline + "Starting Behavior: " + ge.behavior);
        
        % Wearing mask
        txt = txt.append(newline + "Wearing Mask: " + btt(ge.wearingMask));
        
        tab.status.Value = sprintf('%s\n', txt.join(newline));
        
    case 'aen'
        txt = "AEN";
        
        aen_ev = data.fev.aen([data.fev.aen.day] == day);
        
        txt = txt.append(newline + "Day: " + day);
        txt = txt.append(newline + "Origin: " + aen_ev.origin);
        
        tab.status.Value = sprintf('%s\n', txt.join(newline));
        
    otherwise
        warning('Unrecognized type %s', src.Tag)
end



end

function textLabel(ax, params, tab)
% function textLabel(ax, data, tab)

% Set colors based on whether or not contact is infected
if params.infected
    color = [1 0.25 0];
    bgc = [1 .9 .7];
else
    color = [0.2 0.2 0.2];
    bgc = [0.9 0.9 0.9];
end

% Set edge style based on whether or not contact has app
if params.appUser
    linestyle = '-';
else
    linestyle = ':';
end

% Set line width and fontweight based on whether or not contact detected generator
if params.appDetectsGenerator
    linewidth = 2.5;
    fontweight = 'bold';
else
    linewidth = 1;
    fontweight = 'normal';
end

% Set font angle based on whether contact was really TC4TL
if params.falseDiscovery
    fontAngle = 'italic';
    textColor = [0.5 0.5 0.5];
else
    fontAngle = 'normal';
    textColor = color;
end

text(ax, params.x, params.y, num2str(params.num), ...
    'linestyle', linestyle, 'color', textColor, 'backgroundcolor', bgc, ...
    'linewidth', linewidth, 'horizontalalignment', 'center', 'edgecolor', color, 'fontAngle', fontAngle, ...
    'fontweight', fontweight, ...
    'Tag', params.tag, ...
    'ButtonDownFcn', {@buttonDown, tab});

end

function [levels, inc] = gl(day, levels)
% function [levels, inc] = gl(day, levels)
%
% Get level for a particular day
    idx = find(levels.days == day);
    levels.increments(idx) = levels.increments(idx) + 1;
    inc = levels.increments(idx);
end

function plotLabel(tab, x, y, txt, varargin)
% function plotLabel(tab, x, y, txt, varargin)

opts = inputParser;
opts.addParameter('markersize', 22, @isscalar);
opts.addParameter('color', 'k');
opts.addParameter('textcolor', '');
opts.addParameter('markerfacecolor', [0.9 0.9 0.9]);
opts.addParameter('marker', 'o', @ischar);
opts.addParameter('fontangle', 'normal', @ischar);
opts.addParameter('fontweight', 'normal', @ischar);
opts.addParameter('tag', '', @ischar);
opts.parse(varargin{:});
markersize = opts.Results.markersize;
color = opts.Results.color;
markerfacecolor = opts.Results.markerfacecolor;
marker = opts.Results.marker;
fontangle = opts.Results.fontangle;
textcolor = opts.Results.textcolor;
fontweight = opts.Results.fontweight;
tag = opts.Results.tag;

if isempty(textcolor)
    textcolor = color;
end

% Get axes
ax = tab.axes;

hp = plot(ax, x, y, 'marker', marker);
    hp.MarkerSize = markersize;
    hp.Color = color;
    hp.MarkerFaceColor = markerfacecolor;

text(ax, x, y, txt, 'HorizontalAlignment', 'Center', 'VerticalAlignment', 'middle', 'fontangle', fontangle, 'color', textcolor, 'fontweight', fontweight, 'tag', tag, 'ButtonDownFcn', {@buttonDown, tab});

end    

function colornum = is2colornum(is)

switch is
    case 'Uninfected'
        colornum = 0; %rgb = [ 91 155 213];
    case 'Exposed'
        colornum = 1; %rgb = [254 192   0];
    case 'Presymptomatic' 
        colornum = 2; %rgb = [237 125  49];
    case 'Asymptomatic'
        colornum = 3; %rgb = [255 145 145];
    case 'Symptomatic'
        colornum = 4; %rgb = [255   0   0];
    case 'Recovered'
        colornum = 5; %rgb = [ 91 155 213];
    otherwise
        error('Invalid infection state.');
end
end

function levels_below = plotEvent(tab, ev, x, y, levels_below)

    % Get axes
    ax = tab.axes;

    if ismember(ev.type, {'generation', 'removal', 'infectionStatusChange', 'addedToCallList', 'behaviorChange', 'flash', 'identifiedContact', 'putOnMask'})
        return
    end

    % Get the day of the event
    day = ev.day;
    
    % Get the position along the behavior line corresponding to this day
    idx = find(x == day, 1, 'last');
    
    % Get the vertical position of the event icon
    [levels_below, inc] = gl(day, levels_below);

    switch ev.type
        case 'tookTest'
            plotLabel(tab, x(idx), y(idx) - inc, 'T', 'marker', '>', 'markerfacecolor', 'w', 'tag', ev.type);
        case 'receivedTestResult'
            if ev.testResultPositive
                mfc = [1 0.75 0.75];
            else
                mfc = 'w';
            end

            plotLabel(tab, x(idx), y(idx) - inc, 'T', 'marker', '<', 'markerfacecolor', mfc, 'tag', ev.type);
            
        case 'aen'
            text(ax, x(idx), y(idx) - inc, 'AEN', 'horizontalalignment', 'center', 'edgecolor', 'k', 'linewidth', 1, 'backgroundcolor', [0.85 0.85 1], 'ButtonDownFcn', {@buttonDown, tab}, 'tag', ev.type);
            
        case 'keyUpload'
            plotLabel(tab, x(idx), y(idx) - inc, 'K', 'marker', '^', 'markerfacecolor', [0.85 1 0.85], 'tag', ev.type);
        case {'putOnMask', 'flash', 'identifiedContact', 'droppedFromCallList', 'memoryLimitReached'}
            fprintf('Bypassed event: %s\n', ev.type);
        case 'publicHealthCall'

            if ev.success
                color = [0 .7 0];
        %         textcolor = 'k';
                mfc = 'w';
            else
                color = [1 .4 .4];
        %         textcolor = 'k';
                mfc = 'w';
            end

            if strcmpi(ev.callType, 'contact_case')
                fontangle = 'italic';
                fontweight = 'normal';
            elseif strcmpi(ev.callType, 'index_case')
                fontangle = 'normal';
                fontweight = 'bold';
            else
                error('Unrecognized callType %s', ev.callType);
            end


            plotLabel(tab, x(idx), y(idx) - inc, 'PH', 'marker', 'v', 'markerfacecolor', mfc, 'color', color, 'textcolor', '', 'fontangle', fontangle, 'fontweight', fontweight, 'tag', ev.type);
        otherwise
            error('Unrecognized event type %s', ev.type);
    end
end

function out = commas(in)
% function out = commas(in)

jf = java.text.DecimalFormat;
out = string(jf.format(in));

end

function out = btt(in)

if in
    out = "Yes";
else
    out = "No";
end
end

function [counts, bool, agents] = cba(data, day)

% Create empty structures
counts = struct();
bool = struct();
agents = struct();

% Get bool conditions
bool.infected = [data.genEvents.infected];
bool.day = [data.genEvents.day] == day;
bool.hasApp = [data.genEvents.hasApp];
bool.appDetectsGenerator = [data.genEvents.appDetectsGenerator];
bool.falseDiscovery = [data.genEvents.falseDiscovery];

% Get counts
counts.infected.total = nnz(bool.infected & bool.day);
counts.infected.appUser = nnz(bool.infected & bool.day & bool.hasApp);
counts.infected.appDetectsGenerator = nnz(bool.infected & bool.day & bool.appDetectsGenerator);
counts.uninfected.total = nnz(~bool.infected & bool.day);
counts.uninfected.appUser = nnz(~bool.infected & bool.day & bool.hasApp);
counts.uninfected.appDetectsGenerator = nnz(~bool.infected & bool.day & bool.appDetectsGenerator);
counts.uninfected.falseDiscovery = nnz(~bool.infected & bool.day & bool.falseDiscovery);

% Get agent lists
agents.infected.app_detected = join(string([data.genEvents(bool.infected & bool.day & bool.appDetectsGenerator).individual]), ', ');
agents.infected.app_noDetected = join(string([data.genEvents(bool.infected & bool.day & bool.hasApp & ~bool.appDetectsGenerator).individual]), ', ');
agents.infected.noapp = join(string([data.genEvents(bool.infected & bool.day & ~bool.hasApp).individual]), ', ');
agents.uninfected.app_detected = join(string([data.genEvents(~bool.infected & bool.day & bool.appDetectsGenerator).individual]), ', ');
agents.uninfected.app_noDetected = join(string([data.genEvents(~bool.infected & bool.day & bool.hasApp & ~bool.appDetectsGenerator).individual]), ', ');
agents.uninfected.noapp = join(string([data.genEvents(~bool.infected & bool.day & ~bool.hasApp).individual]), ', ');
agents.uninfected.falseDiscovery = join(string([data.genEvents(~bool.infected & bool.day & bool.falseDiscovery).individual]), ', ');

end

function level = behavior2num(behavior)
switch lower(behavior)
    case 'normal'
        level = 0;
    case 'minimal_restriction'
        level = -1;
    case 'moderate_restriction'
        level = -2;
    case 'maximal_restriction'
        level = -3;
    otherwise
        error('Invalid behavior %s', behavior);
end    
end
