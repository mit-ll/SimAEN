function sliders2params(app)
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
% function sliders2params(app)

% Get slider tags and values -- tags will become field names of params
struct_in = [{app.ui.sliders.Tag}; {app.ui.sliders.Value}];        
params = struct(struct_in{:});

fns = fieldnames(params);
for fn = 1:numel(fns)
    f = fns{fn};
    
    slider = findobj(app.ui.sliders, 'Tag', f);
    params.(f) = slider.UserData.Values(params.(f));
end

% Replace fields of disabled sliders with list of possible values
for si = 1:numel(app.ui.sliders)
    if strcmpi(app.ui.sliders(si).Enable, 'off')
        params.(app.ui.sliders(si).Tag) = app.ui.sliders(si).UserData.Values;
    end
end   

% Put in proper place among app properties
app.data.params = params;

end
