import type { Element, GenericElement } from "./Element";
import type { BuiltinElementListeners } from "./Signals";

export type ComponentInfo<props, baseInstance extends Instance|undefined> = Partial<{
    name: string;
    props: props;
    baseInstance: baseInstance;
    containerInstancePath: string;
    renderTickRate: number;
    onElementInitCallback: (element:Element<props,baseInstance>)=>void;
    globalListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
    localListeners: Partial<BuiltinElementListeners<props,baseInstance>>,
    customListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
}>;

export type GenericComponent = Component<unknown, any>;
export type Component<props, baseInstance extends Instance|undefined> = {
    readonly name: string;
    readonly props: props;
    readonly baseComponent: GenericComponent|undefined;
    baseInstance: Instance | undefined;
    containerInstancePath: string | undefined;
    renderTickRate: number;

    onElementInitCallback: ((element:Element<props,baseInstance>)=>void) | undefined;
    globalListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
    localListeners: Partial<BuiltinElementListeners<props,baseInstance>>,
    customListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
    
    CreateElement (propsOverride?:props, mountTo?:GenericElement): Element<props,baseInstance>;
    ExtendComponent <newprops = props, newbaseInstance extends Instance|undefined = baseInstance> (overrideInfo:ComponentInfo<newprops, newbaseInstance>): Component<newprops&props, newbaseInstance>;
}

export function CreateComponent<props, baseInstance extends Instance|undefined> (componentInfo:ComponentInfo<props,baseInstance>):Component<props,baseInstance>;
export function GetNamedComponent (name:string): GenericComponent | undefined;
export function IsComponentNameAnonymous (name:string) :boolean;