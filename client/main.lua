function OpenBossMenu(society, close, options)
	local societyMoney = lib.callback.await('esx_society:getmoney', false, ESX.PlayerData.job.name)
	options = options or {}
	local elements = {}
	local isBoss = lib.callback.await('esx_society:isBoss', false, society)
	if isBoss then
		local defaultOptions = {
			checkBal = true,
			withdraw = true,
			deposit = true,
			wash = true,
			employees = true,
			salary = true,
			grades = true
		}
		for k,v in pairs(defaultOptions) do
			if options[k] == nil then
				options[k] = v
			end
		end

		if options.checkBal then
			elements[#elements+1] = {
				title = TranslateCap('check_society_balance', societyMoney),
				icon = "fas fa-wallet"
			}
		end
		if options.withdraw then
			elements[#elements+1] = {
				title = TranslateCap('withdraw_society_money'),
				description = TranslateCap('withdraw_description'),
				icon = "fas fa-wallet",
				onSelect = function()
					local amount = lib.inputDialog(TranslateCap('withdraw_amount'), {
						{type = 'number', label = TranslateCap('amount_title'), description = TranslateCap('withdraw_amount_placeholder'), required = true, min = 1, max = 250000}
						})
						if not amount then return end
						TriggerServerEvent('esx_society:withdrawMoney', society, amount[1])
						OpenBossMenu(society, nil, options)
				end,
			}
		end
		if options.deposit then
			elements[#elements+1] = {
				title = TranslateCap('deposit_society_money'),
				description = TranslateCap('deposit_description'),
				icon = "fas fa-wallet",
				onSelect = function()
					local amount = lib.inputDialog(TranslateCap('deposit_amount'), {
						{type = 'number', label = TranslateCap('amount_title'), description = TranslateCap('deposit_amount_placeholder'), required = true, min = 1, max = 250000}
						})
						if not amount then return end
						TriggerServerEvent('esx_society:depositMoney', society, amount[1])
						OpenBossMenu(society, nil, options)
				end,
			}
		end

		if options.employees then
			elements[#elements+1] = {
				title = TranslateCap('employee_management'),
				icon = "fas fa-users",
				onSelect = function()
					OpenManageEmployeesMenu(society, options)
				end,
			}
		end

		if options.salary then
			elements[#elements+1] = {
				title = TranslateCap('salary_management'),
				icon = "fas fa-wallet",
				onSelect = function()
					OpenManageSalaryMenu(society, options)
				end,
			}
		end
		if options.grades then
			elements[#elements+1] = {
				title = TranslateCap('grade_management'),
				icon = "fas fa-wallet",
				onSelect = function()
					OpenManageGradesMenu(society, options)
				end,
			}
		end

		lib.registerContext({
			id = 'OpenBossMenu',
			title = TranslateCap('boss_menu'),
			options = elements
		})
		lib.showContext('OpenBossMenu')
	end
end

function OpenManageEmployeesMenu(society, options)
	lib.registerContext({
		id = 'OpenManageEmployeesMenu',
		title = TranslateCap('employee_management'),
		menu = 'OpenBossMenu',
		options = {
			{
				title = TranslateCap('employee_list'),
				icon = "fas fa-users",
				onSelect = function()
					OpenEmployeeList(society, options)
				end,
			},
			{
				title = TranslateCap('recruit'),
				icon = "fas fa-users",
				onSelect = function()
					OpenRecruitMenu(society, options)
				end,
			}
		}
	})
	lib.showContext('OpenManageEmployeesMenu')
end

function OpenEmployeeList(society, options)
	local elements = {}
	local employees = lib.callback.await('esx_society:getEmployees', false, society)
	for i=1, #employees, 1 do
		local gradeLabel = (employees[i].grade_label == '' and employees[i].label or employees[i].grade_label)
		elements[#elements+1] = {
			title = employees[i].name .. " | " ..gradeLabel, gradeLabel = gradeLabel,
			icon = "fas fa-user",
			onSelect = function()
				OpenSelectedEmploye(society, options, employees[i])
			end,
		}
	end
	lib.registerContext({
		id = 'OpenEmployeeList',
		title = TranslateCap('employees_title'),
		menu = 'OpenManageEmployeesMenu',
		options = elements

	})
	lib.showContext('OpenEmployeeList')
end

function OpenSelectedEmploye(society, options, data)
	lib.registerContext({
		id = 'OpenSelectedEmploye',
		title = TranslateCap('employee_management'),
		menu = 'OpenEmployeeList',
		options = {
			{
				title = TranslateCap('promote'),
				icon = "fas fa-users",
				onSelect = function()
					lib.callback.await('esx_society:setJob', false, data.identifier, society, data.grade+1, 'promote')
				end,
			},
			{
				title = TranslateCap('demote'),
				icon = "fas fa-users",
				onSelect = function()
					lib.callback.await('esx_society:setJob', false, data.identifier, society, data.grade-1, 'demote')
				end,
			},
			{
				title = TranslateCap('fire'),
				icon = "fas fa-users",
				onSelect = function()
					lib.callback.await('esx_society:setJob', false, data.identifier, 'unemployed', 0, 'fire')
				end,
			}
		}
	})
	lib.showContext('OpenSelectedEmploye')
end

function OpenRecruitMenu(society, options)
	local elements = {}
	local players = lib.callback.await('esx_society:getOnlinePlayers', false)
	for i=1, #players, 1 do
		if players[i].job.name ~= society then
			elements[#elements+1] = {
				icon = "fas fa-user",
				title = players[i].name,
				onSelect = function()
					lib.callback.await('esx_society:setJob', false, players[i].identifier, society, 0, 'hire')
				end
			}
		else
			elements[#elements+1] = {
				icon = "fas fa-user",
				title = TranslateCap('no_player')
			}
		end
	end
	lib.registerContext({
		id = 'OpenRecruitMenu',
		title = TranslateCap('recruiting'),
		options = elements
	})
	lib.showContext('OpenRecruitMenu')
end

function OpenManageSalaryMenu(society, options)
	local elements = {}
	local job = lib.callback.await('esx_society:getJob', false, society)
	for i=1, #job.grades, 1 do
		local gradeLabel = (job.grades[i].label == '' and job.label or job.grades[i].label)
		elements[#elements+1] = {
			icon = "fas fa-wallet",
			title = TranslateCap('money_generic', gradeLabel, ESX.Math.GroupDigits(job.grades[i].salary)),
			onSelect = function()
				local amount = lib.inputDialog(TranslateCap('change_salary_description'), {
					{type = 'number', label = TranslateCap('amount_title'), description = TranslateCap('change_salary_placeholder'), required = true, min = 1, max = Config.MaxSalary}
				  })
				if not amount then return end
				lib.callback.await('esx_society:setJobSalary', false, society, job.grades[i].grade, amount[1], gradeLabel)
				OpenManageSalaryMenu(society, options)
			end,
		}
	end
	lib.registerContext({
		id = 'OpenManageSalaryMenu',
		title = TranslateCap('salary_management'),
		menu = 'OpenBossMenu',
		options = elements
	})
	lib.showContext('OpenManageSalaryMenu')
end

function OpenManageGradesMenu(society, options)
	local elements = {}
	local job = lib.callback.await('esx_society:getJob', false, society)
	for i=1, #job.grades, 1 do
		local gradeLabel = (job.grades[i].label == '' and job.label or job.grades[i].label)
		elements[#elements+1] = {
			icon = "fas fa-wallet",
			title = ('%s'):format(gradeLabel),
			onSelect = function()
				local text = lib.inputDialog(TranslateCap('change_label_description'), {
					{type = 'input', label = TranslateCap('change_label_title'), description = TranslateCap('change_label_placeholder'), required = true}
				  })
				local label = tostring(text[1])
				lib.callback.await('esx_society:setJobLabel', false, society, job.grades[i].grade, label)
				OpenManageGradesMenu(society, options)
			end,
		}
	end
	lib.registerContext({
		id = 'OpenManageGradesMenu',
		title = TranslateCap('grade_management'),
		menu = 'OpenBossMenu',
		options = elements
	})
	lib.showContext('OpenManageGradesMenu')
end

AddEventHandler('esx_society:openBossMenu', function(society, close, options)
	OpenBossMenu(society, close, options)
end)