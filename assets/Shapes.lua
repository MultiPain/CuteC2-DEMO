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

function drawCapsule(list, x, y, h, r, isFilled, color, alpha)
	local hh = h * 0.5
	
	list:pathArcTo(x, y - hh, r, 0, -3)
	list:pathArcTo(x, y + hh, r, 3, 0)
	
	if (isFilled) then 
		list:pathFillConvex(color, alpha)
		
		list:pathArcTo(x, y - hh, r, 0, -3)
		list:pathArcTo(x, y + hh, r, 3, 0)
		list:pathStroke(0, 1, true)
	else
		list:pathStroke(color, alpha, true)
	end	
end

function drawPoly(list, points, transform, isFilled, color, alpha)
	local x, y = transform:getPosition()
	for i = 1, #points, 2 do 
		local px =  points[i + 0]
		local py =  points[i + 1]
		
		list:pathLineTo(x + px, y + py)
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

function CollisionShape:onStartMove(mx, my)
	-- override
end

function CollisionShape:onMove(dx, dy, mx, my)
	-- override
end

function CollisionShape:onStartResize(mx, my)
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
	if (ui:isMouseClicked(KeyCode.MOUSE_LEFT) and self:contains(mx, my)) then 
		self.px = mx
		self.py = my
		self.clickX = mx
		self.clickY = my
		self:onStartMove(mx, my)
		self.dragPos = true
	elseif (not self.dragPos and ui:isMouseClicked(KeyCode.MOUSE_RIGHT) and self:contains(mx, my)) then 
		self.px = mx
		self.py = my
		self.clickX = mx
		self.clickY = my
		self:onStartResize(mx, my)
		self.dragSize = true
	end
	
	if (self.dragPos) then 
		if (ui:isMouseReleased(KeyCode.MOUSE_LEFT)) then
			self.dragPos = false
		end
		
		local dx = mx - self.px
		local dy = my - self.py
		self:onMove(dx, dy, mx, my)
		self.px = mx
		self.py = my
	end
	
	if (self.dragSize) then 
		if (ui:isMouseReleased(KeyCode.MOUSE_RIGHT)) then
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
	return self.collisionShape:hitTest(mx, my)
end


function Circle:onMove(dx, dy, mx, my)
	self.collisionShape:move(dx, dy)
end

function Circle:onStartResize(mx, my)
	local x, y = self.collisionShape:getPosition()
	local d = math.distance(x, y, mx, my)
	self.startDistance = d -  self.collisionShape:getRadius()
end

function Circle:onSizeChanged(dx, dy, mx, my)
	local x, y = self.collisionShape:getPosition()
	local d = math.distance(x, y, mx, my)
	self.collisionShape:setRadius(d - self.startDistance)
end

function Circle:onPropertiesDraw(ui)
	local shape = self.collisionShape
	local x, y = shape:getPosition()
	local r = shape:getRadius()
	local changed = false
	x, y, r, changed = ui:dragFloat3(self.name, x, y, r)
	
	if (changed) then 
		shape:setPosition(x, y)
		shape:setRadius(r)
	end
end

function Circle:redraw(list, isFilled, alpha)
	local shape = self.collisionShape
	local x, y = shape:getPosition()
	local r = shape:getRadius()
	
	drawCircle(list, x, y, r, isFilled, self.drawColor, alpha)
end

Rect = Core.class(CollisionShape, function(...) return "Rect" end)

function Rect:init(x, y, w, h)
	self.collisionShape = CuteC2.aabb(x, y, x + w, y + h)
end

function Rect:contains(mx, my)
	return self.collisionShape:hitTest(mx, my)
end

function Rect:onStartResize__(mx, my)
	CollisionShape.onStartDrag(self, mx, my)
	local x, y = self.collisionShape:getPosition()
	local d = math.distance(x, y, mx, my)
	self.startDistance = d -  self.collisionShape:getRadius()
end

function Rect:onMove(dx, dy, mx, my)
	self.collisionShape:move(dx, dy)
end

function Rect:onSizeChanged(dx, dy, mx, my)
	local w, h = self.collisionShape:getSize()
	self.collisionShape:setHalfSize(w + dx, h + dy)
end

function Rect:onPropertiesDraw(ui)
	local shape = self.collisionShape
	local x, y = shape:getPosition()
	local w, h = shape:getSize()
	local changed = false
	
	x, y, w, h, changed = ui:dragFloat4(self.name, x, y, w, h)
	
	if (changed) then 
		shape:setPosition(x, y)
		shape:setSize(w, h)
	end
end

function Rect:redraw(list, isFilled, alpha)
	local shape = self.collisionShape
	local x1, y1, x2, y2 = shape:getBoundingBox()
	
	drawRect(list, x1, y1, x2, y2, isFilled, self.drawColor, alpha)
end

Capsule = Core.class(CollisionShape, function(...) return "Capsule" end)

function Capsule:init(x, y, h, r)
	self.collisionShape = CuteC2.capsule(x, y, h, r)
end

function Capsule:contains(mx, my)
	return self.collisionShape:hitTest(mx, my)
end

function Capsule:onMove(dx, dy, mx, my)
	self.collisionShape:move(dx, dy)
end

function Capsule:onSizeChanged(dx, dy, mx, my)
	local shape = self.collisionShape
	local radius = shape:getRadius()
	shape:setHeight(shape:getHeight() + dy)
	
	if (mx < shape:getX()) then 
		shape:setRadius(radius - dx)
	else
		shape:setRadius(radius + dx)
	end
end

function Capsule:onPropertiesDraw(ui)
	local shape = self.collisionShape
	local x, y = shape:getPosition()
	local r, h = shape:getSize()
	local changed = false
	
	x, y, h, r, changed = ui:dragFloat4(self.name, x, y, h, r)
	
	if (changed) then 
		shape:setPosition(x, y)
		shape:getSize(r, h)
	end
end

function Capsule:redraw(list, isFilled, alpha)
	local shape = self.collisionShape
	local x, y = shape:getPosition()
	local r, h = shape:getSize()
	
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

function DragPoint:onMove(dx, dy, mx, my)
end

function DragPoint:onSizeChanged()
end

function DragPoint:onDraw(ui, isFilled, alpha)
	self:updateDragAndDrop(ui)
	local list = ui:getWindowDrawList()
	self:redraw(list, isFilled, alpha)
end

function DragPoint:redraw(list, isFilled, alpha)
	Circle.redraw(self, list, isFilled, color, alpha)
	
	local x, y = self.collisionShape:getPosition()
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
		pt.onMove = self.onPointMove
		pt.index = j
		self.__dragPoints[j] = pt
		j += 1
	end
end

function Poly:onPointMove(dx, dy, mx, my)
	-- self = DragPoint !!!
	local shape = self.collisionShape
	shape:move(dx, dy)
	
	local px, py = self.parent.transform:getPosition()
	local x, y = shape:getPosition()
	self.parent.collisionShape:updatePoint(self.index, x - px, y - py)
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
	local x, y = self.transform:getPosition()
	local ox = x
	local oy = y
	local changed = false
	x, y, changed = ui:dragFloat2(self.name, x, y)
	
	
	if (changed) then 
		self.transform:setPosition(x, y)
		local dx = x - ox
		local dy = y - oy
		
		for i,pt in ipairs(self.__dragPoints) do 
			pt.collisionShape:move(dx, dy)
		end
	end
end

function Poly:onMove(dx, dy, mx, my)
	self.transform:move(dx, dy)
	local tx, ty = self.transform:getPosition()
	
	for i,pt in ipairs(self.__dragPoints) do 
		local x, y = pt.collisionShape:getPosition()
		pt.collisionShape:move(dx, dy)
		self.collisionShape:updatePoint(pt.index, x - tx, y - ty)
	end
end

function Poly:onDraw(ui, isFilled, alpha)
	for i,pt in ipairs(self.__dragPoints) do 
		pt:onDraw(ui, isFilled, alpha)
	end
	CollisionShape.onDraw(self, ui, isFilled, alpha)
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

function Ray:init(sx, sy, ex, ey)
	self.collisionShape = CuteC2.ray(sx, sy, ex, ey)
	
	self.pt1 = DragPoint.new(sx, sy, self)
	self.pt1.index = 1
	self.pt2 = DragPoint.new(ex, ey, self)
	self.pt2.index = 2
	
	self.pt2.onMove = self.onEndPointMove
end

function Ray:onEndPointMove(dx, dy, mx, my)
	-- self = DragPoint !!!
	self.collisionShape:move(dx, dy)
	self.parent:update()
end

function Ray:update()
	local ray = self.collisionShape
	
	local x1, y1 = self.pt1.collisionShape:getPosition()
	ray:setStartPosition(x1, y1)
	
	local x2, y2 = self.pt2.collisionShape:getPosition()
	ray:setTargetPosition(x2, y2)
	ray:setLength(math.distance(x1,y1,0, x2,y2,0))
end

function Ray:contains(x, y)
	return self.pt1:contains(x, y)
end

function Ray:onMove(dx, dy, mx, my)
	self.pt1.collisionShape:move(dx, dy)
	self.pt2.collisionShape:move(dx, dy)
	self.collisionShape:move(dx, dy)
	
	self:update()
end

function Ray:redraw(list, isFilled, color, alpha)
	alpha = isFilled and alpha or 1
	local p1x, p1y = self.pt1.collisionShape:getPosition()
	local p2x, p2y = self.pt2.collisionShape:getPosition()
	
	list:addLine(p1x, p1y, p2x, p2y, self.drawColor, alpha, 2)
end

function Ray:onDraw(...)
	self.pt1:onDraw(...)
	self.pt2:onDraw(...)
	CollisionShape.onDraw(self, ...)
end

function Ray:onPropertiesDraw(ui)	
	local sx, sy = self.pt1.collisionShape:getPosition()
	local ex, ey = self.pt2.collisionShape:getPosition()
	local changed = false
	sx, sy, ex, ey, changed = ui:dragFloat4(self.name, sx, sy, ex, ey)
	
	if (changed) then 
		self.pt1.collisionShape:setPosition(sx, sy)
		self.pt2.collisionShape:setPosition(ex, ey)
		
		self:update()
	end
end