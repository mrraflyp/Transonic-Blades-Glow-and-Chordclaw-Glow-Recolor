local mod = get_mod("transonic_stance_colors")

-- ##########################################################
-- ################## Optimizations & Math ##################

local MATERIAL_CANDIDATES = { "emissive_color", "tint_color", "energy_color", "color", "blade_color", "energy_tint" }

local settings_cache = {
    apply_others = false,
    rgb_target = "disabled",
    rgb_speed = 0.5,
    rgb_speed_slow = 0.5,
    rgb_intensity = 2.0,
    stance_1 = { r = 0, g = 128, b = 255, i = 2.0 },
    stance_2 = { r = 255, g = 0, b = 0, i = 2.0 }
}

local function update_settings_cache()
    settings_cache.apply_others = mod:get("apply_to_others") or false
    settings_cache.rgb_target = mod:get("rgb_cycle_target") or "disabled"
    settings_cache.rgb_speed = mod:get("rgb_cycle_speed") or 0
    settings_cache.rgb_speed_slow = mod:get("rgb_cycle_slow") or 0.5
    settings_cache.rgb_intensity = mod:get("rgb_cycle_intensity") or 2.0

    settings_cache.stance_1.r = mod:get("stance_1_r") or 0
    settings_cache.stance_1.g = mod:get("stance_1_g") or 128
    settings_cache.stance_1.b = mod:get("stance_1_b") or 255
    settings_cache.stance_1.i = mod:get("stance_1_intensity") or 2.0

    settings_cache.stance_2.r = mod:get("stance_2_r") or 255
    settings_cache.stance_2.g = mod:get("stance_2_g") or 0
    settings_cache.stance_2.b = mod:get("stance_2_b") or 0
    settings_cache.stance_2.i = mod:get("stance_2_intensity") or 2.0
end

update_settings_cache()

-- Converts Hue to RGB for the rainbow cycle
local function hsv_to_rgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t_val = v * (1 - (1 - f) * s)
    i = i % 6
    if i == 0 then r, g, b = v, t_val, p
    elseif i == 1 then r, g, b = q, v, p
    elseif i == 2 then r, g, b = p, v, t_val
    elseif i == 3 then r, g, b = p, q, v
    elseif i == 4 then r, g, b = t_val, p, v
    elseif i == 5 then r, g, b = v, p, q
    end
    return r, g, b
end

-- ##########################################################
-- ################## Functions #############################

local function apply_color_to_vars(vars, color_vec)
    if not vars then return end
    for i = 1, #vars do
        local unit = vars[i].unit
        if unit and Unit.alive(unit) then
            for j = 1, #MATERIAL_CANDIDATES do
                pcall(function()
                    Unit.set_vector3_for_materials(unit, MATERIAL_CANDIDATES[j], color_vec, true)
                end)
            end
        end
    end
end

-- Static stance update
local function update_blade_color(effect_instance)
    local is_local_player = false
    local player = Managers.player:local_player(1)

    if player and player.player_unit and ScriptUnit.has_extension(player.player_unit, "visual_loadout_system") then
        local visual_ext = ScriptUnit.extension(player.player_unit, "visual_loadout_system")
        if visual_ext._wieldable_slot_scripts then
            for _, scripts in pairs(visual_ext._wieldable_slot_scripts) do
                for _, script in ipairs(scripts) do
                    if script == effect_instance then
                        is_local_player = true
                        break
                    end
                end
                if is_local_player then break end
            end
        end
    end

    if not is_local_player and not settings_cache.apply_others then
        return
    end

    local is_special = effect_instance._inventory_slot_component.special_active

    -- Don't apply static color if this stance should use RGB
    if settings_cache.rgb_target ~= "disabled" then
        local use_rgb =
            settings_cache.rgb_target == "both"
            or (settings_cache.rgb_target == "stance_1" and not is_special)
            or (settings_cache.rgb_target == "stance_2" and is_special)

        if use_rgb then
            return
        end
    end

    local c = is_special and settings_cache.stance_2 or settings_cache.stance_1
    local color_vec = Vector3(
        (c.r / 255) * c.i,
        (c.g / 255) * c.i,
        (c.b / 255) * c.i
    )

    apply_color_to_vars(effect_instance._weapon_material_variables_1p, color_vec)
    apply_color_to_vars(effect_instance._weapon_material_variables_3p, color_vec)
end

-- ##########################################################
-- #################### Hooks ###############################

-- Frame-by-frame update for RGB cycling
mod:hook_safe(CLASS.TransonicWeaponEffects, "update", function(self, unit, dt, t)

    if settings_cache.rgb_target == "disabled" then
        return
    end

    local is_local_player = false
    local player = Managers.player:local_player(1)

    if player and player.player_unit and ScriptUnit.has_extension(player.player_unit, "visual_loadout_system") then
        local visual_ext = ScriptUnit.extension(player.player_unit, "visual_loadout_system")
        if visual_ext._wieldable_slot_scripts then
            for _, scripts in pairs(visual_ext._wieldable_slot_scripts) do
                for _, script in ipairs(scripts) do
                    if script == self then
                        is_local_player = true
                        break
                    end
                end
                if is_local_player then break end
            end
        end
    end

    if not is_local_player and not settings_cache.apply_others then
        return
    end

    local is_special = self._inventory_slot_component.special_active

    local use_rgb =
        settings_cache.rgb_target == "both"
        or (settings_cache.rgb_target == "stance_1" and not is_special)
        or (settings_cache.rgb_target == "stance_2" and is_special)

    if not use_rgb then
        update_blade_color(self)
        return
    end

    -- Determine RGB cycle speed
    local speed

    if settings_cache.rgb_speed == 0 then
        speed = settings_cache.rgb_speed_slow
    else
        speed = settings_cache.rgb_speed
    end

    -- Generate changing color based on time
    local hue = (t * speed) % 1.0
    local r, g, b = hsv_to_rgb(hue, 1.0, 1.0)
    local i = settings_cache.rgb_intensity

    local color_vec = Vector3(r * i, g * i, b * i)

    apply_color_to_vars(self._weapon_material_variables_1p, color_vec)
    apply_color_to_vars(self._weapon_material_variables_3p, color_vec)
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "wield", function(self)
    update_blade_color(self)
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "_toggle_direction", function(self, toggle_direction)
    update_blade_color(self)
end)

mod.on_setting_changed = function(setting_id)
    update_settings_cache() 
    local player = Managers.player:local_player(1)
    if not player then return end
    
    local player_unit = player.player_unit
    if player_unit and ScriptUnit.has_extension(player_unit, "visual_loadout_system") then
        local visual_ext = ScriptUnit.extension(player_unit, "visual_loadout_system")
        if visual_ext._wieldable_slot_scripts then
            for slot_name, scripts in pairs(visual_ext._wieldable_slot_scripts) do
                for _, script in ipairs(scripts) do
                    if script._set_stance_trigger and script._weapon_material_variables_1p then
                        update_blade_color(script)
                    end
                end
            end
        end
    end
end