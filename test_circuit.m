%% Test Elektrotickle by comparing with LISO

close all
clear classes

filename = 'examples/x';   % LISO file without extension

% Set the LISO_DIR, where LISO can be found
if isempty(getenv('LISO_DIR'))
    liso_dir = [ getenv('HOME') '/c/filter'];
else
    liso_dir = getenv('LISO_DIR');
end

opamps_filename = [liso_dir '/opamp.lib'];
liso_executable = [liso_dir '/fil_static'];
liso_initfile = [liso_dir '/fil.ini'];

liso_inputfile = [filename '.fil'];
liso_outputfile = [filename '.out'];

%% Define some helper functions

% Define the 'db' function ourselves so that we don't need the signal
% processing toolbox.
db = @(x) 20*log10(abs(x));

%% Call Elektrotickle

opamps = load_opamps(opamps_filename);
c      = load_liso(opamps, [filename '.fil']);

[f, sigAC, noiseAC] = c.tickle();
nOutputNodeVar = c.getVariableIndex('node', c.output_node_name);

% Plot the transfer function
figure(1)
ax = subplot(2,1,1);
semilogx(f, db(sigAC(nOutputNodeVar, :)), 'r');
ylabel('dB');

title(sprintf('Transfer function from "%s" to "%s"', ...
    c.input_node_name, c.output_node_name), 'interpreter', 'none');

ax(2) = subplot(2,1,2);
semilogx(f, angle(sigAC(nOutputNodeVar, :)) * 180/pi, 'r');
ylabel('degrees');
xlabel('frequency [Hz]');

% Plot the noises
figure(2)
ax(3) = subplot(1,1,1);
noiseAC_total = sqrt(sum(noiseAC.^2));
loglog(f, noiseAC_total, 'r', f, noiseAC);
ylabel('Volts / sqrt Hz');
xlabel('frequency [Hz]');
title(sprintf('Sum of all noises seen at "%s"', c.output_node_name), ...
    'interpreter', 'none');

L = horzcat({'total'}, cellfun(@(ii) c.getVariableName(ii), num2cell(1:size(noiseAC,1)), 'UniformOutput', false));
legend(L, 'Location', 'Best');


%% Add the LISO results to the plot

% Call LISO
setenv('LISO_DIR', liso_dir);
liso_cmd = [liso_executable ' --initfile ' liso_initfile ' ' liso_inputfile ' ' liso_outputfile];
system(liso_cmd);

% [fid, msg] = fopen(liso_output_filename, 'r');
% liso_result = textscan(fid, '%f %f', 'commentstyle', 'shell', 'collectoutput', true);
% if fid == -1
%     error(msg)
% end
% fclose(fid);
liso_result = textread(liso_outputfile, '', 'commentstyle', 'shell');

% One run of LISO will produce EITHER the transfer function OR the noises.
if strcmp(c.liso_mode, 'tf')
    
    hold(ax(1),'all');
    plot(ax(1), liso_result(:,1), liso_result(:,2), 'o');
    hold(ax(1),'off');
    
    hold(ax(2),'all');
    plot(ax(2), liso_result(:,1), liso_result(:,3), 'o');
    hold(ax(2),'off');
    
elseif strcmp(c.liso_mode, 'noise');
    
    hold(ax(3), 'all');
    plot(ax(3), liso_result(:,1), liso_result(:,2:end), 'o');
    hold(ax(3), 'off');
    
else
    error('Unknown LISO mode');
end

