
_clients = {}

function onConnection(client,...)
	if (client.protocol=="WebSocket") then _clients[client]=client end
	
	function client:initClient()
		INFO("Init client, actuator: ", data.actuator, " - pool : ", data.pool, " - lamp ON : ", data.lampON)
		
		-- First Initialisation
		if data.pool == nil then
			data.pool = 0
			data.actuator = 0
			data.lampON = 0
		end
		
		client.writer:writeMessage("setActuator", tonumber(data.actuator))
		client.writer:writeMessage("setPool", tonumber(data.pool))
		client.writer:writeMessage('setLamp', data.lampON)
	end
		
	function client:onCursor(value)
		data.actuator = value
		NOTE("actuator: ", data.actuator)
		sendToClients('setActuator', tonumber(data.actuator))
	end
	
	function client:onPoolAdd(value)
		if value > 50 then return end
		
		data.pool = value + 1
		NOTE("pool : ", data.pool)
		sendToClients('setPool', tonumber(data.pool))
	end
	
	function client:onPoolDel(value)
		if value < -10 then return end
		
		data.pool = value - 1
		NOTE("pool : ", data.pool)
		sendToClients('setPool', tonumber(data.pool))
	end
	
	function client:onLamp(lampON)
		NOTE("lamp ON : ", lampON)
		data.lampON = lampON
		sendToClients('setLamp', data.lampON)
	end
	
	return { index="index.html" }
end

function sendToClients(event, value)
	
	for client, c in pairs(_clients) do
		client.writer:writeMessage(event, value)
	end
end

function onDisconnection(client)
	_clients[client]=nil
end