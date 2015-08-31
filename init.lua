--Lift addon to minetest
--Version 0.3
--------------------------------Settings--------------------------------

local distance = 5 -- Operating range of connectors
local debug = true -- Print debug information, useful for reporting bugs


------------------------------Setting end-------------------------------
-----Do not edit anything after that line if you are not a developer----

minetest.register_alias("lift:moveblock", "lift:rail_connector")

--Print debug information if addon is in debug mode
--msg - Message to print
local function debugPrint(msg)
  if debug then print(msg) end
end

--Print debug information about location if addon is in debug mode
--pos - position
local function debugPrintLocation(pos)
  if debug then print(pos.x .. " " .. pos.y .. " " .. pos.z) end
end


--Move node
--pos - start position, dir - direction (1 - down, 2 - up)
local function moveNode(pos, dir)
      new_pos = 0
      if (dir == 2) then new_pos = {x=pos.x,y=pos.y+1,z=pos.z} end
      if (dir == 1) then new_pos = {x=pos.x,y=pos.y-1,z=pos.z} end
      debugPrint("Moving node, new pos:")
      debugPrintLocation(new_pos)

      node = minetest.env:get_node(pos)

      minetest.add_node(new_pos, node)
      minetest.remove_node(pos)


end

--Move players in postion
--pos - start position, dir - direction (1 - down, 2 - up)
local function movePlayers(pos, dir)
  all_objects = minetest.get_objects_inside_radius({x=pos.x,y=pos.y+1,z=pos.z}, 1)
  if (dir == 2) then pos = {x=pos.x,y=pos.y+2,z=pos.z} end
  if (dir == 1) then return end
  debugPrint("Called movePlayers")
  debugPrintLocation(pos)
  local _,obj
    for _,obj in ipairs(all_objects) do
	if (obj:is_player()) then obj:moveto(pos, true) print("Moving player") end

    end

end

--Get position based on the reference point
--pos - start position, distance - distance from the base point, axis - axis (x,y,z)
local function getBlockPosBasedOnRefPoint(pos, distance, axis)

  if (axis == "x") then return{x=pos.x+distance,y=pos.y,z=pos.z} end
  if (axis == "y") then return{x=pos.x,y=pos.y+distance,z=pos.z} end
  if (axis == "z") then return{x=pos.x,y=pos.y,z=pos.z+distance} end

end

--Get diretion of rail in contact with the node
--pos - Position of node
local function checkRailDirection(pos)
  for i=1,4,1 do
    if (i == 1) then pos_2 = {x=pos.x+1,y=pos.y,z=pos.z} end
    if (i == 2) then pos_2 = {x=pos.x-1,y=pos.y,z=pos.z} end
    if (i == 3) then pos_2 = {x=pos.x,y=pos.y,z=pos.z+1} end
    if (i == 4) then pos_2 = {x=pos.x,y=pos.y,z=pos.z-1} end
    debugPrint("Checking Rail directon in:")
    debugPrintLocation(pos)
    if (minetest.get_node(pos_2).name == "lift:rail") then
      return minetest.get_meta(pos_2):get_int("dir")
    end

  end
  return false

end

--Check that nothing is standing in the way of node
--pos - Position of node, direction (1 - down, 2 - up)
local function checkPossibilityOfMovingBlock(pos, dir)
   if (dir == 2) then pos = {x=pos.x,y=pos.y+1,z=pos.z} end
   if (dir == 1) then pos = {x=pos.x,y=pos.y-1,z=pos.z} end
   local node = minetest.get_node(pos).name
   debugPrint("checkPossibilityOfMovingBlock  in:")
   debugPrintLocation(pos)
   if (node == "air" or node == "ignore") then return true end
   return false

end

--Check that nothing is standing in the way of nodes connected to the rail_connector
--pos - Position of node, distance - how far check(num of nodes),axis - axis (x,y,z), direction - direction (+, -)
local function checkPossibilityOfMovingNodesInOneDirection(pos, distance, axis, dir, direction)
  for i=1,distance,1 do
      if direction == "+" then block_pos = getBlockPosBasedOnRefPoint(pos, i, axis) end
      if direction == "-" then block_pos = getBlockPosBasedOnRefPoint(pos, -i, axis) end
      debugPrint("checkPossibilityOfMovingNodesInOneDirection in:")
      debugPrintLocation(pos)
      name = minetest.get_node(block_pos).name
      if (name ~= "lift:moveblock_1" and name ~= "lift:moveblock_2") then return true end
      if name == "lift:moveblock_1" then
        if checkPossibilityOfMovingBlock(block_pos, dir) == false then
	  debugPrint("Block stuck by:")
	  debugPrint(name)
	  debugPrintLocation(block_pos)
	  return false
	end
      end
      if name == "lift:moveblock_2" then
      --TODO
      end

      return true
  end
end

--Move nodes standing on the moveblock_2 node
--pos - Position of node, dir - direction (1 - down, 2 - up), range - how many nodes move(num of nodes)
local function moveExtraNode(pos, dir, range)
  if dir == 2 then
    for i=1,range,1 do
      debugPrint("moveExtraNode in:")
      debugPrintLocation(pos)
      print (range -i + 1)
      local block_pos = getBlockPosBasedOnRefPoint(pos, range -i + 1, "y")
      print(minetest.get_node(block_pos).name)
      if (name ~= "air" and name ~= "ignore") then moveNode(block_pos, dir) end

    end
  end

  if dir == 1 then
    for i=1,range,1 do
      debugPrint("moveExtraNode in:")
      debugPrintLocation(pos)
      local block_pos = getBlockPosBasedOnRefPoint(pos, i, "y")
      print(minetest.get_node(block_pos).name)
      if (name ~= "air" and name ~= "ignore") then moveNode(block_pos, dir) end

    end
  end

end

--Process nodes connected to the rail_connector in one direction
--pos - Position of node, distance - how many nodes process (num of nodes), axis - axis (x,y,z), dir - direction (1 - down, 2 - up), direction - direction (+, -)
local function processBlockInOneDirection(pos, distance, axis, dir, direction)
  for i=1,distance,1 do
      debugPrint("processBlockInOneDirection in:")
      debugPrintLocation(pos)
      if direction == "+" then block_pos = getBlockPosBasedOnRefPoint(pos, i, axis) end
      if direction == "-" then block_pos = getBlockPosBasedOnRefPoint(pos, -i, axis) end
      local name = minetest.get_node(block_pos).name
      if (name ~= "lift:moveblock_1" and name ~= "lift:moveblock_2") then return end

      if name == "lift:moveblock_1" then
	movePlayers(block_pos, dir)
	moveNode(block_pos, dir)
      end

      if name == "lift:moveblock_2" then
	movePlayers(block_pos, dir)
	if (dir == 2) then moveExtraNode(block_pos , dir, 4) moveNode(block_pos, dir) end
	if (dir == 1) then moveNode(block_pos, dir) moveExtraNode(block_pos , dir, 4)  end


      end


  end

end

--Process nodes connected to the rail_connector in one axis
--pos - Position of node, distance - how many nodes process (num of nodes), axis - axis (x,y,z), dir - direction - direction (+, -)

local function processBlockInOneAxis(pos, distance, axis, dir)
  if checkPossibilityOfMovingNodesInOneDirection(pos, distance, axis, dir, "+") == false then return false end
  if checkPossibilityOfMovingNodesInOneDirection(pos, distance, axis, dir, "-") == false then return false end
  processBlockInOneDirection(pos, distance, axis, dir, "+")
  processBlockInOneDirection(pos, distance, axis, dir, "-")

end

--Process all nodes connected to the rail_connector
--pos - Position of node, dir - direction (1 - down, 2 - up)

local function procesAllConnectedMoveBlock(pos, dir)
  for i=1,4,1 do
    if (i == 1) then if processBlockInOneAxis(pos, distance, "x", dir) == false then return false end end
    if (i == 2) then if processBlockInOneAxis(pos, distance, "y", dir) == false then return false end end
    if (i == 3) then if processBlockInOneAxis(pos, distance, "z", dir) == false then return false end end
  end
  return true

end
--Check is nodes will be connected to the rail in the next step
--pos - Position of node, dir - direction (1 - down, 2 - up)
local function checkConnectionToRailInNextStep(pos, dir)
  if (dir == 2) then pos = {x=pos.x,y=pos.y+1,z=pos.z} end
  if (dir == 1) then pos = {x=pos.x,y=pos.y-1,z=pos.z} end
  if (minetest.get_node({x=pos.x+1,y=pos.y,z=pos.z}).name == "lift:rail") then return true end
  if (minetest.get_node({x=pos.x-1,y=pos.y,z=pos.z}).name == "lift:rail") then return true end
  if (minetest.get_node({x=pos.x,y=pos.y,z=pos.z+1}).name == "lift:rail") then return true end
  if (minetest.get_node({x=pos.x,y=pos.y,z=pos.z-1}).name == "lift:rail") then return true end
  return false

end

--Set direction of rail working to all conneted rail
--pos - Position of node, dir - direction (1 - down, 2 - up)
local function setNearbyNodeDir(pos, dir)
  for i=1,6,1 do
    if (i == 1) then pos_2 = {x=pos.x+1,y=pos.y,z=pos.z} end
    if (i == 2) then pos_2 = {x=pos.x-1,y=pos.y,z=pos.z} end
    if (i == 3) then pos_2 = {x=pos.x,y=pos.y,z=pos.z+1} end
    if (i == 4) then pos_2 = {x=pos.x,y=pos.y,z=pos.z-1} end
    if (i == 5) then pos_2 = {x=pos.x,y=pos.y+1,z=pos.z} end
    if (i == 6) then pos_2 = {x=pos.x,y=pos.y-1,z=pos.z} end
    local name = minetest.get_node(pos_2).name
    if (name == "lift:rail" or name == "lift:moveblock_1" or name == "lift:moveblock_2"
	or name == "lift:rail" or name == "lift:control_up" or name == "lift:control_down"
	or name == "lift:control_stop" or name == "lift:rail_connector")
    then
      if minetest.get_meta(pos_2):get_int("dir") ~= dir
      then
	minetest.get_meta(pos_2):set_int("dir", dir)
	setNearbyNodeDir(pos_2, dir)

      end
    end
    if (minetest.get_node(pos_2).name == "lift:rail_connector") then
      minetest.get_meta(pos_2):set_int("sleep", 0)
    end

  end


end
minetest.register_node("lift:moveblock_1", {
	tiles = {"lift_moveblock_1.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	description = "lift:moveblock_1"
})

minetest.register_node("lift:moveblock_2", {
	tiles = {"lift_moveblock_2.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	description = "lift:moveblock_2"
})

minetest.register_node("lift:rail", {
	tiles = {"lift_rail_top_and_bottom.png", "lift_rail_top_and_bottom.png", "lift_rail.png", "lift_rail.png", "lift_rail.png", "lift_rail.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	description = "lift:rail"
})

minetest.register_node("lift:control_up", {
	tiles = {"lift_control_top_and_bottom.png", "lift_control_top_and_bottom.png", "lift_control_up.png", "lift_control_up.png", "lift_control_up.png", "lift_control_up.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	description = "lift:control_up"
})
minetest.register_node("lift:control_down", {
	tiles = {"lift_control_top_and_bottom.png", "lift_control_top_and_bottom.png", "lift_control_down.png", "lift_control_down.png", "lift_control_down.png", "lift_control_down.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
  description = "lift:control_down"
})
minetest.register_node("lift:control_stop", {
	tiles = {"lift_control_top_and_bottom.png", "lift_control_top_and_bottom.png", "lift_control_stop.png", "lift_control_stop.png", "lift_control_stop.png", "lift_control_stop.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
  description = "lift:control_stop"
})
minetest.register_node("lift:rail_connector", {
	tiles = {"lift_rail_connector.png"},
	groups = {snappy=2, choppy=2, oddly_breakable_by_hand=2},
	description = "lift:rail_connector"
})

minetest.register_abm({
	nodenames = {"lift:rail_connector"},
	interval = 0.1,
	chance = 1,
	action = function(pos)
		if (minetest.get_meta(pos):get_int("sleep") == 1) then return end

		dir = checkRailDirection(pos)
		print("Rail Direction:")
		print(dir)
		if (dir == 0 or dir == 3) then
		  minetest.get_meta(pos):set_int("sleep",1)
		  return
		end


		if (checkConnectionToRailInNextStep(pos,dir) == false) then
		  minetest.get_meta(pos):set_int("sleep",1)
		 -- setNearbyNodeDir(pos, 3)
		  return
		end

		if (checkPossibilityOfMovingBlock(pos, dir) == false) then
		  minetest.get_meta(pos):set_int("sleep",1)
		--  setNearbyNodeDir(pos, 3)
		  return
		end
		--Fixing: lift moving up too fast
		if (dir == 2) then
		  if (minetest.get_meta(pos):get_int("active") == 0) then
		    minetest.get_meta(pos):set_int("active",1)
		    return
		  end
		end
		if procesAllConnectedMoveBlock(pos, dir, range) == true then
		  movePlayers(pos, dir)
		  moveNode(pos, dir)
		end




	end,
})

minetest.register_on_punchnode(function(pos, node, puncher, pointed_thing)
	if puncher:is_player()
	and node.name == "lift:control_up" then
		setNearbyNodeDir(pos, 2)
	end
	if puncher:is_player()
	and node.name == "lift:control_down" then
		setNearbyNodeDir(pos, 1)
	end
	if puncher:is_player()
	and node.name == "lift:control_stop" then
		setNearbyNodeDir(pos, 0)
	end

end)
