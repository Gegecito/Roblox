-- credits to quenty

--[=[
	Debug drawing library useful for debugging 3D abstractions. One of
	the more useful utility libraries.

	These functions are incredibly easy to invoke for quick debugging.
	This can make debugging any sort of 3D geometry really easy.

	```lua
	-- A sample of a few API uses
	Draw.point(Vector3.new(0, 0, 0))
	Draw.terrainCell(Vector3.new(0, 0, 0))
	Draw.cframe(CFrame.new(0, 10, 0))
	Draw.text(Vector3.new(0, -10, 0), "Testing!")
	```

	:::tip
	This library should not be used to render things in production for
	normal players, as it is optimized for debug experience over performance.
	:::

	@class Draw
]=]

local Workspace = game:GetService("Workspace")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local TextService = game:GetService("TextService")

local Terrain = Workspace.Terrain

local ORIGINAL_DEFAULT_COLOR = Color3.new(1, 0, 0)

local Draw = {}
Draw._defaultColor = ORIGINAL_DEFAULT_COLOR

function Draw.setColor(color)
	Draw._defaultColor = color
end

function Draw.resetColor()
	Draw._defaultColor = ORIGINAL_DEFAULT_COLOR
end

function Draw.setRandomColor()
	Draw.setColor(Color3.fromHSV(math.random(), 0.5+0.5*math.random(), 1))
end

function Draw.ray(ray, color, parent, meshDiameter, diameter)
	assert(typeof(ray) == "Ray", "Bad typeof(ray) for Ray")

	color = color or Draw._defaultColor
	parent = parent or Draw.getDefaultParent()
	meshDiameter = meshDiameter or 0.2
	diameter = diameter or 0.2

	local rayCenter = ray.Origin + ray.Direction/2

	local part = Instance.new("Part")
	part.Material = Enum.Material.ForceField
	part.Anchored = true
	part.Archivable = false
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = CFrame.new(rayCenter, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2, 0, 0)
	part.Color = color
	part.Name = "DebugRay"
	part.Shape = Enum.PartType.Cylinder
	part.Size = Vector3.new(diameter, ray.Direction.Magnitude, diameter)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 0.5

	local rotatedPart = Instance.new("Part")
	rotatedPart.Name = "RotatedPart"
	rotatedPart.Anchored = true
	rotatedPart.Archivable = false
	rotatedPart.CanCollide = false
	rotatedPart.CanQuery = false
	rotatedPart.CanTouch = false
	rotatedPart.CastShadow = false
	rotatedPart.CFrame = CFrame.new(ray.Origin, ray.Origin + ray.Direction)
	rotatedPart.Transparency = 1
	rotatedPart.Size = Vector3.new(1, 1, 1)
	rotatedPart.Parent = part

	local lineHandleAdornment = Instance.new("LineHandleAdornment")
	lineHandleAdornment.Name = "DrawRayLineHandleAdornment"
	lineHandleAdornment.Length = ray.Direction.Magnitude
	lineHandleAdornment.Thickness = 5*diameter
	lineHandleAdornment.ZIndex = 3
	lineHandleAdornment.Color3 = color
	lineHandleAdornment.AlwaysOnTop = true
	lineHandleAdornment.Transparency = 0
	lineHandleAdornment.Adornee = rotatedPart
	lineHandleAdornment.Parent = rotatedPart

	local mesh = Instance.new("SpecialMesh")
	mesh.Name = "DrawRayMesh"
	mesh.Scale = Vector3.new(0, 1, 0) + Vector3.new(meshDiameter, 0, meshDiameter) / diameter
	mesh.Parent = part

	part.Parent = parent

	return part
end


function Draw.updateRay(part, ray, color)
	color = color or part.Color

	local diameter = part.Size.x
	local rayCenter = ray.Origin + ray.Direction/2

	part.CFrame = CFrame.new(rayCenter, ray.Origin + ray.Direction) * CFrame.Angles(math.pi/2, 0, 0)
	part.Size = Vector3.new(diameter, ray.Direction.Magnitude, diameter)
	part.Color = color

	local rotatedPart = part:FindFirstChild("RotatedPart")
	if rotatedPart then
		rotatedPart.CFrame = CFrame.new(ray.Origin, ray.Origin + ray.Direction)
	end

	local lineHandleAdornment = rotatedPart and rotatedPart:FindFirstChild("DrawRayLineHandleAdornment")
	if lineHandleAdornment then
		lineHandleAdornment.Length = ray.Direction.Magnitude
		lineHandleAdornment.Thickness = 5*diameter
		lineHandleAdornment.Color3 = color
	end
end


function Draw.text(adornee, text, color)
	if typeof(adornee) == "Vector3" then
		local attachment = Instance.new("Attachment")
		attachment.WorldPosition = adornee
		attachment.Parent = Terrain
		attachment.Name = "DebugTextAttachment"

		Draw._textOnAdornee(attachment, text, color)

		return attachment
	elseif typeof(adornee) == "Instance" then
		return Draw._textOnAdornee(adornee, text, color)
	else
		error("Bad adornee")
	end
end

function Draw._textOnAdornee(adornee, text, color)
	local TEXT_HEIGHT_STUDS = 2
	local PADDING_PERCENT_OF_LINE_HEIGHT = 0.5

	local billboardGui = Instance.new("BillboardGui")
	billboardGui.Name = "DebugBillboardGui"
	billboardGui.SizeOffset =  Vector2.new(0, 0.5)
	billboardGui.ExtentsOffset = Vector3.new(0, 1, 0)
	billboardGui.AlwaysOnTop = true
	billboardGui.Adornee = adornee
	billboardGui.StudsOffset = Vector3.new(0, 0, 0.01)

	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(1, 0, 1, 0)
	background.Position = UDim2.new(0.5, 0, 1, 0)
	background.AnchorPoint = Vector2.new(0.5, 1)
	background.BackgroundTransparency = 0.3
	background.BorderSizePixel = 0
	background.BackgroundColor3 = color or Draw._defaultColor
	background.Parent = billboardGui

	local textLabel = Instance.new("TextLabel")
	textLabel.Text = tostring(text)
	textLabel.TextScaled = true
	textLabel.TextSize = 32
	textLabel.BackgroundTransparency = 1
	textLabel.BorderSizePixel = 0
	textLabel.TextColor3 = Color3.new(1, 1, 1)
	textLabel.Size = UDim2.new(1, 0, 1, 0)
	textLabel.Parent = background

	if tonumber(text) then
		textLabel.Font = Enum.Font.Code
	else
		textLabel.Font = Enum.Font.GothamMedium
	end

	local textSize = TextService:GetTextSize(
		textLabel.Text,
		textLabel.TextSize,
		textLabel.Font,
		Vector2.new(1024, 1e6))

	local lines = textSize.y/textLabel.TextSize

	local paddingOffset = textLabel.TextSize*PADDING_PERCENT_OF_LINE_HEIGHT
	local paddedHeight = textSize.y + 2*paddingOffset
	local paddedWidth = textSize.x + 2*paddingOffset
	local aspectRatio = paddedWidth/paddedHeight

	local uiAspectRatio = Instance.new("UIAspectRatioConstraint")
	uiAspectRatio.AspectRatio = aspectRatio
	uiAspectRatio.Parent = background

	local uiPadding = Instance.new("UIPadding")
	uiPadding.PaddingBottom = UDim.new(paddingOffset/paddedHeight, 0)
	uiPadding.PaddingTop = UDim.new(paddingOffset/paddedHeight, 0)
	uiPadding.PaddingLeft = UDim.new(paddingOffset/paddedWidth, 0)
	uiPadding.PaddingRight = UDim.new(paddingOffset/paddedWidth, 0)
	uiPadding.Parent = background

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(paddingOffset/paddedHeight/2, 0)
	uiCorner.Parent = background

	local height = lines*TEXT_HEIGHT_STUDS * TEXT_HEIGHT_STUDS*PADDING_PERCENT_OF_LINE_HEIGHT

	billboardGui.Size = UDim2.new(height*aspectRatio, 0, height, 0)
	billboardGui.Parent = adornee

	return billboardGui
end

function Draw.sphere(position, radius, color, parent)
	return Draw.point(position, color, parent, radius*2)
end


function Draw.point(position, color, parent, diameter)
	if typeof(position) == "CFrame" then
		position = position.Position
	end

	assert(typeof(position) == "Vector3", "Bad position")

	color = color or Draw._defaultColor
	parent = parent or Draw.getDefaultParent()
	diameter = diameter or 1

	local part = Instance.new("Part")
	part.Material = Enum.Material.ForceField
	part.Anchored = true
	part.Archivable = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.CFrame = CFrame.new(position)
	part.Color = color
	part.Name = "DebugPoint"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(diameter, diameter, diameter)
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 0.5

	local sphereHandle = Instance.new("SphereHandleAdornment")
	sphereHandle.Archivable = false
	sphereHandle.Radius = diameter/4
	sphereHandle.Color3 = color
	sphereHandle.AlwaysOnTop = true
	sphereHandle.Adornee = part
	sphereHandle.ZIndex = 2
	sphereHandle.Parent = part

	part.Parent = parent

	return part
end


function Draw.labelledPoint(position, label, color, parent)
	if typeof(position) == "CFrame" then
		position = position.Position
	end

	local part = Draw.point(position, color, parent)

	Draw.text(part, label, color)

	return part
end

function Draw.cframe(cframe)
	local model = Instance.new("Model")
	model.Name = "DebugCFrame"

	local position = cframe.Position
	Draw.point(position, nil, model, 0.1)

	local xRay = Draw.ray(Ray.new(
		position,
		cframe.XVector
	), Color3.new(0.75, 0.25, 0.25), model, 0.1)
	xRay.Name = "XVector"

	local yRay = Draw.ray(Ray.new(
		position,
		cframe.YVector
	), Color3.new(0.25, 0.75, 0.25), model, 0.1)
	yRay.Name = "YVector"

	local zRay = Draw.ray(Ray.new(
		position,
		cframe.ZVector
	), Color3.new(0.25, 0.25, 0.75), model, 0.1)
	zRay.Name = "ZVector"

	model.Parent = Draw.getDefaultParent()

	return model
end

function Draw.part(template, cframe, color, transparency)
	assert(typeof(template) == "Instance" and template:IsA("BasePart"), "Bad template")

	local part = template:Clone()
	for _, child in pairs(part:GetChildren()) do
		if child:IsA("Mesh") then
			Draw._sanitize(child)
			child:ClearAllChildren()
		else
			child:Destroy()
		end
	end

	part.Color = color or Draw._defaultColor
	part.Material = Enum.Material.ForceField
	part.Transparency = transparency or 0.75
	part.Name = "Debug" .. template.Name
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Archivable = false

	if cframe then
		part.CFrame = cframe
	end

	Draw._sanitize(part)

	part.Parent = Draw.getDefaultParent()

	return part
end

function Draw._sanitize(inst)
	for key, _ in pairs(inst:GetAttributes()) do
		inst:SetAttribute(key, nil)
	end

	for _, tag in pairs(CollectionService:GetTags(inst)) do
		CollectionService:RemoveTag(inst, tag)
	end
end

function Draw.box(cframe, size, color)
	assert(typeof(size) == "Vector3", "Bad size")

	color = color or Draw._defaultColor
	cframe = typeof(cframe) == "Vector3" and CFrame.new(cframe) or cframe

	local part = Instance.new("Part")
	part.Color = color
	part.Material = Enum.Material.ForceField
	part.Name = "DebugPart"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Archivable = false
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.TopSurface = Enum.SurfaceType.Smooth
	part.Transparency = 0.75
	part.Size = size
	part.CFrame = cframe

	local boxHandleAdornment = Instance.new("BoxHandleAdornment")
	boxHandleAdornment.Adornee = part
	boxHandleAdornment.Size = size
	boxHandleAdornment.Color3 = color
	boxHandleAdornment.AlwaysOnTop = true
	boxHandleAdornment.Transparency = 0.75
	boxHandleAdornment.ZIndex = 1
	boxHandleAdornment.Parent = part

	part.Parent = Draw.getDefaultParent()

	return part
end

function Draw.region3(region3, color)
	return Draw.box(region3.CFrame, region3.Size, color)
end

function Draw.terrainCell(position, color)
	local size = Vector3.new(4, 4, 4)

	local solidCell = Terrain:WorldToCell(position)
	local terrainPosition = Terrain:CellCenterToWorld(solidCell.x, solidCell.y, solidCell.z)

	local part = Draw.box(CFrame.new(terrainPosition), size, color)
	part.Name = "DebugTerrainCell"

	return part
end



function Draw.screenPointLine(a, b, parent, color)
	local offset = (b - a)
	local pos = a + offset/2


	local frame = Instance.new("Frame")
	frame.Name = "DebugScreenLine"
	frame.Size = UDim2.fromScale(math.abs(offset.x), math.abs(offset.y))

	frame.BackgroundTransparency = 1
	frame.Position = UDim2.fromScale(pos.x, pos.y)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BorderSizePixel = 0
	frame.ZIndex = 10000
	frame.Parent = parent

	local length = offset.magnitude
	if length == 0 then
		return frame
	end

	local diameter = 3
	local count = 25

	local slope = offset.y/offset.x
	if slope > 0 then
		for i=0, count do
			Draw.screenPoint(Vector2.new(i/count, i/count), frame, color, diameter)
		end
	else
		for i=0, count do
			Draw.screenPoint(Vector2.new(i/count, 1 - i/count), frame, color, diameter)
		end
	end

	return frame
end

function Draw.screenPoint(position, parent, color, diameter)
	local frame = Instance.new("Frame")
	frame.Name = "DebugScreenPoint"
	frame.Size = UDim2.new(0, diameter, 0, diameter)
	frame.BackgroundColor3 = color or Color3.new(1, 0.1, 0.1)
	frame.BackgroundTransparency = 0.5
	frame.Position = UDim2.fromScale(position.x, position.y)
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.BorderSizePixel = 0
	frame.ZIndex = 20000

	local uiCorner = Instance.new("UICorner")
	uiCorner.CornerRadius = UDim.new(0.5, 0)
	uiCorner.Parent = frame

	frame.Parent = parent
	return frame
end

function Draw.vector(position, direction, color, parent, meshDiameter)
	return Draw.ray(Ray.new(position, direction), color, parent, meshDiameter)
end


function Draw.ring(ringPos, ringNorm, ringRadius, color, parent)
	local ringCFrame = CFrame.new(ringPos, ringPos + ringNorm)

	local points = {}
	for angle = 0, 2*math.pi, math.pi/8 do
		local x = math.cos(angle)*ringRadius
		local y = math.sin(angle)*ringRadius
		local vector = ringCFrame:pointToWorldSpace(Vector3.new(x, y, 0))
		table.insert(points, vector)
	end

	local folder = Instance.new("Folder")
	folder.Name = "DebugRing"

	for i=1, #points do
		local pos = points[i]
		local nextPos = points[(i%#points)+1]
        local ray = Ray.new(pos, nextPos - pos)
        Draw.ray(ray, color, folder)
	end

	folder.Parent = parent or Draw.getDefaultParent()

	return folder
end

--[=[
	Retrieves the default parent for the current execution context.
	@return Instance
]=]
function Draw.getDefaultParent()
	if not RunService:IsRunning() then
		return Workspace.CurrentCamera
	end

	if RunService:IsServer() then
		return Workspace
	else
		return Workspace.CurrentCamera
	end
end


local EPSILON = 1e-6
local SQRT_3_OVER_2 = math.sqrt(3)/2
local SUB_REGION_POSITION_OFFSET = {
	{ 0.25, 0.25, -0.25 };
	{ -0.25, 0.25, -0.25 };
	{ 0.25, 0.25, 0.25 };
	{ -0.25, 0.25, 0.25 };
	{ 0.25, -0.25, -0.25 };
	{ -0.25, -0.25, -0.25 };
	{ 0.25, -0.25, 0.25 };
	{ -0.25, -0.25, 0.25 };
}

local OctreeRegionUtils = {}

--[=[
	Visualizes the octree region.

	@param region OctreeRegion<T>
	@return MaidTask
]=]
function OctreeRegionUtils.visualize(region)
	local size = region.size
	local position = region.position
	local sx, sy, sz = size[1], size[2], size[3]
	local px, py, pz = position[1], position[2], position[3]

	local box = Draw.box(Vector3.new(px, py, pz), Vector3.new(sx, sy, sz))
	box.Transparency = 0.9
	box.Name = "OctreeRegion_" .. tostring(region.depth)

	return box
end

function OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parent, parentIndex)
	local hsx, hsy, hsz = sx/2, sy/2, sz/2

	local region = {
		subRegions = {
			--topNorthEast
			--topNorthWest
			--topSouthEast
			--topSouthWest
			--bottomNorthEast
			--bottomNorthWest
			--bottomSouthEast
			--bottomSouthWest
		};
		lowerBounds = { px - hsx, py - hsy, pz - hsz };
		upperBounds = { px + hsx, py + hsy, pz + hsz };
		position = { px, py, pz };
		size = { sx, sy, sz }; -- { sx, sy, sz }
		parent = parent;
		depth = parent and (parent.depth + 1) or 1;
		parentIndex = parentIndex;
		nodes = {};
		node_count = 0;
	}


	return region
end

function OctreeRegionUtils.addNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		if not current.nodes[node] then
			current.nodes[node] = node
			current.node_count = current.node_count + 1
		end
		current = current.parent
	end
end

function OctreeRegionUtils.moveNode(fromLowest, toLowest, node)
	assert(fromLowest.depth == toLowest.depth, "fromLowest.depth ~= toLowest.depth")
	assert(fromLowest ~= toLowest, "fromLowest == toLowest")

	local currentFrom = fromLowest
	local currentTo = toLowest
	while currentFrom ~= currentTo do
		-- remove from current
		do
			assert(currentFrom.nodes[node], "Not in currentFrom")
			assert(currentFrom.node_count > 0, "No nodes in currentFrom")

			currentFrom.nodes[node] = nil
			currentFrom.node_count = currentFrom.node_count - 1

			-- remove subregion!
			if currentFrom.node_count <= 0 and currentFrom.parentIndex then
				assert(currentFrom.parent, "Bad currentFrom.parent")
				assert(currentFrom.parent.subRegions[currentFrom.parentIndex] == currentFrom, "Not in subregion")
				currentFrom.parent.subRegions[currentFrom.parentIndex] = nil
			end
		end

		-- add to new
		do
			assert(not currentTo.nodes[node], "Failed to add")
			currentTo.nodes[node] = node
			currentTo.node_count = currentTo.node_count + 1
		end

		currentFrom = currentFrom.parent
		currentTo = currentTo.parent
	end
end

function OctreeRegionUtils.removeNode(lowestSubregion, node)
	assert(node, "Bad node")

	local current = lowestSubregion
	while current do
		assert(current.nodes[node], "Not in current")
		assert(current.node_count > 0, "Current has bad node count")

		current.nodes[node] = nil
		current.node_count = current.node_count - 1

		-- remove subregion!
		if current.node_count <= 0 and current.parentIndex then
			assert(current.parent, "No parent")
			assert(current.parent.subRegions[current.parentIndex] == current, "Not in subregion")
			current.parent.subRegions[current.parentIndex] = nil
		end

		current = current.parent
	end
end

function OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, epsilon)
	local diagonal = SQRT_3_OVER_2*diameter
	local searchRadius = radius + diagonal
	return searchRadius*searchRadius + epsilon
end

function OctreeRegionUtils.getNeighborsWithinRadius(region, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
-- luacheck: pop
	assert(maxDepth, "Bad maxDepth")

	local childDiameter = region.size[1]/2
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, childDiameter, EPSILON)

	local radiusSquared = radius*radius

	-- for each child
	for _, childRegion in pairs(region.subRegions) do
		local cposition = childRegion.position
		local cpx, cpy, cpz = cposition[1], cposition[2], cposition[3]

		local ox, oy, oz = px - cpx, py - cpy, pz - cpz
		local dist2 = ox*ox + oy*oy + oz*oz

		-- within search radius
		if dist2 <= searchRadiusSquared then
			if childRegion.depth == maxDepth then
				for node, _ in pairs(childRegion.nodes) do
					local npx, npy, npz = node:GetRawPosition()
					local nox, noy, noz = px - npx, py - npy, pz - npz
					local ndist2 = nox*nox + noy*noy + noz*noz
					if ndist2 <= radiusSquared then
						objectsFound[#objectsFound + 1] = node:GetObject()
						nodeDistances2[#nodeDistances2 + 1] = ndist2
					end
				end
			else
				OctreeRegionUtils.getNeighborsWithinRadius(
					childRegion, radius, px, py, pz, objectsFound, nodeDistances2, maxDepth)
			end
		end
	end
end

function OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, maxDepth)
	local current = region
	for _ = region.depth, maxDepth do
		local index = OctreeRegionUtils.getSubRegionIndex(current, px, py, pz)
		local _next = current.subRegions[index]

		-- construct
		if not _next then
			_next = OctreeRegionUtils.createSubRegion(current, index)
			current.subRegions[index] = _next
		end

		-- iterate
		current = _next
	end
	return current
end

function OctreeRegionUtils.createSubRegion(parentRegion, parentIndex)
	local size = parentRegion.size
	local position = parentRegion.position
	local multiplier = SUB_REGION_POSITION_OFFSET[parentIndex]

	local px = position[1] + multiplier[1]*size[1]
	local py = position[2] + multiplier[2]*size[2]
	local pz = position[3] + multiplier[3]*size[3]
	local sx, sy, sz = size[1]/2, size[2]/2, size[3]/2

	return OctreeRegionUtils.create(px, py, pz, sx, sy, sz, parentRegion, parentIndex)
end

function OctreeRegionUtils.inRegionBounds(region, px, py, pz)
	local lowerBounds = region.lowerBounds
	local upperBounds = region.upperBounds
	return (
		px >= lowerBounds[1] and px <= upperBounds[1] and
		py >= lowerBounds[2] and py <= upperBounds[2] and
		pz >= lowerBounds[3] and pz <= upperBounds[3]
	)
end

function OctreeRegionUtils.getSubRegionIndex(region, px, py, pz)
	local index = px > region.position[1] and 1 or 2
	if py <= region.position[2] then
		index = index + 4
	end

	if pz >= region.position[3] then
		index = index + 2
	end
	return index
end


function OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)
	-- Normally you would modulus this to hash table size, but we want as flat of a structure as possible
	return cx * 73856093 + cy*19351301 + cz*83492791
end


function OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	return math.floor(px / maxRegionSize[1] + 0.5),
		math.floor(py / maxRegionSize[2] + 0.5),
		math.floor(pz / maxRegionSize[3] + 0.5)
end


function OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	return maxRegionSize[1] * cx,
		maxRegionSize[2] * cy,
		maxRegionSize[3] * cz
end


function OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz)
	local position = region.position
	return position[1] == rpx
		and position[2] == rpy
		and position[3] == rpz
end


function OctreeRegionUtils.findRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		return nil
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	return nil
end


function OctreeRegionUtils.getOrCreateRegion(regionHashMap, maxRegionSize, px, py, pz)
	local cx, cy, cz = OctreeRegionUtils.getTopLevelRegionCellIndex(maxRegionSize, px, py, pz)
	local hash = OctreeRegionUtils.getTopLevelRegionHash(cx, cy, cz)

	local regionList = regionHashMap[hash]
	if not regionList then
		regionList = {}
		regionHashMap[hash] = regionList
	end

	local rpx, rpy, rpz = OctreeRegionUtils.getTopLevelRegionPosition(maxRegionSize, cx, cy, cz)
	for _, region in pairs(regionList) do
		if OctreeRegionUtils.areEqualTopRegions(region, rpx, rpy, rpz) then
			return region
		end
	end

	local region = OctreeRegionUtils.create(
		rpx, rpy, rpz,
		maxRegionSize[1], maxRegionSize[2], maxRegionSize[3])
	table.insert(regionList, region)

	return region
end



local OctreeNode = {}
OctreeNode.ClassName = "OctreeNode"
OctreeNode.__index = OctreeNode

function OctreeNode.new(octree, object)
	local self = setmetatable({}, OctreeNode)

	self._octree = octree or error("No octree")
	self._object = object or error("No object")

	self._currentLowestRegion = nil
	self._position = nil

	return self
end

function OctreeNode:KNearestNeighborsSearch(k, radius)
	return self._octree:KNearestNeighborsSearch(self._position, k, radius)
end

--[=[
	Returns the object stored in the octree

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	print(octree:GetObject()) --> "A"
	```

	@return T
]=]
function OctreeNode:GetObject()
	return self._object
end

--[=[
	Finds the nearest neighbors to the octree node

	@param radius number -- The radius to search in
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function OctreeNode:RadiusSearch(radius)
	return self._octree:RadiusSearch(self._position, radius)
end

--[=[
	Retrieves the position

	@return Vector3
]=]
function OctreeNode:GetPosition()
	return self._position
end

--[=[
	Retrieves the as px, py, pz

	@return number -- px
	@return number -- py
	@return number -- pz
]=]
function OctreeNode:GetRawPosition()
	return self._px, self._py, self._pz
end

--[=[
	Sets the position of the octree nodes and updates the octree accordingly

	```lua
	local octree = Octree.new()
	local node = octree:CreateNode(Vector3.new(0, 0, 0), "A")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A" }

	node:SetPosition(Vector3.new(1000, 0, 0))
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> {}
	```

	@param position Vector3
]=]
function OctreeNode:SetPosition(position)
	if self._position == position then
		return
	end

	local px, py, pz = position.x, position.y, position.z

	self._px = px
	self._py = py
	self._pz = pz
	self._position = position

	if self._currentLowestRegion then
		if OctreeRegionUtils.inRegionBounds(self._currentLowestRegion, px, py, pz) then
			return
		end
	end

	local newLowestRegion = self._octree:GetOrCreateLowestSubRegion(px, py, pz)

	-- Sanity check for debugging
	-- if not OctreeRegionUtils.inRegionBounds(newLowestRegion, px, py, pz) then
	-- 	error("[OctreeNode.SetPosition] newLowestRegion is not in region bounds!")
	-- end

	if self._currentLowestRegion then
		OctreeRegionUtils.moveNode(self._currentLowestRegion, newLowestRegion, self)
	else
		OctreeRegionUtils.addNode(newLowestRegion, self)
	end

	self._currentLowestRegion = newLowestRegion
end

--[=[
	Removes the OctreeNode from the octree
]=]
function OctreeNode:Destroy()
	if self._currentLowestRegion then
		OctreeRegionUtils.removeNode(self._currentLowestRegion, self)
	end
end


local EPSILON = 1e-9

local Octree = {}
Octree.ClassName = "Octree"
Octree.__index = Octree

--[=[
	Constructs a new Octree.

	@return Octree<T>
]=]
function Octree.new()
	local self = setmetatable({}, Octree)

	self._maxRegionSize = { 512, 512, 512 } -- these should all be the same number
	self._maxDepth = 4
	self._regionHashMap = {} -- [hash] = region

	return self
end

--[=[
	Returns all octree nodes stored in the octree!

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "Hi")
	octree:CreateNode(Vector3.new(0, 0, 0), "Bob")
	print(octree:GetAllNodes()) --> { "Hi", "Bob" }
	```

	Order is not guaranteed.

	:::warning
	If you have 100,000 nodes in your octree, this is going to be very slow.
	:::

	@return { OctreeNode<T> }
]=]
function Octree:GetAllNodes()
	local options = {}

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			for node, _ in pairs(region.nodes) do
				options[#options+1] = node
			end
		end
	end

	return options
end

--[=[
	Creates a new OctreeNode at the given position which can be retrieved

	:::tip
	Be sure to call :Destroy() on a node if the data becomes stale. Note that
	this is not necessary if the whole octree is removed from memory.
	:::

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 0), "B")
	```

	@param position Vector3
	@param object T
	@return OctreeNode<T>
]=]
function Octree:CreateNode(position, object)
	assert(typeof(position) == "Vector3", "Bad position value")
	assert(object, "Bad object value")

	local node = OctreeNode.new(self, object)

	node:SetPosition(position)

	return node
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius.

	```lua
	local octree = Octree.new()
	octree:CreateNode(Vector3.new(0, 0, 0), "A")
	octree:CreateNode(Vector3.new(0, 0, 0), "B")
	octree:CreateNode(Vector3.new(0, 0, 1000), "C")
	print(octree:RadiusSearch(Vector3.new(0, 0, 0), 100)) --> { "A", "B" }
	```

	@param position Vector3
	@param radius number
	@return { T } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:RadiusSearch(position, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.x, position.y, position.z
	return self:_radiusSearch(px, py, pz, radius)
end

--[=[
	Searches at the position and radius for any objects that may be within
	this radius. Returns the knearest entries.

	The closest entities will be first in the list.

	@param position Vector3
	@param k number -- Number of objects to find
	@param radius number
	@return { any } -- Objects found
	@return { number } -- Distances squared
]=]
function Octree:KNearestNeighborsSearch(position, k, radius)
	assert(typeof(position) == "Vector3", "Bad position")
	assert(type(radius) == "number", "Bad radius")

	local px, py, pz = position.x, position.y, position.z
	local objects, nodeDistances2 = self:_radiusSearch(px, py, pz, radius)

	local sortable = {}
	for index, dist2 in pairs(nodeDistances2) do
		table.insert(sortable, {
			dist2 = dist2;
			index = index;
		})
	end

	table.sort(sortable, function(a, b)
		return a.dist2 < b.dist2
	end)

	local knearest = {}
	local knearestDist2 = {}
	for i = 1, math.min(#sortable, k) do
		local sorted = sortable[i]
		knearestDist2[#knearestDist2 + 1] = sorted.dist2
		knearest[#knearest + 1] = objects[sorted.index]
	end

	return knearest, knearestDist2
end

--[=[
	Internal API to create lowest subregion

	@private
	@param px number
	@param py number
	@param pz number
	@return OctreeSubregion
]=]
function Octree:GetOrCreateLowestSubRegion(px, py, pz)
	local region = self:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateSubRegionAtDepth(region, px, py, pz, self._maxDepth)
end

function Octree:_radiusSearch(px, py, pz, radius)
	local objectsFound = {}
	local nodeDistances2 = {}

	local diameter = self._maxRegionSize[1]
	local searchRadiusSquared = OctreeRegionUtils.getSearchRadiusSquared(radius, diameter, EPSILON)

	for _, regionList in pairs(self._regionHashMap) do
		for _, region in pairs(regionList) do
			local rpos = region.position
			local rpx, rpy, rpz = rpos[1], rpos[2], rpos[3]
			local ox, oy, oz = px - rpx, py - rpy, pz - rpz
			local dist2 = ox*ox + oy*oy + oz*oz

			if dist2 <= searchRadiusSquared then
				OctreeRegionUtils.getNeighborsWithinRadius(
					region, radius, px, py, pz, objectsFound, nodeDistances2, self._maxDepth)
			end
		end
	end

	return objectsFound, nodeDistances2
end

function Octree:_getRegion(px, py, pz)
	return OctreeRegionUtils.findRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

function Octree:_getOrCreateRegion(px, py, pz)
	return OctreeRegionUtils.getOrCreateRegion(self._regionHashMap, self._maxRegionSize, px, py, pz)
end

return Octree
