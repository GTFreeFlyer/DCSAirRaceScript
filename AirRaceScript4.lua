----------------------------------------------------------------------------------------------------------------------
-- Script       : CrossCountryRace.lua - Multiplayer Cross-Country Airrace Script                                   --
-- Version      : 1.2                                                                                               --
-- Requirements : - DCS World 2.5.6 or later                                                                        --
--                - Mist 4.5.126                                                                                     --
-- Author       : Bas 'Joe Kurr' Weijers                                                                            --
--                Dutch Flanker Display Team                                                                        --
-- Contributors : GTFreeFlyer • Added functionality for multiple laps in version 1.2                                --       
--                            • Due to adding laps, behavior changed if you go backwards through the gates          --
--                            • Added functionality for a group race where everyone shares the same start time      --             
----------------------------------------------------------------------------------------------------------------------
-- This script enables mission builders to create an airrace course.                                                --
-- The course consists of two or more gates, and can run from gate 1 to the last gate, or consist of multiple laps. --
-- When the player enters the course through gate 1, the timer for that player is started, and will run until he    --
-- either finishes the course, or leaves the race zone. If the group race option is selected, the timer starts for  --
-- all as soon as the 1st player enters gate 1, and all players must enter gate 1 within 15 seconds after that.     --
--                                                                                                                  --
-- Usage of this script:                                                                                            --
-- * Create a mission with one or more large overlapping trigger zones, named "racezone #001", "racezone #002", etc --
-- * Create two or more small trigger zones inside the large ones, named "gate #001", "gate #002", etc          --
-- * Place some static objects, such as race pylons, next to the gate trigger zones so the players can see the gates--
--   These objects can be of any type, and can have any name, they are just there for visual reference.             --
-- * Add one or more aircraft or helicopters so clients can race with them                                          --
-- * If choosing multiple laps, the start gate and finish gate are the same gate, gate #001                       --
-- * You only need one set of gates for multiple laps. Versions prior to 1.2 required overlapping trigger zones for --
--   multiple laps.  If you want to use this version of the script with a legacy .miz file, leave your trigger zones--
--   as they are, and set NumberLaps=1 (which is the default value for this optional setting)                       --
-- * Create three required triggers:                                                                                --
--                                                                                                                  --
--   1. Mission Start --> <empty>      --> Do Script                                                                --
--                                         NumberRaceZones = <total number of RaceZone triggerzones>      [required]--
--                                         NumberGates = <total number of Gate triggerzones in each lap>  [required]--
--                                         NumberPylons = <total number of Pylon triggerzones>            [required]--
--                                         NumberLaps = <total number of laps per race>                   [optional]--default: 0 (which means the race ends at the final gate, otherwise race ends at gate #001 of the last lap)
--                                         NewPlayerCheckInterval = <number of seconds between checks>    [optional]--default: 1
--                                         RemovePlayerCheckInterval = <number of seconds between checks> [optional]--default: 30
--                                         HorizontalGates = <list of gate numbers requiring level flight>[optional]--default: empty list --example: {2, 5} for gates #002 and #005
--                                         GateHeight = <global height of the gates in meters>            [optional]--default: 25
--                                         BonusGateHeight = <global height of the bonus gates in meters> [optional]--default: 1
--                                         BonusGates = <list of gate numbers for low alt bonus>          [optional]--default: empty list --example: {2, 5} for gates #002 and #005
--                                         StartSpeedLimit = <first gate speed limit in km/h>             [optional]--default: 300
--                                         GroupRace = <true: timer starts for everyone as soon as first  [optional]--default: false
--                                                             plane enters gate #001.                              --
--                                                      false: separate timer for each plane>                       --
--                                         PaceUnitName = <pace's unit name in a group race>              [optional]--default: (none, nil) --example: "PacePlane" (case-sensitive)
--                                                                                                                  --
--   2. Once          --> Time more(1) --> Do Script File                                                           --
--                                         mist_4_5_126.lua or later                                                --
--                                                                                                                  --
--   3. Once          --> Time more(2) --> Do Script File                                                           --
--                                         AirRaceScript4.lua (or whatever you named this script file)              --
--																												    --
-- * If running a group race with a pace plane, a 4th trigger is optional:                                          --
--                                                                                                                  --
--   4. Switched      --> Unit inside zone                              -->    Flag On (PaceDrop)                   --
--                        (your pace plane, any trigger zone name)         (PaceDrop is case-sensitive)             --
--                                                                                                                  --
--                       (This zone must be placed in the path of the pace plane at the very moment you wish to     --
--                        evaluate the line-up of the racers and assign penalties for being out of position. The    --
--                        pace plane typically noses down ahead of the first gate and calls out "race on!"  This    --
--                        is where you want to place this trigger zone. Without this trigger, the race will go on,  --
--                        but cheaters will not be penalized.                                                       -- 
--                                                                                                                  --      
--                       Note: Two general-purpose flags are provided in this script which the user can use in      --
--                             the .miz triggers for whatever purposes during group races. They are named:          --
--                              GroupRaceStarted, and GroupRaceFinished.  Both can either be 0 or 1 (false or true) --                                    
----------------------------------------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------------
-- PLAYER CLASS
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Player Properties
--
Player = {
	Name = '',
	Unit = nil,
	UnitName = '',
	UnitID = 0,
	CurrentGateNumber = 0,
	StartTime = 0,
	Penalty = 0,
	Bonus = 0,
	HitPylon = 0,
	TotalTime = 0,
	IntermediateTimes = {{}},
	DNF = false,
	PylonFlag = false,
	Started = false,
	Finished = false,
	StatusText = '',
	Warnings = {},
	CurrentLapNumber = 1,
	PacePositionEvaluated = false, --this is a flag used in group races that have a pace plane
	RaceEligible = true, --this is a flag used in group races to determine whether the player is eligible for the current race
	GateSpeed = 0, -- measured speed, in knots, when a player passes through a gate
	ResultsDisplayed = false --flag to toggle display at end of race
}

-----------------------------------------------------------------------------------------
-- Player Constructor
-- Parameter playerUnit: A unit from a Mist Unit Table representing a single aircraft
--                       or helicopters
--
function Player:New(playerUnit)
	local unitName = playerUnit:getName()
	local playerName = ''

	if playerUnit:getPlayerName() then
		playerName = playerUnit:getPlayerName()
	else
		playerName = playerUnit:getName()
	end

	local obj = {
		Name = playerName,
		Unit = Unit.getByName(unitName),
		UnitName = unitName,
		UnitID = Unit.getID(Unit.getByName(unitName)),
		CurrentGateNumber = 0,
		StartTime = 0,
		Penalty = 0,
		Bonus = 0,
		HitPylon = 0,
		TotalTime = 0,
		IntermediateTimes = {{}},
		DNF = false,
		PylonFlag = false,
		Started = false,
		Finished = false,
		StatusText = 'New entry',
		Warnings = {},
		CurrentLapNumber = 1,
		PacePositionEvaluated = false, --this is a flag used in group races that have a pace plane
		RaceEligible = true, --this is a flag used in group races to determine whether the player is eligible for the current race
		GateSpeed = 0, -- measured speed, in knots, when a player passes through a gate
		ResultsDisplayed = false --flag to toggle display at end of race
	}
	setmetatable(obj, { __index = Player })

	return obj
end
-----------------------------------------------------------------------------------------
GroupStartTime = 0 --initialize this variable to 0, it will be set to the time of the first player passing through gate #001 if GroupRace is true
GroupTimerStarted = false --flag to indicate whether the group timer has been started
-----------------------------------------------------------------------------------------
-- Start the timer for the current player
--
function Player:StartTimer()
	env.info(string.format("running StartTimer() function for player %s", self.Name))
	if not self.Started then

		--this if-statement decides how to set the player's start time
		if not race.GroupRace then --(if this is an individual race where everyone has their own clock, then...)
		    self.StartTime = timer.getTime()
			env.info(string.format("Individual timer started for player %s. Start time: %d", self.Name, self.StartTime))
		else  --(if this is a group race where everyone shares the same clock start time, then...)
			if not GroupTimerStarted then --this player is the first one to pass through gate #001, so start the group timer and set the player's start time to the group start time
				GroupStartTime = timer.getTime()
				self.StartTime = GroupStartTime
				GroupTimerStarted = true
				trigger.action.setUserFlag("GroupRaceStarted", 1) --optional flag to be used in the .miz for whatever purpose 
				trigger.action.setUserFlag("GroupRaceFinished", 0) --optional flag to be used in the .miz for whatever purpose 
				trigger.action.setUserFlag("PaceDrop", 0) -- reset this flag
				env.info(string.format("Group timer started by player %s. Group start time: %d", self.Name, GroupStartTime))
			else --the group timer has already been started by a previous player, so set this player's start time to the group start time
				self.StartTime = GroupStartTime
				env.info(string.format("Player %s's start time set to group start time: %d", self.Name, self.StartTime))
			end
		end

		self.TotalTime = 0
		self.IntermediateTimes = {{}}
		self.Started = true
		self.Finished = false
		self.ResultsDisplayed = false --resets this flag

		--reset the intermediate times to 0 for each gate, on each lap
        if race.NumberLaps > 1 then
			for lap = 2, race.NumberLaps do
				table.insert(self.IntermediateTimes, {})
			end
		end
		for lap = 1, #self.IntermediateTimes do
			for gate = 1, #race.Course.Gates do
				self.IntermediateTimes[lap][gate]=0
			end
		end

	end
end

-----------------------------------------------------------------------------------------
-- Stop the timer for the current player and save the timer value in the Time field
--
function Player:StopTimer()
	if self.Started then
		self.TotalTime = timer.getTime() - self.StartTime
		self.Started = false
		self.Finished = true
		self.PacePositionEvaluated = false --reset this flag for the next race (it is only used in group races led by a pace plane)
	end
end

-----------------------------------------------------------------------------------------
-- Return the time for the current player and save it in the IntermediateTime field
--
function Player:GetIntermediateTime(lap, gate)
	local intermediate = 0
	if self.Started and not self.Finished then
		intermediate = timer.getTime() - self.StartTime
		self.IntermediateTimes[lap][gate] = intermediate
	end
	return intermediate
end

----------------------------------------------------------------------------------------------------------------------
-- COURSE CLASS
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Course Properties
--
Course = {
	Gates = {}
}

-----------------------------------------------------------------------------------------
-- Course Constructor
--
function Course:New()
	local obj = {
		Gates = {}
	}
	setmetatable(obj, { __index = Course })
	return obj
end

-----------------------------------------------------------------------------------------
-- Adds a gate to the course.
-- Parameter gateNumber: the number of the trigger zone that defines a gate.
--                       e.g. for "gate #012" this is 12
--
function Course:AddGate(gateNumber)
	local gateName = string.format("gate #%03d", gateNumber)
	local triggerZone = trigger.misc.getZone(gateName)
	-- logMessage(string.format("Looking up gate %s", gateName))
	if triggerZone then
		table.insert(self.Gates, gateName)
		-- logMessage(string.format("gate %s added to course", gateName))
	else
		logMessage(string.format("Could not find trigger zone '%s'", gateName))
	end
end

-----------------------------------------------------------------------------------------
-- Return all units currently flying through a gate on the course
--
function Course:GetUnitsInGates()
	local allUnits = mist.makeUnitTable( { '[blue][plane]' } )
	local units = mist.getUnitsInZones(allUnits, self.Gates)
	return units
end


----------------------------------------------------------------------------------------------------------------------
-- AIRRACE CLASS
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Airrace Properties
--
Airrace = {
	RaceZones = {},
	Course = {},
	Players = {},
	FastestTime = 0,
	FastestPlayer = '',
	LastMessage = '',
	LastMessageId = 0,
	GateHeight = 100,
	HorizontalGates = {},
	StartSpeedLimit = 300,
	BonusGateHeight = 10,
	BonusGates = {},
	MessageLogged = false,
	NumberLaps = 0,
	GroupRace = false -- true: timer starts for everyone as soon as first plane makes it through gate #001. false: separate timer for each plane
}

-----------------------------------------------------------------------------------------
-- Airrace Constructor
-- Parameter triggerZoneNames: A table containing the names of one or more trigger zones
--                             covering the entire race course
-- Parameter course          : A reference to the Course object containing all the gates
--
function Airrace:New(triggerZoneNames, triggerZonePylonNames, course, gateHeight, horizontalGates, startSpeedLimit, bonusGateHeight, bonusGates, numberLaps, groupRace, paceUnitName, fastestIntermediates)
	local obj = {
		RaceZones = triggerZoneNames,
		PylonZones = triggerZonePylonNames,
		Course = course,
		Players = {},
		FastestTime = 0,
		FastestPlayer = '',
		FastestIntermediates = fastestIntermediates,
		GateHeight = gateHeight,
		HorizontalGates = horizontalGates or {},
		BonusGateHeight = bonusGateHeight,
		BonusGates = bonusGates,
		StartSpeedLimit = startSpeedLimit,
		NumberLaps = numberLaps,
		GroupRace = groupRace,
		PaceUnitName = paceUnitName,
	}
	setmetatable(obj, { __index = Airrace })
	return obj
end

-----------------------------------------------------------------------------------------
-- Check if any new players have entered one of the RaceZone trigger zones
-- and add them to the list of active players
--
function Airrace:CheckForNewPlayers()
	if self.GroupRace == false or (self.GroupRace == true and trigger.misc.getUserFlag("PaceDrop") == 0 and trigger.misc.getUserFlag("GroupRaceStarted") == 0) then
		local allUnits = mist.makeUnitTable( { '[blue][plane]' } )
		local unitsInZone = mist.getUnitsInZones(allUnits, self.RaceZones)
		local playerExists = false

		for unitIndex, unit in ipairs(unitsInZone) do
			if unit:getPlayerName() then --if this is nil, it means it's an AI unit and we aren't interested in that.
				env.info(string.format("Unit %s is in the race zone", unit:getPlayerName()))
				if unit:getLife() > 1 then	-- Only check for alive units
					playerExists = false
					if #self.Players > 0 then
						for playerIndex, player in ipairs(self.Players) do	
							local unitName = ''				
							if unit:getPlayerName() then
								unitName = unit:getPlayerName()
							else
								unitName = unit:getName() -- I think we can delete this since this would be for an AI unit only
							end			
							if player.Name == unitName then
								playerExists = true
								break
							end
						end
					end
					if not playerExists then
						--check if the unit is airborne.  This is to prevent players from being added and shown on the player list... 
						--...if they are sitting on the ground, which can happen if the airfield is inside the race zone.
						local airborne = unit:inAir()

						if airborne == true then
							env.info(string.format("Player %s added to player list", unit:getPlayerName() or unit:getName()))
							table.insert(self.Players, Player:New(unit))
							--trigger.action.outSoundForUnit(player.UnitID, 'smoke on.ogg')

							--GT: I'm leaving this comment here for the original author to read during git merge.  
							--The above line for outSoundForUnit errors out, attempt to index global 'player' (a nil value).  
							--This errors in the original and should be deleted.  I commented out for now.
						end
					end
				end
			end
		end
	end
end

-----------------------------------------------------------------------------------------
-- Check if any players have left the RaceZone trigger zones, and remove them from
-- the list of active players
--
function Airrace:RemoveExitedPlayers()
	if #self.Players > 0 then
		local allUnits = mist.makeUnitTable( { '[blue][plane]' } )
		local unitsInZone = mist.getUnitsInZones(allUnits, self.RaceZones)
		local playerExists = false

		for playerIndex, player in ipairs(self.Players) do
			playerExists = false
			for unitIndex, unit in ipairs(unitsInZone) do
				if unit:getLife() > 1 then	-- Only check for alive units
					local unitName = ''
					if unit:getPlayerName() then
						unitName = unit:getPlayerName()
					else
						unitName = unit:getName()
					end
					if player.Name == unitName then
						playerExists = true
						break
					end
				end
			end
			if not playerExists then
				--env.info(string.format("Player %s removed from player list", player.Name))
				table.remove(self.Players, playerIndex)
			end
		end
	end
end

-----------------------------------------------------------------------------------------
-- Remove a player from a group race
function Airrace:removePlayerFromGroupRace(player)
	env.info("Attempting to remove" .. player.Name .. " from the group race list")
	if self.GroupRace then
		for racerIndex, racer in ipairs(self.Players) do
			if racer.Name == player.Name then
				table.remove(self.Players, racerIndex)
				env.info(player.Name .. " successfully removed from the player list")
				break
			end
		end	
	end
end
-----------------------------------------------------------------------------------------
-- Return a list of players currently flying through a gate
--
function Airrace:GetPlayersInGates()
	local result = {}
	if #self.Players > 0 then
		local unitsInGates = self.Course:GetUnitsInGates()
		if #unitsInGates > 0 then
			for unitIndex, unit in ipairs(unitsInGates) do
				local unitName = unit:getName()
				for playerIndex, player in ipairs(self.Players) do
					if player.UnitName == unitName then
						table.insert(result, player)
					end
				end
			end
		end
	end
	return result
end

-----------------------------------------------------------------------------------------
-- Return the number of the gate the given player is flying through, or 0 if not in gate
-- Parameter player: Reference to a player in the active players List
--
function Airrace:GetGateNumberForPlayer(player)
	local result = 0
	local playerUnitTable = mist.makeUnitTable( { player.UnitName } )
	for gateIndex, gateName in ipairs(self.Course.Gates) do
		local playersInsideZone = mist.getUnitsInZones(playerUnitTable, { gateName })
		if #playersInsideZone > 0 then
			result = gateIndex
			break
		end
	end
	return result
end
-----------------------------------------------------------------------------------------
-- Check if the player hit the pylon
-- Player parameter: link to the player in the list of active players
-- Gives a penalty for a downed pylon, and gives a DNF if 3 pylons are downed
-----------------------------------------------------------------------------------------
function Airrace:CheckPylonHitForPlayer(player)
	local playerUnitTable = mist.makeUnitTable( { player.UnitName } )
	for pylonIndex, pylonName in ipairs(self.PylonZones) do
		local playersInsideZone = mist.getUnitsInZones(playerUnitTable, { pylonName })
		if #playersInsideZone > 0 and player.PylonFlag == false then
			local gateAltitudeOk = self:CheckPylonAltitudeForPlayer(player)
			if  gateAltitudeOk == true then
				warnPlayer(string.format("PYLON HIT!!! pylon %d ", pylonIndex), player)
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player.Penalty = player.Penalty + 3
				player.HitPylon = player.HitPylon + 1
				player.PylonFlag = true
				env.info(string.format("Player %s hit a pylon (%d)", player.Name, player.HitPylon))
			end
			if player.HitPylon >= 3 then
				player.DNF = true
				player.StatusText = string.format("3rd pylon hit !!! DNF!!!")
				env.info(string.format("Player %s hit 3 pylons. DNF!", player.Name))
				mist.scheduleFunction(function() self:removePlayerFromGroupRace(player) end, {}, timer.getTime()+10)
			end
			break
		end
	end
end
-----------------------------------------------------------------------------------------
function Airrace:CheckPylonAltitudeForPlayer(player)
	local result = true
	local pos = Unit.getByName(player.UnitName):getPosition().p
	local playerPos = { 
	   x = pos["x"], 
	   y = pos["y"], 
	   z = pos["z"] 
	} 
	local TerrainPos = land.getHeight({x = playerPos.x, y = playerPos.z})
	playerAgl = playerPos.y - TerrainPos		
	if playerAgl <= self.GateHeight then
		result = true
	else
		result = false
	end
	return result
end

-----------------------------------------------------------------------------------------
-- Check whether the given player is flying below the Bonus height
-- Parameter player: Reference to a player in the active players list
-- Returns true if the player is below the bonus height, or false when flying too high
-- Use Case: Extra points for being low in a gate, like flying under a bridge
--
function Airrace:CheckBonusAltitudeForPlayer(player)
	local result = true
	local pos = Unit.getByName(player.UnitName):getPosition().p
	local playerPos = {
		x = pos["x"],
		y = pos["y"],
		z = pos["z"]
	}
	local TerrainPos = land.getHeight({x = playerPos.x, y = playerPos.z})
	playerAgl = playerPos.y - TerrainPos
	if playerAgl <= self.BonusGateHeight then
		result = true
	else
		result = false
	end
	return result
end
-----------------------------------------------------------------------------------------
-- Check whether the given player is flying below the gate height
-- Parameter player: Reference to a player in the active players list
-- Returns true if the player is below the gate height, or false when flying too high
--
function Airrace:CheckGateAltitudeForPlayer(player)
	local result = true
	local pos = Unit.getByName(player.UnitName):getPosition().p
	local playerPos = { 
	   x = pos["x"], 
	   y = pos["y"], 
	   z = pos["z"] 
	} 
	local TerrainPos = land.getHeight({x = playerPos.x, y = playerPos.z})
	playerAgl = playerPos.y - TerrainPos		
	if playerAgl <= self.GateHeight then
		result = true
	else
		result = false
		warnPlayer(string.format("Flying too high! Altitude = %d meters | Penalty: 2 sec.", playerAgl), player)
	end

	--also grab the speed at the gate, in knots
	local unitspeed = Unit.getByName(player.UnitName):getVelocity()
	local speed = math.sqrt(unitspeed.x^2 + unitspeed.y^2 + unitspeed.z^2) --m/s
	speed = speed * 1.94 --convert to knots
	speed = math.floor(speed * 10 + 0.5) / 10 -- truncate to one decimal place
	player.GateSpeed = speed

	return result
end
-----------------------------------------------------------------------------------------
-- Check whether this player is flying faster than the speed limit on the first gate
-- Player parameter: link to the player in the list of active players
-- Returns true if the speed is less than 300 km / h, or false if the speed is greater than 300 km / h
--
function Airrace:CheckGateSpeedForPlayer(player)
	local result = true
	local unitspeed = Unit.getByName(player.UnitName):getVelocity()
	speed = math.sqrt(unitspeed.x^2 + unitspeed.y^2 + unitspeed.z^2)
	-- logMessage(string.format("sped %d km/h", speed * 3.6))
	if speed * 3.6 <= self.StartSpeedLimit then
		result = true
		--warnPlayer(string.format("start speed = %d km/h", speed * 3.6), player)
	else
		result = false
		warnPlayer(string.format("EXCEEDING START SPEED LIMIT of %d km/h!! speed = %s km/h", self.StartSpeedLimit, speed * 3.6), player)
	end
	return result
end
-----------------------------------------------------------------------------------------
-- Check the player's roll
-- Player parameter: link to the player in the list of active players
-- Returns true if the roll is in the range of -10 ~ +10 deg.
--
function Airrace:CheckGateRollForPlayer(player)
	local result = true
	local myUnit = Unit.getByName(player.UnitName)
	roll = 180 * mist.getRoll(myUnit) / math.pi
	-- logMessage(string.format("Roll %s gr, %s rad", roll, mist.getRoll(myUnit)))
	if roll >= -10 and roll <= 10 then
		result = true
	else
		result = false
		warnPlayer(string.format("Wings not level! Roll = %d deg. | Penalty: 2 sec.", roll), player)
	end
	return result
end
-----------------------------------------------------------------------------------------
-- Only for group races with pace planes:
-- Check line-up of the player with the pace plane.
-- Assign penalty if the player is ahead of the pace plane at time of drop in.

function Airrace:CheckLineupWithPace(player)	
	player.Penalty = 0

	--get pace plane position
	local pos = Unit.getByName(self.PaceUnitName):getPosition().p
	local pacePos = { 
	   x = pos["x"], 
	   y = pos["y"], 
	   z = pos["z"] 
	}
	local paceHeading = mist.getHeading(Unit.getByName(self.PaceUnitName)) -- heading in radians

	--get player position
	local pos = Unit.getByName(player.UnitName):getPosition().p
	local playerPos = { 
	   x = pos["x"], --N/S position in meters
	   y = pos["y"], --altitude in meters
	   z = pos["z"]  --E/W position in meters
	} 

	--check height above ground for later evaluation
	local TerrainPos = land.getHeight({x = playerPos.x, y = playerPos.z})
	playerAgl = playerPos.y - TerrainPos	

	--rebase player position relative to pace plane at (0,0)
	playerPos.x = playerPos.x - pacePos.x
	playerPos.y = playerPos.y - pacePos.y
	playerPos.z = playerPos.z - pacePos.z

	--perform a rotation so that pace plane is moving straight upwards on an x,z graph
	local playerNewX = playerPos.x * math.cos(-paceHeading) - playerPos.z * math.sin(-paceHeading) --playerNewX is the player's position on the fore-aft axis relative to the pace plane. 
	local playerNewZ = playerPos.x * math.sin(-paceHeading) + playerPos.z * math.cos(-paceHeading) --playerNewZ is the player's position on the left-right axis relative to the pace plane.

	--now playerNewX is positive if the player is to the right of the pace plane,
	--playerNewZ is positive if the player is ahead of the pace plane, 
	--and playerPos.y is positive if the player is above the pace plane.  All values are in meters.

	--Check race eligibility:
	player.RaceEligible = true --Set all players as eligible by default at the start of the following checks:

	--Check if pilot is within 2000 meters (a little more than 1 mile) of the pace plane
	local distToPace = math.sqrt(playerPos.x^2 + playerPos.y^2 + playerPos.z^2) --meters		
	if distToPace > 1852 then 	
		env.info(string.format("Player %s is not eligible for the current group race. Distance to pace plane: %d meters", player.Name, math.floor(distToPace)))
		warnPlayer(string.format("%s removed from race. (More than 1 nm from the Pace)", player.Name), player)
		player.RaceEligible = false 
	end

	--Check if pilot is on the right side of the pace plane
	if playerNewZ < 0 then 	
		env.info(string.format("Player %s is not eligible for the current group race because they are on the left side of the pace plane", player.Name))
		warnPlayer(string.format("%s removed from race. (Wrong side of the Pace)", player.Name), player)
		player.RaceEligible = false 
	end

	--Check if pilot is behind the pace plane
	if playerNewX > 40 then 	
		env.info(string.format("Player %s is not eligible for the current group race because they are too far ahead of the pace plane", player.Name))
		warnPlayer(string.format("%s removed from race. (Too far ahead of the Pace)", player.Name), player)
		player.RaceEligible = false 
	end

	--Check if pilot is within altitude limits the pace plane
	if playerPos.y > 38.48 then -- 38.48 meters = 100 feet
		env.info(string.format("Player %s is not eligible for the current group race because they are more than 100 ft above the pace plane", player.Name))
		warnPlayer(string.format("%s removed from race. (More than 100 ft above the Pace)", player.Name), player)
		player.RaceEligible = false 
	elseif not Unit.getByName(player.UnitName):inAir() then 	
		env.info(string.format("Player %s is not eligible for the current group race because they are on the ground", player.Name))
		warnPlayer(string.format("%s removed from race. (Not airborne)", player.Name), player)
		player.RaceEligible = false 
	elseif playerPos.y < -152.4 then -- 152.4 meters = 500 feet
		env.info(string.format("Player %s is not eligible for the current group race because they are less than 500 ft below the pace plane", player.Name))
		warnPlayer(string.format("%s removed from race. (Less than 500 ft below the Pace)", player.Name), player)
		player.RaceEligible = false 
	end

	--Now decide final eligibility:
	if player.RaceEligible == false then
		warnPlayer(string.format("%s, STAY CLEAR of the course area immediately!", player.Name), player)		
	else
		env.info(string.format("Player %s is eligible for the current group race.", player.Name))
		--Perform lineup checks:
		if playerNewX > 1 then --allow a 1 meter buffer
			local penaltyIncrement = 2 + math.floor(playerNewX/20) --add 2 seconds plus an additional second for every 20 meters ahead of the pace plane
			player.Penalty = player.Penalty + penaltyIncrement
			env.info(string.format("%s was %dm ahead of the Pace. Penalty: %d seconds", player.Name, math.floor(playerNewX), penaltyIncrement))
			warnPlayer(string.format("%s was %dm ahead of the Pace.  | Penalty: %d sec.", player.Name, math.floor(playerNewX), penaltyIncrement), player)									
		end

		if playerPos.y > 2 then 	
			local penaltyIncrement = 2 + math.floor(playerPos.y/5) --add 2 seconds plus an additional second for every 20 meters above the pace plane
			player.Penalty = player.Penalty + penaltyIncrement
			env.info(string.format("%s was %dm above the Pace. Penalty: %d seconds", player.Name, math.floor(playerPos.y), penaltyIncrement))
			warnPlayer(string.format("%s was %dm above the Pace.     | Penalty: %d sec.", player.Name, math.floor(playerPos.y), penaltyIncrement), player)
		end
	end

	player.PacePositionEvaluated = true --set this flag to true so that the player won't be evaluated again until next race	
end
-----------------------------------------------------------------------------------------
-- Update the status and timer for the given player
-- Parameter player: Reference to a player in the active player List
--
function Airrace:UpdatePlayerStatus(player)
	local gateNumber = self:GetGateNumberForPlayer(player)

	-- ignore repeated gate detection, or pre-race period, or if racer not eligible for group race
	if gateNumber <= 0 or ( gateNumber == player.CurrentGateNumber and ( gateNumber ~= 1 or player.Started == true ) ) or not player.RaceEligible then
		if not player.RaceEligible and GroupTimerStarted then
			player.PacePositionEvaluated = false --reset this flag for ineligible racers so that they can be evaluated again for the next race
		end
		return
	end

	--check if this is the first lap, or starting a new lap...
	if gateNumber == 1 and player.CurrentLapNumber == 1 and player.Started == false then
		if self.PaceUnitName == nil then
			player.Penalty = 0 --we don't need to do this if there's a pace plane because it was already reset at the drop-in
		end
		player.Bonus = 0
		player:StartTimer() -- Player is passing gate 1 on lap 1, start timer
		
		local gateSpeedOk = self:CheckGateSpeedForPlayer(player)
		local unitspeed = Unit.getByName(player.UnitName):getVelocity()
		local speedKnots = math.sqrt(unitspeed.x^2 + unitspeed.y^2 + unitspeed.z^2) * 1.94
		if gateSpeedOk == false then
			trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
			player:StopTimer()
			player.StatusText = string.format("EXCEEDED START SPEED LIMIT!!! | Speed: %d kts | DNF!!!", speedKnots)
			player.DNF = true
		else
			--Display message "Started" along with the start speed, and a comparison to the fastest start speed if there is one saved from a previous race
			player.IntermediateTimes[1][1] = speedKnots
			if self.FastestTime ~= 0 then --indicates that the race has already been completed once in the past
				local fastestStartSpeed = self.FastestIntermediates[1][1]
				local difference = speedKnots - fastestStartSpeed
				local sign = "+"
				if difference < 0 then
					sign = "-"
				end
				player.StatusText = string.format("Started. Speed: %d kts (%s%d kts)", speedKnots, sign, math.abs(difference))
			else
				player.StatusText = string.format("Started. Speed: %d kts", speedKnots)
			end
		end

		trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')

		local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)	
		if gateAltitudeOk == false then
			trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
			player.Penalty = player.Penalty + 2
			-- logMessage(string.format("PENALTY: + 2 seconds "))
		end

		local gateRollOk = self:CheckGateRollForPlayer(player)
		if gateRollOk == false then
			trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
			player.Penalty = player.Penalty + 2
			-- logMessage(string.format("PENALTY: + 2 seconds "))
		end		
		
		player.CurrentGateNumber = gateNumber --this will always be 1 inside this if-statement
		player.PylonFlag = false		
		return

	elseif gateNumber == 1 then
		-- Player is starting a new lap, so increase lap number
		player.CurrentLapNumber = player.CurrentLapNumber + 1		
	end

	-- define what to do if player didn't go through the expected gate...
	if gateNumber ~= player.CurrentGateNumber + 1 and not (player.CurrentGateNumber == #self.Course.Gates and gateNumber == 1) then 
					
		if player.CurrentGateNumber == 0 and not player.Finished and player.CurrentLapNumber == 1 then
			-- Player passed unexpected gate at start of race
			player.StatusText = "Wrong start gate! Go back to Gate 1 to start."
			env.info(string.format("Player %s did not enter the course at Gate 1", player.Name))
			return

		elseif not player.Finished then
			-- Player has missed one or more gates
			local missedGates = 0 -- define this as a local variable with default value of 0

			if gateNumber > player.CurrentGateNumber + 1 then
				missedGates = gateNumber - (player.CurrentGateNumber + 1)
				if missedGates == 1 then
					warnPlayer(string.format("Missed gate %d | Penalty: 5 sec.", player.CurrentGateNumber + 1), player)
					env.info(string.format("Player %s missed gate %d", player.Name, player.CurrentGateNumber + 1))
				else
					warnPlayer(string.format("Missed gates %d to %d | Penalty: %d sec.", player.CurrentGateNumber + 1, gateNumber - 1, 5 * missedGates), player)
					env.info(string.format("Player %s missed gates %d to %d", player.Name, player.CurrentGateNumber + 1, gateNumber - 1))
				end

			elseif gateNumber < player.CurrentGateNumber then --Either going backwards or on a new lap with a lower gate number.  
			                                                  --We can't do much about going backwards, this is a sacrifice we make 
														      --from the older version in order to add the ability to do multiple laps.
				missedGates = #self.Course.Gates - (player.CurrentGateNumber + 1) + gateNumber
				if missedGates == 1 then
					warnPlayer(string.format("Missed gate %d | Penalty: 5 sec.", player.CurrentGateNumber + 1 - #self.Course.Gates), player) --this should always be gate 1 if only 1 gate was missed, but we'll calculate it anyway.
					env.info(string.format("Player %s missed gate %d", player.Name, player.CurrentGateNumber + 1 - #self.Course.Gates))
				else
					--we use some logic here to see if the gate numbers wrapped back around to 1
					local firstMissedGate = player.CurrentGateNumber + 1
					local lastMissedGate = gateNumber - 1
					if firstMissedGate > #self.Course.Gates then
						firstMissedGate = firstMissedGate - #self.Course.Gates
					end
					if lastMissedGate <= 0 then
						lastMissedGate = #self.Course.Gates
					else
						lastMissedGate = gateNumber - 1
					end

					warnPlayer(string.format("Missed gates %d to %d | Penalty: %d sec.", firstMissedGate, lastMissedGate, 5 * missedGates), player)
					env.info(string.format("Player %s missed gates %d to %d", player.Name, firstMissedGate, lastMissedGate))
				end
				-- Player has started a new lap, so increase lap number
				player.CurrentLapNumber = player.CurrentLapNumber + 1	
			end			

			player.Penalty = player.Penalty + (5 * missedGates)
			
			if gateNumber == 1 then
				player.CurrentGateNumber = #self.Course.Gates -- roll currentGateNumber back to the last gate in the course
			else
				player.CurrentGateNumber = gateNumber - 1 -- roll currentGateNumber back one gate			
			end
		end	
	end

	-- Player is passing the final gate, stop timer
	if (gateNumber == #self.Course.Gates and self.NumberLaps == 0) or (gateNumber == 1 and player.CurrentLapNumber > self.NumberLaps) then
		local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)
		local gateRollOk = self:CheckGateRollForPlayer(player)
		player.PylonFlag = false
		if gateRollOk == false then
			trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
			player.Penalty = player.Penalty + 2
			-- logMessage(string.format("PENALTY: + 2 seconds "))
		end
		local bonusGateAltitudeOk = self:CheckBonusAltitudeForPlayer(player)
		for i = 1, #self.BonusGates do
			if self.BonusGates[i] == gateNumber then
				if bonusGateAltitudeOk == true then
					player.Bonus = player.Bonus + 5
					warnPlayer(string.format("Low Alt Bonus -5 Sec - %s", player.Name), player)
				end
			end
		end
		if gateAltitudeOk == false then
			trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
			player.Penalty = player.Penalty + 2
			-- logMessage(string.format("PENALTY: + 2 seconds "))
		end
		player.PylonFlag = false
		player:StopTimer()
		player.StatusText = string.format("Finished. Race time:  %s + Penalty: %s sec.\n     Total time: %s ", formatTime(player.TotalTime), player.Penalty, formatTime(player.TotalTime + player.Penalty))
		env.info(string.format("Player %s finished the course. Race time: %s. Penalty: %s. Total time: %s", player.Name, formatTime(player.TotalTime), player.Penalty, formatTime(player.TotalTime + player.Penalty)))
		trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')
		player.CurrentGateNumber = gateNumber
		if self.FastestTime == 0 or self.FastestTime > player.TotalTime + player.Penalty then
			self.FastestTime = player.TotalTime + player.Penalty
			self.FastestPlayer = player.Name
			player.StatusText = string.format("%s - Fastest time!", player.StatusText)
			self.FastestIntermediates = player.IntermediateTimes
			env.info(string.format("Player %s achieved new time record: %s", player.Name, formatTime(self.FastestTime)))
		else
			player.StatusText = string.format("%s (+%s)", player.StatusText, formatTime(player.TotalTime + player.Penalty - self.FastestTime))
			env.info(string.format("Player %s +%s seconds behind best time", player.Name, formatTime(player.TotalTime + player.Penalty - self.FastestTime)))
		end		
		mist.scheduleFunction(function() self:removePlayerFromGroupRace(player) end, {}, timer.getTime()+15)
		return
	end

	-- Player is passing intermediate gate, set intermediate time
	local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)
	local intermediate = player:GetIntermediateTime(player.CurrentLapNumber, gateNumber)
	trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')
	player.StatusText = string.format("Time: %s | Speed: %d kts", formatTime(intermediate), player.GateSpeed)
	env.info(string.format("Player %s reached gate %d", player.Name, gateNumber))
	for i = 1 , #self.HorizontalGates do
		if self.HorizontalGates[i] == gateNumber then
			local gateRollOk = self:CheckGateRollForPlayer(player)
			if gateRollOk == false then
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player.Penalty = player.Penalty + 2
				-- logMessage(string.format("PENALTY: + 2 seconds "))
			end
			break
		end
	end
	player.PylonFlag = false
	local bonusGateAltitudeOk = self:CheckBonusAltitudeForPlayer(player)
	for i = 1, #self.BonusGates do
		if self.BonusGates[i] == gateNumber then
			if bonusGateAltitudeOk == true then
				player.Bonus = player.Bonus + 5
				warnPlayer(string.format("Low Alt Bonus -5 Sec - %s", player.Name), player)
			end
		end
	end
	if gateAltitudeOk == false then
		trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
		player.Penalty = player.Penalty + 2
		-- logMessage(string.format("PENALTY: + 2 seconds "))
	end
	if self.FastestTime ~= 0 then --indicates that the race has already been completed once in the past
		local fastestIntermediate = self.FastestIntermediates[player.CurrentLapNumber][gateNumber]
		local difference = intermediate - fastestIntermediate
		local sign = "+"
		if difference < 0 then
			sign = "-"
		end
		player.StatusText = string.format("%s (%s%s)", player.StatusText, sign, formatTime(math.abs(difference)))
	end
	player.CurrentGateNumber = gateNumber
end
-----------------------------------------------------------------------------------------
-- Display all active players on screen, with their current status
--
function Airrace:ListPlayers()
	local text = string.format("%d players in course", #self.Players)
	local playerNames = {}
	if self.FastestTime > 0 then
		text = string.format("%s - Fastest time: %s by %s", text, formatTime(self.FastestTime), self.FastestPlayer)
	end
	text = string.format("%s\n---------------------------------------", text)
	if #self.Players > 0 then

		--In group races with a pace plane, check the player's line-up with the pace plane at the moment of drop in			
		if self.GroupRace == true and self.PaceUnitName ~= nil then
			paceDroppedIn = trigger.misc.getUserFlag("PaceDrop") -- PaceDrop is a flag that must be set true in the .miz 	
			if paceDroppedIn == 1 then -- 1=true in DCS user flag
				for playerIndex, player in ipairs(self.Players) do	
					if not player.PacePositionEvaluated and not player.Finished == true then
						self:CheckLineupWithPace(player)
					end
				end
			end
		end

		-- Check if any players are currently flying through a gate, and if so check for pylon hits and update their status
		local playersInGates = self:GetPlayersInGates()
		if #playersInGates > 0 then
			for playerIndex, player in ipairs(playersInGates) do
				if (self.GroupRace == false and player.DNF == false) or (self.GroupRace == true and player.Finished == false and player.DNF == false) then
					self:CheckPylonHitForPlayer(player)
					self:UpdatePlayerStatus(player)
				end
			end
		end

		-- Now build the text to be displayed for each player
		local now = timer.getTime()
		for playerIndex, player in ipairs(self.Players) do
			text = string.format("%s\nPlayer: %s", text, player.Name)
			playerNames[playerIndex] = player.UnitName
			if player.CurrentGateNumber > 0 and player.Finished == false then
				if self.NumberLaps > 1 then
					text = string.format("%s | Lap %d Gate %d | %s", text, player.CurrentLapNumber, player.CurrentGateNumber, player.StatusText)
				else
					text = string.format("%s | Gate %d | %s", text, player.CurrentGateNumber, player.StatusText)
				end
			else
				text = string.format("%s - %s", text, player.StatusText)
			end

			if player.Finished == false then
				for messageIdx, message in ipairs(player.Warnings) do
					if message[2] >= now then
						text = text .. "\n  WARNING: " .. message[1]
					end
				end
			end
			if player.RaceEligible == false then
				mist.scheduleFunction(function() self:removePlayerFromGroupRace(player) end, {}, timer.getTime()+15)
			end
		end
	elseif self.GroupRace == true and #self.Players == 0 and trigger.misc.getUserFlag("GroupRaceStarted") == 1 then
		trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
		trigger.action.setUserFlag("GroupRaceFinished", 1) --optional flag to be used in the .miz for whatever purpose 
		env.info("No players remaining in the group race. Flag GroupRaceFinished = 1")
		mist.scheduleFunction(stopRaceScript, nil, timer.getTime()+30)
	end

	trigger.action.outText(text, 10, true)
end

----------------------------------------------------------------------------------------------------------------------
-- MAIN SCRIPT
----------------------------------------------------------------------------------------------------------------------

-----------------------------------------------------------------------------------------
-- Periodically check status for all players and display a list on screen
-- Parameter race: reference to the current Airrace object
--
function RaceTimer(race)
	race:ListPlayers()
end

-----------------------------------------------------------------------------------------
-- Periodically check for new players inside the RaceZone trigger zones
-- Parameter race: reference to the current Airrace object
--
function NewPlayerTimer(race)
	race:CheckForNewPlayers()
end

-----------------------------------------------------------------------------------------
-- Periodically check for players who are no longer inside the RaceZone trigger zones
-- Parameter race: reference to the current Airrace object
--
function RemovePlayerTimer(race)
	race:RemoveExitedPlayers()
end

-----------------------------------------------------------------------------------------
-- Write a message in dcs.log and show it on screen (for debugging purposes)
-- Parameter message: the message to be written
--
function logMessage(message, player)
	env.info(message)
	local msg = {} 
	msg.text = message
	msg.displayTime = 25  
	msg.msgFor = {coa = {'all'}} 
	mist.message.add(msg)
--	trigger.action.outText(message, 10)
end

-----------------------------------------------------------------------------------------
-- Add warning to player status output
-- Parameter message: the message to be shown
-- Parameter player:  the player for which the warning is intended
function warnPlayer(message, player)
	if player then --ignore nil entries
		local displayTime = 15
		local messageTimeout = timer.getTime() + displayTime
		table.insert(player.Warnings, {message, messageTimeout})
	end
end

-----------------------------------------------------------------------------------------
-- Format the given time in seconds to HH:mm:ss.mil (e.g. 01:42:38.382)
-- Parameter seconds: a float containing the number of seconds (from timer.getTime())
--
function formatTime(seconds)
	return string.format("%02d:%02d:%06.3f", seconds / (60 * 60), seconds / 60 % 60, seconds % 60)
end

-----------------------------------------------------------------------------------------
-- Start the script - This function is only used to start group races. Not needed for individual races
function startRaceScript()
	env.info("Start Airrace script")
	--reinitialize parameters for repeat races
	race.Players = {} 
	race.LastMessage = ''
	race.LastMessageId = 0	
	trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
	trigger.action.setUserFlag("GroupRaceFinished", 0) --optional flag to be used in the .miz for whatever purpose 

	--run scheduled timers...
	ScheduledFunctionRaceTimer = mist.scheduleFunction(RaceTimer, { race }, timer.getTime(), 0.2)  -- GT: I made each one of these a global var so they could be stopped via scripting if desired, using mist.removeFunction
	ScheduledFunctionNewPlayerTimer = mist.scheduleFunction(NewPlayerTimer, { race }, timer.getTime(), newPlayerCheckInterval)
	ScheduledFunctionRemovePlayerTimer = mist.scheduleFunction(RemovePlayerTimer, { race }, timer.getTime(), removePlayerCheckInterval)
end

-----------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------
-- Stop the script
function stopRaceScript()
	env.info("Stop Airrace script")
	trigger.action.setUserFlag("PaceDrop", 0) -- reset this flag
	mist.removeFunction(ScheduledFunctionRaceTimer)
	mist.removeFunction(ScheduledFunctionNewPlayerTimer)
	mist.removeFunction(ScheduledFunctionRemovePlayerTimer)
	trigger.action.setUserFlag("GroupRaceStarted", 0)
	trigger.action.setUserFlag("GroupRaceFinished", 0)
end 

-----------------------------------------------------------------------------------------
-- Initialize the script
--
function Init()
	local raceZones = {}
	local racePylons = {}
	local horizontalGates = HorizontalGates
	local course = Course:New()
	race = nil --this is used in the startRaceScript function, so it cannot be a local variable inside the Init function
	local numberRaceZones = NumberRaceZones or 0
	local numberPylons = NumberPylons or 0
	local numberGates = NumberGates or 0
	local numberLaps = NumberLaps or 0
	local newPlayerCheckInterval = NewPlayerCheckInterval or 1
	local removePlayerCheckInterval = RemovePlayerCheckInterval or 30
	local gateHeight = GateHeight or 25
	local startSpeedLimit = StartSpeedLimit or 300
	local bonusGateHeight = BonusGateHeight or 1
	local bonusGates = BonusGates or {}
	local groupRace = GroupRace or false
	local paceUnitName = PaceUnitName or nil
	local fastestIntermediates = {{}}
	
	if numberRaceZones > 0 and numberGates > 0 then
		for idx = 1, numberRaceZones do
			-- logMessage(string.format("Adding zone: RaceZone #%03d", idx))
			table.insert(raceZones, string.format("racezone #%03d", idx))
		end
		for idx = 1, numberPylons do
			-- logMessage(string.format("Adding zone: Pylons #%03d", idx))
			table.insert(racePylons, string.format("pilone #%03d", idx))
		end
		for idx = 1, numberGates do
			course:AddGate(idx)
		end

        if numberLaps > 1 then
			for lap = 2, numberLaps do
				table.insert(fastestIntermediates, {})
			end
		end
		for lap = 1, #fastestIntermediates do
			for gate = 1, numberGates do
				fastestIntermediates[lap][gate]=0
			end
		end

		race = Airrace:New(raceZones, racePylons, course, gateHeight, horizontalGates, startSpeedLimit, bonusGateHeight, bonusGates, numberLaps, groupRace, paceUnitName, fastestIntermediates)

		if not groupRace then --If its a group race, we'll allow more control by running startRaceScript() function from the .miz
			ScheduledFunctionRaceTimer = mist.scheduleFunction(RaceTimer, { race }, timer.getTime(), 0.2)  -- GT: I made each one of these a global var so they could be stopped via scripting if desired, using mist.removeFunction
			                                                                                               --Note: 300 knots is about 500 ft/sec. 0.2sec repeating function is once per 100ft of aircraft travel. Trigger zones smaller than this may be missed!
			ScheduledFunctionNewPlayerTimer = mist.scheduleFunction(NewPlayerTimer, { race }, timer.getTime(), newPlayerCheckInterval)
			ScheduledFunctionRemovePlayerTimer = mist.scheduleFunction(RemovePlayerTimer, { race }, timer.getTime(), removePlayerCheckInterval)
			env.info("Start Airrace script")
		end
	else
		logMessage("Variables 'NumberRaceZones' or 'NumberGates' not set")
	end
end

env.info("-----------------------------------------------------------------------------------------")
env.info("Load Airrace script")

Init()
