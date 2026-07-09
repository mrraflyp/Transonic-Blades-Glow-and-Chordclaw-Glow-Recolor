return {
    mod_name        = { en = "Transonic Stance Colors" },
    mod_description = { en = "Customize the glow color of the Transonic Blades based on your current stance, or enable automatic RGB cycling. Optionally shows the glow in inventory and preview screens." },

    -- General
    apply_to_others             = { en = "Apply to Teammates" },
    apply_to_others_description = { en = "If enabled, changes the blade color for other players in your lobby. If disabled, only your weapon is affected." },

    -- Inventory Preview
    inventory_glow_enabled             = { en = "Show Glow in Inventory" },
    inventory_glow_enabled_description = { en = "When enabled, the inventory blade glow will automatically mirror your last used in-game stance (including RGB mode)." },

    -- Chordclaw Ability
    chordclaw_glow_enabled             = { en = "Apply to Chordclaw Ability" },
    chordclaw_glow_enabled_description = { en = "Applies your current Transonic Blade stance color to the Cryptic's Chordclaw ability. Dynamically mirrors your last used stance." },

    -- Visible Equipment
    ve_glow_enabled             = { en = "Enable Visible Equipment Glow" },
    ve_glow_enabled_description = { en = "Makes the sheathed blade glow on your back. Requires the 'Visible Equipment' mod to be installed." },
    ve_not_installed_warning    = { en = "Visible Equipment mod not detected! Please install it to use this feature." },

    -- RGB Rainbow Mode
    group_rgb_cycle               = { en = "RGB Rainbow Mode Settings" },
    rgb_cycle_target              = { en = "RGB Rainbow Mode" },
    rgb_cycle_target_description  = { en = "Choose which stance should use RGB cycling." },
    rgb_cycle_speed               = { en = "RGB Cycle Speed" },
    rgb_cycle_speed_description   = { en = "Set to 0 to use Slow Motion speed instead." },
    rgb_cycle_slow                = { en = "Slow Motion Speed" },
    rgb_cycle_slow_description    = { en = "Only used when RGB Cycle Speed is 0." },
    rgb_cycle_intensity           = { en = "RGB Glow Intensity" },

    -- Stance 1
    group_stance_1            = { en = "Stance 1: Crowd Clear Color Settings" },
    stance_1_r                = { en = "Red (0-255)" },
    stance_1_g                = { en = "Green (0-255)" },
    stance_1_b                = { en = "Blue (0-255)" },
    stance_1_intensity        = { en = "Glow Intensity" },

    -- Stance 2
    group_stance_2            = { en = "Stance 2: Single Target Color Settings" },
    stance_2_r                = { en = "Red (0-255)" },
    stance_2_g                = { en = "Green (0-255)" },
    stance_2_b                = { en = "Blue (0-255)" },
    stance_2_intensity        = { en = "Glow Intensity" },
}