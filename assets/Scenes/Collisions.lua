require "Shapes"

local function drawManifold(ui, ...)
	ui:text(("Count: %d\nDepths: [%f, %f]\nPoint1: [%f, %f]\nPoint2: [%f, %f]\nNormal: [%f, %f]"):format(...))
end

CollisionsScene = Core.class(BaseScene, function() return "Dark", true end)

function CollisionsScene:init()
	
	self.objects = {}
	self:createRandomShapes(self.objects, 8)
end

function CollisionsScene:onDrawUI()
	local ui = self.ui
	local list = ui:getForegroundDrawList()
	
	for i,obj in ipairs(self.objects) do 
		obj:onDraw(ui, self.filledShapes, self.drawAlpha)
		
		for j, other in ipairs(self.objects) do 
			local t = other:getType()
			
			if (obj ~= other) then 
				local mainfold = CuteC2.collide(obj.collisionShape, other.collisionShape, obj.transform, other.transform)
				
				if (mainfold.count > 0) then 
					local nx = mainfold.normal.x
					local ny = mainfold.normal.y
					local d = mainfold.depths[1]
					local x, y = 0, 0
					if (t == CuteC2.TYPE_POLY) then 
						x, y = other.transform:getPosition()
					else
						x, y = other.collisionShape:getPosition()
					end
					
					local sx = x + nx * d
					local sy = y + ny * d
					
					if (t == CuteC2.TYPE_AABB) then 
						local w, h = other.collisionShape:getSize()
						drawRect(list, sx, sy, sx + w, sy + h, self.filledShapes, 0xff0000, self.drawAlpha)
					elseif (t == CuteC2.TYPE_CIRCLE) then 
						local r = other.collisionShape.radius
						drawCircle(list, sx, sy, r, self.filledShapes, 0xff0000, self.drawAlpha)
					elseif (t == CuteC2.TYPE_CAPSULE) then 
						local r = other.collisionShape.radius
						local h = other.collisionShape.height
						drawCapsule(list, sx, sy, h, r, self.filledShapes, 0xff0000, self.drawAlpha)
					elseif (t == CuteC2.TYPE_POLY) then 
						local points = other.collisionShape:getPoints()
						local tmpX, tmpY = other.transform:getPosition()
						other.transform:setPosition(sx, sy)
						
						drawPoly(list, points, other.transform, self.filledShapes, 0xff0000, self.drawAlpha)
						
						other.transform:setPosition(tmpX, tmpY)
					end
				end
			end
		end
	end
end