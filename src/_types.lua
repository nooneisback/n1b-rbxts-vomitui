local _sig = require(script.Parent.utils.Signal)
export type Signal<T> = _sig.Signal<T>;

export type ContextReaction =	-- controlled by isVisible and kill
	"HideOnShow" |	-- will hide when other context shows
	"HideOnHide" |	-- will hide together with other context
	"ShowOnShow" |	-- will show together with other context
	"ShowOnHide";	-- will show when other context hides
export type Context = {
	name: string;
	rootElement: Element;
	contextReactions: {[string]: ContextReaction}; -- reacts to other context's isVisible change
	isAlive: boolean;
	isVisible: boolean;
	Kill: (self:Context)->();
	_raw: Context;
	_SetIsVisible: (self:Context, newIsVisible:boolean)->();
}

export type ComponentInfo = {
    name: string?;
    props: props?;
    baseInstance: Instance?;
    containerInstancePath: string?;
    renderTickRate: number?;
    onElementInitCallback: (element:Element)->()?;
    globalListeners:{[string]:(self:Element, ...any)->()}?;
	localListeners:{[LocalSignalName]:(self:Element, ...any)->()}?;
	customListeners:{[string]:(self:Element, ...any)->()}?;
}
export type Component = {
	name:string;
	props: props;
    baseComponent: Component | nil;
    baseInstance: Instance | nil;
    containerInstancePath: string | nil;
	renderTickRate: number;

	onElementInitCallback: (element:Element)->() | nil;
    globalListeners:	{[string]:(self:Element, ...any)->()};
	localListeners:		{[LocalSignalName]:(self:Element, ...any)->()};
	customListeners:	{[string]:(self:Element, ...any)->()};
	
    CreateElement: (self:Component, propsOverride:props?, mountTo:Element?) -> Element;
    ExtendComponent: (self:Component, overrideInfo:ComponentInfo) -> Component;

	-- internals
	_raw: Component;
	_containerInstancePathArr: {string} | nil;
};

export type props = {[string]:any};

export type Element = {
	props: props;
	component: Component;
	context: Context;
	mountParent: Element | nil;
	mountChildren: {Element};
	baseInstance: Instance | nil;
    containerInstance: Instance | nil;
	renderTickRate: number;				-- rw
	renderTickLast: number;

	isRoot: boolean;
	isAlive: boolean;
	isRendering: boolean;
	isDying: boolean;
	isVisible: boolean;					-- rw

	MountTo:		    (self:Element, newParent:Element) -> (Element);
	Unmount:		    (self:Element) -> (Element);
	GetLocalSignal:	    <T>(self:Element, signalName:LocalSignalName) -> (Signal<T>);
	GetCustomSignal:	<T>(self:Element, signalName:string) -> (Signal<T>);
	Kill:			    (self:Element) -> ();

    -- internal props and methods
    _raw: Element;
    _listenerConnections:{RBXScriptConnection};
	_localSignals:		{[string]:Signal<(element:Element, ...any)->()>};
	_customSignals:		{[string]:Signal<(element:Element, ...any)->()>};

	_SetIsVisible:		(self:Element, newState:boolean)->();
	_UpdateContext:		(self:Element, isRecursive:boolean)->();
	_UpdateIsRendering:	(self:Element, isRecursive:boolean)->();
}

export type LocalSignalName = 
	"onThisMounted" | "onThisUnmounted" |
	"onChildMounted" | "onChildUnmounted" |
	"onContextChanged" | "onIsVisibleChanged" | "onIsRenderingChanged" |
	"onDying" | "onRenderTick" | "onPropChanged";

return nil;