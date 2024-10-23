local newSignal = require(script.Parent.utils.Signals.Signal).newSignal;

local GlobalSignals = {}

-- Creates a new signal if it doesn't exist, or gets existing if it does
local function GetGlobalSignal(name)
	local signal = GlobalSignals[name]
	if not signal then
		warn("Creating new global element signal " .. name)
		signal = newSignal();
		GlobalSignals[name] = signal
	end
	return signal;
end

return {
	GetGlobalSignal = GetGlobalSignal;
	CreateLocalSignal = newSignal;
}
