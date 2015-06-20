-- Server application for the flex client MonaStatus (can work with other clients)

-- Useful functions
function getCongestion(qos)
  
  local congestion = qos.lostRate
  if qos.lastLatency and qos.lastLatency>0 then
	congestion = congestion + (qos.latency-qos.lastLatency) / qos.lastLatency
  end
  qos.lastLatency = qos.latency
  if congestion > 1 then return 1 elseif congestion < 0 then congestion = 0 end
  return congestion
end

-- Events

function onConnection(client,response,...)
  INFO("Connection to status")
  
  -- Generate the array of publications
  function client:getStatistics(name)
    
    local res = {publications={}, listeners={}, clients=#mona.clients}
    for k,pub in pairs(mona.publications) do
        local pubLine = {}
        pubLine.Name = pub.name
        pubLine.Listeners = #pub.listeners
        pubLine["Dropped Frames"] = pub.droppedFrames
        pubLine["Byte Rate"] = "Video: " .. math.floor(pub.videoQOS.byteRate/125) .. "kb/s\nAudio: " .. math.floor(pub.audioQOS.byteRate/125) .. "kb/s"
        pubLine.Lost = string.format("%.3f",pub.videoQOS.lostRate*100) .. "%\n" .. string.format("%.3f",pub.audioQOS.lostRate*100) .. "%"
        pubLine.Latency = pub.videoQOS.latency .. "ms\n" .. pub.audioQOS.latency .. "ms"
        local currentTime = mona:time()
        pubLine["Congestion"] = math.floor(getCongestion(pub.videoQOS)*100) .. "%\n" .. math.floor(getCongestion(pub.audioQOS)*100) .. "%"
        pubLine["Last Send"] = math.floor(currentTime-pub.videoQOS.lastSendingTime) .. "ms\n" .. math.floor(currentTime-pub.audioQOS.lastSendingTime) .. "ms"
        
        table.insert(res.publications, pubLine)
    end
	
	-- Get listeners of publication
	if name then self:getListeners(name, res) end
    
    return res
  end
  
  -- Generate the array of listeners from one publication
  function client:getListeners(publicationName, res)
    
    local pub = mona.publications[publicationName]
    if not pub then return end
    
    for c,l in pairs(pub.listeners) do
        local listenerLine = {}
        
        listenerLine["Dropped Frames"] = l.droppedFrames and (l.droppedFrames + pub.droppedFrames) or pub.droppedFrames
        listenerLine["Byte Rate"] = "Video: " .. math.floor(l.videoQOS.byteRate/125) .. "kb/s\nAudio: " .. math.floor(l.audioQOS.byteRate/125) .. "kb/s"
        listenerLine.Lost = string.format("%.3f",l.videoQOS.lostRate*100) .. "%\n" .. string.format("%.3f",l.audioQOS.lostRate*100) .. "%"
        listenerLine.Latency = l.videoQOS.latency .. "ms\n" .. l.audioQOS.latency .. "ms"
        local currentTime = mona:time()
        listenerLine["Congestion"] = math.floor(getCongestion(l.videoQOS)*100) .. "%\n" .. math.floor(getCongestion(l.audioQOS)*100) .. "%"
        listenerLine["Last Send"] = math.floor(currentTime-l.videoQOS.lastSendingTime) .. "ms\n" .. math.floor(currentTime-l.audioQOS.lastSendingTime) .. "ms"
        
        table.insert(res.listeners, listenerLine)
    end
  end
  
  -- RPC
  
  -- Call this from listeners to update the droppedFrames counter
  function client:updateDroppedFrames(publicationName, clientId, droppedFrames)
    local pub = mona.publications[publicationName]
    if not pub then return false end
    
    -- Search the listener and update droppedFrame value
    for c,l in pairs(pub.listeners) do
      if clientId == l.client.id then
        l.droppedFrames = droppedFrames
        return true
      end
    end
    return false
  end
  
  return {index="index.html"}
end

function onDisconnection(client)
end
