local vm={}

vm.new=function(vm)
	return {
		INT     = 0,
		PC      = 0,
		SP      = 0,
		program = {},
		stack   = {}
	}
end

vm.run=function(vm,instance)
	while instance.INT==0 do
		
	end
end

return vm