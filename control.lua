ARROW_ENTITY = "orphan-arrow"

function createArrowAt(entity, index)
  global.arrows = global.arrows or {}
  global.arrows[index] = global.arrows[index] or {}
  global.arrows[index][entity.unit_number] = entity.surface.create_entity{name = ARROW_ENTITY, position = entity.position}
end

function clearArrows(index)
  global.arrows = global.arrows or {}
  global.arrows[index] = global.arrows[index] or {}
  local destroyed = false
  for _,arrow in pairs(global.arrows[index]) do
    arrow.destroy()
    destroyed = true
  end
  global.arrows[index] = nil
  return destroyed
end

function deleteArrowAt(entity)
  global.arrows = global.arrows or {}
  for i,_ in pairs(global.arrows) do
    if global.arrows[i][entity.unit_number] then
      global.arrows[i][entity.unit_number].destroy()
      global.arrows[i][entity.unit_number] = nil
      return true
    end
  end
  return false
end



function isPipe(pipe )
  if pipe.type == "pipe-to-ground" or pipe.type == "pipe" or pipe.type == "pump" or pipe.type == "storage-tank" then
    return true
  end
  return false
end


function countPipeConnectedNeighbor(pipe, scannedTable, trimTable, event)
  -- skip already scanned pipes
  if scannedTable[pipe.unit_number] then 
	return scannedTable[pipe.unit_number]
  end
  _,fluidBoxNeighbours = next(pipe.neighbours)
  local connectedNeighbourCount = 0
  local connectedPipeCount = 0
  if fluidBoxNeighbours then
    for _,neighbour in pairs(fluidBoxNeighbours) do
	  connectedNeighbourCount = connectedNeighbourCount + 1
	  if isPipe(neighbour ) then
	    -- found a dead end
		connectedPipeCount = connectedPipeCount + 1
	  end
    end
  end
  
  scannedTable[pipe.unit_number] = connectedNeighbourCount

  -- debugging message
  -- game.players[event.player_index].print{"orphans.pipen", pipe.unit_number, connectedNeighbourCount, connectedPipeCount}
  
  -- only 1 neighbour found, trim the dead end
  if connectedNeighbourCount <= 1 then
    trimDeadEnd(pipe, scannedTable, trimTable, event)
  end
  
  return connectedNeighbourCount
  
end


function trimDeadEnd(pipe, scannedTable, trimTable, event)
  
  -- already trimmed
  if trimTable[pipe.unit_number] then 
	return
  end
  
  trimTable[pipe.unit_number] = pipe
  
  local fluidBoxNeighbours
  _,fluidBoxNeighbours = next(pipe.neighbours)
  
  if fluidBoxNeighbours then
    for _,neighbour in pairs(fluidBoxNeighbours) do
	  if isPipe( neighbour ) then
	    local neighbourCount = countPipeConnectedNeighbor(neighbour, scannedTable, trimTable, event)
		if neighbourCount <= 2 then
		  trimDeadEnd(neighbour, scannedTable, trimTable, event)
		end
	  end
    end
  end

end


script.on_event(defines.events.on_pre_player_mined_item, function(event)
  deleteArrowAt(event.entity)
end)

script.on_event(defines.events.on_robot_pre_mined, function(event)
  deleteArrowAt(event.entity)
end)

script.on_event(defines.events.on_entity_died, function(event)
  deleteArrowAt(event.entity)
end)

script.on_event(defines.events.on_player_left_game, function(event)
  clearArrows(event.player_index)
end)

script.on_event("find-orphans", function(event)
  findAndHighlightOrphans(event, false, false)
end)

script.on_event("find-cheats", function(event)
  findAndHighlightOrphans(event, false, true)
end)

script.on_event("delete-orphans", function(event)
  findAndHighlightOrphans(event, true, false)
end)

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function highlightCheats(event, player, search_area)

  highlightEntity( event, player, search_area, "infinity-container")
  highlightEntity( event, player, search_area, "infinity-pipe")
  highlightEntity( event, player, search_area, "electric-energy-interface")
end


function highlightEntity(event, player, search_area, entityType)

  local infinityPipeList = player.surface.find_entities_filtered{
    area = search_area,
    type = entityType
  }

  for _,pipe in pairs(infinityPipeList) do
    createArrowAt(pipe, event.player_index)
  end
  
  count = tablelength(infinityPipeList)
  
  player.print{"orphans.entity-search", entityType, count}
end


function findAndHighlightOrphanPipes(event, player, search_area, delete)

    local count = 0
	local scannedTable = {}
	local trimTable = {}

    local pipeToGroundList = player.surface.find_entities_filtered{
      area = search_area,
      type = "pipe-to-ground"
    }

    for _,pipe in pairs(pipeToGroundList) do
	  countPipeConnectedNeighbor(pipe, scannedTable, trimTable, event)
    end

    local pipes = player.surface.find_entities_filtered{
      area = search_area,
      type = "pipe"
    }

    for _,pipe in pairs(pipes) do
	  countPipeConnectedNeighbor(pipe, scannedTable, trimTable, event)
    end
	
	count = tablelength(trimTable)

    if delete then
	  player.print{"orphans.delete", count}
	  for _,pipe in pairs(trimTable) do
	    pipe.destroy()
      end
	  return 
	end
	
    for _,pipe in pairs(trimTable) do
	  createArrowAt(pipe, event.player_index)
    end
	
    if count == 0 then
      player.print{"orphans.found-none"}
    elseif count == 1 then
      player.print{"orphans.found-one"}
    else
      player.print{"orphans.found-many", count}
    end

end

function findAndHighlightOrphans(event, delete, findCheat)
  local next = next
  local player = game.players[event.player_index]
  local search_range = settings.global["orphan-finder-search-range"].value
  local search_area =
  {
    {player.position.x - search_range, player.position.y - search_range},
    {player.position.x + search_range, player.position.y + search_range}
  }
  if not clearArrows(event.player_index) then
  
    if findCheat then
		highlightCheats(event, player, search_area)
	else
		findAndHighlightOrphanPipes(event, player, search_area, delete)
	end
	
  else
    player.print{"orphans.markers-cleared"}
  end
end