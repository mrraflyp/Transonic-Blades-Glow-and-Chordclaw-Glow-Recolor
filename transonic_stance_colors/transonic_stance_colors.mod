return {
	run = function()
		fassert(rawget(_G, "new_mod"), "`transonic_stance_colors` encountered an error loading the Darktide Mod Framework.")

		new_mod("transonic_stance_colors", {
			mod_script       = "transonic_stance_colors/scripts/mods/transonic_stance_colors/transonic_stance_colors",
			mod_data         = "transonic_stance_colors/scripts/mods/transonic_stance_colors/transonic_stance_colors_data",
			mod_localization = "transonic_stance_colors/scripts/mods/transonic_stance_colors/transonic_stance_colors_localization",
		})
	end,
	packages = {},
}