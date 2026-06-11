BMB = BMB or {}
BMB.DebugBlocks = BMB.DebugBlocks or {}

local debugHud = CreateClientConVar("bmb_debug_hud", "0", true, false, "Draw BMB mob debug labels.")

local colors = {
    GRASS = Color(80, 210, 75, 70),
    DIRT = Color(135, 90, 45, 80),
    STONE = Color(155, 155, 155, 95)
}

net.Receive("bmb_mock_blocks", function()
    local expire = CurTime() + net.ReadFloat()
    local count = net.ReadUInt(16)
    local blocks = {}

    for _ = 1, count do
        blocks[#blocks + 1] = {
            pos = net.ReadVector(),
            type = net.ReadString()
        }
    end

    BMB.DebugBlocks = {
        expire = expire,
        blocks = blocks
    }
end)

hook.Add("PostDrawTranslucentRenderables", "BMB_DrawMockBlocks", function()
    local debugData = BMB.DebugBlocks
    if not debugData or not debugData.blocks then return end

    if CurTime() > debugData.expire then
        BMB.DebugBlocks = {}
        return
    end

    local size = BMB.Config and BMB.Config.BlockSize or 36
    local mins = Vector(-size * 0.5, -size * 0.5, 0)
    local maxs = Vector(size * 0.5, size * 0.5, size)

    render.SetColorMaterial()

    for _, block in ipairs(debugData.blocks) do
        local color = colors[block.type] or Color(255, 255, 255, 70)
        render.DrawWireframeBox(block.pos, angle_zero, mins, maxs, color, true)
        render.DrawBox(block.pos, angle_zero, mins, maxs, color)
    end
end)

hook.Add("HUDPaint", "BMB_DebugMobHUD", function()
    if not debugHud:GetBool() then return end

    for _, ent in ipairs(ents.GetAll()) do
        if IsValid(ent) and string.sub(ent:GetClass() or "", 1, 4) == "bmb_" then
            local screen = (ent:WorldSpaceCenter() + Vector(0, 0, 28)):ToScreen()
            if screen.visible ~= false then
                local line1 = string.format(
                    "%s  hp:%d  state:%s  mode:%s",
                    ent:GetClass(),
                    ent:GetNWInt("BMBHealth", 0),
                    ent:GetNWString("BMBState", "?"),
                    ent:GetNWString("BMBMoveMode", "?")
                )
                local line2 = string.format(
                    "vel:%.1f/%.1f  dist:%.1f  node:%d  adv:%d",
                    ent:GetVelocity():Length2D(),
                    ent:GetNWFloat("BMBDesiredSpeed", 0),
                    ent:GetNWFloat("BMBDistToGoal", 0),
                    ent:GetNWInt("BMBPathNode", 0),
                    ent:GetNWInt("BMBPathAdvance", 0)
                )
                local resultNames = {
                    [0] = "air",
                    [1] = "ok",
                    [2] = "retry",
                    [3] = "fail"
                }
                local hopLine

                if CurTime() < ent:GetNWFloat("BMBHopDebugUntil", 0) then
                    hopLine = string.format(
                        "hop#%d %s d:%.1f face:%.1f v:%.1f apex:%.1f %s",
                        ent:GetNWInt("BMBHopAttempt", 0),
                        ent:GetNWBool("BMBHopNative", false) and "native" or "manual",
                        ent:GetNWFloat("BMBHopDistance", 0),
                        ent:GetNWFloat("BMBHopFaceDistance", 0),
                        ent:GetNWFloat("BMBHopSpeed", 0),
                        ent:GetNWFloat("BMBHopApex", 0),
                        resultNames[ent:GetNWInt("BMBHopResult", 0)] or "?"
                    )
                end

                draw.SimpleTextOutlined(line1, "DermaDefaultBold", screen.x, screen.y - 8, Color(255, 245, 160), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
                draw.SimpleTextOutlined(line2, "DermaDefaultBold", screen.x, screen.y + 8, Color(180, 230, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))

                if hopLine then
                    draw.SimpleTextOutlined(hopLine, "DermaDefaultBold", screen.x, screen.y + 24, Color(210, 255, 190), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER, 1, Color(0, 0, 0, 220))
                end
            end
        end
    end
end)
