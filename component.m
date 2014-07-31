classdef component < handle
    properties
        type;
        name;
        value;
        node1;
        node2;
        passive;
    end
    methods
        function obj = component(type, name, value, node1, node2)
            obj.type = type;
            obj.name = name;
            obj.value = value;
            obj.node1 = node1;
            obj.node2 = node2;
        end
        %         function disp(obj)
        %             fprintf('%c %s %e %s %s\n', obj.type, obj.name, obj.value, obj.node1, obj.node2);
        %         end
        function n = getNodeNames(obj)
            n = {obj.node1, obj.node2};
        end
        function passive = isPassive(obj)
            passive = obj.passive;
        end
        function Un = getNoiseVoltage(obj, f, T)
            Un = 0;
        end
        function In = getNoiseCurrent(obj, f, T)
            In = 0;
        end
    end
    
end
