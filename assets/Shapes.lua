--!NOEXEC
local SEGMENTS = 0
local GID = 1

function drawCircle(list, x, y, r, isFilled, color, alpha)
	if (isFilled) then 
		list:addCircleFilled(x, y, r, color, alpha, SEGMENTS)
		list:addCircle(x, y, r, 0, 1, SEGMENTS)
	else
		list:addCircle(x, y, r, color, alpha, SEGMENTS)
	end
end

function drawRect(list, x1,y1,x2,y2, isFilled, color, alpha)
	if (isFilled) then 
		list:addRectFilled(x1,y1,x2,y2, color, alpha)
		list:addRect(x1,y1,x2,y2, 0, 1)
	else
		list:addRect(x1,y1,x2,y2, color, alpha)
	end
end

function drawCapsule(list, x,y,h,r, isFilled, color, alpha)
	list:pathArcTo(x, y, r, 0, -3)
	list:pathArcTo(x, y + h, r, 3, 0)
	
	if (isFilled) then 
		list:pathFillConvex(color, alpha)
		
		list:pathArcTo(x, y, r, 0, -3)
		list:pathArcTo(x, y + h, r, 3, 0)
		list:pathStroke(0, 1, true)
	else
		list:pathStroke(color, alpha, true)
	end	
end

function drawPoly(list, points, transform, isFilled, color, alpha)
	local x, y = transform:getPosition()
	for i = 1, #points, 2 do 
		local xp =  points[i+0]
		local yp =  points[i+1]
		
		list:pathLineTo(x + xp, y + yp)
	end
	
	
	if (isFilled) then 
		list:pathFillConvex(color, alpha)
		list:pathStroke(color, alpha, true)
	else
		list:pathStroke(color, alpha, true)
	end
end

local function emptyCallback() end

local CollisionShape = Core.class()

function CollisionShape:init(name)
	self.id = GID
	self.name = name
	self.px = 0
	self.py = 0
	self.show = true
	self.dragPos = false
	self.dragSize = false
	GID += 1
	
	self.drawColor = math.random(0xffffff)
end

function CollisionShape:contains(x, y)
	return false
end

function CollisionShape:onMove(dx, dy, mx, my)
	-- override
end

function CollisionShape:onSizeChanged(dx, dy, mx, my)
	-- override
end

function CollisionShape:onPropertiesDraw(ui)
	-- override
end

function CollisionShape:redraw(list, isFilled, alpha)
	-- override
end

function CollisionShape:updateDragAndDrop(ui)
	local mx, my = ui:getMousePos()
	if (ui:isMouseClicked(1) and self:contains(mx, my)) then 
		self.px = mx
		self.py = my
		self.dragPos = true
	elseif (not self.dragPos and ui:isMouseClicked(2) and self:contains(mx, my)) then 
		self.px = mx
		self.py = my
		self.dragSize = true
	end
	
	if (self.dragPos) then 
		if (ui:isMouseReleased(1)) then
			self.dragPos = false
		end
		
		local dx = mx - self.px
		local dy = my - self.py
		self:onMove(dx, dy, mx, my)
		self.px = mx
		self.py = my
	end
	
	if (self.dragSize) then 
		if (ui:isMouseReleased(2)) then
			self.dragSize = false
		end
		
		local dx = mx - self.px
		local dy = my - self.py
		self:onSizeChanged(dx, dy, mx, my)
		self.px = mx
		self.py = my
	end
end

function CollisionShape:onDraw(ui, isFilled, alpha)
	if (self.id < 0) then 
		self.id = ui:getID(self)
	end
	
	
	ui:pushID(self.id)
	self.show = ui:checkbox("Visible", self.show)
	ui:sameLine()
	
	self:onPropertiesDraw(ui)
	ui:popID()
	
	self:updateDragAndDrop(ui)
	
	if (self.show) then 
		local list = ui:getWindowDrawList()
		
		self:redraw(list, isFilled, alpha)
	end
end

function CollisionShape:getType()
	return self.collisionShape.__shapeType
end

Circle = Core.class(CollisionShape, function(...) return "Circle" end)

function Circle:init(x, y, r)
	self.collisionShape = CuteC2.circle(x, y, r)
end

function Circle:contains(mx, my)
	--local x = self.collisionShape.x
	--local y = self.collisionShape.y
	--local r = self.collisionShape.radius
	--return math.inside({mx,my},{x=x, y=y, radius=r}) < 0
	return self.collisionShape:hitTest(mx, my)
end

function Circle:onMove(dx, dy, mx, my)
	self.collisionShape.x += dx
	self.collisionShape.y += dy
end

function Circle:onSizeChanged(dx, dy, mx, my)
	if (mx < self.collisionShape.x) then 
		self.collisionShape.radius -= dx
	else
		self.collisionShape.radius += dx
	end
end

function Circle:onPropertiesDraw(ui)
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local r = self.collisionShape.radius
	x, y, r = ui:dragFloat3(self.name, x, y, r)
	self.collisionShape.x = x
	self.collisionShape.y = y
	self.collisionShape.radius = r
end

function Circle:redraw(list, isFilled, alpha)
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local r = self.collisionShape.radius
	
	drawCircle(list, x, y, r, isFilled, self.drawColor, alpha)
end

Rect = Core.class(CollisionShape, function(...) return "Rect" end)

function Rect:init(x, y, w, h)
	self.collisionShape = CuteC2.aabb(x, y, w, h)
end

function Rect:contains(mx, my)
	return self.collisionShape:hitTest(mx, my)
end

function Rect:onMove(dx, dy, mx, my)
	self.collisionShape.x += dx
	self.collisionShape.y += dy
end

function Rect:onSizeChanged(dx, dy, mx, my)
	self.collisionShape.width += dx
	self.collisionShape.height += dy
end

function Rect:onPropertiesDraw(ui)
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local w = self.collisionShape.width
	local h = self.collisionShape.height
	x, y, w, h = ui:dragFloat4(self.name, x, y, w, h)
	self.collisionShape.x = x
	self.collisionShape.y = y
	self.collisionShape.width = w
	self.collisionShape.height = h
end

function Rect:redraw(list, isFilled, alpha)
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local w = self.collisionShape.width
	local h = self.collisionShape.height
	
	drawRect(list, x, y, x + w, y + h, isFilled, self.drawColor, alpha)
end

Capsule = Core.class(CollisionShape, function(...) return "Capsule" end)

function Capsule:init(x, y, h, r)
	self.collisionShape = CuteC2.capsule(x, y, h, r)
end

function Capsule:contains(mx, my)
	return self.collisionShape:hitTest(mx, my)
end

function Capsule:onMove(dx, dy, mx, my)
	self.collisionShape.x += dx
	self.collisionShape.y += dy
end

function Capsule:onSizeChanged(dx, dy, mx, my)
	self.collisionShape.height += dy
	
	if (mx < self.collisionShape.x) then 
		self.collisionShape.radius -= dx
	else
		self.collisionShape.radius += dx
	end
end

function Capsule:onPropertiesDraw(ui)
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local h = self.collisionShape.height
	local r = self.collisionShape.radius
	
	x, y, h, r = ui:dragFloat4(self.name, x, y, h, r)
	
	self.collisionShape.x = x
	self.collisionShape.y = y
	self.collisionShape.height = h
	self.collisionShape.radius = r
end

function Capsule:redraw(list, isFilled, alpha)	
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	local h = self.collisionShape.height
	local r = self.collisionShape.radius
	
	drawCapsule(list, x, y, h, r, isFilled, self.drawColor, alpha)
end

-- helper class to create drag&drop points for Polygons
local DragPoint = Core.class(Circle, function(x, y, parent) return x, y, 14 end)

function DragPoint:init(x, y, parent)
	self.parent = parent
	self.index = 0
end

function DragPoint:onPropertiesDraw()
end

function DragPoint:onSizeChanged()
end

function DragPoint:onDraw(ui, isFilled, alpha)
	self:updateDragAndDrop(ui)
	local list = ui:getWindowDrawList()
	self:redraw(list, isFilled, alpha)
end

function DragPoint:onMove(dx, dy, mx, my)
	self.collisionShape.x += dx
	self.collisionShape.y += dy
	
	if (self.parent.name == "Poly") then 
		local x, y = self.parent.transform:getPosition()
		self.parent.collisionShape:updatePoint(self.index, self.collisionShape.x - x, self.collisionShape.y - y)
	end
end

function DragPoint:redraw(list, isFilled, alpha)
	Circle.redraw(self, list, isFilled, color, alpha)
	
	local x = self.collisionShape.x
	local y = self.collisionShape.y
	list:addText(x, y+2, 0, 1, tostring(self.index)) 
	list:addText(x, y, 0xd9d9d9, 1, tostring(self.index)) 
end

Poly = Core.class(CollisionShape, function(...) return "Poly" end)

function Poly:init(x, y, points)
	self.collisionShape = CuteC2.poly(points)
	self.transform = CuteC2.transform(x, y)
	
	self.__dragPoints = {}
	local j = 1
	for i = 1, #points, 2 do 
		local xp = points[i+0]
		local yp = points[i+1]
		local pt = DragPoint.new(x + xp, y + yp, self)
		pt.index = j
		self.__dragPoints[j] = pt		
		j += 1
	end
end

function Poly:contains(mx, my)
	for i,pt in ipairs(self.__dragPoints) do 
		if (pt.dragPos or pt:contains(mx, my)) then 
			return false
		end
	end
	return self.collisionShape:hitTest(mx, my, self.transform)
end

function Poly:onPropertiesDraw(ui)
	local x = self.transform.x
	local y = self.transform.y
	local ox = x
	local oy = y
	local changed = false
	x, y, changed = ui:dragFloat2(self.name, x, y)
	self.transform.x = x
	self.transform.y = y
	
	local dx = x - ox
	local dy = y - oy
	
	if (changed) then 
		for i,pt in ipairs(self.__dragPoints) do 
			pt.collisionShape.x += dx
			pt.collisionShape.y += dy
		end
	end
end

function Poly:onMove(dx, dy, mx, my)
	self.transform:move(dx, dy)
	for i,pt in ipairs(self.__dragPoints) do 
		pt.collisionShape.x += dx
		pt.collisionShape.y += dy
		self.collisionShape:updatePoint(pt.index, pt.collisionShape.x - self.transform.x, pt.collisionShape.y - self.transform.y)
	end
end

function Poly:onDraw(ui, isFilled, alpha)
	CollisionShape.onDraw(self, ui, isFilled, alpha)
	for i,pt in ipairs(self.__dragPoints) do 
		pt:onDraw(ui, isFilled, alpha)
	end
end

function Poly:redraw(list, isFilled, alpha)
	local points = self.collisionShape:getPoints()
	local x, y = self.transform:getPosition()
	
	drawPoly(list, points, self.transform, isFilled, self.drawColor, alpha)
	
	local minX, minY, maxX, maxY = self.collisionShape:getBoundingBox()
	minX += x
	minY += y
	maxX += x
	maxY += y
	drawRect(list, minX, minY, maxX, maxY, isFilled, self.drawColor, alpha / 2)
end

Ray = Core.class(CollisionShape, function(...) return "Ray" end)

function Ray:init(sx, sy, ex, ey, len)
	self.collisionShape = CuteC2.ray(sx, sy, ex, ey, len)
	
	self.pt1 = DragPoint.new(sx, sy, self)
	self.pt1.index = 1
	self.pt2 = DragPoint.new(ex, ey, self)
	self.pt2.index = 2
end

function Ray:onMove(dx, dy, mx, my)
	self.pt1.collisionShape.x += dx
	self.pt1.collisionShape.y += dy
	self.pt2.collisionShape.x += dx
	self.pt2.collisionShape.y += dy
end

function Ray:redraw(list, isFilled, color, alpha)
	
	alpha = isFilled and alpha or 1
	list:addLine(self.pt1.collisionShape.x, self.pt1.collisionShape.y, self.pt2.collisionShape.x, self.pt2.collisionShape.y, color, alpha, 2)
end

function Ray:onDraw(ui, isFilled, color, alpha)
	CollisionShape.onDraw(self, ui, isFilled, color, alpha)
	self.pt1:onDraw(ui, isFilled, color, alpha)
	self.pt2:onDraw(ui, isFilled, color, alpha)
end