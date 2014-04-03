% Read LISO opamps database into Matlab

function opamps = load_opamps(filename)

% Parse the file

if isempty(filename)
  filename = 'opamp.lib';
end

fid = fopen(filename, 'r', 'native', 'US-ASCII');
if fid == -1
    error(msg)
end

line_no = 0;

allowed_fields = {'name', 'a0', 'gbw', 'delay', 'zero', 'pole', ...
    'un', 'in', 'uc', 'ic', 'umax', 'imax', 'sr'};

name = 'unknown';

opamps = struct();

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
  args = regexp(s, '=', 'split');
  
  field = args{1};
  value = args{2};
  
  field = regexprep(field, '\s', '');
  value = regexprep(value, '^\s+', '');
  
  if ~any(strcmp(field, allowed_fields))
    error('Unexpected token "%s" on line %d.\n', args{1}, line_no);
  end

  if strcmp(field, 'name')
      name = value;
      continue
  end
  
  % Check if multiple arguments
  value = regexp(value, '\s+', 'split');
  value = cellfun(@parse_value, value, 'UniformOutput', true);
	  
  % Check whether this parameter has already been specified
  if isfield(opamps, name) && isfield(opamps.(name), field)
     if any(strcmp(field, {'zero', 'pole'}))
       % Add this value to a list
       if length(value)==2
           fk = value(1);  % frequency
           Qk = value(2);  % Q factor
           theta = acos(1 / (2 * Qk));           
           value = fk * [exp(-1i * theta), exp(1i * theta)];
       end
       opamps.(name).(field) = [opamps.(name).(field), value];
       continue
     else
       fprintf('Duplicate specification of "%s" for opamp model "%s" on line %d.\n', ...
	     field, name, line_no);
     end
  end

  opamps.(name).(field) = value;
end

fclose(fid);


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

