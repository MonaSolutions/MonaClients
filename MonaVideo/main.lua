
local listNames = {}

function onConnection(client,...)
	
	INFO("Connection to MonaVideo from ip ", client.address, " (protocol: ", client.protocol, ")")
	
	local userAgent = client.properties["User-Agent"]
	if userAgent and string.find(userAgent, "Mobile") then
		return {index="MonaVideoMobile.html"}
	end
	
	-- Connection from a peer
	-- name : name of the meeting
	-- matrix : transformation to apply on the remote camera
	function client:sendName(name, angle)
		
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
				client.angle = angle
				listNames[name].client2 = client
				
				-- Send client2 Id to client1
				listNames[name].client1.writer:writeInvocation("connect2Peer", client.id, client.angle, false)
				
				-- Return client1 Id to client2
				return { id=listNames[name].client1.id, angle=listNames[name].client1.angle }
			end
		else -- Create the meeting object
			NOTE("Creating meeting session '", name, "'")
			
			client.meetingName = name
			client.angle = angle
			listNames[name] = { client1=client, client2=nil }
			return nil
		end
	end
	return {index="MonaVideo.html"}
end

function onDisconnection(client)
	if client.meetingName then
		local meeting = listNames[client.meetingName]
		
		-- Stop the meeting & delete it
		if meeting then
			NOTE("A client is gone from ", client.meetingName, ", deleting the session...")
			if client == meeting.client1 and meeting.client2 then meeting.client2.writer:writeInvocation("onChange", "disconnect") end
			if client == meeting.client2 and meeting.client1 then meeting.client1.writer:writeInvocation("onChange", "disconnect") end
			listNames[client.meetingName] = nil
		end
	end
end