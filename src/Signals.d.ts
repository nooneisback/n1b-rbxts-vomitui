import type { Signal } from "./utils/Signal";
export type { Signal } from "./utils/Signal";
import { Element, GenericElement } from "./Element";
import { Context } from "./Context";

// Creates a new signal if it doesn't exist, or gets existing if it does
export function GetGlobalSignal<T extends Callback>(name:string) :Signal<T>;
export function CreateLocalSignal<T extends Callback>(): Signal<T>;

export type BuiltinElementListeners<props, baseInstance extends Instance|undefined> = {
    onThisMounted:          (element:Element<props, baseInstance>) => void;
    onThisUnmounted:        (element:Element<props, baseInstance>, oldParent:GenericElement) => void;
    onChildMounted:         (element:Element<props, baseInstance>, newChild:GenericElement) => void;
    onChildUnmounted:       (element:Element<props, baseInstance>, oldChild:GenericElement) => void;
    onContextChanged:       (element:Element<props, baseInstance>, oldContext:Context) => void;
    onIsVisibleChanged:     (element:Element<props, baseInstance>) => void;
    onIsRenderingChanged:   (element:Element<props, baseInstance>) => void;
    onDying:                (element:Element<props, baseInstance>) => void;
    onRenderTick:           (element:Element<props, baseInstance>, fixedDelta:number, realDelta:number, currentTime:number) => void;
}

export type BuiltinElementSignalNames<props, baseInstance extends Instance|undefined> = keyof BuiltinElementListeners<props, baseInstance>;