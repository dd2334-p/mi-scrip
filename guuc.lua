-- LocalScript: CameraShakeClient.lua
-- Colocar en: StarterPlayer > StarterPlayerScripts

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Camera = workspace.CurrentCamera

local remote = ReplicatedStorage:WaitForChild("CameraShakeEvent")

-- Parámetros por defecto (se pueden sobreescribir desde el servidor)
local DEFAULT_DURATION = 0.5
local DEFAULT_INTENSITY = 1.0
local DEFAULT_FREQUENCY = 6 -- frecuencia para math.noise (no confundir con FPS)

-- Variables para manejo de offsets (para no acumular transformaciones)
local previousOffset = Vector3.new(0,0,0)
local shaking = false

local function applyOffset(offset)
	-- primero quitamos el offset anterior
	Camera.CFrame = Camera.CFrame * CFrame.new(-previousOffset)
	-- aplicamos el nuevo
	Camera.CFrame = Camera.CFrame * CFrame.new(offset)
	previousOffset = offset
end

local function clearOffset()
	-- eliminar offset final si queda alguno
	Camera.CFrame = Camera.CFrame * CFrame.new(-previousOffset)
	previousOffset = Vector3.new(0,0,0)
end

local function shake(duration, intensity, frequency)
	if shaking then return end
	shaking = true
	duration = duration or DEFAULT_DURATION
	intensity = intensity or DEFAULT_INTENSITY
	frequency = frequency or DEFAULT_FREQUENCY

	local startTime = tick()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local t = tick() - startTime
		if t >= duration then
			-- tiempo cumplido: desconectar y limpiar offset
			conn:Disconnect()
			clearOffset()
			shaking = false
			return
		end

		-- factor de atenuación (fade out)
		local remaining = 1 - (t / duration) -- 1 -> 0
		local falloff = remaining * remaining -- curva más suave

		-- usar math.noise para offsets suaves
		local nx = (math.noise(t * frequency, 0) - 0.5) * 2
		local ny = (math.noise(0, t * frequency) - 0.5) * 2
		local nz = (math.noise(t * frequency, t * frequency) - 0.5) * 2

		local offset = Vector3.new(nx, ny, nz) * (intensity * 0.5) * falloff

		-- aplicar offset (dividir por 10/20 para que no sea demasiado exagerado)
		applyOffset(offset / 10)
	end)
end

-- Escucha el RemoteEvent desde el servidor.
-- Firma: CameraShakeEvent:FireClient(player, duration, intensity, frequency)
remote.OnClientEvent:Connect(function(duration, intensity, frequency)
	shake(duration, intensity, frequency)
end)

-- Opcional: atajo local para probar con la tecla F (puedes quitarlo)
local UserInputService = game:GetService("UserInputService")
UserInputService.InputBegan:Connect(function(input, gp)
	if gp then return end
	if input.KeyCode == Enum.KeyCode.F then
		shake(0.6, 1.2, 8)
	end
end)

print("CameraShakeClient cargado ✅")
