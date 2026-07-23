--Modified code from the vesion shown by totex here https://www.youtube.com/watch?v=qVWOaRYpli0 and here https://github.com/totex/My-minigames/tree/master/Love2d-UDP-networking

--relevant documentation
--https://defold.com/ref/alpha/socket-lua/#client:receive:pattern-prefix
--https://lunarmodules.github.io/luasocket/tcp.html
--https://love2d.org/wiki/Tutorial:Networking_with_UDP 

--the forum that made this tcp work https://stackoverflow.com/questions/42783263/lua-tcp-ip-simple-client-server-connection


local socket = require('socket')
local address, port = "localhost", 12345

local conn_type ---@type 'client' | 'server' | nil
local tcp

local server = {}
local client = {}
local connected

local msg = 'Hello World!Hello World!Hello World!Hello World!Hello World!123 123 123 123 123 123'
local compressed
local decompressed

local format = 'zlib'

function love.load()
    tcp = socket.tcp()
end

local function send_msg()
    if not connected then return end

    compressed = love.data.compress('string', format, msg, 1)
    connected:send(conn_type..": "..compressed..'\n')
end

function client.load()
    assert(tcp:connect(address, port))
    print("Connected to: ", tcp:getpeername())
    tcp:settimeout(0)
    connected = tcp
end

function server.load()
    assert(tcp:bind(address, port))
    assert(tcp:listen(1))
    print("Server Started", tcp:getsockname())
    tcp:settimeout(0)
end

local function look_for_connection()
    local error
    connected, error = tcp:accept()
    if error and error ~= 'timeout' then print(error) end

    if connected then
        connected:settimeout(0)
    end
end

local function socket_check_data()
    local data, error, partial = connected:receive()

    if error and error ~= 'timeout' then
        if error == 'closed' then
            print('disconected')
            connected = nil
        else
            print(error, partial)
        end
        return
    end

	if data then
		print(data)
        decompressed = love.data.decompress('string', format, data)
	end
end

local update_rate = 0.1
local t = 0
function love.update(dt)
    t = t + dt
    if t > update_rate then
        if connected then
            socket_check_data()

        elseif not connected then
            if conn_type == 'server' then
                look_for_connection()
            end
        else
            
        end
        t = t - update_rate
    end
end

function love.draw()
    for i, value in pairs({
        conn_type,
        msg,
        decompressed,
    }) do
        if value then
            love.graphics.print(value,0,15*i)
        end
    end
end

function love.keypressed( key, isrepeat )
    if not conn_type then
        if key == 'c' then -- client
            client.load()
            conn_type = 'client'
            
        elseif key == 's' then -- server
            server.load()
            conn_type = 'server'
        end
        return
    end
    if key == 'return' then
        send_msg()
    end
end

function love.quit()
    if tcp then tcp:close() end
end

