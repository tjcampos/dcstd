-- Tower Defence Script by Tsunami and TJCampos

if (TD ~= nil) then
	env.warning('TD already created. Exiting...')
	return 0 
end
TD = {}
env.info('TD started')

TD.userPlanes = {'F15C - Eagle 1', 'F15C - Eagle 2','F15C - Eagle 3','SU27 - Flanker 1',
				'SU27 - Flanker 2','SU27 - Flanker 3','Mig 29 - Fulcrum 1','Mig 29 - Fulcrum 2',
				'Mig 29 - Fulcrum 3'}
TD.zones = {'Oni','Valley','Western Moundain','Eastern Moundain'}
TD.buyableUnits = {}

-- Units cost 
TD.buyableUnits[1] = {group = 'AAA - Vulcan', price = 2500}
TD.buyableUnits[2] = {group = 'Avenger - LAS', price = 5000}
TD.buyableUnits[3] = {group = 'Chaparral - RAD', price = 7500}
TD.buyableUnits[4] = {group = 'Tor - RAD', price = 10000}
TD.buyableUnits[5] = {group = 'Ammo_Truck', price = 1000}

TD.creepSettings = {}

-- Creep Settings -> Details aboult the creeps
TD.creepSettings.creepAG = {group = 'Creep_AG', price = 2500, startWave = 1, freq = 10}
TD.creepSettings.creepScout = {group = 'Creep_Scout', price = 600, startWave = 1 , freq = 1}
TD.creepSettings.creepLight = {group = 'Creep_Light', price = 1200, startWave = 4, freq = 4}
TD.creepSettings.creepMedium = {group = 'Creep_Medium', price = 2400, startWave = 8, freq = 8}
TD.creepSettings.creepHeavyMig = {group = 'Creep_Heavy_Mig', price = 5000, startWave = 12, freq = 12}
TD.creepSettings.creepHeavySU = {group = 'Creep_Heavy_SU', price = 5000, startWave = 14, freq = 12}

TD.pilotCost = 1000 -- Credits
TD.planeCost = 100 -- Credits
TD.returnTime = 60 -- (Seconds)
TD.timeBetweenWaves = 15 -- (Seconds)
TD.combatZone = {'Arena'}
TD.goalGroup = 'Goal'

TD.credits = 2000 -- Initial Credits
TD.wave = 0
TD.aliveCreeps = {}
TD.returnCounter = {}
TD.trucksDown = false
for _, i in ipairs(TD.userPlanes) do
	TD.returnCounter[i] = 0
end

-- Functions
-- Switch
function TD.switch(t,p)
  t.case = function (self,x,p)
    local f=self[x] or self.default
    if f then
      if type(f)=="function" then
        f(x, p, self)
      else
        error("case "..tostring(x).." not a function")
      end
    end
  end
  return t
end

-- Find
function TD.find(a, tbl)
	for _,a_ in ipairs(tbl) do if a_==a then return true end end
end

-- Difference
function TD.difference(a, b)
	local ret = {}
	for _,a_ in ipairs(a) do
		if not TD.find(a_,b) then table.insert(ret, a_) end
	end
	return ret
end

-- Show Credits
function TD.showCredits()
	trigger.action.outText('Credits: $' .. TD.credits .. '.', 10)
end

-- Show Wave
function TD.showWave()
	trigger.action.outText('Wave: ' .. TD.wave .. '.', 10)
end

-- Show Trucks
function TD.showTrucks()
	local _initammount = Group.getByName(TD.goalGroup):getInitialSize()
	local _ammount = Group.getByName(TD.goalGroup):getSize()
	trigger.action.outText('Trucks remaining:' .. (_ammount/_initammount)*100 .. '%.', 10)
end

-- Kill Desertors
function TD.killDesertors(_unitsNotInZone)
	local player = nil
	for _, u in pairs(_unitsNotInZone) do
		if not TD.find(u:getName(), TD.userPlanes) then
			env.info('Killing bot: ' .. u:getName())
			trigger.action.explosion(u:getPosition().p, 100)
		end
	end
	
	for i, t in pairs(TD.returnCounter) do
		player = Unit.getByName(i)
		if TD.find(player, _unitsNotInZone) then
			if t > TD.returnTime then
				env.info('Killing player: ' .. player:getName())
				trigger.action.explosion(player:getPosition().p, 100)
			else
				trigger.action.outTextForGroup(Group.getByName(i):getID() ,
					'You are leaving the battlefield. Return or you will be shot in ' .. 
					TD.returnTime - t .. '.' , 1)
				trigger.action.outSoundForGroup(Group.getByName(i):getID(), 'AlertRed.ogg')
				TD.returnCounter[i] = t + 1
			end 
		else
			TD.returnCounter[i] = 0
		end
	end 
end

-- Check Combat Zone Loop
function TD.checkCombatZone()
	env.info('Checking combat zone')
	if TD.combatZone == nil then 
		env.info('No Combat Zone Defined')
		return nil
	end
	local aUnits = {}
	local aUnitsNames = {}	
	for _, u in pairs(mist.DBs.aliveUnits) do
    	if u.unit:isActive() then
    		aUnits[#aUnits+1] = u.unit
    		aUnitsNames[#aUnitsNames+1] = u.unit:getName()
    	end
	end
	local unitsInZone = mist.getUnitsInZones(aUnitsNames,TD.combatZone)
	local unitsNotInZone = TD.difference(aUnits, unitsInZone)
	env.info('Matando')
	TD.killDesertors(unitsNotInZone)
	env.info('Done Checking')
	
	return timer.getTime() + 1
end

-- Buy Unit
function TD.buyUnit(_p)
	local _buyableUnit = _p.buyableUnit
	local _area = _p.area
	if TD.credits >= _buyableUnit.price then
		mist.cloneInZone(_buyableUnit.group, {_area})
		TD.credits = TD.credits - _buyableUnit.price
		trigger.action.outText(_buyableUnit.group .. ' deployed in ' .. _area , 10)
	else
		trigger.action.outText('Insuficient funds. ', 10)
	end
end

-- Add Radio Commands
function TD.addRadioCommands()
	local submenu = nil
	for _, unit in pairs(TD.buyableUnits) do
		submenu = missionCommands.addSubMenu('Buy ' .. unit.group .. '- $' .. unit.price .. ' Credit',nil)
		
		for _, zone in ipairs(TD.zones) do
			missionCommands.addCommand("Deploy on " .. zone, submenu, TD.buyUnit, {buyableUnit = unit, area = zone})
		end
	end
	
	missionCommands.addCommand("Show Credits", nil, TD.showCredits,{})
	missionCommands.addCommand("Show Wave", nil, TD.showWave,{})
	missionCommands.addCommand("Show Trucks", nil, TD.showTrucks,{})
end

-- Spawn Group
function TD.spawnGroup(_p)
	local _groupName = _p.groupName
	local _price = _p.price
	
	local groupName = mist.cloneGroup(_groupName, true)
	TD.aliveCreeps[groupName] = _price
end

-- Spawn Next Wave
function TD.spawnNextWave()
	local count = 0
	TD.wave = TD.wave + 1
	trigger.action.outText('Starting wave ' .. TD.wave, 5)
	trigger.action.outSound('Inc_WaveRed.ogg')
	for _, creep in pairs(TD.creepSettings) do
		if creep.startWave <= TD.wave then
			count = 1 + math.floor((TD.wave - creep.startWave)/creep.freq)
			
			
			mist.scheduleFunction(TD.spawnGroup, {{groupName = creep.group, price = creep.price}}, 
				timer.getTime(), 2, timer.getTime() + 2*count)
 		end
	end	
end

-- Check Next Wave
function TD.waveCaller()
	if TD.trucksDown then
		return nil
	end
	for _, _ in pairs(TD.aliveCreeps) do
		return timer.getTime() + 1
	end
	
	if TD.wave ~= 0 then
		trigger.action.outText('Wave Completed! Get ready for the next wave... ', TD.timeBetweenWaves)
	else
		trigger.action.outText('Welcome to DCS Tower Defence.' .. 
			'Survive as long as your team can. Get ready for start.', 33)
		trigger.action.outSound('InicioRed.ogg')
	end
	timer.scheduleFunction(TD.spawnNextWave, {}, timer.getTime() + TD.timeBetweenWaves)
	return timer.getTime() + TD.timeBetweenWaves + 3
end

-- Event Handler
TD.eventActions = TD.switch {
	[world.event.S_EVENT_CRASH] = function(x, param)
			local _event = param.event
			if not TD.find(_event.initiator:getName(), TD.userPlanes) then
			env.info(_event.initiator:getName())
				TD.credits = TD.credits + TD.aliveCreeps[_event.initiator:getGroup():getName()]
				TD.showCredits()
				TD.aliveCreeps[_event.initiator:getGroup():getName()] = nil
			else
				TD.credits = TD.credits - TD.planeCost
				TD.showCredits()
			end
		end,
	[world.event.S_EVENT_PILOT_DEAD] = function(x, param)
			local _event = param.event
			if TD.find(_event.initiator:getName(), TD.userPlanes) then
				TD.credits = TD.credits - TD.pilotCost
				TD.showCredits()
			end
		end,
	[world.event.S_EVENT_DEAD] = function(x, param)
			local _event = param.event
			local _initAmmount = Group.getByName(TD.goalGroup):getInitialSize()
			local _ammount = Group.getByName(TD.goalGroup):getSize() - 1
			if _event.initiator:getGroup():getName() == TD.goalGroup then
				if _ammount ~= 0 then
					trigger.action.outSound('AlertRed.ogg')
					trigger.action.outText('Warning!!! Trucks  under attack! There are still ' .. 
						(_ammount/_initAmmount)*100 .. '% of the trucks remaining.', 10)
				else
					trigger.action.outSound('MissionFailed3.ogg')
					trigger.action.outText('All trucks are destroyed. Yout team survived until wave ' .. TD.wave .. '.', 30)
					TD.trucksDown = true
				end
			end
		end,
	default = function(x, param) end,
}

TD.eventHandler = {}
function TD.eventHandler:onEvent(_event)
	TD.eventActions:case(_event.id, {event = _event})
end

-- Code
timer.scheduleFunction(TD.checkCombatZone, {}, timer.getTime() + 1)
timer.scheduleFunction(TD.waveCaller, {}, timer.getTime() + 1)
world.addEventHandler(TD.eventHandler)
TD.addRadioCommands()