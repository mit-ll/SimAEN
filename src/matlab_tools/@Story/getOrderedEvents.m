function ordered_events = getOrderedEvents(ev, ind)
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
% function ordered_events = getOrderedEvents(ev, ind)
%
% Return list of processed SIMAEN events ordered by event number in a cell
% array.
%
% Input arguments:
%
%   +   pe: array of processed events.
%
%   +   ind: ID of individual of interest.  Must be a scalar.
%
%   Note: can input a scalar structure of processed events as first input
%   argument.  If this is done, then do not specify 'ind'.
%
% Output argument:
%
%   +   ordered_events: cell array of processed SIMAEN events in order,
%                       sorted by event number.

% Filter processed events down to specified individual
if nargin == 1
    pef = ev; % input has already been filtered
    assert(numel(pef) == 1, ...
        'must specify individual number if input is non-scalar');
else
    pef = filter_events(ev, ind);
end

% Get field names
fns = string(fieldnames(pef));

% Get total number of events (NE)
NE = 0;
for i = 1:numel(fns)
    NE = NE + numel(pef.(fns(i)));
end

% Preallocate
eventNums = zeros(NE, 1);
events = cell(NE, 1);

% Start counter
q = 0;

% Get event numbers and corresponding events
for i = 1:numel(fns)
    for j = 1:numel(pef.(fns(i)))
        q = q + 1;
        eventNums(q) = pef.(fns(i))(j).eventNum;
        events{q} = pef.(fns(i))(j);
    end    
end

% Sort events by event number
[~, I] = sort(eventNums);
ordered_events = events(I);
