local socket = require('socket')
local address, port = "localhost", 12345

local conn_type
local world = {}

local tcp

function love.load()
    tcp = socket.tcp()
    world = {
        server = { x = 100, y = 100, },
        client = { x = 400, y = 100, },
    }
end

local function split(s, delimiter)
	local result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		table.insert(result, match)
	end
	return result
end

local client = {}
function client.load()
    local error
    assert(tcp:connect(address, port))
    print("Connected to: ", tcp:getpeername())
    tcp:settimeout(0)
end
function client.update()
    world.client.x, world.client.y = love.mouse.getPosition()
    local pos = string.format("%d-%d\n", world.client.x, world.client.y)
	tcp:send(pos)

	local data, error, partial = tcp:receive()
    if error then assert(error == "timeout", error, partial) end

	if data then
		local p = split(data, '-')
		world.server.x, world.server.y = p[1], p[2]
	end
end

local server = {}
function server.load()
    assert(tcp:bind(address, port))
    assert(tcp:listen(1))
    print("Server Started")

    tcp:settimeout(0)
end
function server.update()
    if server.client == nil then
        local error
        server.client, error = tcp:accept()
        if error and error ~= 'timeout' then print(error) end
        return
    end
    server.client:receive()

    world.server.x, world.server.y = love.mouse.getPosition()
    local pos = string.format("%d-%d\n", world.server.x, world.server.y)
	server.client:send(pos)

	local data, error, partial = server.client:receive()
    if error and error ~= timeout then
        if error == 'closed' then
            server.client = nil
            return
        end
        print(error, partial)

    end

	if data then
		local p = split(data, '-')
		world.client.x, world.client.y = p[1], p[2]
	end
end

local update_rate = 0.1
local t = 0
function love.update(dt)
    t = t + dt
    if t > update_rate then
        if conn_type == 'client' then
            client.update()
        elseif conn_type == 'server' then
            server.update()
        end
        t = t - update_rate
    end
end

function love.keypressed( key, isrepeat )
    if key == 'c' then -- client
        client.load()
        conn_type = 'client'
        
    elseif key == 's' then -- server
        server.load()
        conn_type = 'server'

    elseif key == "t" then
        if conn_type then print(conn_type) end
    end
end

function love.draw()
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", world.server.x, world.server.y, 50, 50)

	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("fill", world.client.x, world.client.y, 50, 50)
end

function love.quit()
    if tcp then
        tcp:close()
    end
end

