Players = {"GT"}
table.insert(Players, "MD")
text = "Race is on!"
GroupCurrentRankings = {}
local numLaps = 2
local numGates = 3

print("Players = {'GT', 'MD'}")


if numLaps == 0 then numLaps = 1 end
for lap = 1, numLaps do
	table.insert(GroupCurrentRankings, {})
	for gate = 1, numGates do
		table.insert(GroupCurrentRankings[lap], {})
	end
end
print("GroupCurrentRankings = {    { {},{},{} },   { {},{},{} }   }\n")

function AddToGroupCurrentRankings(name, lap, gate, time)
	while lap > #GroupCurrentRankings do
		table.insert(GroupCurrentRankings, {})
	end
	while gate > #GroupCurrentRankings[lap] do
		table.insert(GroupCurrentRankings[lap], {})
	end
	GroupCurrentRankings[lap][gate][name] = time
end

print("Adding to GroupCurrentRankings...")
AddToGroupCurrentRankings("GT", 1, 1, 0.2)
AddToGroupCurrentRankings("MD", 1, 1, 0.1)
print("GroupCurrentRankings = {    { {GT=0.2},{MD=0.1},{} },   { {},{},{} }   }\n")

function SortRanks(currentRaceData)
  print("Now debugging function SortRanks()...")
  local ranks = {}    -- reset
  local added = {}    -- track which players already ranked
  local bucket = {}

  -- search backwards for efficiency
  for lap = numLaps, 1, -1 do --make sure if the user selects zero, numLaps is set to 1
    print("Evaluating lap " .. lap)
    local lapData = currentRaceData[lap]

    for gate = numGates, 1, -1 do
      print("Evaluating gate " .. gate)
      -- collect all players who have a time at this lap/gate
      
      for name, time in pairs(currentRaceData[lap][gate]) do
        if not added[name] then
          table.insert(bucket, {name=name, lap=lap, gate=gate, time=time})
          print("Added to bucket: {name=" .. name .. ", lap=" .. lap .. ", gate=" .. gate .. ", time=" .. time .. "}")
          print("Sorting bucket...")
          table.sort(bucket, function(a,b) return a.time < b.time end) -- sort this bucket by lowest time
        end
      end
    end
  end

  -- append sorted players to Ranks
  --for _, entry in ipairs(bucket) do
  --  table.insert(ranks, entry)
  --  print("Adding bucket entry for " .. entry.name .. " to ranks")
  --  added[entry.name] = true
  --  print("added['" .. entry.name .. "']=true")
  --end
  print("#bucket=" .. #bucket .. ". Returning bucket\n")
  return bucket
end
    


print("Now passing GroupCurrentRankings --> currentRaceData for sorting\n")
rankTable = SortRanks(GroupCurrentRankings)
print("#rankTable = " .. #rankTable)
print("rankTable now sorted and set\n")

print("Printing sorted data...")
for rank, playerInfo in ipairs(rankTable) do
    print("Evaluating rank=" .. rank .. " playerInfo")
    print(playerInfo.name .. " time=" .. playerInfo.time)
end
print("")

for currentRank, playerData in ipairs(rankTable) do
    text = string.format("%s\n%d. %s", text, currentRank, playerData.name)

    --find index position of this player in the Player list...
    for index, player in ipairs(Players) do
        if player.Name == playerData.name then
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
                if message[2] >= timer.getTime() then
                    text = text .. "\n     !!! " .. message[1]
                end
            end

            break
        end
    end
end	
		
print(text)
