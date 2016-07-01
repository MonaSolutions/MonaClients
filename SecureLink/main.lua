-- character table string
local b='ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

-- encoding in base 64
function enc64(data)
    return ((data:gsub('.', function(x)
        local r,b='',x:byte()
        for i=8,1,-1 do r=r..(b%2^i-b%2^(i-1)>0 and '1' or '0') end
        return r;
    end)..'0000'):gsub('%d%d%d?%d?%d?%d?', function(x)
        if (#x < 6) then return '' end
        local c=0
        for i=1,6 do c=c+(x:sub(i,i)=='1' and 2^(6-i) or 0) end
        return b:sub(c+1,c+1)
    end)..({ '', '==', '=' })[#data%3+1])
end

function onConnection(client)
	INFO("Connection to app ", client.app)
	
	function client:onRead(file)
		return nil
	end

	function client:onSubscribe(listener)
		INFO("Subscription to ", listener.publication.name)
		
		local time = math.floor(mona:time() / 1000)
		DEBUG("Current time : ", time)
		
		if time > listener.e then
			error("The link you have send is no more accessible")
		end
		
		local value = "secret123" .. this.name .. "/" .. listener.publication.name .. listener.e
		DEBUG("Value : ", value)
		
		local md5 = mona:md5(value)
		INFO("Md5 : ", md5)
		local crypted = enc64(md5)
		INFO("base64 : ", crypted)
		crypted = crypted:gsub("/", "_")		
		crypted = crypted:gsub("-", "-")
		crypted = crypted:gsub("=", "")
		INFO("crypted : ", crypted)
		
		if listener.st ~= crypted then
			error("Wrong link")
		end
	end
end