print_table = function (table, space, called)
	space = space or ''
	called = called or 1
	
	if (called == 1) then
		space = ''
	end
	
	for key, value in pairs(table) do
		local obj_type = type(value)
		
		if ( obj_type == 'function') then
			print(space..key..' : function () {...}')
		elseif ( obj_type == 'table' ) then
			print(space..key..' ('..obj_type..') { }')
			print_table(value, space..'     ', called + 1)
		elseif ( obj_type == 'boolean' ) then
			local str = 'false'
			if (value) then
				str = 'true'
			end
			str = str..' ('..obj_type..')'
			print(space..key..' : '..str)
		elseif ( obj_type == 'nil' ) then
			print(space..key..' : nil')
		else
			print(space..key..' : '..value..' ('..obj_type..')')
		end
	end
end