local http = table.copy(http)
local queue = {}

----------------------------------------

do
	function http.get2(...)
		table.insert(queue, {
			type = "get",
			args = {...}
		})
	end
	
	function http.post2(...)
		table.insert(queue, {
			type = "post",
			args = {...}
		})
	end
end

----------------------------------------

hook.add("think", "lib_http", function()
	while #queue > 0 and http.canRequest() do
		http[queue[1].type](unpack(queue[1].args))
		
		table.remove(queue, 1)
	end
end)

----------------------------------------

return http