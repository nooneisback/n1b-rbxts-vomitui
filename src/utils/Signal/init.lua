--!native

export type Signal<T> = {
    Connect: (self:Signal<T>, func:T)->(RBXScriptConnection);
    Wait: (self:Signal<T>)->(...any);
    Fire: (self:Signal<T>, ...any)->();
    Event: RBXScriptSignal;
    Bindable: BindableEvent?;
}

local Signal = {} :: Signal<any>; do
    (Signal::any).__index = Signal;
    setmetatable(Signal, { __tostring = function() return "Signal"; end });
    function Signal.Connect(self, func)
        return self.Event:Connect(func);
    end
    function Signal.Wait(self)
        return self.Event:Wait();
    end
    function Signal.Fire(self, ...)
        return self.Bindable:Fire(...);
    end
end

local function CreateFromEvent<T>(event:RBXScriptSignal<T>)
    local signal = setmetatable({
        Event = event;
    }, Signal);
    return signal :: Signal<T>;
end

local function CreateFromBindable<T>(bind:BindableEvent)
    local signal = setmetatable({
        Event = bind.Event;
    }, Signal);
    signal.Bindable = bind;
    return signal :: Signal<T>;
end

local function newSignal<T>()
    local bind = Instance.new("BindableEvent");
    local signal = setmetatable({
        Event = bind.Event;
        Bindable = bind;
    }, Signal);
    return signal :: Signal<T>;
end


return {
    newSignal = newSignal;
    CreateFromBindable = CreateFromBindable;
    CreateFromEvent = CreateFromEvent;
}