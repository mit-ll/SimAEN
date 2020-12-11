function jsdout = processOutput(input, output, varargin)
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
% function jsdout = processOutput(input, output, varargin)
%
% Load JSON results from Python code execution, process, and save as MATLAB
% .mat file(s)
%
% varargin: save (true), cast (true), mimo (false)

noOutputSpecified = false;

%%% Handle input
if mod(nargin, 2) ~= 0 %output not specified
    varargin = [output varargin];
    noOutputSpecified = true;
end
opts = inputParser;
opts.addParameter('save', true, @islogical);
opts.addParameter('cast', true, @islogical);
opts.addParameter('mimo', false, @islogical);
opts.parse(varargin{:});
savefile = opts.Results.save;
castnums = opts.Results.cast;
mimo = opts.Results.mimo;
if mimo
    assert(noOutputSpecified, ...
        'if mimo is true, then do not specify argument output');
end
%%%

disp('====================================================================');
disp('===================   Begin MATLAB Processing   ====================');
disp('====================================================================');

% Ensure that matlab_tools directory is on the path
fprintf('Adding matlab_tools to path... ');
    w = which('LLGrid_genpath'); 
    if ~isempty(w) % on the grid
        simaen_home = getenv('SIMAEN_HOME');
        addpath(LLGrid_genpath([simaen_home, filesep, 'src/matlab_tools']));    
    end
    fprintf('added!\n');

% Handle SISO or MIMO
if mimo % input/output are files containing list of JSON/MAT file path/names
    [json_files, mat_files] = deal(string.empty);
    
    txt = fileread(input); % get text
    sl = splitlines(string(txt)); % convert to string and split by lines
    
    q = 0;
    for i = 1:numel(sl) % For each line...
        pair = split(sl(i)); % Split down the middle (assumes only one space)
        
        if pair ~= ""
            q = q + 1; % increment counter
            assert(numel(pair) == 2, 'cannot split filename pairs into two filenames');
            json_files(q) = pair(1); 
            mat_files(q) = pair(2); 
        end
    end
    
    assert(numel(json_files) == numel(mat_files), ...
        'numbers of JSON and MAT files are not equal.');
else % input/output are the JSON/MAT file path/names themselves
    json_files = string(input);
    mat_files = string(output);
end
    
% Preallocate jsdout
jsdout = cell(numel(json_files), 1); 

for fn = 1:numel(json_files) % For each JSON file...
    % Update user
    fprintf('***\n');
    fprintf('Working on file %d of %d.\n', fn, numel(json_files));    
    fprintf('+  JSON file:\n\t%s\n', json_files(fn));
    if savefile
        fprintf('+  MAT file:\n\t%s\n', mat_files(fn));
    end
    fprintf('***\n');
    
    % Read JSON file, convert to MATLAB format
    txt = fileread(json_files(fn));
    jsd = jsondecode(txt);

    %%% Do extra processing for arrays
    if isfield(jsd, 'arrays')
        
        % Append totals to 'days' field
        jsd = appendTotals(jsd); 

        %%% Handle logs capturing the generator's state.  Need to account
        %%% for missing generators.
        if iscell(jsd.arrays.people.generatorWearingMask)
            jsd.arrays.people.generatorWearingMask = e2nan(jsd.arrays.people.generatorWearingMask); % generatorWearingMask
        else
            assert(all(isnan(jsd.arrays.people.generatorWearingMask)), ...
                'invalid values for generatorWearingMask');
        end
        
        if iscell(jsd.arrays.people.generatorHasApp)
            jsd.arrays.people.generatorHasApp = e2nan(jsd.arrays.people.generatorHasApp);
        else
            assert(all(isnan(jsd.arrays.people.generatorHasApp)), ...
                'invalid values for generatorHasApp');
        end
        %%%
        %%%
    end
    %%%

    % Convert fields of arrays to integer classes that take up less space
    if isfield(jsd, 'arrays') && castnums  

        % Specify fields to convert and the precisions to convert to
        flds.people.uint8 = ["behaviorAtStart"];  %#ok<NBRAK>
        flds.people.uint16 = ["num_descendants", "num_infected_descendants", "first_day", "last_day", "aen_num"];
        flds.people.uint32 = ["individual"]; %#ok<NBRAK>
        flds.days.uint16 = ["day"]; %#ok<NBRAK>
        flds.days.uint32 = ["new_cases", "new_infected_cases", "keyUploads", "aen", "tests", "positive_test_results", "negative_test_results"];

        % Convert ISM
        precision = 'uint8';
        check_int(jsd.arrays.ISM, precision, 'ISM');
        jsd.arrays.ISM = cast(jsd.arrays.ISM, precision);  

        % Convert other fields
        bigFields = string(fieldnames(flds));
        for i = 1:numel(bigFields)
            bigField = bigFields(i);
            precisions = string(fieldnames(flds.(bigField)));
            for j = 1:numel(precisions)            
                precision = precisions(j);
                littleFields = flds.(bigField).(precision);

                for k = 1:numel(littleFields)
                    littleField = littleFields(k);

                    data = jsd.arrays.(bigField).(littleField);
                    check_int(data, precision, littleField);
                    jsd.arrays.(bigField).(littleField) = cast(data, precision);                        
                end
            end 
        end
    end

    % Save results
    if savefile
        fprintf('Saving output... ');
            save(mat_files(fn), '-struct', 'jsd', '-v7.3');
            fprintf('complete!\n');
    end
    
    % Assemble output
    jsdout{fn} = jsd;
end

% Prepare output
jsdout = cell2mat(jsdout);

disp('====================================================================');
disp('====================   End MATLAB Processing   =====================');
disp('====================================================================');

function check_int(data, precision, fld)
% function check_int(data, precision, fld);
%
% Check if data that is about to be converted to different class will lose
% precision if this is done.  If so, throw an error and alert the user
% which data field is the one of interest.

assert(all(data <= intmax(precision) & data >= intmin(precision), 'all'), ...
    'values in %s outside of %s range.  Precision would be lost in data conversion.', fld, precision);
