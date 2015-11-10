
local listNames = {}

function onConnection(client,...)
	
	INFO("Connection to HiMona from ip ", client.address, " (protocol: ", client.protocol, ")")
	
	-- Connection from a peer
	-- name : name of the meeting
	function client:sendName(name)
		
		if name=="" then
			client.writer:writeInvocation("onChange","noname")
			return nil
		end
		
		-- Meeting object already exist
		if listNames[name] then
			
			-- 2 Clients are already connected to this meeting!
			if listNames[name].client2 then
				client.writer:writeInvocation("onChange","roomfull")
				return nil
			else -- connect the caller
				NOTE("A new peer is joining session '", name, "'")
				
				client.meetingName = name
				listNames[name].client2 = client
				
				-- Send client2 Id to client1
				listNames[name].client1.writer:writeInvocation("connect2Peer", client.id)
				
				-- Return client1 Id to client2
				return { id=listNames[name].client1.id }
			end
		else -- Create the meeting object
			NOTE("Creating meeting session '", name, "'")
			
			client.meetingName = name
			listNames[name] = { client1=client, client2=nil }
			return nil
		end
	end
    
  -- Send a command to the other peer
  function client:sendCommand(command, ...)
    INFO("Command '", command, "' received, arguments : ", ...)
    if client.meetingName then
      local meeting = listNames[client.meetingName]
      
      if meeting then
        if client == meeting.client1 and meeting.client2 then meeting.client2.writer:writeInvocation(command, ...) end
        if client == meeting.client2 and meeting.client1 then meeting.client1.writer:writeInvocation(command, ...) end
        return ...
      end
    end
    error("Client is not in a meeting")
  end
  
  return {index="index.html"}
end

function onDisconnection(client)
	if client.meetingName then
		local meeting = listNames[client.meetingName]
		
		-- Stop the meeting & delete it
		if meeting then
      local meeter = nil
			if client == meeting.client1 and meeting.client2 then meeter = meeting.client2
      elseif client == meeting.client2 and meeting.client1 then meeter = meeting.client1 end
      
      if meeter then
        NOTE("A client is gone from ", client.meetingName, ", deleting the session...")
        meeter.writer:writeInvocation("onChange", "disconnect")
        listNames[client.meetingName] = nil
      else
        INFO("Meeter from ", client.meetingName, " already deleted, nothing to do")
      end
		end
	end
end