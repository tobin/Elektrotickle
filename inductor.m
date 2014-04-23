classdef inductor < component
    methods
        function obj = inductor(name, value, node1, node2)
            obj = obj@component('L', name, value, node1, node2);
            obj.passive = true;
        end
        function Z = impedance(obj, f)
            s = 2i*pi*f;
            Z = s * obj.value;
        end
    end
end
