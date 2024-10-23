local _t = require(script.Parent._types);
local CreateComponent = require(script.Parent.Component).CreateComponent;

local ComponentCache = {};

-- Gets a component that creates an element which contains the given instance type
-- and its props mirror the instance's properties
local function GetRobloxComponent(className:string): _t.Component
    local _comp = ComponentCache[className] :: _t.Component?;
    local comp:_t.Component = _comp;
    if (not _comp) then
        comp = CreateComponent({
            name = className;
            baseInstance = Instance.new(className);
            onElementInitCallback = function(elementProxy:_t.Element)
                local propsProxy = elementProxy.props;
                local propsInit = propsProxy._raw :: _t.props;
                local propsMeta = getmetatable(propsProxy);
                local instBase = elementProxy.baseInstance;
                propsMeta.__index = instBase;
                propsMeta.__newindex = instBase;
                for i,v in pairs(propsInit) do if (string.sub(i,1,1)~="_") then propsMeta[i] = v; end end
                local sig = elementProxy:GetLocalSignal("onPropChanged");
                instBase.Changed:Connect(function(i) sig:Fire(elementProxy, i) end);
            end;

            localListeners = {
                ["onIsVisibleChanged"] = function(element:_t.Element)
                    local baseInstance = element.baseInstance :: Instance;
                    local mountParent = element.mountParent;
                    baseInstance.Parent = (element.isVisible and mountParent and mountParent.containerInstance) or nil;
                end;
                ["onDying"] = function(element:_t.Element)
                    (element.baseInstance::Instance):Destroy();
                end;
                ["onThisMounted"] = function(element:_t.Element)
                    local baseInstance = element.baseInstance :: Instance;
                    local mountParent = element.mountParent :: _t.Element;
                    baseInstance.Parent = (element.isVisible and mountParent.containerInstance) or nil;
                end;
                ["onThisUnmounted"] = function(element:_t.Element)
                    local baseInstance = element.baseInstance :: Instance;
                    baseInstance.Parent = nil;
                end;
            };
        });
        ComponentCache[className] = comp;
    end
    return comp;
end

return {
    GetRobloxComponent = GetRobloxComponent;
}