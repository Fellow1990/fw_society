# esx_society

Society management for ESX. Adds employee management (hire, fire, promote / demote, change salary), society bank accounts and money washing. It's crucial that this script gets started before all resources that utilize societies do, or else many things will go wrong.

## Requirements
- [esx_addonaccount](https://github.com/esx-framework/ESX-Legacy-Addons)

### Manually
- Download https://github.com/esx-framework/ESX-Legacy-Addons
- Put it in the `[esx]` directory

## Installation
- Import `esx_society.sql` in your database
- Add this in your `server.cfg`:

```
ensure esx_society
```

## Explanation
ESX Society works with addon accounts named 'society_xxx', for example 'society_taxi' or 'society_realestateagent'. If you job grade is 'boss' the society money will be displayed in your hud.

## Usage
```lua
local society = 'taxi'
local amount  = 100

TriggerServerEvent('esx_society:withdrawMoney', society, amount)
TriggerServerEvent('esx_society:depositMoney', society, amount)
TriggerServerEvent('esx_society:washMoney', society, amount)


TriggerEvent('esx_society:openBossMenu', society, function (menu)
	ESX.CloseContext() 
end, {wash = false}) -- set custom options, e.g disable washing
```

# Legal
### License
esx_society - societies for ESX

Copyright (C) 2015-2025 Jérémie N'gadi

This program Is free software: you can redistribute it And/Or modify it under the terms Of the GNU General Public License As published by the Free Software Foundation, either version 3 Of the License, Or (at your option) any later version.

This program Is distributed In the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty Of MERCHANTABILITY Or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License For more details.

You should have received a copy Of the GNU General Public License along with this program. If Not, see http://www.gnu.org/licenses/.