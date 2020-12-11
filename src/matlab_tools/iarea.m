function ar = iarea(input, max_day)
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
% function ar = iarea(input, max_day)

% Handle input
if isstruct(input)
    % Get infection status matrix
    aout = arrays(processed_events, max_day);
    ISM = aout.ISM;
elseif isnumeric(input)
    ISM = input;
else
    error('Invalid input.');
end

% Prepare mountain plot
nums = [1 2 3 4 5 6];
Y = zeros(numel(nums), size(ISM, 2));
for col = 1:size(ISM, 2)    
    for row = 1:numel(nums)
        Y(row, col) = nnz(ISM(:, col) == nums(row));
    end
end
Y = Y';

% Make mountain plot for Normal states
figure;
hax(1) = subplot(1,2,1);
ar = area(hax, 0:1:max_day, Y);

ar(1).DisplayName = 'Exposed';
    ar(1).FaceColor = [254 192 0] / 255;
ar(2).DisplayName = 'Presymptomatic';
    ar(2).FaceColor = [237 125 49] / 255;
ar(3).DisplayName = 'Symptomatic';
    ar(3).FaceColor = [255 0 0] / 255;
ar(4).DisplayName = 'Asymptomatic';
    ar(4).FaceColor = [255 145 145] / 255;
ar(5).DisplayName = 'Uninfected';
    ar(5).FaceColor = [91 155 213] / 255;
ar(6).DisplayName = 'Recovered';
    ar(6).FaceColor = [151 215 255] / 255;

% Prepare mountain plot for quarantined states
nums = -[1 2 3 4 5 6];
Yq = zeros(numel(nums), size(ISM, 2));
for col = 1:size(ISM, 2)    
    for row = 1:numel(nums)
        Yq(row, col) = nnz(ISM(:, col) == nums(row));
    end
end
Yq = Yq';

% Make mountain plot for quarantined states
hax(2) = subplot(1,2,2);
arq = area(hax(2), 0:1:max_day, Yq);

arq(1).DisplayName = 'Quar. Exposed';
    arq(1).FaceColor = [254 192 0] / 255;
arq(2).DisplayName = 'Quar. Presymptomatic';
    arq(2).FaceColor = [237 125 49] / 255;
arq(3).DisplayName = 'Quar. Symptomatic';
    arq(3).FaceColor = [255 0 0] / 255;
arq(4).DisplayName = 'Quar. Asymptomatic';
    arq(4).FaceColor = [255 145 145] / 255;
arq(5).DisplayName = 'Quar. Uninfected';
    arq(5).FaceColor = [91 155 213] / 255;
arq(6).DisplayName = 'Quar. Recovered';
    arq(6).FaceColor = [151 215 255] / 255;
    
xlabel(hax, 'Day');
ylabel(hax, 'Number of Individuals');
title(hax(1), 'Non-Quarantined States');
title(hax(2), 'Quarantined States');
legend(hax(1)); legend(hax(2));
grid(hax, 'on');

ylim1 = min([hax(1).YLim(1) hax(2).YLim(1)]);
ylim2 = max([hax(1).YLim(2) hax(2).YLim(2)]);
hax(1).YLim = [ylim1 ylim2];
hax(2).YLim = [ylim1 ylim2];

end
