function out = specificity_aen(arr, bsi)
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
% function out = specificity_aen(arr, bsi)

% Make sure we're working on a column vector
assert(iscolumn(arr), 'arr must be a column vector.');

% Assemble combined datasets
aOut = metric.assemble(arr, 'people', 'subflds', ["infected", "aen", "testResultPositiveReceived"], 'bsi', bsi);

% Figure out which individuals received a positive test and received an aen
positive_test_and_aen = ...
    cellfun(@(x,y)(x & y), aOut.aen, aOut.testResultPositiveReceived, 'UniformOutput', false);

out = nnz(positive_test_and_aen{1}) / nnz(aOut.testResultPositiveReceived{1});
