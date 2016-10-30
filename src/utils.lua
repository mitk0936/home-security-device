print_table = function (table, space)
	space = space or ""
	
	for key, value in pairs(table) do
		local obj_type = type(value)
		
		if ( obj_type == "function") then
			print(space..key.." : function () {...}")
		elseif ( obj_type == "table" ) then
			print(space..key.." { } ->")
			print_table(value, space.."     ")
		elseif ( obj_type == "boolean" ) then
			local str = "false"
			if (value) then
				str = "true"
			end
			print(space..key.." : "..str)
		elseif ( obj_type == "nil" ) then
			print(space..key.." : nil")
		else
			print(space..key.." : "..value)   
		end
	end
end