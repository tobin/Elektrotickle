classdef circuit < handle
    % Description
    
    properties
        components = {};
        input_node_name;
        input_node;
        output_node_name;
        output_node;
        n_nodes = 0;
        n_components = 0;
        node_numbers = struct();
        node_names = {};
        f = [];
    end
    
    methods
        function addComponent(obj, thing)
            obj.n_components = obj.n_components + 1;
            obj.components{obj.n_components} = thing;
            nodes = thing.getNodeNames();
            for ii = 1:length(nodes)
                obj.getNodeNumber(nodes{ii});
            end
        end
        
        function setInputNodeName(obj, node_name)
            obj.input_node_name = node_name;
            obj.input_node = obj.getNodeNumber(obj.input_node_name);
        end
        
        function setOutputNodeName(obj, node_name)
            obj.output_node_name = node_name;
            obj.output_node = obj.getNodeNumber(obj.output_node_name);
        end
        
        function setFreqs(obj, f)
            obj.f = f;
        end
        
        function node_number = getNodeNumber(obj, node_name)
            if strcmp(node_name, 'gnd')
                node_number = 0;
            elseif isfield(obj.node_numbers, node_name)
                node_number = obj.node_numbers.(node_name);
            else
                % Create a new node
                obj.n_nodes = obj.n_nodes + 1;
                node_number = obj.n_nodes;
                obj.node_names{node_number} = node_name;
                obj.node_numbers.(node_name) = node_number;
            end
        end
        
        function node_name = getNodeName(obj, node_number)
            node_name = obj.node_names{node_number};
        end
        
        function disp(obj)            
            fprintf('Circuit object containing %d components:\n', obj.n_components);
            for ii = 1:obj.n_components
                disp(obj.components{ii});
            end
        end        
        
        function M = make_matrix(obj, f)
            
            node_gnd = 0;
            
            % Iterate over the components

            M = sparse(obj.n_components + obj.n_nodes + 1);
            
            
            for ii = 1:obj.n_components
                component = obj.components{ii};
                
                %  [       ] [ i ]   [ 0 ]
                %  [   M   ] [   ] = [   ]
                %  [       ] [ U ]   [ 1 ]
                
                % LISO writes one equation for every component, one
                % equation for every node except the ground node, and
                % finally one equation for the input potential.  This is
                % encoded into a matrix, which is multiplied by a vector
                % containing the current through every component, the input
                % current, and every node potential except the ground node.
                
                % It's a bit annoying to have to exclude the ground node
                % from the matrix, so here we include it, adding an
                % equation that sets its potential to zero.  But then, in
                % the nodal equation for ground, I think we have to
                % subtract all the current sources?
                
                % The number of currents is (n_components + 1).
                
                if component.isPassive()
                    % Dereference the nodes
                    node1 = obj.getNodeNumber(component.node1);
                    node2 = obj.getNodeNumber(component.node2);
                    
                    % Passive components
                    M(ii, ii) = component.impedance(f);
                    
                    if node1 ~= node_gnd
                        M(ii, obj.n_components + 1 + node1) =  -1;
                    end
                    
                    if node2 ~= node_gnd
                        M(ii, obj.n_components + 1 + node2) =  1;
                    end
                    
                    % Nodal current equations
                    if node1 ~= node_gnd
                        M(obj.n_components + node1, ii) =  -1;  % What flows in here...
                    end
                    
                    if node2 ~= node_gnd
                        M(obj.n_components + node2, ii) = 1;  % flows out of here.
                    end
                    
                else    % It's an opamp
                    
                    node1 = obj.getNodeNumber(component.node1);
                    node2 = obj.getNodeNumber(component.node2);
                    node3 = obj.getNodeNumber(component.node3);
                    % Impedance equations
                    % (none)
                    
                    % Potential equations
                    % U_output = H(s) * (U_plus - U_minus)
                    if node1 ~= node_gnd
                        M(ii, obj.n_components + 1 + node1) = -1;
                    end
                    
                    if node2 ~= node_gnd
                        M(ii, obj.n_components + 1 + node2) = 1;
                    end
                    
                    if node3 ~= node_gnd
                        M(ii, obj.n_components + 1 + node3) =  1 / component.gain(f);
                    else
                        error('Opamp output connected to ground');
                    end
                    
                    % Nodal current equations
                    M(obj.n_components + node3, ii) = 1;     % Current coming out of the opamp
                    
                end
            end
            
            % Set the input                        
            M(obj.n_components + obj.n_nodes + 1, obj.n_components + 1 + obj.input_node) = 1;  % Input voltage
            M(obj.n_components + obj.input_node,  obj.n_components + 1) = 1;        % Input current
            
        end
        
        function sigAC = tickle(obj,varargin)
            
            f_vect = obj.f;
            
            if length(varargin) > 1
                f_vect = varargin{1};
            end
            
            n_freqs = length(f_vect);
            
            sigAC = zeros(obj.n_components + obj.n_nodes + 1, n_freqs);            
            y    = sparse(obj.n_components + obj.n_nodes + 1, 1);
            
            y(end, 1) = 1;
            
            for ii = 1:n_freqs
                f = f_vect(ii);
                M = obj.make_matrix(f);
                x = M \ y;
                sigAC(:, ii) = x;
            end
        end
        
        function print_equations(obj)
            M = obj.make_matrix(1/2*pi);           
            
            for ii = 1:size(M, 1)
                for jj = 1:size(M, 2)
                    if M(ii,jj) ~= 0
                        fprintf('+ (%s)', num2str(full(M(ii,jj))));
                        if jj <= obj.n_components
                            fprintf('i[%s]', obj.components{jj}.name);
                        elseif jj == obj.n_components + 1
                            fprintf('i[in]');
                        else
                            fprintf('U[%s]', obj.getNodeName(jj - obj.n_components - 1));
                        end
                    end                    
                end
                fprintf('\n');
            end
            
        end
    end
    
    
end

