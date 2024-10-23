import type { Signal } from "./utils/Signal";
export type { Signal } from "./utils/Signal";
import { Element, GenericElement } from "./Element";
import { Context } from "./Context";

// Creates a new signal if it doesn't exist, or gets existing if it does
export function GetGlobalSignal<T extends Callback>(name:string) :Signal<T>;
export function CreateLocalSignal<T extends Callback>(): Signal<T>;

export type BuiltinElementListeners<props, baseInstance extends Instance|undefined> = {
    onThisMounted:          (this:Element<props, baseInstance>) => void;
    onThisUnmounted:        (this:Element<props, baseInstance>, oldParent:GenericElement) => void;
    onChildMounted:         (this:Element<props, baseInstance>, newChild:GenericElement) => void;
    onChildUnmounted:       (this:Element<props, baseInstance>, oldChild:GenericElement) => void;
    onContextChanged:       (this:Element<props, baseInstance>, oldContext:Context) => void;
    onIsVisibleChanged:     (this:Element<props, baseInstance>) => void;
    onIsRenderingChanged:   (this:Element<props, baseInstance>) => void;
    onDying:                (this:Element<props, baseInstance>) => void;
    onRenderTick:           (this:Element<props, baseInstance>, fixedDelta:number, realDelta:number, currentTime:number) => void;
}

export type BuiltinElementSignalNames<props, baseInstance extends Instance|undefined> = keyof BuiltinElementListeners<props, baseInstance>;