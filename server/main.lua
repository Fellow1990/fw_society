local Jobs = setmetatable({}, {__index = function(_, key)
	return ESX.GetJobs()[key]
end})

local RegisteredSocieties = {}
local SocietiesByName = {}

function GetSociety(name)
	return SocietiesByName[name]
end
exports("GetSociety", GetSociety)

function registerSociety(name, label, account, datastore, inventory, data)
	if SocietiesByName[name] then
		print(('[^3WARNING^7] society already registered, name: ^5%s^7'):format(name))
		return
	end
	local society = {
		name = name,
		label = label,
		account = account,
		datastore = datastore,
		inventory = inventory,
		data = data
	}
	SocietiesByName[name] = society
	table.insert(RegisteredSocieties, society)
end
AddEventHandler('esx_society:registerSociety', registerSociety)
exports("registerSociety", registerSociety)

AddEventHandler('esx_society:getSocieties', function(cb)
	cb(RegisteredSocieties)
end)

AddEventHandler('esx_society:getSociety', function(name, cb)
	cb(GetSociety(name))
end)

lib.callback.register('esx_society:getmoney', function(source, name)
    local society, money
    TriggerEvent('esx_society:getSociety', name, function(sname)
        society = sname
    end)
    TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
        money = account.money or 0
    end)
    return money
end)

RegisterServerEvent('esx_society:withdrawMoney')
AddEventHandler('esx_society:withdrawMoney', function(societyName, amount)
	local source = source
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to withdraw from non-existing society - ^5%s^7!'):format(source, societyName))
		return
	end
	local xPlayer = ESX.GetPlayerFromId(source)
	amount = ESX.Math.Round(tonumber(amount))
	if xPlayer.job.name ~= society.name then
		return print(('[^3WARNING^7] Player ^5%s^7 attempted to withdraw from society - ^5%s^7!'):format(source, society.name))
	end
	TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
		if amount > 0 and account.money >= amount then
			account.removeMoney(amount)
			xPlayer.addMoney(amount, TranslateCap('money_add_reason'))
			Config.Notify('have_withdrawn', xPlayer.source, ESX.Math.GroupDigits(amount))
		end
	end)
end)

RegisterServerEvent('esx_society:depositMoney')
AddEventHandler('esx_society:depositMoney', function(societyName, amount)
	local source = source
	local xPlayer = ESX.GetPlayerFromId(source)
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to deposit to non-existing society - ^5%s^7!'):format(source, societyName))
		return
	end
	amount = ESX.Math.Round(tonumber(amount))
	if xPlayer.job.name ~= society.name then
		return print(('[^3WARNING^7] Player ^5%s^7 attempted to deposit to society - ^5%s^7!'):format(source, society.name))
	end
	if amount > 0 and xPlayer.getMoney() >= amount then
		TriggerEvent('esx_addonaccount:getSharedAccount', society.account, function(account)
			xPlayer.removeMoney(amount, TranslateCap('money_remove_reason'))
			Config.Notify('have_deposited', xPlayer.source, ESX.Math.GroupDigits(amount))
			account.addMoney(amount)
		end)
	end
end)

RegisterServerEvent('esx_society:putVehicleInGarage')
AddEventHandler('esx_society:putVehicleInGarage', function(societyName, vehicle)
	local source = source
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to put vehicle in non-existing society garage - ^5%s^7!'):format(source, societyName))
		return
	end
	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		table.insert(garage, vehicle)
		store.set('garage', garage)
	end)
end)

RegisterServerEvent('esx_society:removeVehicleFromGarage')
AddEventHandler('esx_society:removeVehicleFromGarage', function(societyName, vehicle)
	local source = source
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to remove vehicle from non-existing society garage - ^5%s^7!'):format(source, societyName))
		return
	end
	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		for i=1, #garage, 1 do
			if garage[i].plate == vehicle.plate then
				table.remove(garage, i)
				break
			end
		end
		store.set('garage', garage)
	end)
end)

lib.callback.register('esx_society:getEmployees', function(source, society)
	local employees = {}
	local response = MySQL.query.await('SELECT * FROM `users` WHERE `job` = ?', {society})
	for i = 1, #response do
		local row = response[i]
		employees[#employees+1] = {				
			identifier = row.identifier,
			name = row.firstname..' '..row.lastname,
			label = Jobs[society].label,
			grade = row.job_grade,
			grade_name = Jobs[society].grades[tostring(row.job_grade)].name,
			grade_label = Jobs[society].grades[tostring(row.job_grade)].label
		}
	end
	return employees
end)

lib.callback.register('esx_society:getJob', function(source, society)
	if not Jobs[society] then
		return false
	end
	local job = json.decode(json.encode(Jobs[society]))
	local grades = {}
	for k,v in pairs(job.grades) do
		table.insert(grades, v)
	end
	table.sort(grades, function(a, b)
		return a.grade < b.grade
	end)
	job.grades = grades
	return job
end)

lib.callback.register('esx_society:setJob', function(source, identifier, job, grade, actionType)
	local xPlayer = ESX.GetPlayerFromId(source)
	local isBoss = Config.BossGrades[xPlayer.job.grade_name]
	local xTarget = ESX.GetPlayerFromIdentifier(identifier)
	if not isBoss then
		print(('[^3WARNING^7] Player ^5%s^7 attempted to setJob for Player ^5%s^7!'):format(source, xTarget.source))
		return false
	end
	if not xTarget then
		MySQL.update('UPDATE users SET job = ?, job_grade = ? WHERE identifier = ?', {job, grade, identifier},
		function()
			return false
		end)
		return
	end
	xTarget.setJob(job, grade)
	if actionType == 'hire' then
		Config.Notify('you_have_been_hired', xTarget.source, job)
		Config.Notify('you_have_hired', xPlayer.source, xTarget.getName())
	elseif actionType == 'promote' then
		Config.Notify('you_have_been_promoted', xTarget.source)
		Config.Notify('you_have_promoted', xPlayer.source, xTarget.getName(), xTarget.getJob().grade_label)
	elseif actionType == 'demote' then
		Config.Notify('you_have_been_demoted', xTarget.source)
		Config.Notify('you_have_demoted', xPlayer.source, xTarget.getName(), xTarget.getJob().grade_label)
	elseif actionType == 'fire' then
		Config.Notify('you_have_been_fired', xTarget.source, xPlayer.getJob().label)
		Config.Notify('you_have_fired', xPlayer.source, xTarget.getName())
	end
	return true
end)

lib.callback.register('esx_society:setJobSalary', function(source, job, grade, salary, gradeLabel)
	local xPlayer = ESX.GetPlayerFromId(source)
	if xPlayer.job.name == job and Config.BossGrades[xPlayer.job.grade_name] then
		if salary <= Config.MaxSalary then
			MySQL.update('UPDATE job_grades SET salary = ? WHERE job_name = ? AND grade = ?', {salary, job, grade},
			function(rowsChanged)
				Jobs[job].grades[tostring(grade)].salary = salary
				ESX.RefreshJobs()
				Wait(1)
				local xPlayers = ESX.GetExtendedPlayers('job', job)
				for _, xTarget in pairs(xPlayers) do
					if xTarget.job.grade == grade then
						xTarget.setJob(job, grade)
					end
				end
				Config.Notify('salary_change', xPlayer.source, salary, gradeLabel)
				return true
			end)
		else
			print(('[^3WARNING^7] Player ^5%s^7 attempted to setJobSalary over the config limit for ^5%s^7!'):format(source, job))
			return false
		end
	else
		print(('[^3WARNING^7] Player ^5%s^7 attempted to setJobSalary for ^5%s^7!'):format(source, job))
		return true
	end
end)

lib.callback.register('esx_society:setJobLabel', function(source, job, grade, label)
    local xPlayer = ESX.GetPlayerFromId(source)
    if xPlayer.job.name == job and Config.BossGrades[xPlayer.job.grade_name] then
        MySQL.update('UPDATE job_grades SET label = ? WHERE job_name = ? AND grade = ?', {label, job, grade},
        function(rowsChanged)
            Jobs[job].grades[tostring(grade)].label = label
            ESX.RefreshJobs()
            Wait(1)
            local xPlayers = ESX.GetExtendedPlayers('job', job)
            for _, xTarget in pairs(xPlayers) do
                if xTarget.job.grade == grade then
                    xTarget.setJob(job, grade)
                end
            end
			Config.Notify('grade_change', xPlayer.source, label)
			return true
        end)
    else
        print(('[^3WARNING^7] Player ^5%s^7 attempted to setJobLabel for ^5%s^7!'):format(source, job))
		return false
    end
end)

lib.callback.register('esx_society:getOnlinePlayers', function(source)
		local onlinePlayers = {}
		local xPlayers = ESX.GetExtendedPlayers()
		for i=1, #(xPlayers) do 
			local xPlayer = xPlayers[i]
			table.insert(onlinePlayers, {
				source = xPlayer.source,
				identifier = xPlayer.identifier,
				name = xPlayer.name,
				job = xPlayer.job
			})
		end
	return onlinePlayers
end)

ESX.RegisterServerCallback('esx_society:getVehiclesInGarage', function(source, cb, societyName)
	local society = GetSociety(societyName)
	if not society then
		print(('[^3WARNING^7] Attempting To get a non-existing society - %s!'):format(societyName))
		return
	end
	TriggerEvent('esx_datastore:getSharedDataStore', society.datastore, function(store)
		local garage = store.get('garage') or {}
		cb(garage)
	end)
end)

lib.callback.register('esx_society:isBoss', function(source, job)
	return isPlayerBoss(source, job)
end)

function isPlayerBoss(playerId, job)
	local xPlayer = ESX.GetPlayerFromId(playerId)
	if xPlayer.job.name == job and Config.BossGrades[xPlayer.job.grade_name] then
		return true
	end
end