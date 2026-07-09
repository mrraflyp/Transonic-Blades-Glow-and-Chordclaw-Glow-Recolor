local mod = get_mod("transonic_stance_colors")
local VisualLoadoutCustomization = require("scripts/extension_systems/visual_loadout/utilities/visual_loadout_customization")

-- ##########################################################
-- ################## State & Setup #########################

local MAIN_MATERIAL_CANDIDATES = { "emissive_color", "tint_color", "energy_color", "color", "blade_color", "energy_tint" }
local CLAW_MATERIAL_CANDIDATES = { "emissive_color", "tint_color", "energy_color", "color", "blade_color", "energy_tint", "self_illumination", "emissive" }
local EXACT_MATS = { "blade_energy", "blade_wiggle" }

mod._last_known_special_active = mod._last_known_special_active or false
mod._is_unwielding = false
mod._cached_player_unit = nil
mod._cached_visual_ext = nil
mod._last_cc_stance = nil
mod._force_cc_update = true

local ve_state_cache = setmetatable({}, { __mode = "k" })

-- ##########################################################
-- ############# NEW: High-Performance Caches ###############
-- These stop the mod from spamming the C++ engine every frame
local owner_type_cache = setmetatable({}, { __mode = "k" })
local effect_owner_cache = setmetatable({}, { __mode = "k" })
-- ##########################################################

local settings_cache = {
    apply_others = false,
    ve_glow_enabled = true,
    chordclaw_glow_enabled = true,
    inventory_enabled = false,
    rgb_target = "disabled",
    rgb_speed = 0.5,
    rgb_speed_slow = 0.5,
    rgb_intensity = 2.0,
    stance_1 = { r = 0, g = 128, b = 255, i = 2.0 },
    stance_2 = { r = 255, g = 0, b = 0, i = 2.0 }
}

local function update_settings_cache()
    settings_cache.apply_others = mod:get("apply_to_others") or false
    settings_cache.ve_glow_enabled = mod:get("ve_glow_enabled") == nil and true or mod:get("ve_glow_enabled")
    settings_cache.chordclaw_glow_enabled = mod:get("chordclaw_glow_enabled") == nil and true or mod:get("chordclaw_glow_enabled")
    settings_cache.inventory_enabled = mod:get("inventory_glow_enabled") or false
    
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

local function hsv_to_rgb(h, s, v)
    local r, g, b
    local i = math.floor(h * 6)
    local f = h * 6 - i
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t_val = v * (1 - (1 - f) * s)
    i = i % 6
    if     i == 0 then r, g, b = v,     t_val, p
    elseif i == 1 then r, g, b = q,     v,     p
    elseif i == 2 then r, g, b = p,     v,     t_val
    elseif i == 3 then r, g, b = p,     q,     v
    elseif i == 4 then r, g, b = t_val, p,     v
    elseif i == 5 then r, g, b = v,     p,     q
    end
    return r, g, b
end

-- ##########################################################
-- ################## Ironclad State Safeguard ##############

local function get_safe_local_player_unit()
    if not Managers.state or not Managers.state.player_unit_spawn or not Managers.player then
        return nil
    end
    local ok, player = pcall(Managers.player.local_player, Managers.player, 1)
    if ok and player then
        return player.player_unit
    end
    return nil
end

-- ##########################################################
-- ################## Exact Unit ID Matching ################

local unit_to_player_map = setmetatable({}, { __mode = "k" })

local function get_weapon_owner_type(weapon_unit)
    if not weapon_unit then return "unknown" end
    
    -- Fast Path: Check memory cache first
    if owner_type_cache[weapon_unit] then 
        return owner_type_cache[weapon_unit] 
    end
    
    local parent_unit = unit_to_player_map[weapon_unit]
    
    if not parent_unit then return "unknown" end
    if not Managers.state or not Managers.state.player_unit_spawn then return "ui" end
    
    local current_player_unit = get_safe_local_player_unit()
    if current_player_unit then
        if current_player_unit == parent_unit then 
            owner_type_cache[weapon_unit] = "local"
            return "local" 
        end
        
        local fp_ext = ScriptUnit.has_extension(current_player_unit, "first_person_system")
        if fp_ext and fp_ext.first_person_unit then
            local fp_unit = fp_ext:first_person_unit()
            if fp_unit == parent_unit then 
                owner_type_cache[weapon_unit] = "local"
                return "local" 
            end
        end
    end
    
    if Managers.player then
        local ok, players = pcall(Managers.player.players, Managers.player)
        if ok and players then
            for _, p in pairs(players) do
                if p.player_unit == parent_unit then 
                    owner_type_cache[weapon_unit] = "teammate"
                    return "teammate" 
                end
            end
        end
    end
    
    return "ui"
end

local function is_effect_local_player(effect_instance)
    if not effect_instance then return false end

    -- Fast Path: Check memory cache first
    if effect_owner_cache[effect_instance] ~= nil then
        return effect_owner_cache[effect_instance]
    end

    local is_local = false
    local current_player_unit = get_safe_local_player_unit()

    if current_player_unit and ScriptUnit.has_extension(current_player_unit, "visual_loadout_system") then
        local visual_ext = ScriptUnit.extension(current_player_unit, "visual_loadout_system")
        if visual_ext._wieldable_slot_scripts then
            for _, scripts in pairs(visual_ext._wieldable_slot_scripts) do
                for _, script in ipairs(scripts) do
                    if script == effect_instance then
                        is_local = true
                        break
                    end
                end
                if is_local then break end
            end
        end
    end
    
    -- Save the result to cache so we never have to run this heavy lookup again for this instance
    if current_player_unit then
        effect_owner_cache[effect_instance] = is_local
    end
    
    return is_local
end

-- ##########################################################
-- ################## Color & Material Drivers ##############

local function apply_color_to_vars(vars, color_vec)
    if not vars then return end
    for i = 1, #vars do
        local u = vars[i].unit
        if u and Unit.alive(u) then
            for j = 1, #MAIN_MATERIAL_CANDIDATES do
                pcall(Unit.set_vector3_for_materials, u, MAIN_MATERIAL_CANDIDATES[j], color_vec, true)
            end
        end
    end
end

local function get_inventory_color(t_val)
    local is_stance2 = mod._last_known_special_active
    local rgb_target = settings_cache.rgb_target
    local use_rgb = rgb_target == "both"
        or (rgb_target == "stance_1" and not is_stance2)
        or (rgb_target == "stance_2" and is_stance2)

    if use_rgb then
        local speed = settings_cache.rgb_speed == 0 and settings_cache.rgb_speed_slow or settings_cache.rgb_speed
        local hue = (t_val * speed) % 1.0
        local r, g, b = hsv_to_rgb(hue, 1.0, 1.0)
        local i = settings_cache.rgb_intensity
        return Vector3(r * i, g * i, b * i), true
    end

    local c = is_stance2 and settings_cache.stance_2 or settings_cache.stance_1
    return Vector3((c.r / 255) * c.i, (c.g / 255) * c.i, (c.b / 255) * c.i), false
end

local function apply_color_to_ve_unit(u, current_color, is_rgb)
    if not u or not Unit.alive(u) then return end
    
    local current_stance = mod._last_known_special_active
    local color_key = string.format("%.3f,%.3f,%.3f", current_color.x, current_color.y, current_color.z)

    if not is_rgb then
        local state = ve_state_cache[u]
        if state and state.stance == current_stance and state.color == color_key then
            return
        end
    end

    ve_state_cache[u] = {
        stance = current_stance,
        color = color_key
    }

    local stance_value = current_stance and 1.0 or 0.0
    for m = 1, #EXACT_MATS do
        local mat = EXACT_MATS[m]
        pcall(Unit.set_scalar_for_material, u, mat, "on_off", 1.0)
        pcall(Unit.set_scalar_for_material, u, mat, "stance_trigger", 0.0)
        pcall(Unit.set_scalar_for_material, u, mat, "inverse_direction", stance_value)
    end

    local final_color = current_color
    if current_stance then
        local compensation_factor = 0.25 
        final_color = Vector3(current_color.x * compensation_factor, current_color.y * compensation_factor, current_color.z * compensation_factor)
    end

    for j = 1, #MAIN_MATERIAL_CANDIDATES do
        pcall(Unit.set_vector3_for_materials, u, MAIN_MATERIAL_CANDIDATES[j], final_color, true)
    end
end

-- ##########################################################
-- ################## In-Game Blade Updater #################

local function update_blade_color(effect_instance, t_val, force_static)
    if not effect_instance then return end

    local is_local = is_effect_local_player(effect_instance)
    local is_special = effect_instance._inventory_slot_component and effect_instance._inventory_slot_component.special_active or false

    if not is_local and not settings_cache.apply_others then return end

    local rgb_target = settings_cache.rgb_target
    local use_rgb = rgb_target == "both"
        or (rgb_target == "stance_1" and not is_special)
        or (rgb_target == "stance_2" and is_special)

    if not use_rgb and not force_static then
        return
    end

    local color_vec
    if use_rgb then
        local speed = settings_cache.rgb_speed == 0 and settings_cache.rgb_speed_slow or settings_cache.rgb_speed
        local hue = ((t_val or 0) * speed) % 1.0
        local r, g, b = hsv_to_rgb(hue, 1.0, 1.0)
        local i = settings_cache.rgb_intensity
        color_vec = Vector3(r * i, g * i, b * i)
    else
        local c = is_special and settings_cache.stance_2 or settings_cache.stance_1
        color_vec = Vector3((c.r / 255) * c.i, (c.g / 255) * c.i, (c.b / 255) * c.i)
    end
    
    apply_color_to_vars(effect_instance._weapon_material_variables_1p, color_vec)
    apply_color_to_vars(effect_instance._weapon_material_variables_3p, color_vec)
end

-- ##########################################################
-- ################## Trackers & Mod Hooks ##################

local transonic_preview_units = {}
local preview_t = 0                 
local tracked_weapon_effects = {} 

mod:hook(VisualLoadoutCustomization, "spawn_item", function(func, item, attach_settings, link_unit, ...)
    local item_unit_3p, attachment_units_3p, bind_pose, attachment_id_lookup, attachment_name_lookup, attachment_units_bind_poses, item_name_by_unit = func(item, attach_settings, link_unit, ...)

    if item and item.name and string.find(item.name, "transonic") then
        if link_unit then unit_to_player_map[item_unit_3p] = link_unit end
        
        if attachment_units_3p and attachment_units_3p[item_unit_3p] then
            for _, u in ipairs(attachment_units_3p[item_unit_3p]) do 
                if link_unit then unit_to_player_map[u] = link_unit end
            end
        end

        if get_weapon_owner_type(item_unit_3p) == "ui" then
            if item_unit_3p then table.insert(transonic_preview_units, item_unit_3p) end
            if attachment_units_3p and attachment_units_3p[item_unit_3p] then
                for _, u in ipairs(attachment_units_3p[item_unit_3p]) do 
                    table.insert(transonic_preview_units, u) 
                end
            end
        end
    end
    
    return item_unit_3p, attachment_units_3p, bind_pose, attachment_id_lookup, attachment_name_lookup, attachment_units_bind_poses, item_name_by_unit
end)

mod:hook(VisualLoadoutCustomization, "spawn_base_unit", function(func, item_data, attach_settings, link_unit, ...)
    local item_unit_3p = func(item_data, attach_settings, link_unit, ...)
    if item_data and item_data.name and string.find(item_data.name, "transonic") then
        if link_unit then unit_to_player_map[item_unit_3p] = link_unit end
    end
    return item_unit_3p
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "init", function(self) tracked_weapon_effects[self] = true end)
mod:hook_safe(CLASS.TransonicWeaponEffects, "destroy", function(self) 
    tracked_weapon_effects[self] = nil 
    effect_owner_cache[self] = nil -- Free memory when weapon is destroyed
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "update", function(self, unit, dt, t) 
    if not tracked_weapon_effects[self] then tracked_weapon_effects[self] = true end 
    update_blade_color(self, t, false)
end)

mod:hook_safe(CLASS.ActionUnwield, "start", function(self)
    if self._is_local_unit then mod._is_unwielding = true end
end)
mod:hook_safe(CLASS.ActionUnwield, "finish", function(self)
    if self._is_local_unit then mod._is_unwielding = false end
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "wield", function(self)
    if is_effect_local_player(self) then
        mod._last_known_special_active = self._inventory_slot_component.special_active
    end
    update_blade_color(self, 0, true)
end)

mod:hook_safe(CLASS.TransonicWeaponEffects, "_toggle_direction", function(self, toggle_direction)
    if is_effect_local_player(self) and not mod._is_unwielding then
        mod._last_known_special_active = toggle_direction
    end
    update_blade_color(self, 0, true)
end)

local function get_locally_wielded_units()
    local wielded = {}
    for effect_instance in pairs(tracked_weapon_effects) do
        if is_effect_local_player(effect_instance) then
            local vars_1p = effect_instance._weapon_material_variables_1p
            local vars_3p = effect_instance._weapon_material_variables_3p
            if vars_1p then
                for i = 1, #vars_1p do
                    local u = vars_1p[i].unit
                    if u then wielded[u] = true end
                end
            end
            if vars_3p then
                for i = 1, #vars_3p do
                    local u = vars_3p[i].unit
                    if u then wielded[u] = true end
                end
            end
        end
    end
    return wielded
end

-- The holy grail loop: runs every frame, overrides the engine, integrates with visible_equipment
mod.update = function(dt)
    local t = Managers.time and Managers.time:time("main") or 0
    local current_color, is_rgb_active = get_inventory_color(t)

    local locally_wielded = get_locally_wielded_units()

    -- 1. Update UI Preview Dummies
    if #transonic_preview_units > 0 then
        preview_t = preview_t + dt
        
        local ui_color, ui_is_rgb = nil, false
        if settings_cache.inventory_enabled then
            ui_color, ui_is_rgb = get_inventory_color(preview_t)
        end
        
        for i = #transonic_preview_units, 1, -1 do
            local unit = transonic_preview_units[i]
            if unit and Unit.alive(unit) then
                if get_weapon_owner_type(unit) ~= "ui" or locally_wielded[unit] then
                    table.remove(transonic_preview_units, i)
                elseif ui_color then 
                    apply_color_to_ve_unit(unit, ui_color, ui_is_rgb)
                end
            else
                table.remove(transonic_preview_units, i)
            end
        end
    end

    -- 2. Visible Equipment Compatibility
    if settings_cache.ve_glow_enabled then
        local ve_mod = get_mod("visible_equipment")
        if ve_mod then
            local pt = ve_mod.pt and ve_mod:pt()
            if pt and pt.item_units_by_equipment_component then
                for eq_comp, slots in pairs(pt.item_units_by_equipment_component) do
                    local primary_unit = slots["slot_primary"]
                    if primary_unit and Unit.alive(primary_unit) then
                        
                        local owner = get_weapon_owner_type(primary_unit)
                        local should_glow = false
                        
                        if owner == "local" or owner == "ui" then
                            should_glow = true
                        elseif owner == "teammate" then
                            should_glow = settings_cache.apply_others
                        end
                        
                        if should_glow and current_color then
                            if not locally_wielded[primary_unit] then
                                apply_color_to_ve_unit(primary_unit, current_color, is_rgb_active)
                            end
                            
                            local attachments = pt.attachment_units_by_equipment_component[eq_comp]
                            if attachments and attachments["slot_primary"] and attachments["slot_primary"][primary_unit] then
                                for _, att in ipairs(attachments["slot_primary"][primary_unit]) do
                                    if not locally_wielded[att] then
                                        apply_color_to_ve_unit(att, current_color, is_rgb_active)
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- 3. Chordclaw Ability Dynamic Sync (Highly Optimized)
    if settings_cache.chordclaw_glow_enabled and current_color then
        local current_player_unit = get_safe_local_player_unit()

        if current_player_unit ~= mod._cached_player_unit then
            mod._cached_player_unit = current_player_unit
            if current_player_unit then
                mod._cached_visual_ext = ScriptUnit.has_extension(current_player_unit, "visual_loadout_system") and ScriptUnit.extension(current_player_unit, "visual_loadout_system")
            else
                mod._cached_visual_ext = nil
            end
            mod._force_cc_update = true
        end

        if mod._cached_visual_ext and mod._cached_visual_ext._equipment then
            local claw_slot = mod._cached_visual_ext._equipment["slot_combat_ability"]
            if claw_slot then
                
                if is_rgb_active or mod._force_cc_update or mod._last_cc_stance ~= mod._last_known_special_active then
                    mod._last_cc_stance = mod._last_known_special_active
                    mod._force_cc_update = false

                    local function apply_to_unit(u)
                        if u and Unit.alive(u) then
                            for j = 1, #CLAW_MATERIAL_CANDIDATES do
                                pcall(Unit.set_vector3_for_materials, u, CLAW_MATERIAL_CANDIDATES[j], current_color, true)
                            end
                        end
                    end

                    apply_to_unit(claw_slot.unit_1p)
                    apply_to_unit(claw_slot.unit_3p)
                end
            end
        end
    end
end

mod.on_setting_changed = function(setting_id)
    update_settings_cache()
    
    for k in pairs(ve_state_cache) do
        ve_state_cache[k] = nil
    end
    
    mod._force_cc_update = true
    for effect_instance, _ in pairs(tracked_weapon_effects) do
        update_blade_color(effect_instance, 0, true)
    end
    
    if setting_id == "ve_glow_enabled" and settings_cache.ve_glow_enabled then
        if not get_mod("visible_equipment") then
            mod:echo(mod:localize("ve_not_installed_warning"))
        end
    end
end