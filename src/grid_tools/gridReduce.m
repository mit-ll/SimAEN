function output = gridReduce(outputDir, outputFile, varargin)
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
% function output = gridReduce(outputDir, outputFile, varargin)
%
% Reduce .mat files containing Python JSON results to a smaller set of
% MATLAB .mat files.

% Handle input
opts = inputParser;
opts.addParameter('save', true, @islogical);
opts.parse(varargin{:});
savefile = opts.Results.save;

% Ensure that matlab_tools directory is on the path
addpath(genpath('matlab_tools'));

% Get list of mat files
fprintf('Getting list of .mat files... ');
    D = dir([outputDir, filesep, '*.mat']);
    [names, files] = deal(cell(size(D)));
    [names{:}] = D.name;
    for i = 1:numel(names)
        files{i} = [outputDir, filesep, names{i}];
    end
    fprintf('complete!\n');

% Get size of output structures
fprintf('Getting size of output structures... ');
    rows = -inf;
    cols = -inf;
    for i = 1:numel(files)
        L = load(files{i}, 'config');
        rows = max([rows L.config.config_num_in_group]);
        cols = max([cols L.config.config_group_num]);
    end
    fprintf('complete!  %d rows and %d columns.\n', rows, cols);

% Process results
for i = 1:numel(files)
    
    fprintf('Processing file %d of %d... ', i, numel(files));
    
    % Get file name i
    file = files{i};
    
    % Load file
    L = load(file);
    
    % Get row and column for output
    row = L.config.config_num_in_group;
    col = L.config.config_group_num;
    fprintf('row %d, column %d... ', row, col);
    
    % Set up output if this is the first file
    if i == 1        
        fns = fieldnames(L); % get fields in saved output
        S = [fns(:) cell(size(fns(:)))]';
        output = struct(S{:});
        
        for j = 1:numel(fns)
            fnsj = fieldnames(L.(fns{j}));
            C = cell(numel(fnsj), 1);
            [C{:}] = deal(cell(rows, cols));
            S = [fnsj(:) C(:)]';
            output.(fns{j}) = struct(S{:});
        end
    end
    
    for j = 1:numel(fns)        
        output.(fns{j})(row, col) = L.(fns{j});
    end
    fprintf('complete!\n');
end

% Save output, if desired
if savefile
    fprintf('Saving file... ');
        save(outputFile, '-struct', 'output', '-v7.3');
        fprintf('complete!\n');
        fprintf('\tFile: %s', outputFile);
end
