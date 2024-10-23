import type { Signal } from "./utils/Signal";
import type { Component } from "./Component";
import type { Context } from "./Context";
import { BuiltinElementListeners, BuiltinElementSignalNames } from "./Signals";


export type GenericElement = Element<unknown, any>;
export type Element<props, baseInstance extends Instance|undefined> = {
	readonly props: props;
    readonly component: Component<props, baseInstance>;
    readonly context: Context | undefined;
    readonly mountParent: GenericElement;
    readonly mountChildren: GenericElement[];
    readonly baseInstance: baseInstance;
    readonly containerInstance: Instance | undefined;
	renderTickRate: number;
	readonly renderTickLast: number;

    readonly isRoot: boolean;
    readonly isAlive: boolean;
    readonly isRendering: boolean;
	readonly isDying: boolean;
    isVisible: boolean;

	MountTo		    (newParent:GenericElement): (Element<props,baseInstance>);
	Unmount		    ():(Element<props,baseInstance>);
	Kill			(): void;
    
	GetCustomSingal	(signalName:string): Signal<(element:Element<props,baseInstance>,...args:any[])=>void>;
	GetLocalSignal	<T extends BuiltinElementSignalNames<props,baseInstance>>(signalName:T): (Signal<BuiltinElementListeners<props,baseInstance>[T]>);
};

export type OverrideProps<props, baseInstance extends Instance|undefined> = Partial<{
    globalListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
    localListeners: Partial<BuiltinElementListeners<props,baseInstance>>,
    customListeners: Record<string, (element:Element<props,baseInstance>, ...args:any[])=>void>,
} & props>;
export function CreateElement<props, baseInstance extends Instance|undefined>(
    component: Component<props,baseInstance>,
    propsOverride?: OverrideProps<props, baseInstance>,
    mountTo?: GenericElement,
) : Element<props, baseInstance>