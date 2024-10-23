export type Signal<T extends Callback> = {
    Connect (self:Signal<T>, func:T): RBXScriptConnection;
    Wait    (self:Signal<T>): Parameters<T>;
    Fire    (self:Signal<T>, ...args:Parameters<T>): void;
    Event:  RBXScriptSignal;
    Bindable: BindableEvent|undefined;
}

export function newSignal<T extends Callback>(): Signal<T>;
export function CreateFromBindable<T extends Callback>(bind:BindableEvent<T>): Signal<T>;
export function CreateFromEvent<T extends Callback>(event:RBXScriptSignal<T>): Signal<T>;