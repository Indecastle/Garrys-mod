local bezier = {}

----------------------------------------

function bezier.quadratic(p1, p2, p3, t)
	local ti = 1 - t
	
	return ti * (ti * p1 + t * p2) + t * (ti * p2 + t * p3)
end

function bezier.cubic(p1, p2, p3, p4, t)
	local ti = 1 - t
	
	local p6 = ti * p2 + t * p3
	
	return ti * (ti * (ti * p1 + t * p2) + t * p6) + t * (ti * p6 + t * (ti * p3 + t * p4))
end

----------------------------------------

return bezier