local socket = require("scripts.socket")
local Memory = dofile("scripts/memory.lua")
local addrs = Memory.addrs

gui.use_surface("client")
gui.clearGraphics()
memory.usememorydomain("ARM9 System Bus")

local function read_s32(addr) return memory.read_s32_le(addr) end
local function read_u32(addr) return memory.read_u32_le(addr) end
local function read_u8(addr)  return memory.read_u8(addr)     end

-- player address
local playerPtr = 0x0216E2A0 

while true do
    local x, y = 5, 400

    gui.text(x, y, "Mario Kart RL", "yellow"); y = y + 16

    local racer = read_u32(playerPtr)
    if racer == 0 or racer == 0xFFFFFFFF then
        gui.text(x, y, "Not in race / pointer not loaded yet")
        emu.frameadvance()
        goto continue
    end

    -- inputs
    local joy = joypad.getwithmovie()
    local inputs = ""
    for _, btn in ipairs({"A","B","X","Y","L","R","Up","Down","Left","Right"}) do
        if joy[btn] then inputs = inputs .. btn .. " " end
    end
    if inputs == "" then inputs = "(none)" end

    -- checkpoint wall and crash
    local ptrRaceStatus = read_u32(addrs.ptrRaceStatus)
    local ptrRacerData = read_u32(addrs.ptrRacerData)
    local checkpoint, wallSpeedMult, flags44 = -1, 4096, 0
    
    if ptrRaceStatus ~= 0 and ptrRacerData ~= 0 then
        -- Checkpoint
        checkpoint = read_u8(ptrRaceStatus + 0x46)
        -- Wall speed multiplier for detecting crashes
        wallSpeedMult = Memory.get_s32(memory.read_bytes_as_array(ptrRacerData + 0x38C, 4), 1)
        -- Flags
        flags44 = Memory.get_u32(memory.read_bytes_as_array(ptrRacerData + 0x44, 4), 1)
    end

    -- draw text to screen
    gui.text(x, y, "Inputs: " .. inputs); y=y+20
    gui.text(x, y, "Checkpoint: " .. checkpoint .. "  WallMult: " .. wallSpeedMult .. "  Flags: " .. flags44); y=y+20
    
    -- Send stats using socket
    local stats = {
        checkpoint = checkpoint,
        wallSpeedMult = wallSpeedMult,

        A = joy.A and 1 or 0,
        B = joy.B and 1 or 0,
        X = joy.X and 1 or 0,
        Y = joy.Y and 1 or 0,
        L = joy.L and 1 or 0,
        R = joy.R and 1 or 0,
        Up = joy.Up and 1 or 0,
        Down = joy.Down and 1 or 0,
        Left = joy.Left and 1 or 0,
        Right = joy.Right and 1 or 0,
    }
    socket.sendStats(stats)

    -- pcall(socket.receiveCtrls)

    emu.frameadvance()
    ::continue::
end