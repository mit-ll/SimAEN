function gridRunStatus(delay, runConfig)
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
% function gridRunStatus(delay, runConfig)
%
% Print status of grid run continually at fixed intervals specified by
% 'delay' input argument.

% Get number of expected outputs for everything except metrics
nout = runConfig.NuC * runConfig.NRPC;
ndig = ceil(log10(nout + 1));

nout_m = runConfig.NuC;
% ndig_m = ceil(log10(nout_m + 1));

% Start timer
tic;

while true
    mj = LLGrid_myjobs;
    
    p_events = dir([runConfig.folders.p_events, filesep, '*.json']);
    p_arrays = dir([runConfig.folders.p_arrays, filesep, '*.json']);
    m_events = dir([runConfig.folders.m_events, filesep, '*.mat']);
    m_arrays = dir([runConfig.folders.m_arrays, filesep, '*.mat']);
    m_metrics = dir([runConfig.folders.m_metrics, filesep, '*.mat']);
    
    fprintf('%s - %s\n', datestr(now, 'HH:MM:SS'), toc2str(toc));
    fprintf('%*d / %d event JSON files created.', ndig, numel(p_events), nout);
        if numel(p_events) > 0
            fprintf('  (%0.1f MB)\n', sum([p_events.bytes]) / 1e6);
        else
            fprintf('\n');
        end
    fprintf('%*d / %d array JSON files created.', ndig, numel(p_arrays), nout);
        if numel(p_arrays) > 0
            fprintf('  (%0.1f MB)\n', sum([p_arrays.bytes]) / 1e6);
        else
            fprintf('\n');
        end
    fprintf('%*d / %d event MAT files created.', ndig, numel(m_events), nout);
        if numel(m_events) > 0
            fprintf('  (%0.1f MB)\n', sum([m_events.bytes]) / 1e6);
        else
            fprintf('\n');
        end
    fprintf('%*d / %d array MAT files created.', ndig, numel(m_arrays), nout);
        if numel(m_arrays) > 0
            fprintf('  (%0.1f MB)\n', sum([m_arrays.bytes]) / 1e6);
        else
            fprintf('\n');
        end
    fprintf('%*d / %*d metric MAT files created.', ndig, numel(m_metrics), ndig, nout_m);
        if numel(m_metrics) > 0
            fprintf('  (%0.1f MB)\n', sum([m_metrics.bytes]) / 1e6);
        else
            fprintf('\n');
        end
   
    if mj ~= 0
        fprintf('Jobs are running...\n');
    else
        fprintf('No jobs are running.\n');
        beep; pause(1); beep; pause(1); beep;
        break;
    end
    
    fprintf('\n');
    pause(delay);
end

function out = toc2str(tock)
% function out = toc2str(tock)

hr = floor(tock / 3600);
min = floor((tock - hr * 3600) / 60);
sec = floor(tock - hr * 3600 - min * 60);
out = sprintf('%02.0f:%02.0f:%02.0f', hr, min, sec);
