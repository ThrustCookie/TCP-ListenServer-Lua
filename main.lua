--Modified code from the vesion shown by totex here https://www.youtube.com/watch?v=qVWOaRYpli0 and here https://github.com/totex/My-minigames/tree/master/Love2d-UDP-networking

--relevant documentation
--https://defold.com/ref/alpha/socket-lua/#client:receive:pattern-prefix
--https://lunarmodules.github.io/luasocket/tcp.html
--https://love2d.org/wiki/Tutorial:Networking_with_UDP 

--the forum that made this tcp work https://stackoverflow.com/questions/42783263/lua-tcp-ip-simple-client-server-connection


local socket = require('socket')
local address, port = "localhost", 12345

local conn_type
local world
local tcp

local server = {}
local client = {}

function love.load()
    tcp = socket.tcp()
    world = {
        server = { x = 100, y = 100, },
        client = { x = 400, y = 100, },
    }
end

function love.keypressed( key, isrepeat )
    if key == 'c' then -- client
        client.load()
        conn_type = 'client'
        
    elseif key == 's' then -- server
        server.load()
        conn_type = 'server'
    end
end

local function split(s, delimiter)
	local result = {}
	for match in (s..delimiter):gmatch("(.-)"..delimiter) do
		result[#result+1] = match
	end
	return result
end


function client.load()
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

function server.load()
    assert(tcp:bind(address, port))
    assert(tcp:listen(1))
    print("Server Started", tcp:getsockname())

    tcp:settimeout(0)
end
function server.update()
    if server.client == nil then --- looks for connection
        local error
        server.client, error = tcp:accept()
        if error and error ~= 'timeout' then print(error) end
        return
    end
    world.server.x, world.server.y = love.mouse.getPosition()
    local pos = string.format("%d-%d\n", world.server.x, world.server.y)
	server.client:send(pos)

	local data, error, partial = server.client:receive()
    if error and error ~= 'timeout' then
        if error == 'closed' then
            print('client disconected')
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

function love.draw()
	love.graphics.setColor(0, 1, 0)
	love.graphics.rectangle("fill", world.server.x, world.server.y, 50, 50)

	love.graphics.setColor(1, 0, 0)
	love.graphics.rectangle("fill", world.client.x, world.client.y, 50, 50)
    
	love.graphics.setColor(1, 1, 1)
    if conn_type then
        love.graphics.print(conn_type,0,0)
    end
end

function love.quit()
    if tcp then tcp:close() end
end

