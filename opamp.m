classdef opamp < component
    properties
        a0 = inf;     % DC gain
        gbw = inf;    % gain-bandwidth product (Hz)
        delay = 0;    % delay (s)
        zero = [];    % list of additional zeros (Hz)
        pole = [];    % list of additional poles (Hz)
        un = 0;       % voltage noise (V/rtHz)
        in = 0;       % current noise (A/rtHz)
        uc = 0;       % voltage noise 1/f corner (Hz)
        ic = 0;       % current noise 1/f corner (Hz)
        umax = 0;     % maximum output voltage amplitude (V)
        imax = 0;     % maximum output current amplitude (A)
        sr = 0;       % maximum output slew rate (V/s)
        
        node3;
    end
    
    methods
        function obj = opamp(name, value, node1, node2, node3, opamps)
            obj = obj@component('N', name, value, node1, node2);
            obj.node3 = node3;
            obj.passive=false;
            model = opamps.(value);
            params = fields(model);
            for ii=1:length(params)
                obj.(params{ii}) = model.(params{ii});
            end
        end
        function H = gain(obj, f)
            H = obj.a0 / (1 + obj.a0 * 1i * f / obj.gbw) * ...   % Single pole model
                exp(-1i * 2 * pi * obj.delay * f) * ...          % additional delay
                prod(1 + 1i * f ./ obj.zero) / ...
                prod(1 + 1i * f ./ obj.pole);
        end
        function Un = getNoiseVoltage(obj, f, params)
            Un = obj.un * sqrt(1 + obj.uc / f);   % Section 12.2, Equation (8)
        end
        function In = getNoiseCurrent(obj, f, params)
            In = obj.in * sqrt(1 + obj.ic / f);
        end
        function n = getNodeNames(obj)
            n = {obj.node1, obj.node2, obj.node3};
        end
    end
end