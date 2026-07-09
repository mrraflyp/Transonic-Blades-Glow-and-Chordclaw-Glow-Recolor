return {
  mod_name = { en = "Transonic Stance Colors" },
  mod_description = { en = "Customize the glow color of the Transonic Blades based on your current stance, or enable automatic RGB cycling." },

  -- General Settings
  apply_to_others = { en = "Apply to Teammates" },
  apply_to_others_description = { en = "If enabled, changes the blade color for other players in your lobby. If disabled, only your weapon is affected." },
  
  -- RGB Rainbow Mode
  group_rgb_cycle = { en = "RGB Rainbow Mode Settings" },
  rgb_cycle_target = { en = "RGB Rainbow Mode" },
  rgb_cycle_target_description = { en = "Choose which stance should use RGB cycling."},
  rgb_cycle_speed = { en = "RGB Cycle Speed" },
  rgb_cycle_speed_description = { en = "Set to 0 to use Slow Motion."},
  rgb_cycle_slow = { en = "Slow Motion Speed" },
  rgb_cycle_slow_description = { en = "Only used when RGB Cycle Speed is 0."},
  rgb_cycle_intensity = { en = "RGB Glow Intensity" },

  -- Stance 1 (Crowd Clear)
  group_stance_1 = { en = "Stance 1: Crowd Clear Color Settings" },
  stance_1_r = { en = "Red (0-255)" },
  stance_1_g = { en = "Green (0-255)" },
  stance_1_b = { en = "Blue (0-255)" },
  stance_1_intensity = { en = "Glow Intensity" },
  
  -- Stance 2 (Single Target)
  group_stance_2 = { en = "Stance 2: Single Target Color Settings" },
  stance_2_r = { en = "Red (0-255)" },
  stance_2_g = { en = "Green (0-255)" },
  stance_2_b = { en = "Blue (0-255)" },
  stance_2_intensity = { en = "Glow Intensity" },
}