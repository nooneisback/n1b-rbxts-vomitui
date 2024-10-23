import type { Element } from "./Element";
import type { Component } from "./Component";
import { RobloxComponent } from "./RobloxComponents";

export type ContextReaction =	// controlled by isVisible and kill
	"HideOnShow" |	// will hide when other context shows
	"HideOnHide" |	// will hide together with other context
	"ShowOnShow" |	// will show together with other context
	"ShowOnHide";	// will show when other context hides

export type Context<props={}, baseInstance extends Instance|undefined = ScreenGui> = {
	readonly name: string;
	readonly rootElement: Element<props, baseInstance>;
	readonly contextReactions: Record<string, ContextReaction>;
	readonly isAlive: boolean;
	isVisible: boolean;
	Kill ():void;
}

export function CreateContext<props={}, baseInstance extends Instance|undefined = ScreenGui>(
	name:string,
	rootComponent?:Component<props,baseInstance>,
	rootParent?:Instance
):Context<props,baseInstance>;