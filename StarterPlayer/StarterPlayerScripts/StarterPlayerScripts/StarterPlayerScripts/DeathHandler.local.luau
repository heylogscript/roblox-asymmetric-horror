-- DeathHandler.local.luau
-- Disables movement and camera controls when player's health reaches 0 (death)
-- Works with Forsaken-Brainrot game structure

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local character
local humanoid

-- Function to disable controls
local function disableControls()
    if player then
        -- Disable movement controls
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.Scriptable
        player.DevTouchMovementMode = Enum.DevTouchMovementMode.Scriptable
        
        -- Disable camera controls
        player.DevEnableMouseLock = false
        player.DevEnableShiftLock = false
        player.CameraMode = Enum.CameraMode.Scriptable
        
        -- Lock camera in place
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Scriptable
            -- Keep camera where it is (don't update)
        end
    end
end

-- Function to enable controls (for respawn)
local function enableControls()
    if player then
        -- Reset to default values (or your game's defaults)
        player.DevComputerMovementMode = Enum.DevComputerMovementMode.UserChoice
        player.DevTouchMovementMode = Enum.DevTouchMovementMode.UserChoice
        player.DevEnableMouseLock = true
        player.DevEnableShiftLock = true
        player.CameraMode = Enum.CameraMode.Classic  -- or whatever your default is
        
        -- Reset camera type
        local camera = workspace.CurrentCamera
        if camera then
            camera.CameraType = Enum.CameraType.Custom
        end
    end
end

-- Set up character
local function onCharacterAdded(newCharacter)
    character = newCharacter
    humanoid = character:WaitForChild("Humanoid")
    
    -- Re-enable controls on respawn
    enableControls()
    
    -- Listen for health changes
    humanoid.HealthChanged:Connect(function(health)
        if health <= 0 then
            disableControls()
        end
    end)
end

-- Handle initial character if already spawned
if player.Character then
    onCharacterAdded(player.Character)
end

-- Handle future respawns
player.CharacterAdded:Connect(onCharacterAdded)

-- Optional: Also disable controls if player dies instantly (e.g., from fall damage)
-- HealthChanged should catch it, but just in case:
if humanoid and humanoid.Health <= 0 then
    disableControls()
end