classdef resistor < component
    methods
        function obj = resistor(name, value, node1, node2)
            obj = obj@component('R', name, value, node1, node2);
            obj.passive = true;
        end
        function Z = impedance(obj, f)
            Z = obj.value;
        end
        function Un = getNoiseVoltage(obj, f, params)
            Un = sqrt(4 * params.kB * params.T * obj.value);
        end
    end
end
