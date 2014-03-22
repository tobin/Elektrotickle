classdef circuit < handle
    % This class represents a circuit composed of passive components
    % (resistors, capacitors, and inductors) and opamps.  Both components
    % and nodes have names, and are assigned serial numbers by the program.
    % All potentials are assumed to be with respect to a special ground
    % node, called "gnd," which must be present.  Input and output nodes
    % can also be specified, and the program will compute the transfer
    % functions from the input node to all other nodes, and the noise
    % contributions from all components to the output node.
    %
    % Tobin Fricke <tobin.fricke@ligo.org>
    % Max Planck Institute for Gravitational Physics (AEI Hannover)
    % Berlin 2014-03-21
    
    properties
        components = {};          % list of all components (objects)
        
        n_nodes = 0;              % total number of nodes
        n_components = 0;         % total number of components
        
        node_numbers = struct();  % dictionary of node names to serials
        node_names = {};          % dictionary of node numbers to names
        
        comp_numbers = struct();  % dictionary of component names to serial
        comp_names = {};          % dictionary of component numbers to name
        
        input_node_name;          % input node (name)
        input_node = 0;           % input node (serial number)
        
        output_node_name;         % output node (name)
        output_node = 0;          % output node (serial number)
        
        params = struct( ...
            'kB', 1.3806488e-23, ...  % Bolzmann's constant
            'T',  25 + 273.15 ...     % Temperature
            );

        liso_mode;
        f = [];                   % frequency vector
    end
    
    methods
        function addComponent(obj, thing)
            if isfield(obj.comp_numbers, thing.name)
                error('Duplicate component with name "%s"', thing.name)
            end
            
            % Allocate a new component serial number
            obj.n_components = obj.n_components + 1;
            my_serial = obj.n_components;
            
            obj.components{my_serial} = thing;
            obj.comp_names{my_serial} = thing.name;  % Perhaps not really necessary
            obj.comp_numbers.(thing.name) = my_serial;
            
            % Assign serial numbers to the nodes
            node_names = thing.getNodeNames();
            nodes = zeros(1, length(node_names));
            for ii = 1:length(nodes)
                nodes(ii) = obj.getNodeNumber(node_names{ii});
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
            % node_number = getNodeNumber(obj, node_name)
            %
            % Given a node number, return the node's
            % serial number.  If the node has not
            % yet been seen, a new serial number is allocated and the node is added to the dictionary.
            
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
        
        function ii = getVariableIndex(obj, thing_type, name)
            % ii = getVariableIndex(thing_type, name)
            %
            % Examples:
            %
            % ii = getVariableIndex('current', 'r22') % Find current through R22
            % ii = getVariableIndex('node', 'nin')    % Get index of node 'nin'
            switch thing_type
                case 'current'
                    ii = obj.comp_numbers(name);
                case 'node'
                    ii = obj.n_components + 1 + obj.node_numbers.(name);
                otherwise
                    error('Expected "current" or "node"');
            end
        end
        
        function varName = getVariableName(obj, index)
            if index <= obj.n_components
                varName = obj.components{index}.name;
            elseif index == obj.n_components + 1
                varName = 'i[in]';
            elseif index <= obj.n_components + 1 + obj.n_nodes
                varName = obj.node_names{index - obj.n_components - 1};
            else
                error('Invalid variable index');
            end
        end
        
        function M = make_matrix(obj, f)            
            %  M = make_matrix(obj, f) 
            %
            %  Form the matrix representing the circuit.  This matrix is
            %  later used to solve the circuit, by forming a linear
            %  equation of the form:
            %
            %  [       ] [ i ]   [ 0 ]
            %  [   M   ] [   ] = [   ]
            %  [       ] [ U ]   [ 1 ]
            %
            %  i.e. if the matrix is multiplied by a vector that contains
            %  all of the currents and node potentials in the circuit, the
            %  result will be a vector that is all zero except for the last
            %  entry.
            %
            %  Each component generates one equation (for passive
            %  components, this is Ohm's law), and each node generates one
            %  equation (in which the currents into it sum to zero).
                            
            node_gnd = 0;
            
            % Allocate space for the matrix
            M = sparse(obj.n_components + obj.n_nodes + 1);
            
            % Iterate over the components   
            for ii = 1:obj.n_components
                component = obj.components{ii};                            
                
                % TODO: If we want a proper object-oriented design, the
                % individual components should generate their own
                % equations, instead of doing it here.
                
                if component.isPassive()
                    % Dereference the nodes
                    node1 = obj.getNodeNumber(component.node1);
                    node2 = obj.getNodeNumber(component.node2);
                    
                    % Passive components
                    M(ii, ii) = component.impedance(f);
                
                    % The ground node is assumed to have potential zero,
                    % and no equations are written for it.
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
        
        function [f_vect, sigAC, noiseAC] = tickle(obj, varargin)
            % sigAC gives the transfer functions from the input node to
            % every nodal voltage and every current.
            %
            % noiseAC gives the noise contribution from each component and
            % current to the output node.
            
            % The frequency vector can be either given as an argument to
            % tickle(), or can be specified in the LISO input file.
            f_vect = obj.f;
            if length(varargin) > 1
                f_vect = varargin{1};
            end            
            
            if obj.output_node == 0
                error('No output node specified');
            end
            
            n_freqs = length(f_vect);
            
            sigAC = zeros(obj.n_components + obj.n_nodes + 1, n_freqs);
            noiseAC = zeros(obj.n_components + obj.n_nodes + 1, n_freqs);
            
            % The last row in the equation A x = y is the one that sets the
            % input voltage to 1.            
            y = sparse(obj.n_components + obj.n_nodes + 1, 1);            
            y(end, 1) = 1;
            
            for ii = 1:n_freqs
                f = f_vect(ii);
                
                % Calculate transfer functions
                A = obj.make_matrix(f);
                x = A \ y;
                sigAC(:, ii) = x;
                
                % Calculate noise contributions
                % (See pages 60-61 of LISO Manual)
                
                % Calculate index of output node
                n = obj.getVariableIndex('node', obj.output_node_name);
                e_n = sparse(obj.n_components + obj.n_nodes + 1, 1);
                e_n(n, 1) = 1;
                
                yhat = transpose(A) \ e_n;   % Equation (77)
                
                % Compute the vector of noise voltages and currents
                k = zeros(obj.n_components + obj.n_nodes + 1, 1);
                for jj = 1:obj.n_components
                    thing = obj.components{jj};
                    
                    % Noise potential from this component
                    k(jj) = thing.getNoiseVoltage(f, obj.params);
                    
                    % Current noise
                    if isa(thing, 'opamp')
                        % Opamps inject current noise into their input
                        % nodes!
                        opamp_int_node_p = obj.getNodeNumber(thing.node1);
                        opamp_int_node_m = obj.getNodeNumber(thing.node2);
                        
                        % FIXME: Should add in quadrature in case there are
                        % multiple opamps with their inputs tied to the
                        % same nodes.
                        k(obj.n_components + 1 + opamp_int_node_p) = ...
                            thing.getNoiseCurrent(f, obj.params);
                        
                        k(obj.n_components + 1 + opamp_int_node_m) = ...
                            thing.getNoiseCurrent(f, obj.params);
                    end
                end
                
                y_noise = yhat .* k;
                noiseAC(:,ii) = abs(y_noise);
                
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

