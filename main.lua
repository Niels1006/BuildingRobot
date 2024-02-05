local robot = require("robot")
local component = require("component")
local sides = require("sides")

local inventory_controller = component.inventory_controller
local g = component.generator
local c = component.computer
local computer = require("computer")
local os = require("os")

-- local robot = cmp.robot

local grid = {
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 1, 1, 1, 1, 1, 1, 1, 2, 1, 1, 1, 1, 1, 1, 1, 3},
    {3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3, 3}
}

function move(dir)
    move_wo_coords(dir)
    y = y + dir
end

function move_wo_coords(dir)
    if dir == 1 then
        while robot.forward() == nil do end

    else
        while robot.back() == nil do end
    end
end

function go_to(x, y) end

function check_for_inv_blocks()
    -- 1,2,3 basalt 
    -- 4.1 ornate, 4.2 black ornate

    s1 = 0
    s2 = 0
    s3 = 0

    for i = 6, 32 do s1 = s1 + robot.count(i) end

    for i = 33, 40 do s2 = s2 + robot.count(i) end

    for i = 41, 48 do s3 = s3 + robot.count(i) end

    return s1, s2, s3
end

function refill_all_from_chest()

    for i = 1, 4 do
        robot.select(i)
        robot.placeUp()

        for j = starts[i], stops[i] do
            robot.select(j)
            for k = 1, inventory_controller.getInventorySize(sides.up) do
                inventory_controller.suckFromSlot(sides.up, k,
                                                  64 - robot.count())
                if robot.count() == 64 then break end
            end
        end
        robot.select(i)
        robot.swingUp()
    end

    refill_generator()
    block_slots = {starts[1], starts[2], starts[3]}

end

function refill_generator()
    robot.select(5)
    g.insert(64 - g.count())
end

function print_fields_of_object(o) for k2, v2 in pairs(o) do print(k2, v2) end end

function build_one_chunk(start)
    if start == 1 then
        s = 1
    else
        s = start
        robot.turnRight()
        robot.forward()
        robot.turnLeft()
        x = x + 1
    end

    for i = s, 17 do
        for j = 1, 17 do
            robot.select(block_slots[grid[i][j]])
            robot.placeDown()

            if j == 17 then break end

            if i % 2 == 1 then
                move(1)
            else
                move(-1)
            end
        end

        if robot.count(block_slots[1]) < 16 then
            block_slots[1] = block_slots[1] + 1
        end
        if robot.count(block_slots[2]) < 16 then
            block_slots[2] = block_slots[2] + 1
        end
        if robot.count(block_slots[3]) < 17 then
            block_slots[3] = block_slots[3] + 1
        end

        if block_slots[1] > stops[1] then refill_all_from_chest() end

        if i ~= 17 then
            robot.turnRight()
            robot.forward()
            robot.turnLeft()
            x = x + 1
        end
    end

end

function check_charge()
    if computer.energy() / computer.maxEnergy() < 0.2 then
        repeat refill_all_from_chest() until computer.energy() /
            computer.maxEnergy() > 0.95

    end
end

function main()
    x = 1
    y = 1
    face = 0 -- 0 front, 1 left, 2 bottom, 3 right

    starts, stops = {6, 33, 41, 5}, {32, 40, 48, 5}
    block_slots = {starts[1], starts[2], starts[3]}

    io.write("Chunks in forward direction to build: ")
    local chunks_length = tonumber(io.read())
    io.write("Chunks in right direction to build: ")
    local chunks_right = tonumber(io.read())

    refill_all_from_chest()

    for m = 1, chunks_length do
        for n = 1, chunks_right do
            check_charge()

            if n == 1 then
                build_one_chunk(1)
            else
                build_one_chunk(2)
            end
        end

        robot.turnLeft()
        for _ = 1, chunks_right * 16 do move_wo_coords(1) end
        robot.turnRight()

    end


    c.stop()


    

end

main()
