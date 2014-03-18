
filename = 'whitening';   % LISO file without extension
opamps = load_opamps('opamp.lib');
c = load_liso(opamps, [filename '.fil']);

liso_result = textread([filename '.out'], '', 'commentstyle', 'shell');

c.print_equations();

M = c.make_matrix(1e3);
n = size(M, 1);
y = sparse(n);
y(n,1) = 1;
x = M \ y

% %%
sigAC = c.tickle();
f = c.f;

n_components = length(c.components);

subplot(2,1,1);
semilogx(f, db(sigAC(n_components + 1 + c.output_node, :)), 'r', ...
        liso_result(:, 1), liso_result(:,2), 'b');
    
legend('Elektrotickle', 'LISO', 'location', 'SouthEast');

subplot(2,1,2)
semilogx(f, 180/pi*angle(sigAC(n_components + 1 + c.output_node, :)), 'r', ...
        liso_result(:, 1), liso_result(:,3), 'b');
