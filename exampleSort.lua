NumLaps=2
NumGates=10
NumPlayers=2
GateTimes={}

if NumLaps == 0 then NumLaps = 1 end
for lap = 1, NumLaps do
  table.insert(GateTimes, {})
  for gate = 1, NumGates do
    table.insert(GateTimes[lap], {})
  end
end


function addToGateTimes(name, lap, gate, time)
  if lap > #GateTimes then
    table.insert(GateTimes, {})
  end
  if gate > #GateTimes[lap] then
    table.insert(GateTimes[lap], {})
  end
  GateTimes[lap][gate][name] = time
end

function sortRanks()
  -- sorted top to bottom:
  -- 1) highest lap
  -- 2) highest gate
  -- 3) lowest time

  Ranks = {}                     -- reset
  local added = {}              -- track which players already ranked

  -- search backwards for efficiency
  for lap = #GateTimes, 1, -1 do
    for gate = #GateTimes[lap], 1, -1 do
      
      -- collect all players who have a time at this lap/gate
      local bucket = {}
      for name, time in pairs(GateTimes[lap][gate]) do
        if not added[name] then
          table.insert(bucket, {name=name, lap=lap, gate=gate, time=time})
        end
      end

      -- sort this bucket by lowest time
      table.sort(bucket, function(a,b)
        return a.time < b.time
      end)

      -- append sorted players to Ranks
      for _, entry in ipairs(bucket) do
        table.insert(Ranks, entry)
        added[entry.name] = true

        -- stop early if we have all players
        if #Ranks == NumPlayers then
          return
        end
      end
    end
  end
end

addToGateTimes("GT",1,1,34)
addToGateTimes("MD",1,1,34.2)
addToGateTimes("GT",1,2,39)
addToGateTimes("MD",1,2,38.9)
addToGateTimes("MD",1,3,50)
addToGateTimes("GT",1,4,57)
addToGateTimes("MD",1,4,55)
addToGateTimes("GT",2,1,62)
addToGateTimes("MD",2,1,62)
addToGateTimes("GT",2,2,64)
addToGateTimes("MD",2,2,63)
sortRanks()

for rank, playerInfo in ipairs(Ranks) do
  print (string.format("Lap%d Pylon%02d|Time %07.3f s|%s", playerInfo.lap, playerInfo.gate, playerInfo.time, playerInfo.name))
end


--example format of GateTimes table: This just collects the data to be sorted later into the Ranks table
--GateTimes={  
--       {--lap 1
--         {name1=time1, name2=time2}, --gate1
--         {name1=time3}, --gate2
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

--example format of Ranks table sorted top to bottom, first by highest lapNum, then by highest gateNum, then by lowest timeVal
--Ranks={
--       {name = "name1", gate = gateNum, lap = lapNum, time = timeVal},
--       {name = "name2", gate = gateNum, lap = lapNum, time = timeVal},
--       {name = "name3", gate = gateNum, lap = lapNum, time = timeVal},
-- }
