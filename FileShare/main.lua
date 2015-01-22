
files = {}

function onConnection(client)
	
	-- Register the filename
	function client:registerFile(filename)
		if not filename or filename == "" then error("no filename") end
		
		-- If filename already used : add an extension (_X)
		if files[filename] then
			local extension = 0
			while files[filename.."_"..extension] do
				extension = extension + 1	
			end
			filename = filename.."_"..extension
		end
		
		files[filename] = {sharing=1, downloading=0, peers={}}
		files[filename].peers[client] = "sharing"
		client.file = filename
		NOTE("Created group : ", filename)
		return filename
	end
	
	-- Record the new downloader
	function client:newDownloader(filename)
		if not files[filename] then error("Incorrect group name in newDownloader()") end
		
		client.file = filename
		files[filename].peers[client] = "downloading"
		files[filename].downloading = files[filename].downloading + 1
		INFO("New Downloader on ", filename, " : ", files[filename].downloading)
		updatePeersInfos(filename)
	end
	
	-- Record the new sharing peer
	function client:newSharer(filename)
		if not files[filename] then error("Incorrect group name in newSharer()") end
		
		files[filename].peers[client] = "sharing"
		files[filename].downloading = files[filename].downloading - 1
		files[filename].sharing = files[filename].sharing + 1
		INFO("New Share peer on ", filename, " : ", files[filename].sharing)
		updatePeersInfos(filename)
	end
	
	-- A peer is gone => update objects
	function client:onUnjoinGroup(group)
		if client.file and files[client.file] and files[client.file].peers[client] then
		  INFO("A ", files[client.file].peers[client], " client from group ", client.file, " is gone")
		  
		  if files[client.file].peers[client] == "sharing" then
	
			  files[client.file].sharing = files[client.file].sharing - 1
			  if files[client.file].sharing < 1 then
				  files[client.file] = nil
				  NOTE("Group ", client.file, " has been deleted")
				  return
			  end
		  else
			  files[client.file].downloading = files[client.file].downloading - 1
		  end
		  files[client.file].peers[client] = nil
		  updatePeersInfos(client.file)
		end
	end
	
	return {index="FileShare.html"}
end

-- Send number of sharing & downloading peers to each peer of the group
function updatePeersInfos(filename)
	if not files[filename] then return end
	
	local group = files[filename]
	for c, state in pairs(group.peers) do
		c.writer:writeInvocation("updateInfos", group.downloading, group.sharing)
	end
end
