local _t = require(script.Parent._types);
type Context = _t.Context;
type Component = _t.Component;
type Element = _t.Element;
local GetRobloxComponent = require(script.Parent.RobloxComponent).GetRobloxComponent;

local ActiveContexts:{[string]:Context} = {};

local Context = {} :: Context; do
    setmetatable(Context, {
        __tostring = function() return "Context"; end
    });
    (Context :: any).__index = Context;

    Context.isAlive = false;
    Context.isVisible = false;

    function Context.Kill(self)
        self.rootElement:Kill();
    end

    function Context._SetIsVisible(proxy, newIsVisible)
        local raw = proxy._raw;
        raw.isVisible = newIsVisible;
        local name = raw.name;
        if (newIsVisible) then
            for _,context in pairs(ActiveContexts) do
                local reaction = context.contextReactions[name] :: _t.ContextReaction;
                if (reaction == "HideOnShow") then
                    context.isVisible = false;
                elseif (reaction=="ShowOnShow") then
                    context.isVisible = true;
                end
            end
        else
            for _,context in pairs(ActiveContexts) do
                local reaction = context.contextReactions[name] :: _t.ContextReaction;
                if (reaction == "HideOnHide") then
                    context.isVisible = false;
                elseif (reaction=="ShowOnHide") then
                    context.isVisible = true;
                end
            end
        end
    end
end

local function meta__newindex(proxy:_t.Context, i:string, v1:any)
    local raw = proxy._raw;
    local v0 = raw[i];
    if (v0==v1) then return; end
    if (i=="isVisible") then
        proxy.rootElement.isVisible = v1;
    else
        error(`Property {i} is read-only`);
    end
end

local ScreenGuiComponent = GetRobloxComponent("ScreenGui");
local function CreateContext(name:string, _rootComponent:Component?, rootParent:Instance?)
    if (ActiveContexts[name]) then error(`Active context {name} already exists, kill it first.`); end
    local contextProxy = newproxy() :: _t.Context;
    local contextRaw = {} :: _t.Context;

    local rootComponent = _rootComponent or ScreenGuiComponent;
    local rootElement = rootComponent:CreateElement();
    if (rootElement.baseInstance) then rootElement.baseInstance.Parent = rootParent; end
    local rawElement = rootElement._raw;
    rawElement.context = contextProxy;
    rawElement.isRoot = true;

    rootElement:GetLocalSignal("onDying"):Connect(function(_:Element)
        ActiveContexts[contextProxy.name] = nil;
    end)
    rootElement:GetLocalSignal("onIsVisibleChanged"):Connect(function(ele:Element)
        contextProxy:_SetIsVisible(ele.isVisible);
    end)

    contextRaw.name = name;
    contextRaw.rootElement = rootElement;
    contextRaw.contextReactions = {};
    contextRaw._raw = contextRaw;

    setmetatable(contextRaw, Context);
    local contextMeta = getmetatable(contextProxy);
    contextMeta.__index = contextRaw;
    contextMeta.__newindex = meta__newindex;

    ActiveContexts[contextProxy.name] = contextProxy;
    return contextProxy;
end

return {
    CreateContext = CreateContext :: (name:string, rootComponent:Component?, rootParent:Instance?)->(Context);
}