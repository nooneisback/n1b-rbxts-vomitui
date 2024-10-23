local GetGlobalSignal = require(script.Parent.Signals).GetGlobalSignal;
local CreateLocalSignal = require(script.Parent.Signals).CreateLocalSignal;
local _t = require(script.Parent._types);

type Element = _t.Element;
type Component = _t.Component;

-- Shared vars
	-- Ticking
local funcUpdateTickGroup:(element:Element, newIsRendering:boolean)->();

-- Element class
local Element:Element = {} :: Element; do
	setmetatable(Element, { __tostring = function() return "Element"; end });
	(Element::any).__index = Element;

	-- properties
	Element.isRoot = false;
	Element.isAlive = true;
	Element.isRendering = false;
	Element.isVisible = false;
	Element.isDying = false;

	-- methods
	function Element.MountTo(proxy, parent)
		local raw = proxy._raw;
		if (not raw.isAlive) then error("Tried to call a dead element"); end
		if (not parent.isAlive) then error("The target element is dead"); end
		if (raw.isRoot) then error("Cannot mount/unmount root elements"); end
		if (raw.mountParent) then error("This element is already mounted"); end
		raw.mountParent = parent;
		table.insert(parent.mountChildren, proxy);
		local cinst = parent.containerInstance;
		if (cinst) then
			local binst = raw.baseInstance;
			if (binst) then binst.Parent = cinst; end
		end
		proxy:_UpdateContext(true);
		local selfsig = raw._localSignals.onThisMounted;
		local _ = selfsig and selfsig:Fire(proxy);
		local paresig = parent._localSignals.onChildMounted;
		local _ = paresig and paresig:Fire(parent, proxy);
		return proxy;
	end

	function Element.Unmount(proxy)
		local raw = proxy._raw;
		if (not raw.isAlive) then error("Tried to call a dead element"); end
		if (raw.isRoot) then error("Cannot mount/unmount root elements"); end
		local parent = raw.mountParent;
		if (not parent) then error("This element is not mounted"); end
		raw.mountParent = nil;
		table.remove(parent.mountChildren, table.find(parent.mountChildren, proxy));
		local inst = raw.baseInstance; if (inst) then inst.Parent = nil; end
		proxy:_UpdateContext(true);
		local selfsig = raw._localSignals.onThisUnmounted;
		local _ = selfsig and selfsig:Fire(proxy, parent);
		local paresig = parent._localSignals.onChildUnmounted;
		local _ = paresig and paresig:Fire(parent, proxy);
		return proxy;
	end

	function Element.GetLocalSignal<T>(proxy, signame)
		local raw = proxy._raw;
		if (not raw.isAlive) then error("Tried to call a dead element"); end
		local sigobj = raw._localSignals[signame];
		if (not sigobj) then
			sigobj = CreateLocalSignal();
			raw._localSignals[signame] = sigobj;
			if (signame == "onRenderTick") then
				proxy:_UpdateIsRendering(false);
			end
		end
		return sigobj :: _t.Signal<T>;
	end

	function Element.GetCustomSignal<T>(proxy, signame)
		local raw = proxy._raw;
		if (not raw.isAlive) then error("Tried to call a dead element"); end
		local sigobj = raw._customSignals[signame];
		if (not sigobj) then
			sigobj = CreateLocalSignal();
			raw._customSignals[signame] = sigobj;
		end
		return sigobj :: _t.Signal<T>;
	end

	function Element.Kill(proxy, rootoverride)
		local raw = proxy._raw;
		if (not raw.isAlive) then error("Tried to call a dead element"); end
		if (raw.isDying) then error("This element is already being killed"); end
		if (raw.isRoot and not rootoverride) then error("Cannot kill root elements"); end
		raw.isDying = true;
		for _,v in ipairs(raw.mountChildren) do
			v:Kill();
		end
		local selfsig = raw._localSignals.onDying;
		local _ = selfsig and selfsig:Fire(proxy);
		local parent = raw.mountParent;
		if (parent and not parent.isDying) then
			raw.mountParent = nil;
			table.remove(parent.mountChildren, table.find(parent.mountChildren, proxy));
			local paresig = parent._localSignals.onChildUnmounted;
			local _ = paresig and paresig:Fire(parent, proxy);
		end
		local inst = raw.baseInstance; local _ = inst and inst:Destroy();
		raw.isAlive = false;
		proxy:_UpdateIsRendering(false);
		for _,v in ipairs(raw._listenerConnections) do v:Disconnect(); end
	end

	function Element._SetIsVisible(proxy, newState)
		local raw = proxy._raw;
		raw.isVisible = newState;
		local sig = raw._localSignals.onIsVisibleChanged;
		local _ = sig and sig:Fire(proxy);
		proxy:_UpdateIsRendering(true);
	end

	function Element._UpdateIsRendering(proxy, isRecursive)
		local raw = proxy._raw;
		-- update is rendering
		local newState = not not (
			(raw.isVisible and not raw.isDying) and
			(raw.isRoot or (raw.mountParent and raw.mountParent.isRendering))
		);
		if (raw.isRendering ~= newState) then
			raw.isRendering = newState;
			local sig = raw._localSignals.onIsRenderingChanged;
			local _ = sig and sig:Fire(proxy);
			if (isRecursive) then
				for _,v in ipairs(raw.mountChildren) do
					v:_UpdateIsRendering(true);
				end
			end
		end
		-- update tick
		funcUpdateTickGroup(proxy, newState);
	end
end

local proxy__newindex= function(proxy:Element, i, v1)
	local raw = proxy._raw;
	if (not raw.isAlive) then error("Tried to call a dead element"); end
	local v0 = raw[i];
	if (v0==v1) then return; end
	if (i=="isVisible") then
		proxy:_SetIsVisible(v1);
	elseif (i=="renderTickRate") then
		if (v1<0) then error(`Invalid value Element.renderRate = {v1}, must be 0 or above`); end
		if (v1%1~=0) then
			warn(`Value Element.renderRate = {v1} will be rounded to {math.round(v1)}`);
			v1 = math.round(v1);
		end
		raw[i]=v1;
		proxy:_UpdateIsRendering(false);
	else
		error(`Property Element.{i} is invalid or read-only`);
	end
end

function CreateElement(component:_t.Component, propsOverride:_t.props?, mountTo:_t.Element?)
	-- indirect and direct element objects
	local elementProxy = newproxy() :: _t.Element;
	local elementRaw:Element = {} :: _t.Element;
	-- generate indirect access for props
	local propsProxy = newproxy();
	local propsRaw = table.clone(component.props); do
		local propsMeta = getmetatable(propsProxy);
		propsRaw._propsraw = propsRaw;
		propsRaw._elementraw = elementRaw;
		propsMeta.__index = propsRaw;
		propsMeta.__newindex = function(self,i,v1)
			local _propsRaw = self._raw :: _t.props;
			local v0 = _propsRaw[i];
			if (v1==v0) then return; end
			_propsRaw[i]=v1;
			local sig = _propsRaw._elementraw._localSignals.onPropChanged;
			local _ = sig and sig:Fire(elementProxy, i);
		end
	end
	-- generate base and container instances
	local baseInstance = component.baseInstance; baseInstance = baseInstance and baseInstance:Clone();
	local contInstance = baseInstance; if (baseInstance) then
		local path = component._containerInstancePathArr;
		if (path) then for _,i in ipairs(path) do
				contInstance = contInstance:FindFirstChild(i) or error("Couldn't find container instance in path");
		end end
		baseInstance.Destroying:Connect(function()
			pcall(elementProxy.Kill, elementProxy);
		end);
	end
	-- set public properties
	elementRaw.props = propsProxy;
	elementRaw.component = component;
	elementRaw.mountChildren = {};
	elementRaw.baseInstance = baseInstance;
	elementRaw.containerInstance = contInstance;
	elementRaw.renderTickRate = component.renderTickRate;
	elementRaw.renderTickLast = -1;
	-- combine listeners and apply propsOverride to propsRaw
    local globalListeners = table.clone(component.globalListeners);
	local localListeners = table.clone(component.localListeners);
	local customListeners = table.clone(component.customListeners);
	local listenerConnections = {};
	if (propsOverride) then
		for i,v in pairs(propsOverride) do
			if (i=="globalListeners" or i=="localListeners" or i=="customListeners") then
				local newListeners = v;
				local oldListeners = i=="globalListeners" and globalListeners or i=="localListeners" and localListeners or customListeners;
				for name,listener in pairs(newListeners) do oldListeners[i]=v; end
			else
				propsRaw[i]=v;
			end
		end
	end
	-- apply internal properties
	elementRaw._raw = elementRaw;
	elementRaw._listenerConnections = listenerConnections;
	elementRaw._localSignals = {};
	elementRaw._customSignals = {};
	-- generate indirect access for element
	setmetatable(elementRaw, Element);
	local meta = getmetatable(elementProxy);
	meta.__index = elementRaw;
	meta.__newindex = proxy__newindex;
	-- connect global, local and custom listeners
	for name, listener in pairs(globalListeners) do
		local signal = GetGlobalSignal(name) :: _t.Signal<any>;
		listenerConnections[#listenerConnections+1] = signal:Connect(function(...) listener(elementProxy, ...); end);
	end
	for name, listener in pairs(localListeners) do
		local signal = elementProxy:GetLocalSignal(name) :: _t.Signal<any>;
		listenerConnections[#listenerConnections+1] = signal:Connect(function(...) listener(elementProxy, ...); end);
	end
	for name, listener in pairs(customListeners) do
		local signal = elementProxy:GetCustomSignal(name) :: _t.Signal<any>;
		listenerConnections[#listenerConnections+1] = signal:Connect(function(...) listener(elementProxy, ...); end);
	end
	-- final
	local call = component.onElementInitCallback;
	local _ = call and call(elementProxy);
	local _ = mountTo and elementProxy:MountTo(mountTo);
	return elementProxy :: _t.Element;
end

do -- Ticking
	local TickGroups:{[number]:{[Element]:boolean}} = {};
	local IsTickingHash:{[Element]:number?} = {};
	
	local DeltaTicks:{[number]:number} = {};
	local NextTicks:{[number]:number} = {};
	local currTime = os.clock();
	-- creates new group if missing
	local function funcInitGroup(frameRate)
		local delta = frameRate==0 and 0 or 1/frameRate;
		local nextTick = currTime;
		TickGroups[frameRate] = {};
		DeltaTicks[frameRate] = delta;
		NextTicks[frameRate] = nextTick;
	end
	-- updates tick group for element
	function funcUpdateTickGroup(proxy, newIsRendering)
		local raw = proxy._raw;
		local oldGroupId = IsTickingHash[proxy];
		local newGroupId = (newIsRendering and raw._localSignals.onRenderTick) or nil; -- must be rendering and have onRenderTick signal required at least once to tick
		if (oldGroupId~=newGroupId) then
			if (oldGroupId) then TickGroups[oldGroupId][proxy] = nil; end
			if (newGroupId) then
				if (not TickGroups[newGroupId]) then
					funcInitGroup(newGroupId);
				end
				TickGroups[newGroupId][proxy] = true;
			end
			IsTickingHash[proxy] = newGroupId;
		end
	end
	-- main tick loop
	game:GetService("RunService").RenderStepped:Connect(function(_delta)
		currTime += _delta;
		for groupId, nextTick in pairs(NextTicks) do
			if (groupId~=0 and nextTick<currTime) then continue; end
			local fixeddelta = DeltaTicks[groupId];
			NextTicks[groupId] = currTime + fixeddelta;
			for Element in pairs(TickGroups[groupId]) do
				local raw = Element._raw;
				local last = raw.renderTickLast;
				local realdelta = (last==-1) and (currTime-fixeddelta) or (currTime-last);
				raw._localSignals.onRenderTick:Fire(Element, fixeddelta, realdelta, currTime);
				raw.renderTickLast = currTime;
			end
		end
	end);
end

return {
	CreateElement = CreateElement,
}
