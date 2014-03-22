%% Test Elektrotickle by comparing with LISO

filename = 'examples/whitening';   % LISO file without extension

opamps = load_opamps('opamp.lib');
c      = load_liso(opamps, [filename '.fil']);


% Define the 'db' function ourselves so that we don't need the signal
% processing toolbox.
db = @(x) 20*log10(abs(x));

[f, sigAC, noiseAC] = c.tickle();
nOutputNodeVar = c.getVariableIndex('node', c.output_node_name);

% Plot the transfer function
figure(1)
ax = [];
ax(1) = subplot(2,1,1);
semilogx(f, db(sigAC(nOutputNodeVar, :)), 'r');   
ylabel('dB');

title(sprintf('Transfer function from "%s" to "%s"', ...
    c.input_node_name, c.output_node_name), 'interpreter', 'none');

ax(2) = subplot(2,1,2);
semilogx(f, angle(sigAC(nOutputNodeVar, :)) * 180/pi, 'r');
ylabel('degrees');
xlabel('frequency [Hz]');

% Plot the noise
figure(2)
ax(3) = subplot(1,1,1);
noiseAC_total = sqrt(sum(noiseAC.^2));
loglog(f, noiseAC_total, 'r', f, noiseAC);
ylabel('Volts / sqrt Hz');
xlabel('frequency [Hz]');
title(sprintf('Sum of all noises seen at "%s"', c.output_node_name), ...
    'interpreter', 'none');

legend(cellfun(@(ii) c.getVariableName(ii), num2cell(1:size(noiseAC,1)), 'UniformOutput', false), ...
    'Location','Best');
%% Add the LISO results to the plot

liso_dir = '/home/tobin/c/filter';
old_dir = pwd;
chdir(liso_dir);
cmd = ['./fil_static ' old_dir '/' filename '.fil']
system(cmd);
chdir(old_dir);

liso_output_filename = [filename '.out'];
% [fid, msg] = fopen(liso_output_filename, 'r');
% liso_result = textscan(fid, '%f %f', 'commentstyle', 'shell', 'collectoutput', true);
% if fid == -1
%     error(msg)
% end
% fclose(fid);
liso_result = textread(liso_output_filename, '', 'commentstyle', 'shell');

if strcmp(c.liso_mode, 'tf')
    fprintf('LISO mode is TF\n');

    hold(ax(1),'all');
    plot(ax(1), liso_result(:,1), liso_result(:,2), 'o');
    hold(ax(1),'off');
    
    hold(ax(2),'all');
    plot(ax(2), liso_result(:,1), liso_result(:,3), 'o');
    hold(ax(2),'off');
    
elseif strcmp(c.liso_mode, 'noise');
    fprintf('LISO mode is NOISE\n');
    hold(ax(3), 'all');
    plot(ax(3), liso_result(:,1), liso_result(:,2:end), 'o');
    hold(ax(3), 'off');
else
    error('Unknown LISO mode');
end


