import type { Component } from "./Component";
import { Element } from "./Element";

export type RobloxComponent<T extends Instance >
    = Component<Partial<WritableInstanceProperties<T>>, T>;

export type RobloxElement<T extends Instance>
    = Element<Partial<WritableInstanceProperties<T>>, T>;

export function GetRobloxComponent<className extends keyof CreatableInstances>(className:className) : RobloxComponent<CreatableInstances[className]>;