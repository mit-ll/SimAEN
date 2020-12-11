function varargout = exf(str, f, varargin) 
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
% function varargout = exf(str, f, varargin)
%
% Extract one or more fields from structure array
%
% Input arguments:
%
%   +   str: structure array
%
%   +   f: field(s) to be extracted.  Specify as char, string array, or
%          cell string array
%
%   +   varargin: input/parameter pair
%
%       +   parameter: 'UniformOutput'
%
%           value: logical
%           
%           default: true
%
%           description: set to false under same circumstances you would
%           need to do so when using arrayfun or cellfun.  Can specify as a
%           logical array with one element per number of fields specified
%           in f.  Can also specify as a scalar that will be applied to all
%           fields specified in f.
%
% Output arguments:
%
%   +   varargout: data present in specified field(s), each organized into
%                  a single array

% Handle input
opts = inputParser;
opts.addParameter('UniformOutput', true, @islogical);
opts.parse(varargin{:});
UniformOutput = opts.Results.UniformOutput;

% Convert f, if necessary
if ischar(f)
    f = string(f);
elseif isstring(f)
elseif iscell(f)
    f = string(f);
else
    error('Invalid input format %s for argument f', class(f));
end

% Handle UniformOutput
if isscalar(UniformOutput) && ~isscalar(f)
    UniformOutput = repmat(UniformOutput, size(f));
end

% Assertions
assert(numel(UniformOutput) == numel(f), ...
    'Mismatch between number of UniformOutput arguments and number of fields.');

% Preallocate varargout
varargout = cell(numel(f), 1);

% Handle empty structs
if isempty(str)
    for i = 1:numel(UniformOutput)
        if UniformOutput(i)
            varargout{i} = [];
        else
            varargout{i} = {};
        end
    end
    return;
end

% Get empty cell (ec)
ec = cell(size(str));

% Output
for i = 1:numel(f)
    out = ec;
    
    [out{:}] = str.(f(i));
    
    if UniformOutput(i)
        out = cell2mat(out);
    end
    
    varargout{i} = out;
end
