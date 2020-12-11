function uif = basicPlot(arraysOut)
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
% function uif = basicPlot(arraysOut)

% Extract relevant data from arraysOut
data = arrayfun(@(x)(x.arrays.days), arraysOut);

% Create UI figure
% ss = get(0, 'ScreenSize');
% uif = uifigure('Position', [100 100, ss(3)*.6, ss(4)*.4]); 
uif = uifigure;

% Create UI tab group
uitg = uitabgroup('Parent', uif); 
pos = uif.Position;
uitg.Position = [0 0 pos(3) pos(4)];

% Set up window alignment across tabs
lims = struct('x', cell(4,1), 'y', cell(4,1));
for i = 1:numel(lims)
    lims(i).x = [inf -inf];
    lims(i).y = [inf -inf];
end

for cn = 1:size(data, 2)
    
    % Create new tab
    uit = uitab('Parent', uitg, 'Title', sprintf('Config %d', cn));
    
    r = 2; c = 2;

    % Set xlabel and ylabel
    xlbl = 'Day';
    ylbls = ["Current Cases", "Total Cases", "Called Today", "New Cases"];

    % Create empty array of axes (preallocation)
    ax = matlab.graphics.axis.Axes.empty(r*c, 0);
    
    for i = 1 : r*c 
        ax(i) = subplot(r, c, i); % create subplot
        ax(i).Parent = uit; %assign axes to current tab

        % Set labels and turn on grid
        xlabel(ax(i), xlbl);
        ylabel(ax(i), ylbls(i));
        grid(ax(i), 'on');

        % Change y axis to log scale for plots specified below
        if ismember(ylbls(i), ["Current Cases", "Total Cases", "New Cases", "Total Called"])
            ax(i).YScale = 'log';
        end

        hold(ax(i), 'on');
    end

    runcount = 0;

    runcount = runcount + 1;
    style = struct('color',runcount,'minimal',0,'smooth',7);
    
    % Create plots
    nicePlot(data(:,cn), ax(1), 'current_cases', style);
    nicePlot(data(:,cn), ax(2), 'total_infected_cases', style);
    nicePlot(data(:,cn), ax(3), 'calls', style);
    nicePlot(data(:,cn), ax(4), 'new_cases', style);    

    % Update global axes window limits
    for i = 1 : r*c        
        lims(i).x(1) = min([ax(i).XLim(1), lims(i).x(1)]);
        lims(i).x(2) = max([ax(i).XLim(2), lims(i).x(2)]);
        lims(i).y(1) = min([ax(i).YLim(1), lims(i).y(1)]);
        lims(i).y(2) = max([ax(i).YLim(2), lims(i).y(2)]);
    end
    
    % Get information to configure axes window limits
    axs{cn} = ax; %#ok<AGROW>
end

% Align windows of all plots
for i = 1:numel(axs)
    for j = 1:numel(axs{i})
        axs{i}(j).XLim = lims(j).x;
        axs{i}(j).YLim = lims(j).y;
    end
end
end

function [] = nicePlot(data, ax, f, style)
% function [] = nicePlot(data, ax, f, style)
%
% 1. Current Cases
% 2. Total Cases
% 3. Contacted Today 
% 4. New Cases
penn = [22,41,47,47,79,112,155,206,311,399,509,698,946,1260,1795,2345,2845,3432,4155,4963,6009,7268,8570,10444,11589,13127,14853,16631,18300,20051,21719,22938,24292,25465,26753,28258,29888,31652,32902,33914,35249,36082,38379,40208,41153,42616,43558,45137,46327,47971,49579,50494,51225,52816,53864,54800,55956,57371,58560,59939,60459,61310,62101,63105,64136,65185,65700,66669,67311,68126,69252,70211,71009,71563,71925,72778,73557,74220,74984,75697,76129,76646,77225,77780,78335,78815,79505,79908,80339,80870,81316,81848,82481,82944,83203,83589,83978,84289,84683,85199,85590,85935,86576,87208,87685,88141,88860,89446,89863,90467,91139,91775,92612,93392,93922,94403,95100,95898,96725,97542,98482,99216,99794,100330,101266,102269,103075,104079,104780,105384,106405,107460,108223,109105,110292,111115,111745,112995,114083,114939,115807,116787,117468,118033,118894,119724,120446,121247,122028,122665,123312,124221,125016,125918,126905,127732,128531,129070,129647,130247,130905,131692,132417,133160,133679,134204,134760,135279,135912,136781,137576,138134,138795,139548,140532,141570,142495,143280,143824,144540,145156];
    isLog = strcmp(ax.YScale, 'log');
    days = data(1).day;
    
    % Handle missing fields in style
    if ~ismember('color',fieldnames(style))
        style.color = 0;
    end
    if ~ismember('minimal',fieldnames(style))
        style.minimal = 0;
    end
    if ~ismember('color',fieldnames(style))
        style.smooth = 0;
    end
    
    style.smooth = ceil(style.smooth);
    
    % Set plot color based on style.color
    switch style.color
        case 1
            color = [0.71,0.91,0.93];
        case 2
            color = [204 0 255]/255;
        case 3
            color = [1, 0, 0];
        case 4
            color = [102 255 51]/255;
        otherwise
            color = [0.75, 0.75, 0.75];
    end
    
    p = [];
    for ii = 1:length(data)
        
        new_data = data(ii).(f);        
        p = [p; new_data(:)'];
        
        if isLog
            p(p <= 0) = 1; % This is a dumb fix for the way that matlab handles patches on log plots
        end
        if style.minimal == 0
            plot(ax,days,p(end,:),'Color',[0.5,0.5,0.5])
        end
        hold all
    end
    if style.minimal == 0
        plot(ax,days,max(p,[],1),'--','Color',color,'LineWidth',1.5)
        plot(ax,days,min(p,[],1),'--','Color',color,'LineWidth',1.5)
    end
    
    if ~isa(p, 'double')
        p = double(p);
    end
    
    s = std(p,0,1);
    x = [days(:)', fliplr(data(1).day(:)')];
    y = [mean(p, 1) + s, fliplr(mean(p, 1) - s)];
    patch(ax,x,y,color,'FaceAlpha',0.5,'EdgeColor','none')
    if style.smooth > 0
        px = [p,repmat(p(:,end),1,style.smooth)];
        psmooth = conv(mean(px,1),rectwin(style.smooth)/style.smooth,'same');
        plot(ax,days,psmooth(1:size(p,2)),'k','LineWidth',2)
        plot(ax,days,psmooth(1:size(p,2)),'Color',color,'LineWidth',0.5)
    else
        plot(ax,days,mean(p,1),'k','LineWidth',2)
        plot(ax,days,mean(p,1),'Color',color,'LineWidth',0.5)
    end
    if strcmp(f,'total_infected_cases')
        plot(ax,days,penn(1:length(days)),'k.')
    end
end
