
function onConnection(client)
	
	INFO("Connection of client from address ", client.address)
	
	function client.dumpON()
		NOTE("Dump activated")
		client.dump = true
	end
	
	function client:onPublish(publication)
		
		if not client.dump then return end
		
		-- ************** DUMP FLV ****************	
		local pathFile = mona:absolutePath(path) .. "dump_" .. publication.name .. ".ts"
		NOTE("Begin dumping file 'dump_" , publication.name , ".ts'")
		publication.file = io.open(pathFile, "wb")
        publication.flvWriter = mona:createMediaWriter("mp2t")
		
		function publication:onVideo(time,packet)
			publication:write(2, time, packet)
		end
		
		function publication:onAudio(time,packet)
			publication:write(1, time, packet)
		end
		
		-- MediaContainer FLV maker
		function publication:write(amfType, time, packet)
			
            local flvData = publication.flvWriter:write(amfType, time, packet)
            publication.file:write(flvData)
		end
		
	end
	
	function client:onUnpublish(publication)
		if publication.file then
			NOTE("End dumping file 'dump_" , publication.name , ".ts'")
			publication.file:close()
		end
	end
	return {index="VideoPublisher.html"}
end