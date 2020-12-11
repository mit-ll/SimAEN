function json = writeSetup(setup, groups, NRPC, varargin)
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
% function json = writeSetup(setup, groups, NRPC, varargin)

% Handle input
opts = inputParser;
opts.addParameter('fileout', '', @ischar);
opts.parse(varargin{:});
fileout = opts.Results.fileout;

if isempty(fileout)
    fileout = 'setup.json';
end

% Handle groups
C = cellfun(@(x)(cellstr(x)), groups, 'UniformOutput', false);
groups = C(:)';

% Create output structure
output = struct(...
    'setup', setup, ...
    'NRPC', NRPC);
output.groups = groups;

% Save file
json = jsonencode(output);
fido = fopen(fileout, 'w');
fwrite(fido, json);
fclose(fido);

