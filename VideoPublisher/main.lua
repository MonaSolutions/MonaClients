
function onConnection(client)
	
	INFO("Connection of client from address ", client.address)
	
	function client.dumpON()
		NOTE("Dump activated")
		client.dump = true
	end
	
	function client:onPublish(publication)
		
		if not client.dump then return end
		
		-- ************** DUMP FLV ****************	
		local pathFile = mona:absolutePath(path) .. "dump_" .. publication.name .. ".flv"
		NOTE("Begin dumping file 'dump_" , publication.name , ".flv'")
		publication.file = io.open(pathFile, "wb")
		publication.file:write("\x46\x4c\x56\x01\x05\x00\x00\x00\x09\x00\x00\x00\x00") -- audio and video
		--publication.file:write("\x46\x4c\x56\x01\x04\x00\x00\x00\x09\x00\x00\x00\x00") -- audio
		
		function publication:onVideo(time,packet)
			publication:write("\x09", time, packet)
		end
		
		function publication:onAudio(time,packet)
			publication:write("\x08", time, packet)
		end
		
		-- MediaContainer FLV maker
		function publication:write(amfType, time, packet)
			
			publication.file:write(amfType) -- type
			local hexSize = string.gsub(string.format("%06X",#packet), "..", function(a) return string.char(tonumber(a,16)) end)
			publication.file:write(hexSize) -- size on 3 bytes
			local hexTime = string.gsub(string.format("%06X",time), "..", function(a) return string.char(tonumber(a,16)) end)
			publication.file:write(hexTime)  -- time on 3 bytes
			publication.file:write("\x00\x00\x00\x00") -- unknown 4 bytes set to 0
			publication.file:write(packet) -- packet
			local hexFooter = string.gsub(string.format("%08X",11+#packet), "..", function(a) return string.char(tonumber(a,16)) end)
			publication.file:write(hexFooter)  -- footer
		end
		
	end
	
	function client:onUnpublish(publication)
		if publication.file then
			NOTE("End dumping file 'dump_" , publication.name , ".flv'")
			publication.file:close()
		end
	end
	return {index="VideoPublisher.html"}
end