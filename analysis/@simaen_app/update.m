function update(app, varargin)
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
% function update(app, varargin)
%
% varargin: force_update (false)

% Handle input
opts = inputParser;
opts.addParameter('force_update', false, @islogical);
opts.parse(varargin{:});
force_update = opts.Results.force_update;

% Inform user of update start
app.ui.fig.Name = [app.ui.original_name, ' (updating...)'];

% Get the parameters resulting from slider choices
sliders2params(app);

% Get the resulting config ids
[new_config_ids_nrpc, new_config_ids_unique] = simaen_app.params2ids(app.configs, app.data.params, app.runConfig.NRPC);

% Determine whether or not using lookup data
if app.ui.checkbox_lookup.Value
    use_lookup = true;
    new_config_ids = new_config_ids_unique;
else
    use_lookup = false;
    new_config_ids = new_config_ids_nrpc;
end

if force_update || ((~isfield(app.data, 'config_ids') || ~isequal(app.data.config_ids, new_config_ids)))
    app.data.config_ids = new_config_ids;
    
    % Inform user of file load progress
    app.ui.fig.Name = sprintf(...
        '%s (updating... loading results files...)', ...
        app.ui.original_name);
    
    % Load the resulting array files
    if use_lookup
        app.data.lookup = app.loadResults('use_lookup', use_lookup);
        app.data.arrays = [];
    else
        app.data.arrays = app.loadResults('use_lookup', use_lookup);
        app.data.lookup = [];
    end
end

if use_lookup % Use lookup values
    M = cell2mat({app.data.lookup.(app.data.metric.Tag)});
else % Do not use lookup values
    % Get number of bootstrap resamples to collect
    N = str2double(app.ui.bootstrap.Value);
    if ~isnumeric(N) || N <= 0 || mod(N, 1) ~= 0
        error('Invalid N');
    end
    
    % Preallocate M
    M = zeros(N, size(app.data.arrays, 2));

    %%% Perform calculation with selected metric
    for j = 1:size(app.data.arrays, 2) % For each parameter combination...
                
        % Get total number of elements to resample from
        num_total = sum(arrayfun(@(x)(numel(x.people.individual)), app.data.arrays(:, j)));
        
        for k = 1:N % For each bootstrap iteration...
            
            % Inform user of calculuation progress
            app.ui.fig.Name = sprintf(...
                '%s (updating... parameter %d/%d, bootstrap %d/%d)', ...
                app.ui.original_name, j, size(app.data.arrays, 2), ...
                k, N);
            
            % Get bootstrap indices
            if k == 1
                bsi = (1:num_total)';
            else
                bsi = datasample((1:num_total)', num_total);
            end
            
            % Perform calculation with selected metric and bootstrap
            % indices
            M(k, j) = app.data.metric.Calculator(app.data.arrays(:, j), bsi);            
        end
    end
    %%%
end

% Plot the resulting data
boxplot(app.ui.axes, M);

% Change spinner values or change YLim based on spinner values
if ~app.ui.checkbox.Value
    app.ui.minSpinner.Limits = [-inf inf];
    app.ui.maxSpinner.Limits = [-inf inf];
    
    app.ui.minSpinner.Value = app.ui.axes.YLim(1);
    app.ui.maxSpinner.Value = app.ui.axes.YLim(2);
    
    app.ui.minSpinner.Limits = [-inf app.ui.maxSpinner.Value];
    app.ui.maxSpinner.Limits = [app.ui.minSpinner.Value inf];
else
    app.ui.axes.YLim = [app.ui.minSpinner.Value app.ui.maxSpinner.Value];
end

% Change the X tick marks
app.ui.axes.XTick = 1:numel(app.data.thisSlider.MajorTicks);
app.ui.axes.XTickLabel = app.data.thisSlider.UserData.Values;

% Inform user of update complete
app.ui.fig.Name = app.ui.original_name;
 
end
