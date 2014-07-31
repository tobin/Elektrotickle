classdef capacitor < component
    methods
        function obj = capacitor(name, value, node1, node2)
            obj = obj@component('C', name, value, node1, node2);
            obj.passive = true;
        end
        function Z = impedance(obj, f)
            Z = 1./(2*pi*i*f*obj.value);
        end
    end
end
