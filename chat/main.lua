-- Test client for push

writers = {}

-- Function for parsing data coming from a client
-- Prevent formatting problems
function parseMessage(bytes)
	
	if type(bytes) == "string" then
		return bytes
	else
		-- TODO I don't remind me why a table can be a well formed message
		if type(bytes) == "table" and type(bytes[1]) == "string" then  -- prevent date parsing
			return bytes[1]
		else
			WARN("Error in message formatting : ", mona:toJSON(bytes))
			return bytes[1]
		end
	end
end

function onConnection(client,...)
	
	INFO("Connection of a new client to the chatroom")
	writers[client] = nil
  
	-- Identification function
	function client:onIdentification(bytes)
	
		local name = parseMessage(bytes)
		
		if name then
			INFO("Trying to connect user : ", name)
			
			-- Send all current users
			for user,peerName in pairs(writers) do
				client.writer:writeInvocation("onEvent", "connection", peerName)
			end
			
			writers[client] = name
			writeMsgToChat("", "User "..name.." has joined the chatroom!")
			sendEventToUsers("connection", name)
		end
	end
  
	-- Reception of a message from a client
	function client:onMessage(bytes)
  
		nameClient = writers[client]
		local message = parseMessage(bytes)
		
		if not nameClient then
			WARN("Unauthentied user has tried to send a message : ", mona:toJSON(message))
		else
			if message then
				INFO("New message from user "..nameClient.." : ")
				INFO(mona:toJSON(message))
				writeMsgToChat(nameClient..">", message)
			end
		end
	end
end

-- send an event to each client
function sendEventToUsers(event, userName)
  for user,name in pairs(writers) do
      user.writer:writeInvocation("onEvent", event, userName)
  end
end

-- send the message to each clients
function writeMsgToChat(prompt, message)
  for user,name in pairs(writers) do
      user.writer:writeInvocation("onReception", prompt, message)
  end
end

function onDisconnection(client)

  local name = writers[client]
  if name then
    writers[client] = nil
    writeMsgToChat("", "User "..name.." has quit the chatroom!")
	sendEventToUsers("disconnection", name)
  end
end