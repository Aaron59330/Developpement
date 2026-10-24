-- Global marker system for CorePickax.
-- The native FiveM DrawMarker is never replaced.
-- Ground position is detected once per marker, then locked so markers stay fixed.

local lockedGround = {}

local function isVector3(value)
    local valueType = type(value)
    return valueType == 'vector3' or valueType == 'vector4'
end

local function markerKey(x, y, z)
    -- Fixed coordinates are enough to identify a marker in this resource.
    return ('%.3f:%.3f:%.3f'):format(x, y, z)
end

local function addCandidate(candidates, z, sourceZ, maxDistance)
    if type(z) ~= 'number' then return end

    local distance = math.abs(z - sourceZ)
    if distance <= maxDistance then
        candidates[#candidates + 1] = {
            z = z,
            distance = distance
        }
    end
end

local function detectGroundOnce(x, y, sourceZ, marker)
    if not marker or marker.Grounded == false then
        return sourceZ
    end

    local key = markerKey(x, y, sourceZ)
    if lockedGround[key] ~= nil then
        return lockedGround[key]
    end

    RequestCollisionAtCoord(x, y, sourceZ)

    local maxDistance = marker.MaxGroundSnapDistance or 6.0
    local candidates = {}
    local probes = marker.GroundProbeSteps or {
        0.35, 0.75, 1.25, 2.0, 3.0, 5.0, 8.0, 15.0, 30.0, 50.0
    }

    -- Progressive probes: prefer the valid surface closest to the configured Z.
    for i = 1, #probes do
        local found, groundZ = GetGroundZFor_3dCoord(x, y, sourceZ + probes[i], false)
        if found then
            addCandidate(candidates, groundZ, sourceZ, maxDistance)
        end
    end

    -- Vertical ray as a fallback for roads, ramps and MLO floors.
    local rayUp = marker.GroundRayUp or 2.0
    local rayDown = marker.GroundRayDown or 8.0
    local ray = StartExpensiveSynchronousShapeTestLosProbe(
        x, y, sourceZ + rayUp,
        x, y, sourceZ - rayDown,
        1,
        PlayerPedId(),
        7
    )

    if ray and ray ~= 0 then
        local _, hit, endCoords = GetShapeTestResult(ray)
        if hit == 1 and endCoords then
            addCandidate(candidates, endCoords.z, sourceZ, maxDistance)
        end
    end

    local bestZ = nil
    local bestDistance = math.huge

    for i = 1, #candidates do
        local candidate = candidates[i]
        if candidate.distance < bestDistance then
            bestDistance = candidate.distance
            bestZ = candidate.z
        end
    end

    local groundZ = bestZ or sourceZ

    -- On verrouille uniquement le vrai Z du sol. Les compensations visuelles
    -- sont appliquées ensuite selon le type de marker.
    lockedGround[key] = groundZ
    return groundZ
end

function ClearGlobalMarkerGroundCache()
    lockedGround = {}
end

-- Couleur du serveur (AccentColor) : utilisée quand GlobalMarker.Color n'impose pas de r / g / b
local function accentRGB()
    local h = Config and Config.AccentColor
    if type(h) == 'string' and h:match('^#%x%x%x%x%x%x$') then
        return tonumber(h:sub(2, 3), 16), tonumber(h:sub(4, 5), 16), tonumber(h:sub(6, 7), 16)
    end
end

function DrawGlobalMarker(...)
    local args = { ... }
    local marker = Config and Config.GlobalMarker

    if not marker or marker.Enabled == false then
        return DrawMarker(table.unpack(args))
    end

    local markerType = args[1]
    local x, y, z
    local baseIndex

    if isVector3(args[2]) then
        x = args[2].x
        y = args[2].y
        z = args[2].z
        baseIndex = 3
    else
        x = tonumber(args[2])
        y = tonumber(args[3])
        z = tonumber(args[4])
        baseIndex = 5
    end

    if not x or not y or not z then
        return DrawMarker(table.unpack(args))
    end

    local dirX = args[baseIndex] or 0.0
    local dirY = args[baseIndex + 1] or 0.0
    local dirZ = args[baseIndex + 2] or 0.0
    local rotX = args[baseIndex + 3] or 0.0
    local rotY = args[baseIndex + 4] or 0.0
    local rotZ = args[baseIndex + 5] or 0.0

    local oldScaleX = args[baseIndex + 6] or 1.0
    local oldScaleY = args[baseIndex + 7] or 1.0
    local oldScaleZ = args[baseIndex + 8] or 1.0
    local oldRed = args[baseIndex + 9] or 255
    local oldGreen = args[baseIndex + 10] or 255
    local oldBlue = args[baseIndex + 11] or 255
    local oldAlpha = args[baseIndex + 12] or 255
    local p19 = args[baseIndex + 15] or 2
    local textureDict = args[baseIndex + 17]
    local textureName = args[baseIndex + 18]

    markerType = marker.Type or markerType
    z = detectGroundOnce(x, y, z, marker)

    local size = marker.Size or {}
    local color = marker.Color or {}
    local ar, ag, ab = accentRGB()

    -- Position finale au sol : GroundZ réel + éventuel réglage général, puis
    -- compensation propre au type 23 pour que le cercle soit visuellement
    -- posé sur la surface et non légèrement flottant.
    z = z + (marker.GroundOffset or 0.0)

    if marker.AutoVisualGroundOffset ~= false and markerType == 23 then
        z = z + (marker.Type23GroundOffset or -0.10)
    end

    return DrawMarker(
        markerType,
        x, y, z,
        dirX, dirY, dirZ,
        rotX, rotY, rotZ,
        size.x or oldScaleX,
        size.y or oldScaleY,
        size.z or oldScaleZ,
        color.r or ar or oldRed,
        color.g or ag or oldGreen,
        color.b or ab or oldBlue,
        color.a or oldAlpha,
        false, -- fixed: no vertical bobbing
        false, -- fixed: no camera-facing movement
        p19,
        false, -- fixed: no rotation animation
        textureDict,
        textureName,
        marker.DrawOnEnts == true
    )
end
