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
classdef Venn < handle
    properties
        values % M x N matrix of logical values.  
               % M corresponds to number of individuals
               % N corresponds to the number of variables being assessed
        names string = string.empty(1,0);
    end
    
    methods(Static)
        function new(arr)
            % Get exposed
            
            
            % Get infected
            
            % Get AEN
            
            % Get MCT
            
        end
        
        function [combos, counts] = val2cc(values)
        % function [combos, counts] = val2cc(values)
        
            C = cell(1, size(values, 2));
            for i = 1:numel(C)
                C{i} = [true false];
            end
        
            combos = logical(combvec(C{:})');
            counts = zeros(size(combos, 1), 1);
            
            for i = 1:numel(counts)
                condition = true(size(values, 1), 1);
                
                for j = 1:size(values, 2)
                    condition = condition & values(:, j) == combos(i, j);
                end

                counts(i) = nnz(condition);
            end
        end
    end
    
    methods
        function V = Venn(vals, names)
        % function V = Venn(vals, names)
        %
        % Venn class constructor
        
        V.values = [];
        V.names = string.empty(1, 0);
        if nargin == 0            
        elseif nargin == 1
            V.values = vals;
        elseif nargin == 2
            V.values = vals;
            V.names = names;
        else
            error('Invalid number of input arguments.');
        end            
            
        end
    end
end
