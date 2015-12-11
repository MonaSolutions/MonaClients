
textShared = {}

function onConnection(client)
	
	-- Register the text
	function client:registerPage(name)
		if not name or name == "" then error("no text name") end
		
		if textShared[name] ~= nil then -- already exists : notify other peers
			
			local group = textShared[name]
			textShared[name].sharing=1
			textShared[name].downloading=0
			for c, state in pairs(group.peers) do
				if c ~= client then
					c.writer:writeInvocation("resetPage")
					textShared[name].peers[c] = "downloading"
				end
			end
			INFO("Reseted group text : ", name)
		else -- new sender
		
			textShared[name] = {sharing=1, downloading=0, peers={}}
			textShared[name].peers[client] = "sharing"
			client.groupName = name
			NOTE("Created group : ", name)
		end
		
		return name
	end
	
	-- Record the new downloader
	function client:newDownloader(name)
		if not textShared[name] then error("Incorrect group name in newDownloader()") end
		
		client.groupName = name
		textShared[name].peers[client] = "downloading"
		textShared[name].downloading = textShared[name].downloading + 1
		INFO("New Downloader on ", name, " : ", textShared[name].downloading)
		updatePeersInfos(name)
	end
	
	-- Record the new sharing peer
	function client:newSharer(name)
		if not textShared[name] then error("Incorrect group name in newSharer()") end
		
		textShared[name].peers[client] = "sharing"
		textShared[name].downloading = textShared[name].downloading - 1
		textShared[name].sharing = textShared[name].sharing + 1
		INFO("New Share peer on ", name, " : ", textShared[name].sharing)
		updatePeersInfos(name)
	end
	
	-- A peer is gone => update objects
	function client:onUnjoinGroup(group)
		if client.groupName and textShared[client.groupName] and textShared[client.groupName].peers[client] then
		  INFO("A ", textShared[client.groupName].peers[client], " client from group ", client.groupName, " is gone")
		  
		  if textShared[client.groupName].peers[client] == "sharing" then -- was a sender?
	
			  textShared[client.groupName].sharing = textShared[client.groupName].sharing - 1
			  if textShared[client.groupName].sharing < 1 then -- last sender is gone : delete the group object
				  textShared[client.groupName] = nil
				  NOTE("Group ", client.groupName, " has been deleted")
				  return
			  end
		  else -- was a receiver?
			  textShared[client.groupName].downloading = textShared[client.groupName].downloading - 1
		  end
		  textShared[client.groupName].peers[client] = nil
		  updatePeersInfos(client.groupName)
		end
	end
	
	return {index="index.html"}
end

-- Send number of sharing & downloading peers to each peer of the group
function updatePeersInfos(name)
	if not textShared[name] then return end
	
	local group = textShared[name]
	for c, state in pairs(group.peers) do
		c.writer:writeInvocation("updateInfos", group.downloading, group.sharing)
	end
end
