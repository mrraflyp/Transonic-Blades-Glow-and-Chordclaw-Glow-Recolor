local mod = get_mod("transonic_stance_colors")

return {
    name = mod:localize("mod_name"),
    description = mod:localize("mod_description"),
    is_togglable = true,
    options = {
        widgets = {
            {
                setting_id    = "apply_to_others",
                type          = "checkbox",
                default_value = false,
            },

            -- ── Inventory Preview ──────────────────────────────────────────
            {
                setting_id    = "inventory_glow_enabled",
                type          = "checkbox",
                default_value = false,
            },

            -- ── Visible Equipment Integration ──────────────────────────────
            {
                setting_id    = "ve_glow_enabled",
                type          = "checkbox",
                default_value = true,
            },

            -- ── Chordclaw Ability ──────────────────────────────────────────
            {
                setting_id    = "chordclaw_mode",
                type          = "dropdown",
                default_value = "both",
                options = {
                    { text = "Disabled (Vanilla)",        value = "disabled" },
                    { text = "Follow Active Stance",      value = "both" },
                    { text = "Follow Stance 1 Only",      value = "stance_1" },
                    { text = "Follow Stance 2 Only",      value = "stance_2" },
                    { text = "Independent Static Color",  value = "static" },
                    { text = "Independent RGB Cycle",     value = "rgb" },
                },
            },
            {
                setting_id = "group_chordclaw_static",
                type = "group",
                sub_widgets = {
                    { setting_id = "cc_r",         type = "numeric", default_value = 128, range = {0, 255} },
                    { setting_id = "cc_g",         type = "numeric", default_value = 0,   range = {0, 255} },
                    { setting_id = "cc_b",         type = "numeric", default_value = 255, range = {0, 255} },
                    { setting_id = "cc_intensity", type = "numeric", default_value = 2.0, range = {0.1, 100.0} },
                },
            },
            {
                setting_id = "group_chordclaw_rgb",
                type = "group",
                sub_widgets = {
                    { setting_id = "cc_rgb_speed",     type = "numeric", default_value = 1.0,  range = {0, 100.0} },
                    { setting_id = "cc_rgb_slow",      type = "numeric", default_value = 0.01, range = {0.01, 1.0}, decimals_number = 2 },
                    { setting_id = "cc_rgb_intensity", type = "numeric", default_value = 2.0,  range = {0.1, 100.0} },
                },
            },

            -- ── RGB Rainbow Mode (Blades) ──────────────────────────────────
            {
                setting_id    = "rgb_cycle_target",
                type          = "dropdown",
                default_value = "disabled",
                options = {
                    { text = "Disabled",       value = "disabled" },
                    { text = "Stance 1 Only",  value = "stance_1" },
                    { text = "Stance 2 Only",  value = "stance_2" },
                    { text = "Both Stances",   value = "both" },
                },
            },
            {
                setting_id = "group_rgb_cycle",
                type = "group",
                sub_widgets = {
                    { setting_id = "rgb_cycle_speed",     type = "numeric", default_value = 1,    range = {0, 100.0} },
                    { setting_id = "rgb_cycle_slow",      type = "numeric", default_value = 0.01, range = {0.01, 1.0}, decimals_number = 2 },
                    { setting_id = "rgb_cycle_intensity", type = "numeric", default_value = 2.0,  range = {0.1, 100.0} },
                },
            },

            -- ── Stance 1 ──────────────────────────────────────────────────
            {
                setting_id = "group_stance_1",
                type = "group",
                sub_widgets = {
                    { setting_id = "stance_1_r",         type = "numeric", default_value = 0,   range = {0, 255} },
                    { setting_id = "stance_1_g",         type = "numeric", default_value = 128, range = {0, 255} },
                    { setting_id = "stance_1_b",         type = "numeric", default_value = 255, range = {0, 255} },
                    { setting_id = "stance_1_intensity", type = "numeric", default_value = 2.0, range = {0.1, 100.0} },
                },
            },

            -- ── Stance 2 ──────────────────────────────────────────────────
            {
                setting_id = "group_stance_2",
                type = "group",
                sub_widgets = {
                    { setting_id = "stance_2_r",         type = "numeric", default_value = 255, range = {0, 255} },
                    { setting_id = "stance_2_g",         type = "numeric", default_value = 0,   range = {0, 255} },
                    { setting_id = "stance_2_b",         type = "numeric", default_value = 0,   range = {0, 255} },
                    { setting_id = "stance_2_intensity", type = "numeric", default_value = 2.0, range = {0.1, 100.0} },
                },
            },
        },
    },
}