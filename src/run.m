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
%% Set configurations

% Add necessary directories to path
addpath(genpath(pwd));

% Get default configuration
setup = defaultConfig();

% num_worlds should be 1
setup.num_worlds = 1;
if setup.num_worlds > 1
    warning('Some functionality may not work properly when num_worlds > 1');
end

% Deviate from default, if desired
setup.mean_new_cases = 2;
setup.sigma_new_cases = 1.5;

setup.p_identify_individual_using_manual_contact_tracing = 1;
setup.p_contact_public_health_after_positive_test = 1.00;
setup.p_running_app = 0.5;
setup.p_app_detects_generator = 0.5;
setup.test_delay = 2;

setup.end_day = 30;    
setup.max_num_current_cases = 1.5e5;    

% Generate separate configs for each combination of variables
groups = {};
% groups = {["mean_new_cases", "mean_new_cases_minimal", "mean_new_cases_moderate", "mean_new_cases_maximal"], ["p_running_app", "p_app_detects_generator"]};
configs = multiConfig(setup, 'groups', groups);

NRPC = 1; %number of times to run each config (Number Runs Per Config)


%% Run Python code

% Write logs to JSON?
writeLogs = true;

% Reload module
clear mod;
%mod = py.importlib.import_module('WorkflowModel');
%py.importlib.reload(mod);

if setup.num_worlds > 1
    warning('Event processing will not function with multiple worlds.');
end

% Run the code
tic
[world_data, eventsOut, arraysOut] = runPython(configs, NRPC, 'writeLogs', writeLogs); %pe: processed events
fprintf('Total duration: %0.1f seconds\n', toc);

if setup.num_worlds > 1
    warning('Event processing will not function with multiple worlds.');
end
