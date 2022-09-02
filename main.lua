require("monkeypatch")
local list = require("lib.list")
local vec3 = require("lib.mathsies").vec3
local quat = require("lib.mathsies").quat
local mat4 = require("lib.mathsies").mat4

local consts = require("consts")

local loadObj = require("util.loadObj")

local spaceship = loadObj("assets/models/spaceship.obj")
local particleMesh = love.graphics.newMesh(consts.vertexFormat, {
	{1,1,1, 0,0, 0,0,0}, {0,0,0, 0,0, 0,0,0}, {0,0,0, 0,0, 0,0,0}
}, "triangles")

local meshShader = love.graphics.newShader("meshShader.glsl")
local particleShader = love.graphics.newShader("particleShader.glsl")

local function get(t, k) if t then return t[k] end end

local entities, spaceDustSectors
local entitiesToAdd, entitiesToRemove
local player, camera

function love.load()
	love.graphics.setDepthMode("lequal", true)
	love.graphics.setFrontFaceWinding("ccw")
	
	entities = list()
	player = {
		previousPosition = vec3(), position = vec3(), velocity = vec3(), angularVelocity = vec3(), orientation = quat(0, 1, 0, 0), angularSpeed = math.tau / 10, speed = 2, mesh = spaceship, colour = {1, 1, 1}, gun = {cooldownTimer = 0, cooldown = 0.001, bulletSpeed = 1000, bulletColour = {1, 1, 0}}
	}
	entities:add(player)
	camera = player
	local second = {
		previousPosition = vec3(), position = vec3(0, 0, -5), velocity = vec3(0, 0, 0), angularVelocity = vec3(), orientation = quat(), angularSpeed = math.tau, speed = 20, mesh = spaceship, colour = {0.5, 0.5, 0.5}
	}
	entities:add(second)
	if false then
		camera = second
	end
	spaceDustSectors = {num = 0}
end

local function updateSpaceDust()
	-- remove sectors outside of a cube near player and empty entries
	for x, sectorsX in pairs(spaceDustSectors) do
	if x ~= "num" then -- if x == "num" then continue end >:(
		if math.abs(x - math.floor(camera.position.x / consts.spaceDustSectorSize)) <= consts.distanceToKeepSpaceDustSectors then
			for y, sectorsXY in pairs(sectorsX) do
			if y ~= "num" then -- if y == "num" then continue end >:(
				if math.abs(y - math.floor(camera.position.y / consts.spaceDustSectorSize)) <= consts.distanceToKeepSpaceDustSectors then
					for z, sector in pairs(sectorsXY) do
					if z ~= "num" then -- if z == "num" then continue end >:(
						if math.abs(z - math.floor(camera.position.z / consts.spaceDustSectorSize)) <= consts.distanceToKeepSpaceDustSectors then
							--
						else
							sectorsXY[z] = nil
							sectorsXY.num = sectorsXY.num - 1
						end
					end
					end
				else
					sectorsX[y] = nil
					sectorsX.num = sectorsX.num - 1
				end
			end
			end
		else
			spaceDustSectors[x] = nil
			spaceDustSectors.num = spaceDustSectors.num - 1
		end
	end
	end
	-- ensure sectors present in a cube around player
	for x = -consts.distanceToKeepSpaceDustSectors, consts.distanceToKeepSpaceDustSectors do
		x = x + math.floor(camera.position.x / consts.spaceDustSectorSize)
		for y = -consts.distanceToKeepSpaceDustSectors, consts.distanceToKeepSpaceDustSectors do
			y = y + math.floor(camera.position.y / consts.spaceDustSectorSize)
			for z = -consts.distanceToKeepSpaceDustSectors, consts.distanceToKeepSpaceDustSectors do
				z = z + math.floor(camera.position.z / consts.spaceDustSectorSize)
				local sector = get(get(get(spaceDustSectors, x), y), z)
				if not sector then
					local newSector = {}
					for i = 1, consts.spaceDustPerSector do
						local px = (x + love.math.random()) * consts.spaceDustSectorSize
						local py = (y + love.math.random()) * consts.spaceDustSectorSize
						local pz = (z + love.math.random()) * consts.spaceDustSectorSize
						local position = vec3(px, py, pz)
						newSector[i] = {position = position, colour = {love.math.random(), love.math.random(), love.math.random()}}
					end
					local sectorsX
					if spaceDustSectors[x] then
						sectorsX = spaceDustSectors[x]
					else
						sectorsX = {num = 0}
						spaceDustSectors[x] = sectorsX
						spaceDustSectors.num = spaceDustSectors.num + 1
					end
					local sectorsXY
					if sectorsX[y] then
						sectorsXY = sectorsX[y]
					else
						sectorsXY = {num = 0}
						sectorsX[y] = sectorsXY
						sectorsX.num = sectorsX.num + 1
					end
					sectorsXY[z] = newSector
					sectorsXY.num = sectorsXY.num + 1
				end
			end
		end
	end
end

-- local function takeFromDtWithTimer(dt, timer)
-- 	local timer2 = math.max(timer - dt, 0)
-- 	local dt2 = dt - (timer - timer2)
-- 	assert(timer2 <= timer)
-- 	assert(dt2 <= dt)
-- 	return dt2, timer2
-- end

local function progressTimeWithTimer(curTime, dt, timer) -- modified from takeFromDtWithTimer
	assert(curTime <= dt)
	local usableTime = dt - curTime
	local timer2 = math.max(timer - usableTime, 0) -- use usableTime to progress/increase timer, stopping at 0
	local usableTime2 = usableTime - (timer - timer2) -- get new used usable time using change in timer
	local curTime2 = curTime + (usableTime - usableTime2) -- progress current time by how much usable time was used
	assert(timer2 <= timer)
	assert(usableTime2 <= usableTime)
	assert(curTime2 >= curTime)
	assert(curTime2 <= dt)
	return curTime2, timer2
end

local function tickGun(entity, gun, dt)
	local curTime = 0
	while curTime < dt do
		curTime, gun.cooldownTimer = progressTimeWithTimer(curTime, dt, gun.cooldownTimer)
		if gun.cooldownTimer == 0 then
			local shouldShoot = entity == player and love.keyboard.isDown("space")
			if shouldShoot then
				-- shooting is done here
				local lerp = curTime / dt
				assert(lerp >= 0 and lerp <= 1, lerp)
				local shootOrientation = quat.slerp(entity.previousOrientation, entity.orientation, lerp)
				gun.cooldownTimer = gun.cooldown
				local direction = vec3.rotate(vec3(0, 0, 1), shootOrientation)
				local velocity = player.velocity + direction * gun.bulletSpeed
				local bullet = {
					previousPosition = vec3.clone(player.position),
					position = vec3.clone(player.position) + velocity * (dt - curTime),
					velocity = velocity,
					colour = {unpack(gun.bulletColour)},
					-- colour = {love.math.random(), love.math.random(), love.math.random()},
					particle = true
				}
				entitiesToAdd[#entitiesToAdd+1] = bullet
			else
				break
			end
		end
	end
end

function love.update(dt)
	entitiesToAdd, entitiesToRemove = {}, {}
	for entity in entities:elements() do
		entity.previousPosition = entity.position
		entity.position = entity.position + entity.velocity * dt
		if entity.orientation then
			entity.previousOrientation = entity.orientation
			entity.orientation = quat.normalize(entity.orientation * quat.fromAxisAngle(entity.angularVelocity * dt))
		end
		if entity.gun then
			tickGun(entity, entity.gun, dt)
		end
	end
	if player then
		local accel = vec3()
		if love.keyboard.isDown("w") then accel.z = accel.z + player.speed end
		if love.keyboard.isDown("s") then accel.z = accel.z - player.speed end
		if love.keyboard.isDown("a") then accel.x = accel.x - player.speed end
		if love.keyboard.isDown("d") then accel.x = accel.x + player.speed end
		if love.keyboard.isDown("q") then accel.y = accel.y - player.speed end
		if love.keyboard.isDown("e") then accel.y = accel.y + player.speed end
		player.velocity = player.velocity + vec3.rotate(accel, player.orientation) * dt
		
		local rotate = vec3()
		if love.keyboard.isDown("j") then rotate.y = rotate.y - player.angularSpeed end
		if love.keyboard.isDown("l") then rotate.y = rotate.y + player.angularSpeed end
		if love.keyboard.isDown("i") then rotate.x = rotate.x - player.angularSpeed end
		if love.keyboard.isDown("k") then rotate.x = rotate.x + player.angularSpeed end
		if love.keyboard.isDown("u") then rotate.z = rotate.z + player.angularSpeed end
		if love.keyboard.isDown("o") then rotate.z = rotate.z - player.angularSpeed end
		player.angularVelocity = player.angularVelocity + rotate * dt
	end
	updateSpaceDust()
	for _, entity in ipairs(entitiesToAdd) do
		entities:add(entity)
	end
	for _, entity in ipairs(entitiesToRemove) do
		entities:remove(entity)
	end
end

local function drawParticle(particle, projectionMatrix, cameraMatrix)
	love.graphics.setColor(particle.colour)
	particle.prevDrawPos = particle.drawPos -- uses previous (perspectiveMatrix and) cameraMatrix
	if consts.useEyeSpaceForParticlePositions then
		particle.drawPos = cameraMatrix * particle.position
		particleShader:send("cameraToScreen", {mat4.elements(projectionMatrix)})
	else
		particle.drawPos = projectionMatrix * cameraMatrix * particle.position
	end
	particleShader:send("startDist", #(particle.position-player.position))
	particleShader:send("endDist", #((particle.previousPosition or particle.position)-player.position))
	particleShader:send("eyeSpace", consts.useEyeSpaceForParticlePositions)
	particle.prevDrawPos = particle.prevDrawPos or particle.drawPos
	particleShader:send("drawPos", {vec3.components(particle.drawPos)})
	particleShader:send("lineVector", {vec3.components(particle.prevDrawPos - particle.drawPos)})
	love.graphics.draw(particleMesh)
end

local canvas = love.graphics.newCanvas(love.graphics.getDimensions())
function love.draw()
	if not camera then return end
	
	love.graphics.setCanvas({canvas, depth = true})
	love.graphics.clear()
	local projectionMatrix = mat4.perspectiveLeftHanded(love.graphics.getWidth()/love.graphics.getHeight(), 90, 1000, 0.01)
	local cameraMatrix = mat4.camera(camera.position, camera.orientation)
	for entity in entities:elements() do
		if entity ~= camera then -- if entity == camera then continue end >:(
			if entity.particle then
				love.graphics.setShader(particleShader)
				love.graphics.setWireframe(true)
				particleShader:send("useFalloff", false)
				drawParticle(entity, projectionMatrix, cameraMatrix)
			else
				love.graphics.setShader(meshShader)
				love.graphics.setWireframe(false)
				love.graphics.setColor(entity.colour)
				local modelMatrix = mat4.transform(entity.position, entity.orientation)
				meshShader:send("modelToScreen", {mat4.elements(projectionMatrix * cameraMatrix * modelMatrix)})
				love.graphics.draw(entity.mesh)
			end
		end
	end
	-- local n = 0
	love.graphics.setWireframe(true)
	love.graphics.setShader(particleShader)
	for x, sectorsX in pairs(spaceDustSectors) do
	if x ~= "num" then -- if x == "num" then continue end >:(
		for y, sectorsXY in pairs(sectorsX) do
		if y ~= "num" then -- if y == "num" then continue end >:(
			for z, sector in pairs(sectorsXY) do
			if z ~= "num" then -- if z == "num" then continue end >:(
				for i = 1, #sector do
					-- n = n + 1
					local particle = sector[i]
					particleShader:send("useFalloff", true)
					particleShader:send("renderDistance", consts.distanceToKeepSpaceDustSectors * consts.spaceDustSectorSize)
					particleShader:send("fogRange", consts.spaceDustFogRange)
					drawParticle(particle, projectionMatrix, cameraMatrix)
				end
			end
			end
		end
		end
	end
	end
	-- print(n)
	love.graphics.setCanvas()
	love.graphics.setShader()
	love.graphics.setWireframe(false)
	love.graphics.setColor(1, 1, 1)
	
	-- OpenGL --> LÖVE
	love.graphics.scale(1, -1)
	love.graphics.translate(0, -love.graphics.getHeight())
	
	love.graphics.draw(canvas)
end
