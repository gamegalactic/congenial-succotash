local QBCore = exports['qb-core']:GetCoreObject()

-- Whitelist: players who can bypass Perico defences
local PericoWhitelist = {
    "FGI59936" -- Steven / GameGalactic
}

-- Command: /perico on | /perico off
QBCore.Commands.Add('perico', 'Toggle Perico island defences (admin only)', {
    { name = 'state', help = 'on/off' }
}, false, function(source, args)
    local state = args[1]
    if not state or (state ~= 'on' and state ~= 'off') then
        TriggerClientEvent('QBCore:Notify', source, 'Usage: /perico on | /perico off', 'error')
        return
    end

    local enabled = state == 'on'
    TriggerClientEvent('perico:defences', -1, enabled, PericoWhitelist)

    local msg = enabled and 'Island defences ACTIVATED' or 'Island defences DEACTIVATED'
    TriggerClientEvent('QBCore:Notify', -1, msg, enabled and 'error' or 'success')
end, 'admin')
