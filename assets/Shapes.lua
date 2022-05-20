--!NOEXEC
local SEGMENTS = 0
local GID = 1

function drawVec(list, x, y, transform, len, color, alpha, thickness)
	local cosa, sina = transform:getCosSin()
	list:addLine(x, y, x + cosa * len, y + sina * len, color, alpha, thickness)
	list:addCircle(x, y, 4, color, alpha)
end

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
	
	for i, pt in ipairs(points) do 
		local px = x + pt.x
		local py = y + pt.y
		
		list:pathLineTo(px, py)
	end
	
	if (isFilled) then 
		list:pathFillConvex(color, alpha)
		list:pathStroke(color, alpha, true)
	else
		list:pathStroke(color, alpha, true)
	end
	
	
	for i, pt in ipairs(points) do 
		local px = x + pt.x
		local py = y + pt.y
		
		list:addLine(x, y, px, py, 0, 1)
	end
	
	drawVec(list, x, y, transform, 51, 0, 1, 3)
	drawVec(list, x, y, transform, 50, 0xffffff, 1)
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

function CollisionShape:startDrag(mx, my)
	self.px = mx
	self.py = my
	self.clickX = mx
	self.clickY = my
end

function CollisionShape:stopDrag()
	self.px = nil
	self.py = nil
	self.clickX = nil
	self.clickY = nil
end

function CollisionShape:updateDrag(mx, my)
	local dx = mx - self.px
	local dy = my - self.py
	
	self.px = mx
	self.py = my
	
	return dx, dy
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
		self:startDrag(mx, my)
		self:onStartMove(mx, my)
		self.dragPos = true
	elseif (not self.dragPos and ui:isMouseClicked(KeyCode.MOUSE_RIGHT) and self:contains(mx, my)) then 
		self:startDrag(mx, my)
		self:onStartResize(mx, my)
		self.dragSize = true
	end
	
	if (self.dragPos) then 
		if (ui:isMouseReleased(KeyCode.MOUSE_LEFT)) then
			self.dragPos = false
			self:stopDrag()
		else
			local dx, dy = self:updateDrag(mx, my)
			self:onMove(dx, dy, mx, my)
		end
	end
	
	if (self.dragSize) then 
		if (ui:isMouseReleased(KeyCode.MOUSE_RIGHT)) then
			self.dragSize = false
			self:stopDrag()
		else
			local dx, dy = self:updateDrag(mx, my)
			self:onSizeChanged(dx, dy, mx, my)
		end
	end
end

function CollisionShape:onDraw(ui, isFilled, alpha)
	if (self.id < 0) then 
		self.id = ui:getID(self)
	end
	
	ui:pushID(self.id)
	if (ui:collapsingHeader(self.name)) then 
		self.show = ui:checkbox("Visible", self.show)
		self:onPropertiesDraw(ui)
	end
	ui:popID()
	
	if (self.show) then 
		local list = ui:getWindowDrawList()
		
		self:redraw(list, isFilled, alpha)
	end
	self:updateDragAndDrop(ui)
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
	x, y, r, changed = ui:dragFloat3("Position, radius", x, y, r)
	
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
	
	x, y, changed = ui:dragFloat2("Position", x, y)
	if (changed) then 
		shape:setPosition(x, y)
	end
	
	changed = false
	w, h, changed = ui:dragFloat2("Size", w, h)
	
	if (changed) then 
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
	
	x, y, changed = ui:dragFloat4(self.name, x, y)
	
	if (changed) then 
		shape:setPosition(x, y)
	end
	
	changed = false
	h, r, changed = ui:dragFloat4("Height, radius", h, r)
	
	if (changed) then 
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
	
	local text = tostring(self.index)
	list:addText(x, y+2, 0, 1, text) 
	list:addText(x, y, 0xd9d9d9, 1, text) 
end

function DragPoint:rotate(cx, cy, rotation)
	local s = math.sin(rotation)
	local c = math.cos(rotation)
	local px, py = self.collisionShape:getPosition()
	
	px -= cx
	py -= cy
	
	local pxnew = px * c - py * s;
	local pynew = px * s + py * c;
	
	self.collisionShape:setPosition(pxnew + cx, pynew + cy)
end

Poly = Core.class(CollisionShape, function(...) return "Poly" end)

function Poly:init(x, y, points)
	self.collisionShape = CuteC2.poly(points)
	self.transform = CuteC2.transform(x, y)
	self.dragPoint = 0
	self.drawNormals = false
end

function Poly:updateDragAndDrop(ui)
	CollisionShape.updateDragAndDrop(self, ui)
	
	if (self.dragPoint > 0) then 
		local mx, my = ui:getMousePos()
		local dx, dy = self:updateDrag(mx, my)
		
		-- update vertex position with respect to shape rotation
		local vx, vy = self.collisionShape:getVertex(self.dragPoint)
		local rot = self.transform:getRotation()
		local l = math.length(dx, dy)
		local ang = math.atan2(dy, dx)
		
		ang -= rot
		vx += math.cos(ang) * l
		vy += math.sin(ang) * l
		
		self.collisionShape:setVertex(self.dragPoint, vx, vy)
		
		if (ui:isMouseReleased(KeyCode.MOUSE_LEFT)) then
			self.dragPoint = 0
		end
	end
end

function Poly:contains(mx, my)
	local points = self.collisionShape:getRotatedPoints(self.transform)
	local tx, ty = self.transform:getPosition()
	
	for i, pt in ipairs(points) do 
		local x = tx + pt.x
		local y = ty + pt.y
		
		local d = math.distance(mx, my, 0, x, y, 0)
		if (d <= 12) then
			self.dragPoint = i
			self:startDrag(mx, my)
			return false
		end
	end
	
	return self.collisionShape:hitTest(mx, my, self.transform)
end

function Poly:onPropertiesDraw(ui)
	self.drawNormals = ui:checkbox(self.name .. " draw normals", self.drawNormals)
	
	local x, y = self.transform:getPosition()
	local changed = false
	x, y, changed = ui:dragFloat2("Position", x, y)
	
	if (changed) then 
		self.transform:setPosition(x, y)
	end
	
	local rot = self.transform:getRotation()
	
	changed = false
	rot, changed = ui:dragFloat("Rotation", rot, 0.01)
	
	if (changed) then 
		self.transform:setRotation(rot)
	end
end

function Poly:onMove(dx, dy, mx, my)
	self.transform:move(dx, dy)
end

function Poly:onStartResize(mx, my)
	local x, y = self.transform:getPosition()
	local ang = math.atan2(self.clickY - y, self.clickX - x)
	self.clickAng = ang
	self.prevAng = ang
end

function Poly:onSizeChanged(dx, dy, mx, my)
	local x, y = self.transform:getPosition()
	local currentAng = math.atan2(my - y, mx - x)
	self.transform:rotate(currentAng - self.prevAng)
	self.prevAng = currentAng
end
	
function Poly:redraw(list, isFilled, alpha)
	local points = self.collisionShape:getRotatedPoints(self.transform)
	
	drawPoly(list, points, self.transform, isFilled, self.drawColor, alpha)	
	
	local tx, ty = self.transform:getPosition()
	for i, pt in ipairs(points) do 
		local x = tx + pt.x
		local y = ty + pt.y
		
		list:addCircle(x, y, 12, 0x00ff00, 1)
	end
	
	if (self.drawNormals) then 
		local normals = self.collisionShape:getRotatedNormals(self.transform)
		for i = 1, #points do 
			local x1 = tx + points[i].x
			local y1 = ty + points[i].y
			local x2 = x1 + normals[i].x * 16
			local y2 = y1 + normals[i].y * 16
			
			list:addLine(x1, y1, x2, y2, 0xffffff, alpha)
		end
	end
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
	sx, sy, changed = ui:dragFloat2("Start", sx, sy)
	if (changed) then 
		self.pt1.collisionShape:setPosition(sx, sy)
		self:update()
	end
	
	changed = false
	ex, ey, changed = ui:dragFloat2("Target", ex, ey)
	
	if (changed) then 
		self.pt2.collisionShape:setPosition(ex, ey)
		self:update()
	end
end