----------------------------------------------------------------------------------------------------------------------
-- Script       : CrossCountryRace.lua - Multiplayer Cross-Country Airrace Script                                   --
-- Version      : 1.2                                                                                               --
-- Requirements : - DCS World 2.5.6 or later                                                                        --
--                - Mist 4.5.126                                                                                    --
-- Author       : Bas 'Joe Kurr' Weijers                                                                            --
--                Dutch Flanker Display Team                                                                        --
-- Contributors : GTFreeFlyer • Added functionality for multiple laps in version 1.2                                --       
--                            • Due to adding laps, behavior changed if you go backwards through the gates          --
--                            • Added functionality for a group race where everyone shares the same start time      -- 
--                            • Added dynamic ranking display for group races                                       -- 
--                            • Added functionality for knife-edge gates                                            --
--                            • Added illumination for night racing, smoke zones, and fireworks zones               --
--                            • Added more user settings                                                            --
--                More contributors are listed at the bottom of the README at the GitHub link below.                --
----------------------------------------------------------------------------------------------------------------------
-- VIEW THE README!                                                                                                 --
-- https://github.com/GTFreeFlyer/DCSAirRaceScript/tree/master                                                      --
-- It's much more detailed than what you'll find written here. There is no need to continue reading below!          --
----------------------------------------------------------------------------------------------------------------------
-- This script enables mission builders to create an airrace course.                                                --
-- The course consists of two or more gates, and can run from gate 1 to the last gate, or consist of multiple laps. --
-- When the player enters the course through gate 1, the timer for that player is started, and will run until he    --
-- either finishes the course, or leaves the race zone. If the group race option is selected, the timer starts for  --
-- all as soon as the 1st player enters gate 1, and all players must enter gate 1 within 15 seconds after that.     --
--                                                                                                                  --
-- Usage of this script (Some basic info is below, but you should VIEW THE README on github as it is very detailed) --
-- * Create a mission with one or more large overlapping trigger zones, named "racezone-1", "racezone-2", etc       --
-- * Create two or more small trigger zones inside the large ones, named "gate-1", "gate-2", etc                    --
-- * Place some static objects, such as race pylons, next to the gate trigger zones so the players can see the gates--
--   These objects can be of any type, and can have any name, they are just there for visual reference.             --
-- * Add one or more aircraft or helicopters so clients can race with them                                          --
-- * If choosing multiple laps, the start gate and finish gate are the same gate, gate-1                            --
-- * You only need one set of gates for multiple laps. Versions prior to 1.2 required overlapping trigger zones for --
--   multiple laps.  If you want to use this version of the script with a legacy .miz file, leave your trigger zones--
--   as they are, and set NumberLaps as required (NumberLaps is the default value for this optional setting)        --
-- * Create three required triggers:                                                                                --
--                                                                                                                  --
--   1. Mission Start --> <empty> --> Do Script                                                                     --
--                                    NumberLaps = <total number of laps per race>                        [optional]-- default: 0 (which means the race ends at the final gate, otherwise race ends at gate-1 of the last lap)
--                                    NewPlayerCheckInterval = <number of seconds between checks>         [optional]-- default: 1
--                                    RemovePlayerCheckInterval = <number of seconds between checks>      [optional]-- default: 30
--                                    HorizontalGates = <list of gate numbers requiring level flight>     [optional]-- default: {1} (first gate only) --example: {1, 2, 5} for gates 1, 2, and 5
--                                    VerticalGates = <list of gate numbers requiring knife-edge flight>  [optional]-- default: {} (empty list)  --example: {3, 6, 8} for gates 3, 6, and 8
--                                    RaceZoneCeiling = <max. detect altitude (ft) of planes in racezone  [optional]-- default: 99999 --make sure this is at least 500 feet above where the pace drop-in occurs
--                                    GateHeight = <global height of the gates in feet>                   [optional]-- default: 300 --maximum height of plane above ground to "hit" gate
--                                    BonusGateHeight = <global height of the bonus gates in feet>        [optional]-- default: 20
--                                    BonusGates = <list of gate numbers for low alt bonus>               [optional]-- default: {} (empty list) --example: {2, 5} for gates 2, and 5
--                                    BonusTime = <time in seconds to subtract when hitting a bonus gate> [optional]-- default: 1
--                                    PenaltyTimeMissedGate = <penalty time in seconds>                   [optional]-- default: 5
--                                    PenaltyTimePylonHit = <penalty time in seconds>                     [optional]-- default: 3
--                                    PenaltyTimeAboveGateHeight = <penalty time in seconds>              [optional]-- default: 2
--                                    PenaltyTimeHorizontalGate = <penalty time in seconds>               [optional]-- default: 2
--                                    PenaltyTimeVerticalGate = <penalty time in seconds>                 [optional]-- default: 2
--                                    NumberMissedGatesDNF = <number of missed gates to trigger a DNF>    [optional]-- default: 999. Range 1 to 9999. Penalties at gates not counted.
--                                    NumberPylonHitsDNF = <number of pylon hits to trigger a DNF>        [optional]-- default: 999. Range 1 to 9999. 
--                                    StartSpeedLimit = <first gate speed limit in knots>                 [optional]-- default: 999
--                                    GroupRace = <true or false>                                         [optional]-- default: false. True: timer starts for everyone as soon as first plane enters gate-1. false: separate timer for each plane
--                                    GroupRaceTimeout = <minutes after clock starts, or pace drops in>   [optional]-- default: 120. Offers protection in case one racer decides to fly around inside the racezone, purposefully not finishing.
--                                    PaceUnitName = <pace's unit name in a group race>                   [optional]-- default: (none, nil) --example: "PacePlane" (case-sensitive)
--                                    GroupRaceParticipantFilter = <distance in feet>                     [optional]-- default: 999999. If using a pace plane, pilots will only be added to the list if they are within this range of the pace before drop-in.
--                                    IlluminationOn = <true or false whether you want lighting at night> [optional]-- default: true. If true, the illum. flares will appear over all the gates plus any additional illumination trigger zones
--									  IlluminationStartTime = <time in seconds after midnight>            [optional]-- default: 64800 (06:00 PM)  
--									  IlluminationStopTime = <time in seconds after midnight>             [optional]-- default: 21600 (06:00 AM). Flares are respawned every 4 minutes from start time until stop time.
--									  IlluminationBrightness = <value 1 to 1000000>                       [optional]-- default: 10000   
--                                    IlluminationAGL = <Elevation AGL in feet where they spawn>          [optional]-- default: 2600
--                                    IlluminationRespawnTimer = <seconds until respawn>                  [optional]-- default: 240 Illum. flares last for 4 minutes before the burn out.
--                                                                                                                  --
--   2. Once     --> Time more(1) --> Do Script File                                                                --
--                                    mist_4_5_126.lua (or later)                                                   --
--                                                                                                                  --
--   3. Once     --> Time more(2) --> Do Script File                                                                --
--                                    AirRaceScript4.lua (or whatever you named this script file)                   --
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
--                       Note: General-purpose flags are provided in this script which the user can use in          --
--                             the .miz triggers for whatever purposes during group races. Two are named:           --
--                              GroupRaceStarted, and GroupRaceFinished.  Another is named FinishLineCrossed,       --
--                              and the others are Lap1Gate1Reached, Lap1Gate2Reached ... Lap3Gate15Reached, etc.   --
--                              All can either be 0 or 1 (In the .miz: false or true. off or on.)                   --                                    
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
	PlayerObject = nil,
	UnitID = 0,
    AircraftType = '', --string. "A-10C, "KA-50", etc.
	CurrentGateNumber = 0,
	StartTime = 0,
	Penalty = 0,
	Bonus = 0,
	HitPylon = 0,
    MissedGates = 0,
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
	ResultsDisplayed = false, --flag to toggle display at end of race
	--ScheduledForRemoval = false
}

-----------------------------------------------------------------------------------------
-- Player Constructor
-- Parameter playerUnit: A unit from a Mist Unit Table representing a single aircraft
--                       or helicopters
--
function Player:New(playerUnit)
	local unitName = playerUnit:getName() --string. unit name from the mission editor
	local playerName = ''

	if playerUnit:getPlayerName() then
		playerName = playerUnit:getPlayerName() --string. player name of human
	else
		playerName = playerUnit:getName() --string. player name of AI unit
	end

	local obj = {
		Name = playerName,
		Unit = Unit.getByName(unitName),
		UnitName = unitName,
		PlayerObject = playerUnit,
		UnitID = Unit.getID(Unit.getByName(unitName)),
        AircraftType = playerUnit:getTypeName(), --string. "A-10C, "KA-50", etc.
		CurrentGateNumber = 0,
		StartTime = 0,
		Penalty = 0,
		Bonus = 0,
		HitPylon = 0,
        MissedGates = 0,
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
		ResultsDisplayed = false, --flag to toggle display at end of race
		--ScheduledForRemoval = false
	}
	setmetatable(obj, { __index = Player })

	return obj
end
-----------------------------------------------------------------------------------------
GroupStartTime = 0 --initialize this variable to 0, it will be set to the time of the first player passing through gate-1 if GroupRace is true
PaceDropTime = 0 --initialize this variable to 0, it will be set to the time when the pace drops in, if there is a pace
GroupTimerStarted = false --flag to indicate whether the group timer has been started
GroupWinnerCrossedFinishLine = false --flag to indicate if the winner has crossed the finish line (group races only)
-----------------------------------------------------------------------------------------
-- Start the timer for the current player
--
function Player:StartTimer()
	env.info(string.format("running StartTimer() function for player %s", self.Name))
	if not self.Started then

		--this if-statement decides how to set the player's start time
		if not race.GroupRace then --(if this is an individual race where everyone has their own clock, then...)
		    self.StartTime = timer.getTime()
			if #race.FireworksZones > 0 then shootFireworks(race.FireworksZones) end
			env.info(string.format("Individual timer started for player %s. Start time: %d", self.Name, self.StartTime))
		else  --(if this is a group race where everyone shares the same clock start time, then...)
			if not GroupTimerStarted then --this player is the first one to pass through gate-1, so start the group timer and set the player's start time to the group start time
				GroupStartTime = timer.getTime()
				self.StartTime = GroupStartTime
				GroupTimerStarted = true
				trigger.action.setUserFlag("GroupRaceStarted", 1) --optional flag to be used in the .miz for whatever purpose 
				trigger.action.setUserFlag("GroupRaceFinished", 0) --optional flag to be used in the .miz for whatever purpose
                trigger.action.setUserFlag("Lap1Gate1Reached", 1) --optional flag to be used in the .miz for whatever purpose                  
				trigger.action.setUserFlag("PaceDrop", 0) -- reset this flag
				if #race.FireworksZones > 0 then shootFireworks(race.FireworksZones) end
				env.info(string.format("Group timer started by player %s. Group start time: %d", self.Name, GroupStartTime))
			else --the group timer has already been started by a previous player, so set this player's start time to the group start time
				self.StartTime = GroupStartTime
				env.info(string.format("Player %s's start time set to group start time: %d", self.Name, self.StartTime))
			end
		end

        --reset player parameters to default
        self.Penalty = 0
		self.Bonus = 0
		self.HitPylon = 0
        self.MissedGates = 0
		self.TotalTime = 0
		self.IntermediateTimes = {{}}
		self.DNF = false
		self.PylonFlag = false
		self.Started = true
		self.Finished = false
		self.Warnings = {}
		self.CurrentLapNumber = 1
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
--                       e.g. for "gate-12" this is 12
--
function Course:AddGate(gateNumber)
	local gateName = string.format("gate-%d", gateNumber)
	local triggerZone = trigger.misc.getZone(gateName)
	if triggerZone then
		table.insert(self.Gates, gateName)
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
	GateHeight = 300 * .3048, --convert to m
	HorizontalGates = {1},
	VerticalGates = {},
    RaceZoneCeiling = 99999 * .3048, --convert to m
	StartSpeedLimit = 999 * 1.852, --convert to km/h
	BonusGateHeight = 15 * .3048, --convert to m
	BonusGates = {},
    BonusTime = 1,
	PenaltyTimeMissedGate = 5,
	PenaltyTimePylonHit = 3,
	PenaltyTimeAboveGateHeight = 2,
	PenaltyTimeHorizontalGate = 2,
	PenaltyTimeVerticalGate = 2,
	NumberMissedGatesDNF = 999,
	NumberPylonHitsDNF = 999,
	MessageLogged = false,
	NumberLaps = 0,
	GroupRace = false,
	GroupRaceParticipantFilter = 999999 * .3048, --convert to meters
    GroupRaceTimeout = 120 * 60, --convert to seconds
	IlluminationOn = true,
	IlluminationStartTime = 64800,
	IlluminationStopTime = 21600,
	IlluminationBrightness = 10000,
	IlluminationAGL = 2600* .3048, --convert to meters
	FireworksZones = {},
	GroupCurrentRankings = {},
}
-----------------------------------------------------------------------------------------
-- Airrace Constructor
-- Parameter triggerZoneNames: A table containing the names of one or more trigger zones
--                             covering the entire race course
-- Parameter course          : A reference to the Course object containing all the gates
--
function Airrace:New(triggerZoneNames, triggerZonePylonNames, course, gateHeight, horizontalGates, verticalGates, raceZoneCeiling, 
						startSpeedLimit, bonusGateHeight, bonusGates, bonusTime, penaltyTimeMissedGate, penaltyTimePylonHit, penaltyTimeAboveGateHeight, 
						penaltyTimeHorizontalGate, penaltyTimeVerticalGate,	numberMissedGatesDNF, numberPylonHitsDNF, numberLaps, groupRace, 
						paceUnitName, fastestIntermediates, participantFilter, groupRaceTimeout, 
						illuminationOn, illuminationStartTime, illuminationStopTime, illuminationBrightness, illuminationAGL, fireworksZones)
	local obj = {
		RaceZones = triggerZoneNames,
		PylonZones = triggerZonePylonNames,
		Course = course,
		Players = {},
		FastestTime = 0,
		FastestPlayer = '',
		FastestIntermediates = fastestIntermediates,
		GateHeight = gateHeight,
		HorizontalGates = horizontalGates or {1},
		VerticalGates = verticalGates or {},
        RaceZoneCeiling = raceZoneCeiling,
		BonusGateHeight = bonusGateHeight,
		BonusGates = bonusGates,
        BonusTime = bonusTime,
		PenaltyTimeMissedGate = penaltyTimeMissedGate,
		PenaltyTimePylonHit = penaltyTimePylonHit,
		PenaltyTimeAboveGateHeight = penaltyTimeAboveGateHeight,
		PenaltyTimeHorizontalGate = penaltyTimeHorizontalGate,
		PenaltyTimeVerticalGate = penaltyTimeVerticalGate,
		NumberMissedGatesDNF = numberMissedGatesDNF,
		NumberPylonHitsDNF = numberPylonHitsDNF,
		StartSpeedLimit = startSpeedLimit,
		NumberLaps = numberLaps,
		GroupRace = groupRace,
		PaceUnitName = paceUnitName,
		GroupRaceParticipantFilter = participantFilter,
        GroupRaceTimeout = groupRaceTimeout,
		IlluminationOn = illuminationOn,
		IlluminationStartTime = illuminationStartTime,
		IlluminationStopTime = illuminationStopTime,
		IlluminationBrightness = illuminationBrightness,
		IlluminationAGL = illuminationAGL,
		FireworksZones = fireworksZones,
		GroupCurrentRankings = {},
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
				--env.info(string.format("Unit %s is in the race zone", unit:getPlayerName()))
				if unit:getLife() > 1 and unit:getPosition().p.y <= self.RaceZoneCeiling then	-- Only check for alive units below the racezone ceiling
					playerExists = false
					if #self.Players > 0 then
						for playerIndex, player in ipairs(self.Players) do				
							local unitName = unit:getPlayerName()		
							if player.Name == unitName then
								playerExists = true
								break
							end
						end
					end					
					if not playerExists then
						--Check if the unit is airborne.  This is to prevent players from being added and shown on the player list... 
						--...if they are sitting on the ground, which can happen if the airfield is inside the race zone.
						local airborne = unit:inAir()
						if airborne == true then
							--we also want to check the distance to the pace plane in group races
							if self.GroupRace == true and self.PaceUnitName ~= nil then
								--get pace plane position
								local pos = Unit.getByName(self.PaceUnitName):getPosition().p
								local pacePos = { 
								x = pos["x"], 
								y = pos["y"], 
								z = pos["z"] 
								}
								--get player position
								local pos = unit:getPosition().p
								local playerPos = { 
								x = pos["x"], --N/S position in meters
								y = pos["y"], --altitude in meters
								z = pos["z"]  --E/W position in meters
								} 							
								local distToPace = math.sqrt((playerPos.x-pacePos.x)^2 + (playerPos.y-pacePos.y)^2 + (playerPos.z-pacePos.z)^2) --meters
								if distToPace <= self.GroupRaceParticipantFilter then
									table.insert(self.Players, Player:New(unit))
                                    env.info(string.format("Player %s in a %s added to player list", unit:getPlayerName() or unit:getName(), unit:getTypeName()))
								end
							else								
								table.insert(self.Players, Player:New(unit))
                                env.info(string.format("Player %s in a %s added to player list", unit:getPlayerName() or unit:getName(), unit:getTypeName()))
							end							
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

			if player.PlayerObject:isExist() and player.PlayerObject:getLife() > 1 and player.PlayerObject:inAir() then -- check if the player from the race list is still alive and airborne
				for unitIndex, unit in ipairs(unitsInZone) do					
					
					if unit:getLife() > 1 and unit:inAir() then -- Only check for match with alive and airborne units detected in the racezone
						local unitName = ''
						if unit:getPlayerName() then
							unitName = unit:getPlayerName()
						else
							unitName = unit:getName()
						end
						if player.Name == unitName and unit:getPosition().p.y <= self.RaceZoneCeiling then
							playerExists = true
							break
						end
					end
				end
			else
				env.info(string.format("%s is being removed from the player list because not alive or airborne", player.Name))
			end

			if not playerExists then
				table.remove(self.Players, playerIndex)
				env.info(string.format("%s removed from player list", player.Name))
			end
		end
	end
end

-----------------------------------------------------------------------------------------
-- Remove a player from a group race
-- function Airrace:removePlayerFromGroupRace(player, reason)
-- 	env.info("Attempting to remove" .. player.Name .. " from the group race list. Reason: " .. reason)
-- 	if self.GroupRace then
-- 		for racerIndex, racer in ipairs(self.Players) do
-- 			if racer.Name == player.Name then
-- 				table.remove(self.Players, racerIndex)
-- 				env.info(player.Name .. " successfully removed from the player list")
-- 				break
-- 			end
-- 		end	
-- 	end
-- end
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
				player.Penalty = player.Penalty + self.PenaltyTimePylonHit
				player.HitPylon = player.HitPylon + 1
				player.PylonFlag = true
				env.info(string.format("Player %s hit a pylon (%d)", player.Name, player.HitPylon))
			end
			if player.HitPylon >= self.NumberPylonHitsDNF then
				player.DNF = true
				player.StatusText = string.format("DNF! | Too many pylons hit")
				env.info(string.format("Player %s hit too many pylons. DNF!", player.Name))
				--local reason = "Too many pylon hits"
				--mist.scheduleFunction(function() self:removePlayerFromGroupRace(player, reason) end, {}, timer.getTime()+10)
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
		warnPlayer(string.format("Flying too high! Altitude = %d feet | Penalty: %d sec.", playerAgl * 3.28, self.PenaltyTimeAboveGateHeight), player)
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
	if speed * 3.6 <= self.StartSpeedLimit then
		result = true
	else
		result = false
		warnPlayer(string.format("EXCEEDING START SPEED LIMIT of %d kts!! speed = %s kts", self.StartSpeedLimit * .54, speed * 3.6 * .54), player)
	end
	return result
end
-----------------------------------------------------------------------------------------
---Check the player's roll angle for wings level or knife edge requirements at gate
function Airrace:evaluateRollAngle(gateNumber, player)
	--check for wings level requirement
	for i = 1 , #self.HorizontalGates do
		if self.HorizontalGates[i] == gateNumber then
			local result = true
			local myUnit = Unit.getByName(player.UnitName)
			local roll = 180 * mist.getRoll(myUnit) / math.pi --degreees
			if roll >= -10 and roll <= 10 then
				result = true
			else
				result = false
				warnPlayer(string.format("Wings not level! Roll = %d deg. | Penalty: %d sec.", roll, self.PenaltyTimeHorizontalGate), player)
			end

			if result == false then
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player.Penalty = player.Penalty + self.PenaltyTimeHorizontalGate
			end
			break
		end
	end
	--check for knife edge requirement
	for i = 1 , #self.VerticalGates do
		if self.VerticalGates[i] == gateNumber then
			local result = true
			local myUnit = Unit.getByName(player.UnitName)
			local roll = 180 * mist.getRoll(myUnit) / math.pi --degreees
			if (roll >= 80 and roll <= 100) or (roll >= -100 and roll <= -80) or (roll >= 260 and roll <= 280) then
				result = true
			else
				result = false
				warnPlayer(string.format("Wings not vertical! Roll = %d deg. | Penalty: %d sec.", roll, self.PenaltyTimeVerticalGate), player)
			end
			if result == false then
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player.Penalty = player.Penalty + self.PenaltyTimeVerticalGate
			end
			break
		end
	end
end
-----------------------------------------------------------------------------------------
-- Illumination flares for night racing
function Airrace:NightRaceIllumination()
	local missionTime = timer.getAbsTime()
	if missionTime >= self.IlluminationStartTime or missionTime <= self.IlluminationStopTime then
		for gate = 1, #self.Course.Gates do
			local gateZoneName = string.format("gate-%d", gate)
			local gateZoneInfo = trigger.misc.getZone(gateZoneName)
			if gateZoneInfo then --protection against a missing zone number
				local gateZoneVec3 = gateZoneInfo.point
				local terrainElevation = land.getHeight({x = gateZoneVec3.x, y = gateZoneVec3.z})
				local illumLocation = {x=gateZoneVec3.x, y=terrainElevation + self.IlluminationAGL, z=gateZoneVec3.z}
				trigger.action.illuminationBomb(illumLocation, self.IlluminationBrightness)
			end
		end
	
		if IlluminationNumberZones > 0 then
			for zone = 1, IlluminationNumberZones do
				local illumZoneName = string.format("illum-%d", zone)
				local illumZoneInfo = trigger.misc.getZone(illumZoneName)
				if illumZoneInfo then --protection against a missing zone number
					local illumZoneVec3 = illumZoneInfo.point
					local terrainElevation = land.getHeight({x = illumZoneVec3.x, y = illumZoneVec3.z})
					local illumLocation = {x=illumZoneVec3.x, y=terrainElevation + self.IlluminationAGL, z=illumZoneVec3.z}
					trigger.action.illuminationBomb(illumLocation, self.IlluminationBrightness)
				end
			end
		end
	end
end 
-----------------------------------------------------------------------------------------
-- Smoke markers
function PopSmokeMarkers()
    local smokeColorChoices = {Green=NumberGreenSmokeZones, 
                                 Red=NumberRedSmokeZones, 
                               White=NumberWhiteSmokeZones, 
                              Orange=NumberOrangeSmokeZones,
                                Blue=NumberBlueSmokeZones}
    for color, numZones in pairs(smokeColorChoices) do
        if numZones > 0 then
            for zone = 1, numZones do
                local smokeZoneName = string.format("%s smoke-%d", color, zone)
                local smokeZoneInfo = trigger.misc.getZone(smokeZoneName)
                if smokeZoneInfo then --protection against a missing zone number
                    local smokeZoneVec3 = smokeZoneInfo.point
                    local terrainElevation = land.getHeight({x = smokeZoneVec3.x, y = smokeZoneVec3.z})
                    local smokeLocation = {x=smokeZoneVec3.x, y=terrainElevation, z=smokeZoneVec3.z}
                    trigger.action.smoke(smokeLocation, color)
                end
            end
        end
    end
    timer.scheduleFunction(PopSmokeMarkers, {}, timer.getTime()+300) --refresh the smoke in another 5 minutes
end
-----------------------------------------------------------------------------------------
-- Collect names and times at each gate during a gorup race, to be sorted later
function Airrace:AddToGroupCurrentRankings(name, lap, gate, time, aircraftType)
	while lap > #self.GroupCurrentRankings do
		table.insert(self.GroupCurrentRankings, {})
	end
	while gate > #self.GroupCurrentRankings[lap] do
		table.insert(self.GroupCurrentRankings[lap], {})
	end
	self.GroupCurrentRankings[lap][gate][name] = {time = time, aircraftType =  aircraftType}
end
-----------------------------------------------------------------------------------------
-- sort the names for display in a group race as follows:
  -- sorted top to bottom:
  -- 1) highest lap, then by...
  -- 2) highest gate, then by..
  -- 3) lowest time
function Airrace:SortRanks(currentRaceData)
	env.info("Sorting...")
	local added = {}    -- track which players already ranked
	local bucket = {}   -- a temporary holding table that will be sorted
	local numLaps = 0   -- initialize the variable as a local
	
	--the script always assumes you are on lap 1 when you start, even on point A to point B (zero lap) races
	if self.NumberLaps == 0 then
		numLaps = 1
	else
		numLaps = self.NumberLaps
	end

	-- search backwards through the table for efficiency
	for lap = numLaps, 1, -1 do
		--local lapData = currentRaceData[lap]
		for gate = #self.Course.Gates, 1, -1 do
			
			-- collect all players who have a time at this lap/gate
			for name, data in pairs(currentRaceData[lap][gate]) do
				if not added[name] then
					added[name] = true
					table.insert(bucket, {name=name, lap=lap, gate=gate, time=data.time, aircraftType=data.aircraftType})
					table.sort(bucket, function(a,b) return a.time < b.time end) -- sort this bucket by lowest time
				end
			end
		end
	end	
	
	return bucket
end
--example format of bucket table sorted top to bottom, first by highest lapNum, then by highest gateNum, then by lowest timeVal
--bucket={
--       {name = "name1", gate = gateNum, lap = lapNum, time = timeVal, aircraftType = "A-10C"}
--       {name = "name2", gate = gateNum, lap = lapNum, time = timeVal, aircraftType = "KA-50"}
--       {name = "name3", gate = gateNum, lap = lapNum, time = timeVal, aircraftType = "F4U-1D"}
-- }
-----------------------------------------------------------------------------------------
-- Format aircraft type name into a better formatted string
function formatAircraftType(aircraftType)
    local aircraftName = aircraftType
    if aircraftType = "Bf-109k-4"          then aircraftName = "Bf-109"     return end
    if aircraftType = "F4U-1D"             then aircraftName = "Corsair"    return end
    if aircraftType = "FW-190A8"           then aircraftName = "Anton"      return end`
    if aircraftType = "F4U-190D9"          then aircraftName = "Dora"       return end
    if aircraftType = "Mig-21Bis"          then aircraftName = "Mig-21"     return end
    if aircraftType = "SpitfireLFMkIXCW"   then aircraftName = "Spitfire"   return end
    if aircraftType = "FA-18C_hornet"      then aircraftName = "Hornet"     return end
    if aircraftType = "CH-47D"             then aircraftName = "Chinook"    return end
    if aircraftType = "Ka-27"              then aircraftName = "Helix"      return end
    return aircraftName
end
-----------------------------------------------------------------------------------------
-- Only for group races with pace planes:
-- Check line-up of the player with the pace plane.
-- Assign penalty if the player is ahead of the pace plane at time of drop in.
function Airrace:CheckLineupWithPace(player)
	if player.PlayerObject:isExist() then
		return --don't bother continuing if player doesn't exist.  Happens if there's a disconnect or plane crash prior to drop in.
	end

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
		player.StatusText = "Not eligible for race | Bad pace position"
		warnPlayer(string.format("%s, STAY CLEAR of the course area immediately!", player.Name), player)
		player.DNF = true
		self:AddToGroupCurrentRankings(player.Name, 1, 1, 0, player.AircraftType) -- fixed entry with time=0 at first gate, for comparison to other racers
	else
		player.StatusText = "Cleared in. Go-Go-Go!"
		env.info(string.format("Player %s is eligible for the current group race.", player.Name))
		--Perform lineup checks:
		if playerNewX > 1 then --allow a 1 meter buffer
			local penaltyIncrement = 2 + math.floor(playerNewX/20) --add 2 seconds plus an additional second for every 20 meters ahead of the pace plane
			player.Penalty = player.Penalty + penaltyIncrement
			env.info(string.format("%s was %dm ahead of the Pace. Penalty: %d sec.", player.Name, math.floor(playerNewX), penaltyIncrement))
			warnPlayer(string.format("%s was %dm ahead of the Pace.  | Penalty: %d sec.", player.Name, math.floor(playerNewX), penaltyIncrement), player)									
		end

		if playerPos.y > 2 then 	
			local penaltyIncrement = 2 + math.floor(playerPos.y/5) --add 2 seconds plus an additional second for every 20 meters above the pace plane
			player.Penalty = player.Penalty + penaltyIncrement
			env.info(string.format("%s was %dm above the Pace. Penalty: %d sec.", player.Name, math.floor(playerPos.y), penaltyIncrement))
			warnPlayer(string.format("%s was %dm above the Pace.     | Penalty: %d sec.", player.Name, math.floor(playerPos.y), penaltyIncrement), player)
		end
	end

	player.RaceEligible = true --used for debug and testing. take this out after testing.  It is used to force eligibility when the test plane is not close enough to the pace plane.

	player.PacePositionEvaluated = true --set this flag to true so that the player won't be evaluated again until next race	
end
-----------------------------------------------------------------------------------------
-- Update the status and timer for the given player
-- Parameter player: Reference to a player in the active player List
--
function Airrace:UpdatePlayerStatus(player)
	if self.GroupRace == false or (self.GroupRace == true and player.DNF == false) then
		local gateNumber = self:GetGateNumberForPlayer(player) --this gives the gate number the player has been detected in, but player.CurrentGateNumber has not yet been incremeted up to match this
		local timeNow = timer.getTime()

-- ignore repeated gate detection, or pre-race period, or if racer not eligible for group race
		if gateNumber <= 0 or ( gateNumber == player.CurrentGateNumber and ( gateNumber ~= 1 or player.Started == true ) ) or not player.RaceEligible then
			if not player.RaceEligible and GroupTimerStarted then
				player.PacePositionEvaluated = false --reset this flag for ineligible racers so that they can be evaluated again for the next race
			end
			return
		end

--check if this is the first lap, or starting a new lap...
		if (gateNumber == 1 and player.CurrentLapNumber == 1 and player.Started == false) or player.DNF ==true then --player.DNF can only be true here if it's not a group race. Here, we allow the DNF player to come back around and restart the race.
			--this is the first lap of the race
			player:StartTimer() -- Player is passing gate 1 on lap 1, start timer		
			local gateSpeedOk = self:CheckGateSpeedForPlayer(player)
			local unitspeed = Unit.getByName(player.UnitName):getVelocity()
			local speedKnots = math.sqrt(unitspeed.x^2 + unitspeed.y^2 + unitspeed.z^2) * 1.94
			if gateSpeedOk == false then
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player:StopTimer()
				player.StatusText = string.format("DNF! | Exceeded start speed limit | Speed: %d kts", speedKnots)
				player.DNF = true
				return
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
					if self.GroupRace == true then
						player.StatusText = string.format("Speed: %d kts (%s%d kts) | Time: %s", speedKnots, sign, math.abs(difference), formatTime(timeNow - GroupStartTime))
					else
						player.StatusText = string.format("Speed: %d kts | Time: %s", speedKnots, formatTime(0))
					end
				else --the race has not yet been completed in the past...
					if self.GroupRace == true then
						player.StatusText = string.format("Speed: %d kts | Time: %s", speedKnots, formatTime(timeNow - GroupStartTime))
					else
						player.StatusText = string.format("Speed: %d kts | Time: %s", speedKnots, formatTime(0))
					end
				end			
			end
			trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')
			local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)	
			if gateAltitudeOk == false then
				trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
				player.Penalty = player.Penalty + self.PenaltyTimeAboveGateHeight
			end
			self:evaluateRollAngle(gateNumber, player)		
			player.CurrentGateNumber = gateNumber --this will always be 1 inside this if-statement
			player.PylonFlag = false
			if self.GroupRace == true then 
				self:AddToGroupCurrentRankings(player.Name, player.CurrentLapNumber, player.CurrentGateNumber, timeNow - GroupStartTime, player.AircraftType)
			end
			return
		elseif gateNumber == 1 then
			-- Player is starting a new lap, so increase lap number
			player.CurrentLapNumber = player.CurrentLapNumber + 1		
		end

-- define what to do if player didn't go through the expected gate...
		if player.DNF == false then
			if gateNumber ~= player.CurrentGateNumber + 1 and not (player.CurrentGateNumber == #self.Course.Gates and gateNumber == 1) then 					
				if player.CurrentGateNumber == 0 and not player.Finished and player.CurrentLapNumber == 1 then
					-- Player passed unexpected gate at start of race
					player.StatusText = "Wrong start gate! Go back to Gate 1 to start."
					env.info(string.format("Player %s did not enter the course at Gate 1", player.Name))
					return
				elseif not player.Finished then
					-- Player has missed one or more gates
					local missedGates = 0 -- define this as a local counter with default value of 0
					if gateNumber > player.CurrentGateNumber + 1 then
						missedGates = gateNumber - (player.CurrentGateNumber + 1)
						player.MissedGates = player.MissedGates + missedGates
						if player.MissedGates >= self.NumberMissedGatesDNF then
							player.DNF = true
							player.StatusText = string.format("DNF! | Too many missed gates")
							env.info(string.format("Player %s missed %d gate(s). DNF!", player.Name, player.MissedGates))
							--local reason = "Too many missed gates"
							--mist.scheduleFunction(function() self:removePlayerFromGroupRace(player, reason) end, {}, timeNow + 10)
							return					
						else
							if missedGates == 1 then
								warnPlayer(string.format("Missed gate %d | Penalty: %d sec.", player.CurrentGateNumber + 1, self.PenaltyTimeMissedGate), player)
								env.info(string.format("Player %s missed gate %d", player.Name, player.CurrentGateNumber + 1))
							else
								warnPlayer(string.format("Missed gates %d to %d | Penalty: %d sec.", player.CurrentGateNumber + 1, gateNumber - 1, self.PenaltyTimeMissedGate * missedGates), player)
								env.info(string.format("Player %s missed gates %d to %d", player.Name, player.CurrentGateNumber + 1, gateNumber - 1))
							end
						end
					elseif gateNumber < player.CurrentGateNumber then --Either going backwards or on a new lap with a lower gate number.  
																	--We can't do much about going backwards, this is a sacrifice we make 
																	--from the older version in order to add the ability to do multiple laps.
						missedGates = #self.Course.Gates - (player.CurrentGateNumber + 1) + gateNumber
						player.MissedGates = player.MissedGates + missedGates
						if player.MissedGates >= self.NumberMissedGatesDNF then
							player.DNF = true
							player.StatusText = string.format("DNF! | Too many missed gates!")
							env.info(string.format("Player %s missed %d gate(s). DNF!", player.Name, player.MissedGates))
							--local reason = "Too many missed gates"
							--mist.scheduleFunction(function() self:removePlayerFromGroupRace(player, reason) end, {}, timeNow + 10)
							return
						else
							if missedGates == 1 then
								warnPlayer(string.format("Missed gate %d | Penalty: %d sec.", player.CurrentGateNumber + 1 - #self.Course.Gates, self.PenaltyTimeMissedGate), player) --this should always be gate 1 if only 1 gate was missed, but we'll calculate it anyway.
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
								warnPlayer(string.format("Missed gates %d to %d | Penalty: %d sec.", firstMissedGate, lastMissedGate, self.PenaltyTimeMissedGate * missedGates), player)
								env.info(string.format("Player %s missed gates %d to %d", player.Name, firstMissedGate, lastMissedGate))
							end
						end
						-- Player has started a new lap, so increase lap number
						player.CurrentLapNumber = player.CurrentLapNumber + 1	
					end
					player.Penalty = player.Penalty + (self.PenaltyTimeMissedGate * missedGates)			
					if gateNumber == 1 then
						player.CurrentGateNumber = #self.Course.Gates -- roll currentGateNumber back to the last gate in the course
					else
						player.CurrentGateNumber = gateNumber - 1 -- roll currentGateNumber back one gate			
					end
					if self.GroupRace == true then
						self:AddToGroupCurrentRankings(player.Name, player.CurrentLapNumber, player.CurrentGateNumber, timeNow - GroupStartTime, player.AircraftType)
					end
				end
				return	
			end

-- Player is passing the final gate, stop timer
			if (gateNumber == #self.Course.Gates and self.NumberLaps == 0) or (gateNumber == 1 and player.CurrentLapNumber > self.NumberLaps) then
				local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)
				self:evaluateRollAngle(gateNumber, player)
				player.PylonFlag = false
				local bonusGateAltitudeOk = self:CheckBonusAltitudeForPlayer(player)
				for i = 1, #self.BonusGates do
					if self.BonusGates[i] == gateNumber then
						if bonusGateAltitudeOk == true then
							player.Bonus = player.Bonus + self.BonusTime
							warnPlayer(string.format("Low alt. bonus: -%d sec", self.BonusTime), player)
						end
					end
				end
				if gateAltitudeOk == false then
					trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
					player.Penalty = player.Penalty + self.PenaltyTimeAboveGateHeight
				end
				player.PylonFlag = false
				player:StopTimer()
				if #self.BonusGates > 0 then
					player.StatusText = string.format("Finished | Time: %s + Penalty: %d sec. - Bonus: %d sec.\n          Total time: %s ", formatTime(player.TotalTime), player.Penalty, player.Bonus, formatTime(player.TotalTime + player.Penalty - player.Bonus))
					env.info(string.format("%s finished the course. Race time: %s. Penalty: %d. Bonus: %d. Total time: %s", player.Name, formatTime(player.TotalTime), player.Penalty, player.Bonus, formatTime(player.TotalTime + player.Penalty - player.Bonus)))
				else
					player.StatusText = string.format("Finished | Time: %s + Penalty: %d sec.\n          Total time: %s ", formatTime(player.TotalTime), player.Penalty, formatTime(player.TotalTime + player.Penalty))
					env.info(string.format("%s finished the course. Race time: %s. Penalty: %d. Total time: %s", player.Name, formatTime(player.TotalTime), player.Penalty, formatTime(player.TotalTime + player.Penalty)))
				end        
				trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')
				player.CurrentGateNumber = gateNumber
				if self.FastestTime == 0 or self.FastestTime > player.TotalTime + player.Penalty - player.Bonus then
					self.FastestTime = player.TotalTime + player.Penalty - player.Bonus
					self.FastestPlayer = player.Name
					player.StatusText = string.format("%s - Fastest time!", player.StatusText)
					self.FastestIntermediates = player.IntermediateTimes
					env.info(string.format("%s achieved new time record: %s", player.Name, formatTime(self.FastestTime)))
				else
					player.StatusText = string.format("%s (+%s)", player.StatusText, formatTime(player.TotalTime + player.Penalty  - player.Bonus - self.FastestTime))
					env.info(string.format("%s +%s seconds behind best time", player.Name, formatTime(player.TotalTime + player.Penalty  - player.Bonus - self.FastestTime)))
				end		

				--fireworks!
				if #self.FireworksZones > 0 then shootFireworks(self.FireworksZones) end		
				
				--set the general purpose flags used for group races...
				if self.GroupRace == true then
					if GroupWinnerCrossedFinishLine == false then
						GroupWinnerCrossedFinishLine = true
						trigger.action.setUserFlag("FinishLineCrossed", 1)
					end
					local gateFlagName = string.format("Lap%dGate%dReached", player.CurrentLapNumber, gateNumber)
					local gateFlagValue = trigger.misc.getUserFlag(gateFlagName)
					if not gateFlagValue or gateFlagValue == 0 then
						trigger.action.setUserFlag(gateFlagName, 1) --optional flag to be used in the .miz for whatever purpose 
					end
				end			
				if self.GroupRace == true then
					self:AddToGroupCurrentRankings(player.Name, player.CurrentLapNumber, player.CurrentGateNumber, player.TotalTime + player.Penalty - player.Bonus, player.AircraftType)
				end
				--local reason = "Completed course"
				--mist.scheduleFunction(function() self:removePlayerFromGroupRace(player, reason) end, {}, timeNow + 15)
				return
			end

--If none of the checks from above pass, then you'll end up here...

-- Player is passing intermediate gate, set intermediate time
			if gateNumber ~= player.CurrentGateNumber then --prevents repeated gate detection
				local gateAltitudeOk = self:CheckGateAltitudeForPlayer(player)
				local intermediate = player:GetIntermediateTime(player.CurrentLapNumber, gateNumber)
				trigger.action.outSoundForUnit(player.UnitID, 'pik.ogg')
				player.StatusText = string.format("Speed: %d kts | Time: %s", player.GateSpeed, formatTime(intermediate))
				env.info(string.format("%s reached Lap %d Gate %d", player.Name, player.CurrentLapNumber, gateNumber))
				self:evaluateRollAngle(gateNumber, player)
				player.PylonFlag = false
				local bonusGateAltitudeOk = self:CheckBonusAltitudeForPlayer(player)
				for i = 1, #self.BonusGates do
					if self.BonusGates[i] == gateNumber then
						if bonusGateAltitudeOk == true then
							player.Bonus = player.Bonus + self.BonusTime
							warnPlayer(string.format("Low alt. bonus -%d sec", self.BonusTime), player)
						end
					end
				end
				if gateAltitudeOk == false then
					trigger.action.outSoundForUnit(player.UnitID, 'penalty.ogg')
					player.Penalty = player.Penalty + self.PenaltyTimeAboveGateHeight
				end
				if self.FastestTime ~= 0 then --indicates that the race has already been completed once in the past, so we'll show a time comparison to the best record time
					local fastestIntermediate = self.FastestIntermediates[player.CurrentLapNumber][gateNumber]
					--there's a chance the best set of intermediates contains a zero time for a gate if that gate was skipped for some reason by the fastest player, so we protect against this and don't show the comparison
					if fastestIntermediate ~= 0 then
						local difference = intermediate - fastestIntermediate
						local sign = "+"
						if difference < 0 then
							sign = "-"
						end
						player.StatusText = string.format("%s (%s%s sec.)", player.StatusText, sign, math.abs(difference))
					end
				end
				player.CurrentGateNumber = gateNumber

				--set the general purpose flags used for group races...
				if self.GroupRace == true  then
					local gateFlagName = string.format("Lap%dGate%dReached", player.CurrentLapNumber, gateNumber)
					local gateFlagValue = trigger.misc.getUserFlag(gateFlagName)
					if not gateFlagValue or gateFlagValue == 0 then
						trigger.action.setUserFlag(gateFlagName, 1) --optional flag to be used in the .miz for whatever purpose
					end
				end

				if self.GroupRace == true then
					self:AddToGroupCurrentRankings(player.Name, player.CurrentLapNumber, player.CurrentGateNumber, timeNow - GroupStartTime, player.AircraftType)
				end
			end
		end
	end
end
-----------------------------------------------------------------------------------------
-- Display all active players on screen, with their current status
--
function Airrace:ListPlayers()
	local timeNow = timer.getTime()
	local text = ""
	--if it's a group race...
	if self.GroupRace == true then
		--if there's a pace plane present...
		if self.PaceUnitName ~= nil  then
			--if the drop-in occured but no one started yet...
			if trigger.misc.getUserFlag("PaceDrop") == 1 and trigger.misc.getUserFlag("GroupRaceStarted") == 0 and trigger.misc.getUserFlag("GroupRaceFinished") == 0 then
				if PaceDropTime == 0 then 
					PaceDropTime = timeNow
				end
				text = "Racers dropping in!"
			--if the race started...	
			elseif trigger.misc.getUserFlag("GroupRaceStarted") == 1 and trigger.misc.getUserFlag("GroupRaceFinished") == 0 then
				text = string.format("Race in progress. Time: %s", formatTime(timeNow-GroupStartTime))
			--if the race finished...
			elseif trigger.misc.getUserFlag("GroupRaceFinished") == 1 then
				text = "Race finished"
			else
				text = string.format("%d racers ready", #self.Players)
			end
		--if there's no pace plane preset...	
		else 
			if trigger.misc.getUserFlag("GroupRaceStarted") == 1 and trigger.misc.getUserFlag("GroupRaceFinished") == 0 then
				text = string.format("Race in progress. Time: %s", formatTime(timeNow-GroupStartTime))
			--if the race finished...
			elseif trigger.misc.getUserFlag("GroupRaceStarted") == 0 and trigger.misc.getUserFlag("GroupRaceFinished") == 1 then
				text = "Race finished"
			else
				text = string.format("%d racers nearby", #self.Players)
			end
		end
	--if not a group race...
	else 
		text = string.format("%d racers in course", #self.Players)
	end
	
	if self.FastestTime > 0 then
		text = string.format("%s - Best time: %s by %s", text, formatTime(self.FastestTime), self.FastestPlayer)
	end
	--text = string.format("%s\n---------------------------------------", text)

	if #self.Players > 0 then		
		if self.GroupRace == true then

			--First, check to make sure there's at least one player still racing in the group race...
			local allPlayersAreFinished = true
			for playerIndex, player in ipairs(self.Players) do
				if player.DNF == false or player.Finished == false then 
					allPlayersAreFinished = false 
				end
			end
			if allPlayersAreFinished == true then
				trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
				trigger.action.setUserFlag("GroupRaceFinished", 1) --optional flag to be used in the .miz for whatever purpose
				env.info("All racers are now DNF or finished the race. Flag GroupRaceFinished = 1")
				mist.scheduleFunction(stopRaceScript, nil, timeNow + 30)
				return
			end		

			--In group races with a pace plane, check the player's line-up with the pace plane at the moment of drop in			
			if self.PaceUnitName ~= nil then
				local paceDroppedIn = trigger.misc.getUserFlag("PaceDrop") -- PaceDrop is a flag that must be set true in the .miz 	
				if paceDroppedIn == 1 then -- 1=true in DCS user flag
					for playerIndex, player in ipairs(self.Players) do	
						if not player.PacePositionEvaluated and not player.Finished == true and player.PlayerObject:isExist() then
							self:CheckLineupWithPace(player)
						end
					end

					--reset the general-purpose gate flags for the upcoming race				
					if trigger.misc.getUserFlag("Lap1Gate1Reached") == 1 then
						local lapNumberCorrection = 0 --initialize
						if self.NumberLaps == 0 then
							lapNumberCorrection = 1
						else 
							lapNumberCorrection = self.NumberLaps
						end
						for lap = 1, lapNumberCorrection do
							for gate = 1, #self.Course.Gates do
								local flagName = string.format("Lap%dGate%dReached", lap, gate)
								trigger.action.setUserFlag(flagName, 0)
							end
						end					
					end
				end
			end

			--check if the group race has timed out...		
			if (((trigger.misc.getUserFlag("GroupRaceStarted") == 1) and (timeNow > GroupStartTime + self.GroupRaceTimeout)) or ((trigger.misc.getUserFlag("PaceDrop") == 1) and (timeNow > PaceDropTime + self.GroupRaceTimeout))) then
				trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
				trigger.action.setUserFlag("GroupRaceFinished", 1) --optional flag to be used in the .miz for whatever purpose 
				env.info("Group race timed out. Flag GroupRaceFinished = 1")
				mist.scheduleFunction(stopRaceScript, nil, timeNow)
				return
			end	
		end

		-- Check if any players are currently flying through a gate, and if so check for pylon hits and update their status
		local playersInGates = self:GetPlayersInGates()
		if #playersInGates > 0 then	
			for playerIndex, player in ipairs(playersInGates) do		
				if self.GroupRace == false or (self.GroupRace == true and player.Finished == false) then
					if player.DNF == false then 
						self:CheckPylonHitForPlayer(player)
					end
					self:UpdatePlayerStatus(player) --we'll check for DNF in the next function. Necessary to restart an individual race.
				end
			end
		end

		-- Now build the text to be displayed to the racers.. (displays are different for group races vs. individual races)

		if self.GroupRace == true and GroupTimerStarted then
		--for group races that have started...
			local rankTable = self:SortRanks(self.GroupCurrentRankings)
			local playerIndex = 0 --initialize
            local highestLapNum = 0 --initialize

			for currentRank, playerData in ipairs(rankTable) do
                if self.NumberLaps > 1 then
                    if playerData.lap > highestLapNum then
                        text = string.format("%s\nLap %d of %d", text, playerData.lap, self.NumberLaps)
                    else
                        text = string.format("%s\nLap %d of %d", text, highestLapNum, self.NumberLaps)                    
                    end
                end
                text = string.format("%s\n---------------------------------------", text)
				text = string.format("%s\n%d. %s (%s)", text, currentRank, playerData.name:sub(1,22), formatAircraftType(playerData.aircraftType))

				--find index position of this player in the Player list...
				for index, player in ipairs(self.Players) do					
					if player.Name == playerData.name then
						if player.CurrentGateNumber > 0 and player.Finished == false then							
							if player.DNF == true then
								text = string.format("%s | %s", text, player.StatusText)
							else
								text = string.format("%s | Pylon %d | %s", text, player.CurrentGateNumber, player.StatusText)
							end
						else --if you haven't begun the race yet...
							text = string.format("%s - %s", text, player.StatusText)
						end

						for messageIdx, message in ipairs(player.Warnings) do
							if message[2] >= timeNow then
								text = text .. "\n     !!! " .. message[1]
							end
						end

						break
					end
				end
			end	

		else --for individual races, or for group races that have not started yet
			for playerIndex, player in ipairs(self.Players) do
                text = string.format("%s\n---------------------------------------", text)
				text = string.format("%s\n%s (%s)", text, player.Name:sub(1,22), player.AircraftType)
				if player.CurrentGateNumber > 0 and player.Finished == false then
					if player.DNF == true then
						text = string.format("%s | %s", text, player.StatusText)
					elseif self.NumberLaps > 1 then
						text = string.format("%s | Lap %d Pylon %d | %s", text, player.CurrentLapNumber, player.CurrentGateNumber, player.StatusText)
					else
						text = string.format("%s | Pylon %d | %s", text, player.CurrentGateNumber, player.StatusText)
					end
				else
					text = string.format("%s - %s", text, player.StatusText)
				end

				for messageIdx, message in ipairs(player.Warnings) do
					if message[2] >= timeNow then
						text = text .. "\n     !!! " .. message[1]
					end
				end
				
				--if self.GroupRace == true and player.RaceEligible == false and player.ScheduledForRemoval == false then
					--local reason = "Not eligible for upcoming race"
					--mist.scheduleFunction(function() self:removePlayerFromGroupRace(player, reason) end, {}, timeNow+15)
					--player.ScheduledForRemoval = true
				--end
			end	 			
		end
	
	--check if there are no more players remaining in the group race
	elseif self.GroupRace == true and #self.Players == 0 and (trigger.misc.getUserFlag("GroupRaceStarted") == 1 or trigger.misc.getUserFlag("PaceDrop") == 1) then
		trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
		trigger.action.setUserFlag("GroupRaceFinished", 1) --optional flag to be used in the .miz for whatever purpose
		env.info("No players remaining in the group race. Flag GroupRaceFinished = 1")
		mist.scheduleFunction(stopRaceScript, nil, timeNow+30)
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
-- Periodically refresh illumination flares--
function RefreshIllumination(race)
	race:NightRaceIllumination()
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
function formatTime(seconds)
	return string.format("%02d:%02d:%06.3f", seconds / (60 * 60), seconds / 60 % 60, seconds % 60)
end

-----------------------------------------------------------------------------------------
-- Shoot fireworks in the fireworks-x triggerzones whenever a player crosses the finish line
function shootFireworks(zones)
	for idx, triggerZoneName in ipairs(zones) do 
		local triggerZoneInfo = trigger.misc.getZone(triggerZoneName) --returns a table with two keys: point and radius
		local triggerZoneLocation = triggerZoneInfo.point --vec3 format
		local terrainPos = land.getHeight({x = triggerZoneLocation.x, y = triggerZoneLocation.z})
		triggerZoneLocation.y = terrainPos + 1 -- fireworks originate 1m above ground
		trigger.action.signalFlare(triggerZoneLocation, trigger.flareColor.Red, 0) --last digit is the heading for flare launch . color options: Green, Red, White, Yellow  
		trigger.action.signalFlare(triggerZoneLocation, trigger.flareColor.White, 90)
		trigger.action.signalFlare(triggerZoneLocation, trigger.flareColor.Green, 180)
		trigger.action.signalFlare(triggerZoneLocation, trigger.flareColor.Yellow, 270)
	end
end

-----------------------------------------------------------------------------------------
-- Start the script - This function is only used to start group races. Not needed for individual races
function startRaceScript()
	env.info("Start Airrace script")
	--reinitialize parameters for repeat races
	race.Players = {} 
	race.LastMessage = ''
	race.LastMessageId = 0
	GroupWinnerCrossedFinishLine = false
	trigger.action.setUserFlag("GroupRaceStarted", 0) --optional flag to be used in the .miz for whatever purpose 
	trigger.action.setUserFlag("GroupRaceFinished", 0) --optional flag to be used in the .miz for whatever purpose 
	trigger.action.setUserFlag("FinishLineCrossed", 0) --optional flag to be used in the .miz for whatever purpose 

	--Build an empty table to hold ranking data (names and gate times)
	race.GroupCurrentRankings = {}
	local numLaps = race.NumberLaps
	if numLaps == 0 then numLaps = 1 end
		for lap = 1, numLaps do
		table.insert(race.GroupCurrentRankings, {})
		for gate = 1, #race.Course.Gates do
			table.insert(race.GroupCurrentRankings[lap], {})
		end
	end
	--example format of GroupCurrentRankings table: This just collects the data to be sorted later into the Ranks table
--    GroupCurrentRankings={  
--       {--lap 1
--         {name1={time=time1, aircraftType=aircraftType}, name2={time=time2, aircraftType=aircraftType}}, --gate1
--         {name1={time=time3, aircraftType=aircraftType}}, --gate2
--         {}, --gate3
--         {}, --gate4
--       },
--       {--lap 2
--         {}, --gate1
--         {}, --gate2
--         {}, --gate3
--         {}, --gate4
--       },
--      }

	--run scheduled timers...
	ScheduledFunctionRaceTimer = mist.scheduleFunction(RaceTimer, { race }, timer.getTime(), 0.2)  -- GT: I made each one of these a global var so they could be stopped via scripting if desired, using mist.removeFunction
	ScheduledFunctionNewPlayerTimer = mist.scheduleFunction(NewPlayerTimer, { race }, timer.getTime(), newPlayerCheckInterval)
	ScheduledFunctionRemovePlayerTimer = mist.scheduleFunction(RemovePlayerTimer, { race }, timer.getTime(), removePlayerCheckInterval)
end

-----------------------------------------------------------------------------------------
-- Stop the script
function stopRaceScript()
	env.info("Stop Airrace script")
	
	mist.removeFunction(ScheduledFunctionRaceTimer)
	mist.removeFunction(ScheduledFunctionNewPlayerTimer)
	mist.removeFunction(ScheduledFunctionRemovePlayerTimer)

	--reset flags and variables
	trigger.action.setUserFlag("PaceDrop", 0)
	trigger.action.setUserFlag("GroupRaceStarted", 0)
	trigger.action.setUserFlag("GroupRaceFinished", 0)
	GroupTimerStarted = false
	GroupWinnerCrossedFinishLine = false
	PaceDropTime = 0
end
-----------------------------------------------------------------------------------------
-- Detect crashes, deaths, ejections
local crashHandler = {}
function crashHandler:onEvent(event)
	if #race.Players ==  0 then return end

	local initiator = event.initiator
	if not initiator then return end

	local ok, name = pcall(initiator.getPlayerName, initiator)
    if not ok or not name then return end   -- AI, scenery object, or invalid unit

	local reason = nil

		local playerName = ""		

	if event.id == world.event.S_EVENT_CRASH then
			reason = "Crashed"
	elseif event.id == world.event.S_EVENT_EJECTION then
			reason = "Ejected"	
	elseif event.id == world.event.S_EVENT_DEAD  or event.id == world.event.S_EVENT_PILOT_DEAD then
			reason = "Died"	
	end

	if not reason then return end

	env.info("Player " .. name .. " "  .. reason)

	for _, player in ipairs(race.Players) do					
		if player.Name == name then
			player.DNF = true
			player.StatusText = "DNF! | " ..  reason
			race:AddToGroupCurrentRankings(player.Name, 1, 1, 0, player.AircraftType) -- fixed entry with time=0 at first gate, for comparison to other racers, in case player dies before the first gate
		end
	end
end
-----------------------------------------------------------------------------------------
-- counts the number of desired zones
function countZones(name)
	local exitLoop = false
	local counter = 1
	while exitLoop == false do
		local triggerZone = trigger.misc.getZone(string.format("%s-%d", name, counter))
		if triggerZone then ---999 to protect against infinite loop
			counter = counter + 1
		else
			env.info(string.format("%d %s zones detected", counter-1, name))			
			exitLoop = true --not really necessary since return is on the next line, but extra safety
			return counter-1
		end
	end
end
-----------------------------------------------------------------------------------------
-- Initialize the script
--
function Init()
	local raceZones = {}
	local racePylons = {}
	local horizontalGates = HorizontalGates or {1}
	local verticalGates = VerticalGates or {}
    local raceZoneCeiling = RaceZoneCeiling or 99999
	local course = Course:New()
	race = nil --this is used in the startRaceScript function, so it cannot be a local variable inside the Init function
	local numberLaps = NumberLaps or 0
	newPlayerCheckInterval = NewPlayerCheckInterval or 1 --this is used in the startRaceScript function, so it cannot be a local variable inside the Init function
	removePlayerCheckInterval = RemovePlayerCheckInterval or 30 --this is used in the startRaceScript function, so it cannot be a local variable inside the Init function
	local gateHeight = GateHeight or 300
	local startSpeedLimit = StartSpeedLimit or 999
	local bonusGateHeight = BonusGateHeight or 20
	local bonusGates = BonusGates or {}
    local bonusTime = BonusTime or 1
	local penaltyTimeMissedGate = PenaltyTimeMissedGate or 5
	local penaltyTimePylonHit = PenaltyTimePylonHit or 3
	local penaltyTimeAboveGateHeight = PenaltyTimeAboveGateHeight or 2
	local penaltyTimeHorizontalGate = PenaltyTimeHorizontalGate or 2
	local penaltyTimeVerticalGate = PenaltyTimeVerticalGate or 2
	local numberMissedGatesDNF = NumberMissedGatesDNF or 999
	local numberPylonHitsDNF = NumberPylonHitsDNF or 999
	local groupRace = GroupRace or false
	local paceUnitName = PaceUnitName or nil
	local fastestIntermediates = {{}}
	local participantFilter = GroupRaceParticipantFilter or 99999
    local groupRaceTimeout = GroupRaceTimeout or 120
	local illuminationOn = IlluminationOn or true
	local illuminationStartTime = IlluminationStartTime or 64800
	local illuminationStopTime = IlluminationStopTime or 21600
	local illuminationBrightness = IlluminationBrightness or 10000
	local illuminationAGL = IlluminationAGL or 2600
	local illuminationRespawnTimer = IlluminationRespawnTimer or 240 --seconds
	local fireworksZones = {}

	--count the number of each type of zone
	local numberRaceZones = countZones("racezone")
	local numberGates = countZones("gate")
	local numberPylons = countZones("pylon")
	IlluminationNumberZones = countZones("illum")
	NumberFireworksZones = countZones("fireworks")
    NumberGreenSmokeZones = countZones("Green smoke")
    NumberRedSmokeZones = countZones("Red smoke")
    NumberWhiteSmokeZones = countZones("White smoke")
    NumberOrangeSmokeZones = countZones("Orange smoke")
    NumberBlueSmokeZones = countZones("Blue smoke")    

	--protect values to valid ranges
	if illuminationBrightness > 1000000 then
		illuminationBrightness = 1000000
	elseif illuminationBrightness < 1 then
		illuminationBrightness = 1
	end
	if numberMissedGatesDNF < 1 then
		numberMissedGatesDNF = 1
	end
	if numberPylonHitsDNF < 1 then
		numberPylonHitsDNF = 1
	end
    if bonusTime < 0 then --in case the user thinks they must use a negative number to subtract time
        bonusTime = -bonusTime
    end

    --unit conversions for script usage
    raceZoneCeiling = raceZoneCeiling * .3048 --convert feet to meters
    gateHeight = gateHeight * .3048 --convert feet to meters
    bonusGateHeight = bonusGateHeight * .3048 --convert feet to meters
    startSpeedLimit = startSpeedLimit * 1.852 --convert knots to km/h
    participantFilter = participantFilter * .3048 --convert feet to meters
    illuminationAGL = illuminationAGL * .3048 --convert feet to meters
    groupRaceTimeout = groupRaceTimeout * 60 --convert minutes to seconds	
	
	if numberRaceZones > 0 and numberGates > 0 then
		for idx = 1, numberRaceZones do
			table.insert(raceZones, string.format("racezone-%d", idx))
		end
		for idx = 1, numberPylons do
			table.insert(racePylons, string.format("pylon-%d", idx))
		end
		for idx = 1, numberGates do
			course:AddGate(idx)
		end
		for idx = 1, NumberFireworksZones do
			table.insert(fireworksZones, string.format("fireworks-%d", idx))
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

		race = Airrace:New(raceZones, racePylons, course, gateHeight, horizontalGates, verticalGates, raceZoneCeiling, startSpeedLimit, bonusGateHeight, bonusGates, bonusTime,
							penaltyTimeMissedGate, penaltyTimePylonHit, penaltyTimeAboveGateHeight, penaltyTimeHorizontalGate, penaltyTimeVerticalGate, 
							numberMissedGatesDNF, numberPylonHitsDNF, numberLaps, groupRace, paceUnitName, fastestIntermediates, participantFilter, groupRaceTimeout, 
							illuminationOn, illuminationStartTime, illuminationStopTime, illuminationBrightness, illuminationAGL, fireworksZones)

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

	if illuminationOn == true then
		mist.scheduleFunction(RefreshIllumination, { race }, timer.getTime(), illuminationRespawnTimer)
	end

    PopSmokeMarkers()
end

env.info("-----------------------------------------------------------------------------------------")
env.info("Load Airrace script")

world.addEventHandler(crashHandler)

Init()
