% LISO file parser
% Tobin Fricke
% 2014-03-15

function c = load_liso(opamps, filename)
% Parse the file

[fid, msg] = fopen(filename, 'r', 'native', 'US-ASCII');
if fid == -1
    error(msg)
end

line_no = 0;

% Initialize the Optickle model with only a laser carrier
c = circuit();

while true
    s = fgetl(fid);
    
    % Check for end-of-file or other errors
    if s == -1
        break
    end
    line_no = line_no + 1;
    
    % Remove comments and trailing whitespace
    s = regexprep(s, '\s*(#.*)?$', '');
    
    % Discard lines with no tokens
    if isempty(s)
        continue
    end
    
    % Split the line into tokens deliminated by whitespace
    args = regexp(s, '\s+', 'split');
    
   
    switch args{1}
        case 'r'     % r name value node1 node2 (resistor)
            name = args{2};
            value = parse_value(args{3});
            node1 = args{4};
            node2 = args{5};            
            c.addComponent(resistor(name, value, node1, node2));
                
        case 'c'     % c name value node1 node2 (capacitor)
            name = args{2};
            value = parse_value(args{3});
            node1 = args{4};
            node2 = args{5};
            c.addComponent(capacitor(name, value, node1, node2));
            
        case 'op'    % op name type node+ node- nodeout
                        name = args{2};
            value = args{3};
            node1 = args{4};
            node2 = args{5};
            node3 = args{6};
            c.addComponent(opamp(name, value, node1, node2, node3, opamps));
            
        case 'uinput'  
            c.setInputNodeName(args{2});
            %c.setInputImpedance(args{3});
            
        case 'uoutput'
             pieces = regexp(args{2}, ':', 'split');
             c.setOutputNodeName(pieces{1});  % FIXME
             
        case 'freq'  % freq lin|log startfreq stopfreq steps
            startfreq = parse_value(args{3});
            stopfreq = parse_value(args{4});
            steps = parse_value(args{5});
            switch args{2}
                case 'lin'
                    f = linspace(startfreq, stopfreq, steps);
                case 'log'
                    f = logspace(log10(startfreq), log10(stopfreq), steps);
                otherwise
                    fprintf('line %d: error in frequency specification, unrecognized token "%s"\n', ...
                        line_no, args{2});
            end
            c.setFreqs(f);
        otherwise
            fprintf('line %d: "%s" command is not supported\n', line_no, args{1});
    end
    
end

fclose(fid);

% Perform the linking

end

function value = parse_value(str)
    
    multipliers.G = 1e9;
    multipliers.M = 1e6;
    multipliers.k = 1e3;    
    multipliers.m = 1e-3;
    multipliers.u = 1e-6;
    multipliers.n = 1e-9;
    multipliers.p = 1e-12;
    multipliers.f = 1e-15;
    
    [A,count,errmsg,nextindex] = sscanf(str, '%f%[GMkmunpf]');
    value = A(1);
  
    if count==2  
        suffix = char(A(2));
        if ~any(strcmp(suffix, fields(multipliers)))
            fprintf('Unknown suffix "%s" in "%s"\n', A(2), str);
        end
        value = value * multipliers.(suffix);
    end
end
