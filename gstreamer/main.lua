
socket = mona:createUDPSocket()
function socket:onPacket(data, address)
	-- consider just video and audio packets
	if data:byte(1) ~= 0x09 and data:byte(1) ~= 0x08 then return end
	-- compute time
	local time = data:byte(5)*65536+data:byte(6)*256+data:byte(7)
	if not starttime or starttime>time then starttime = time end
	time = time-starttime
	if not lasttime or time<lasttime then
		-- start or restart publication
		if testpublication then testpublication:close() end
		testpublication = mona:publish("file")
		if not testpublication then error("already published") end
	end
	lasttime = time
	
	-- publish
	if data:byte(1)==0x09 then
		testpublication:pushVideo(time, data:sub(12,#data-4)) -- offset 11
	else
		testpublication:pushAudio(time, data:sub(12,#data-4)) -- offset 11
	end
	testpublication:flush()
end
NOTE("gstreamer-catch server started on 0.0.0.0:6666 : ", socket:bind("0.0.0.0:6666"))