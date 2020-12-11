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
classdef metric < handle
    properties
        Name string
        Calculator function_handle
        Tag string
    end
    
    methods(Static)
        function m = defaultList()
        % function m = defaultList()
        %
        % Generate default list of metric objects
        
        m = [
            metric('Effective R', @metric.effective_r, 'effective_r');            
            metric('Percentage of Recovered Individuals Receiving One or More AENs', @metric.pct_recovered_inds_aens, 'pct_recovered_inds_aens');
            metric('Number of Max Restricted Days Per Individual', @metric.num_max_restricted_days_per_individual, 'num_max_restricted_days_per_individual');
            metric('Number of Max Restricted Days Per Infected Individual', @metric.num_max_restricted_days_per_infected_individual, 'num_max_restricted_days_per_infected_individual');
            metric('Percentage of Max Restricted Individuals who are Infected', @metric.pct_max_restricted_infected, 'pct_max_restricted_infected');
            metric('Percentage of AEN Going to Infected Individuals', @metric.pct_aen_infected_individuals, 'pct_aen_infected_individuals');
            metric('Specificity: MCT', @metric.specificity_mct, 'specificity_mct');
            metric('Specificity: AEN', @metric.specificity_aen, 'specificity_aen');
            ];
        end
        
        function out = reBootstrap(in, I)
        % function out = reBootstrap(in, I)
        
            % Replicate original results so that it is the same size as the
            % bootstrapped output ('in').
            temp = in;
            for i = 1:numel(temp)
                temp(i) = {repmat(temp(i), size(I{i}, 1), 1)};
            end
            
            % Use I to reorder the results so that it was resampled the
            % same way as what produced I.
            for i = 1:numel(temp)
                temp{i} = cellfun(@(x,y)(x(y)), temp{i}, I{i}, 'UniformOutput', false);
            end
            
            % Put temp in output
            out = temp;
        end
        
        out = assemble(arr, fld, varargin)
        bsi = get_bsi(arr, first)
        
        %%% Metrics calculators
        out = effective_r(arr, bsi)
        out = pct_aen_infected_individuals(arr, N)
        out = pct_recovered_inds_aens(arr, N)
        out = pct_max_restricted_infected(arr, N)
        out = num_max_restricted_days_per_individual(arr, bsi, varargin)        
        out = num_max_restricted_days_per_infected_individual(arr, bsi)    
        out = specificity_mct(arr, bsi);
        out = specificity_aen(arr, bsi);
        %%%
    end
    
    methods
        function m = metric(name, calculator, tag)
        % function m = metric(name, calculator, tag)
        %
        % Class constructor
        
        m.Name = name;
        m.Calculator = calculator;
        m.Tag = tag;
        
        end
    end
end
        
