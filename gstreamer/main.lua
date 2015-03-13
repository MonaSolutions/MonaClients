--[[
    This script allows you to publish a stream named "file" from a gstreamer instance.
    
    Follow these steps to test the publication :
    
    1. Copy this directory in the "www/gstreamer/" directory of MonaServer,
    2. Edit the www/main.lua file to add the line 'children("gstreamer")' in order to start this service at Mona's start,
    3. Run MonaServer,
    4. Install gstreamer and run the following command :
    
        gst-launch-1.0 videotestsrc pattern=smpte is-live=true ! timeoverlay font-desc="Serif,Medium 40" color=4294901760 ! x264enc bitrate=128 tune=zerolatency ! queue ! mux. audiotestsrc wave=ticks ! audioconvert ! speexenc bitrate=8000 ! queue ! mux. flvmux name=mux ! udpsink port=6666 host=127.0.0.1
        
    5. And then listen to the RTMP (rtmp://127.0.0.1/file) or RTMFP address (rtmfp://127.0.0.1/file) to see the result, you can use our sample VideoPlayer at http://raspi.monaserver.ovh/MonaClients/VideoPlayer/.
]]

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