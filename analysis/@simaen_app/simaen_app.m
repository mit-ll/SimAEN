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
classdef simaen_app < handle
    properties
        arrayFiles
        metricsFiles
        runConfig
        data
        configs
        ui
        metrics
    end
    
    methods(Static)
        params = setup2params(setup)
        [ids_nrpc, ids_unique] = params2ids(configs, params, NRPC)
        verify_ids(files, params, ids)
    end
    
    methods        
        
        function app = simaen_app(runConfigFile)
        % function app = simaen_app(runConfigFile)
        %
        % Class constructor

        % Handle input
        if nargin == 0
            [f, p, i] = uigetfile({'*.mat', 'MAT Files (*.mat)'}, 'Load runConfig file');
            if i == 0; return; end %user cancelled
            runConfigFile = [p, filesep, f];
        end
        
        % Convert to char, if necessary
        if isstring(runConfigFile)
            runConfigFile = char(runConfigFile);
        end

        % Load runConfig
        app.runConfig = load(runConfigFile);       
        
        %%%
        % Get array file and metrics file locations (locations assumed
        % based on location of runConfigFile)
        p = fileparts(runConfigFile);
        
        arrayDir = [p, filesep, 'mats', filesep, 'arrays'];
        assert(exist(arrayDir, 'dir') == 7, ...
            'array directory does not exist in expected location %s', arrayDir);
        W = what(arrayDir);
        app.arrayFiles = string([arrayDir, filesep]) + string(W.mat);
        
        use_metrics = false;
        metricsDir = [p, filesep, 'mats', filesep, 'metrics'];
        if exist(metricsDir, 'dir') ~= 7
            warning('metrics directory does not exist in expected location %s', metricsDir);
            app.metricsFiles = [];            
        else
            W = what(metricsDir);
            app.metricsFiles = string([metricsDir, filesep]) + string(W.mat);
            if all(arrayfun(@(x)(exist(x, 'file') == 2), app.metricsFiles))
                use_metrics = true;
            end
        end
        %%%
        
        % Get associated configs
        app.configs = multiConfig(app.runConfig.setup, 'groups', app.runConfig.groups);
        
        % Get metrics to track
        app.metrics = metric.defaultList();
        
        % Set current metric
        app.data.metric = app.metrics(1);
        
        % Construct figure
        app.constructFigure;  
        
        % Set Use Lookup Data check box
        if use_metrics
            app.ui.checkbox_lookup.Value = 1;
        else
            app.ui.checkbox_lookup.Value = 0;
            app.ui.checkbox_lookup.Enable = 'off';
        end        
        
        % Update
        app.update();
        end
        
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%    OTHER FUNCTIONS    %%%%%%%%%%%%%%%%%%%%%%%
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
        
        constructFigure(app)
        update(app, varargin)
        sliders2params(app)
        out = loadResults(app, varargin)
            
    end    
end

