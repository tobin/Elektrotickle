% Set the LISO_DIR, where LISO can be found
if isempty(getenv('LISO_DIR'))
    liso_dir = [ getenv('HOME') '/c/filter'];
else
    liso_dir = getenv('LISO_DIR');
end

opamps_filename = [liso_dir '/opamp.lib'];

opamps = load_opamps(opamps_filename);

c1 = load_liso(opamps, 'examples/whitening.fil');
c2 = load_liso(opamps, 'examples/whitening_inv.fil');


[f1, sigAC1, noiseAC1] = c1.tickle();
[f2, sigAC2, noiseAC2] = c2.tickle();

nOutputNodeVar1 = c1.getVariableIndex('node', c1.output_node_name);
nOutputNodeVar2 = c2.getVariableIndex('node', c2.output_node_name);

tf1 = sigAC1(nOutputNodeVar1, :);
tf2 = sigAC2(nOutputNodeVar2, :);

figure(1)

% Plot the transfer function
ax = subplot(2,1,1);
semilogx(f1, db(tf1), ...
    f2, db(tf2));
ylabel('dB');

legend('inverting', 'non-inverting', 'Location', 'Best');
grid on
%title(sprintf('Transfer function from "%s" to "%s"', ...
%    c.input_node_name, c.output_node_name), 'interpreter', 'none');

ax(2) = subplot(2,1,2);
semilogx(f1, angle(tf1) * 180/pi, ...
    f2, angle(tf2) * 180/pi);
ylabel('degrees');
xlabel('frequency [Hz]');
grid on

figure(2)

ax(3) = subplot(1,1,1);

noiseAC1_total = sqrt(sum(noiseAC1.^2)) ;
noiseAC2_total = sqrt(sum(noiseAC2.^2)) ;

loglog(f1, noiseAC1_total./ abs(tf1), f2, noiseAC2_total./ abs(tf2));

ylabel('Volts / sqrt Hz');
xlabel('frequency [Hz]');
title('Input-referred noise');

legend('inverting', 'non-inverting', 'Location', 'Best');

figure(3)


loglog(f1, noiseAC1_total, f2, noiseAC2_total);

ylabel('Volts / sqrt Hz');
xlabel('frequency [Hz]');
title('Output-referred noise');

legend('inverting', 'non-inverting', 'Location', 'Best');


figure(4)
loglog(f1, noiseAC1_total, 'r', f1, noiseAC1);
ylabel('Volts / sqrt Hz');
xlabel('frequency [Hz]');
title(sprintf('Sum of all noises seen at "%s"', c1.output_node_name), ...
    'interpreter', 'none');

L = horzcat({'total'}, cellfun(@(ii) c1.getVariableName(ii), num2cell(1:size(noiseAC1,1)), 'UniformOutput', false));
legend(L, 'Location', 'Best');

