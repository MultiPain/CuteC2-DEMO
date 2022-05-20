local PI = math.pi

RayScene = Core.class(BaseScene, function() return "Dark", true end)

function RayScene:init()
	self.ray = Ray.new(100, 400, 300, 400)
	self.objects = {}
	self:createRandomShapes(self.objects, 6)
end

function RayScene:onDrawUI()
	local ui = self.ui	
	local list = ui:getForegroundDrawList()
	
	self.ray:onDraw(ui, self.filledShapes, self.drawAlpha)
	
	local ray = self.ray.collisionShape
	for i, shape in ipairs(self.objects) do 
		shape:onDraw(ui, self.filledShapes, self.drawAlpha)
		local hit, normalX, normalY, t = shape.collisionShape:rayTest(ray, shape.transform)
		
		if (hit) then 
			local sx, sy = ray:getStartPosition()
			local tx, ty = ray:getTargetPosition()
			local hitX = sx + tx * t
			local hitY = sy + ty * t
			list:addCircle(hitX, hitY, 4, 0x00ff00, 1)
			list:addLine(hitX, hitY, hitX + normalX * 20, hitY  + normalY * 20, 0x00ff00, 1)
		end
	end
end