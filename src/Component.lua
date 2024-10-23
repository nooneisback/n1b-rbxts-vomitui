local _t = require(script.Parent._types);
local CreateElement = require(script.Parent.Element).CreateElement;

type Element = _t.Element;
type Component = _t.Component;

local funcIsAnon:(name:string)->(boolean);
local funcGetAnonName:()->(string);
local CreateComponent;
local NamedComponents:{[string]:Component} = {};

local Component = {} :: Component; do
    (Component :: any).__index = Component;
    setmetatable(Component, {
        __tostring = function() return "Component"; end
    });

    function Component.ExtendComponent(self, newInfo)
        local proxy = CreateComponent({}) :: Component;
        local raw = proxy._raw;
        -- create values
        local name = newInfo.name or funcGetAnonName();
        local props = table.clone(self.props);
        local baseComponent = self;
        local baseInstance = newInfo.baseInstance or self.baseInstance;
        local containerInstancePath = newInfo.containerInstancePath or self.containerInstancePath;
        local renderTickRate = newInfo.renderTickRate or self.renderTickRate;
        local onElementInitCallback = newInfo.onElementInitCallback or self.onElementInitCallback;
        local globalListeners = table.clone(self.globalListeners);
        local localListeners = table.clone(self.localListeners);
        local customListeners = table.clone(self.customListeners);
        local _containerInstancePathArr = newInfo.containerInstancePath and string.split(newInfo.containerInstancePath) or self._containerInstancePathArr;
        -- prepare values
        if (newInfo.props) then for i,v in pairs(newInfo.props) do
            props[i] = v;
        end end
        if (newInfo.globalListeners) then for i,v in pairs(newInfo.globalListeners) do
            globalListeners[i] = v;
        end end
        if (newInfo.localListeners) then for i,v in pairs(newInfo.localListeners) do
            localListeners[i] = v;
        end end
        if (newInfo.customListeners) then for i,v in pairs(newInfo.customListeners) do
            customListeners[i] = v;
        end end
        -- set values
        raw.name = name;
        raw.props = props;
        raw.baseComponent = baseComponent;
        raw.baseInstance = baseInstance;
        raw.containerInstancePath = containerInstancePath;
        raw.renderTickRate = renderTickRate;
        raw.onElementInitCallback = onElementInitCallback;
        raw.globalListeners = globalListeners;
        raw.localListeners = localListeners;
        raw.customListeners = customListeners;
        raw._containerInstancePathArr = _containerInstancePathArr;
        -- add to named components if not anon
        if (not funcIsAnon(name)) then
            if (NamedComponents[name]) then
                warn(`Duplicate component name {name}. The previous one will be shadowed when calling GetNamedComponent.`);
            end
            NamedComponents[name] = proxy;
        end
        return proxy;
    end

    function Component.CreateElement(self:Component, propsOverride:_t.props?, mountTo:Element?)
        return CreateElement(self, propsOverride, mountTo);
    end
end

local meta__newindex = function(proxy:Component, i:string, v1:any)
    local raw = proxy._raw;
    local v0 = raw[i];
    if (v0==v1) then return; end
    if (i=="baseInstance" or i=="renderTickRate" or i=="globalListeners" or i=="localListeners") then
        raw[i]=v1;
    elseif (i=="containerInstancePath") then
        if (v1==nil or #v1==0) then
            raw._containerInstancePathArr = nil;
        else
            raw._containerInstancePathArr = string.split(v1, '/');
        end
        raw[i]=v1;
	else
		error(`Property Component.{i} is invalid or read only`);
    end
end

-- anon names
do
    local anonNamePrefix = "ANON";
    local AnonCount = 0;
    function funcGetAnonName()
        local name = anonNamePrefix..tostring(math.round(AnonCount));
        AnonCount+=1;
        return name;
    end
    local anonLen = #anonNamePrefix;
    function funcIsAnon(name)
        return string.sub(name, 1, anonLen)==anonNamePrefix;
    end
end

function CreateComponent(info:_t.ComponentInfo)
    local name = info.name or funcGetAnonName();
    local props = info.props or {};
    local baseInstance = info.baseInstance or nil;
    local containerInstancePath = info.containerInstancePath or nil;
    local renderTickRate = info.renderTickRate or 15;
    local onElementInitCallback = info.onElementInitCallback or nil;
    local globalListeners = table.clone(info.globalListeners or {});
	local localListeners = table.clone(info.localListeners or {});
	local customListeners = table.clone(info.customListeners or {});

    local raw = {} :: Component;
    raw.name = info.name;
    raw.props = props;
    raw.baseInstance = baseInstance;
    raw.globalListeners = globalListeners;
    raw.localListeners = localListeners;
    raw.customListeners = customListeners;
    raw.renderTickRate = renderTickRate;
    raw.onElementInitCallback = onElementInitCallback;
    raw.containerInstancePath = containerInstancePath;
    raw._raw = raw;
    
    setmetatable(raw, Component);
    local proxy = newproxy();
    local meta = getmetatable(proxy);
    meta.__index = raw;
    meta.__newindex = meta__newindex;

    if (not funcIsAnon(name)) then
        if (NamedComponents[name]) then
            warn(`Duplicate component name {name}. The previous one will be shadowed when calling GetNamedComponent.`);
        end
        NamedComponents[name] = proxy;
    end
    return proxy :: Component;
end

local function GetNamedComponent(name:string)
    return NamedComponents[name] :: Component|nil;
end

return {
    CreateComponent = CreateComponent;
    GetNamedComponent = GetNamedComponent;
    IsComponentNameAnonymous = funcIsAnon;
}