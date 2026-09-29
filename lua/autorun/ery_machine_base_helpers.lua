--[[
    ERY_MACHINE:DrawAttachments(entity, attachments)

    Single entry point for clientside attachment models. Call this from your
    entity's Draw() every frame, passing the attachments table you want shown.

    On the first call it builds the clientside models. On every call it reads
    each attachment's current fields and applies them, so you can mutate the
    table (e.g. in Think) between draws for live animation -- rotating dishes,
    blinking lights, whatever -- without rebuilding anything.

    attachments is an array of tables, each supporting:
        ID        (number)            -- local identifier for this attachment,
                                          used by other attachments' Parent field
                                          (default: the attachment's array index)
        Model     (string)            -- model path. Leave empty ("") for an invisible
                                          pivot: it is never built or drawn, but other
                                          attachments can still Parent to it.
        Pos       (Vector)            -- local offset from parent (default 0,0,0)
        Angle     (Angle)             -- local angle offset, pitch/yaw/roll (default 0,0,0)
        Parent    (number)            -- ID of the attachment to parent to. 0 (default)
                                          means parent to the base entity. Any other
                                          number parents to the attachment with that ID.
        Color     (Color)             -- default color_white
        Material  (string)            -- optional override material
        AxisScale (Vector)            -- optional per-axis bone scale
        Scale     (number)            -- uniform scale, used only if AxisScale is absent (default 1)
        Hidden    (boolean)           -- true = skip drawing this attachment. Its transform
                                          is still resolved, so children keep following it,
                                          and its clientside model is kept so un-hiding is free.

    Each attachment table is kept as the live source of truth -- edit its
    fields directly at any time (Pos, Angle, Color, Material, AxisScale,
    Scale, Parent, or even Model) and the next Draw call reflects the change.
    An attachment's __model field tracks which model string it was built
    with, so changing .Model triggers a rebuild of just that slot.

    IDs only need to be unique within a single attachments table. If you
    don't set ID explicitly, the attachment's position in the array is used,
    so purely-flat setups (no Parent usage) need no changes at all.

    Example -- spinning radar dish sat on a rotating base, base on the entity:
        entity.Attachments = {
            { ID = 1, Model = "models/radar_base.mdl", Pos = Vector(0,0,0),  Angle = Angle(0,0,0), Parent = 0 },
            { ID = 2, Model = "models/radar_dish.mdl", Pos = Vector(0,0,20), Angle = Angle(0,0,0), Parent = 1 },
        }

        function ENT:Think()
            local base = self.Attachments[1]
            base.Angle.y = (base.Angle.y + FrameTime() * 45) % 360

            local dish = self.Attachments[2]
            dish.Angle.p = (dish.Angle.p + FrameTime() * 90) % 360
        end

        function ENT:Draw()
            self:DrawModel()
            ERY_MACHINE:DrawAttachments(self, self.Attachments)
        end
]]

ERY_MACHINE = ERY_MACHINE or {}

if CLIENT then

    local function buildModel(attach)
        local mdl = ClientsideModel(attach.Model, RENDERGROUP_TRANSLUCENT)
        if IsValid(mdl) then
            mdl:SetNoDraw(true)
            attach.__model = attach.Model
        end
        return mdl
    end

    -- Computes worldPos/worldAng for a single attachment given its parent's
    -- already-resolved worldPos/worldAng. Doesn't touch the model itself.
    local function resolveTransform(attach, parentPos, parentAng)
        local pos = attach.Pos or vector_origin
        local ang = attach.Angle or angle_zero

        local worldPos = parentPos
            + parentAng:Forward() * pos.x
            + parentAng:Right()   * pos.y
            + parentAng:Up()      * pos.z

        local worldAng = Angle(parentAng.p, parentAng.y, parentAng.r)
        worldAng:RotateAroundAxis(parentAng:Up(), ang.y)
        worldAng:RotateAroundAxis(parentAng:Right(), ang.p)
        worldAng:RotateAroundAxis(parentAng:Forward(), ang.r)

        return worldPos, worldAng
    end

    function ERY_MACHINE:DrawAttachments(entity, attachments)
        if not IsValid(entity) or not attachments then return end

        entity.__eryAttachModels = entity.__eryAttachModels or {}
        local slots = entity.__eryAttachModels

        -- Build lookup of ID -> attachment, and track which slot keys are
        -- still in use so stale clientside models can be cleaned up.
        local byID = {}
        local liveKeys = {}

        for i, attach in ipairs(attachments) do
            local id = attach.ID or i
            attach.__resolvedID = id
            byID[id] = attach
            liveKeys[id] = true
        end

        for key, mdl in pairs(slots) do
            if not liveKeys[key] then
                if IsValid(mdl) then
                    mdl:Remove()
                end
                slots[key] = nil
            end
        end

        local parentPos = entity:GetPos()
        local parentAng = entity:GetAngles()

        -- Resolved world transforms this frame, keyed by attachment ID, so
        -- children can look up their parent's transform regardless of draw
        -- order. Filled in lazily via resolveWorld() below.
        local resolved = {}
        local resolving = {} -- cycle guard

        local resolveWorld -- forward declare for recursion

        resolveWorld = function(id)
            if resolved[id] then
                return resolved[id].pos, resolved[id].ang
            end

            local attach = byID[id]
            if not attach then
                -- Unknown parent reference, fall back to the entity.
                return parentPos, parentAng
            end

            if resolving[id] then
                -- Parent cycle detected, fall back to the entity to avoid
                -- infinite recursion.
                return parentPos, parentAng
            end
            resolving[id] = true

            local parentID = attach.Parent or 0
            local basePos, baseAng
            if parentID == 0 then
                basePos, baseAng = parentPos, parentAng
            else
                basePos, baseAng = resolveWorld(parentID)
            end

            local worldPos, worldAng = resolveTransform(attach, basePos, baseAng)
            resolved[id] = { pos = worldPos, ang = worldAng }

            resolving[id] = nil

            return worldPos, worldAng
        end

        for i, attach in ipairs(attachments) do
            local key = attach.__resolvedID
            local mdl = slots[key]

            -- An empty Model is a pure pivot: nothing to build or draw,
            -- but its transform is still resolved for its children.
            local isPivot = attach.Model == nil or attach.Model == ""

            if isPivot and IsValid(mdl) then
                -- Model was blanked out after being built; free it.
                mdl:Remove()
                slots[key] = nil
            end

            -- Hidden attachments skip drawing but keep their built
            -- model, so showing them again costs nothing.
            if not isPivot and not attach.Hidden then
                if not IsValid(mdl) or attach.__model ~= attach.Model then
                    if IsValid(mdl) then
                        mdl:Remove()
                    end

                    mdl = buildModel(attach)
                    slots[key] = mdl
                end

                if IsValid(mdl) then
                    local worldPos, worldAng = resolveWorld(key)

                    mdl:SetPos(worldPos)
                    mdl:SetAngles(worldAng)

                    if attach.AxisScale then
                        local mtx = Matrix()
                        mtx:Scale(attach.AxisScale)
                        mdl:EnableMatrix("RenderMultiply", mtx)
                    else
                        mdl:DisableMatrix("RenderMultiply")
                        mdl:SetModelScale(attach.Scale or 1, 0)
                    end

                    if attach.Material and attach.Material ~= "" then
                        mdl:SetMaterial(attach.Material)
                    else
                        mdl:SetMaterial("")
                    end

                    local col = attach.Color or color_white

                    render.SetColorModulation(
                        col.r / 255,
                        col.g / 255,
                        col.b / 255
                    )

                    mdl:DrawModel()

                    render.SetColorModulation(1, 1, 1)
                end
            end
        end
    end

    function ERY_MACHINE:CleanupAttachments(entity)
        if not entity then return end

        if entity.__eryAttachModels then
            for _, mdl in pairs(entity.__eryAttachModels) do
                if IsValid(mdl) then
                    mdl:Remove()
                end
            end

            entity.__eryAttachModels = nil
        end
    end

end