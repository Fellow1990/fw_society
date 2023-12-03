# fw_society

If you use any HUD money change this

  			>ESX.TriggerServerCallback('esx_society:getSocietyMoney', function(money)
  			>	SendNUIMessage({ action = 'setMoney', id = 'society', value = money })
  			>end, ESX.PlayerData.job.name)

to

>local money = lib.callback.await('esx_society:getmoney', false, ESX.PlayerData.job.name)
>SendNUIMessage({ action = 'setMoney', id = 'society', value = money })
