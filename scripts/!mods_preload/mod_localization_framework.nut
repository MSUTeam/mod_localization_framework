::Localization <- {
	Version = "1.0.0",
	ModID = "mod_localization_framework",
	Name = "Localization Framework"
};

::mods_registerMod(::Localization.ModID, ::Localization.Version, ::Localization.Name);

::mods_queue(::Localization.ModID, "mod_msu", function() {
	::Localization.Mod <- ::MSU.Class.Mod(::Localization.ModID, ::Localization.Version, ::Localization.Name);

	foreach (script in ::IO.enumerateFiles("mod_localization_framework/hooks"))
	{
		::include(script);
	}

	::Localization.Language <- {
		English = 0,
		German = 1,
		Russian = 2,
		French = 3,
		Chinese = 4,
		Spanish = 5,
		Polish = 6
	};

	::Localization.Loc <- {};

	local page = ::Localization.Mod.ModSettings.addPage("General");
	::Localization.LanguageSetting <- page.addEnumSetting("language", "English", ::MSU.Table.keys(::Localization.Language), "Language", "Set language. Only works with mods that use the localization framework. Requires re-loading a saved game after changing this setting.");
	::Localization.LanguageSetting.addCallback(function( _newValue ) {
		::Localization.LanguageSetting.set(_newValue, false, false, false);
		foreach (perk in ::Const.Perks.LookupMap)
		{
			perk.Name = ::Localization.getLoc(perk.Script + ".Name");
			perk.Tooltip = ::Localization.getLoc(perk.Script + ".Tooltip");
		}
		if (("State" in this.World) && this.World.State != null)
		{
			foreach (bro in ::World.getPlayerRoster().getAll())
			{
				local skills = bro.getSkills().m.Skills;
				skills.extend(bro.getSkills().m.SkillsToAdd);
				foreach (skill in skills)
				{
					if (skill.getID() != "")
					{
						local fileName = ::IO.scriptFilenameByHash(skill.ClassNameHash);
						skill.m.Name = ::Localization.getLoc(fileName + ".m.Name");
						skill.m.Description = ::Localization.getLoc(fileName + ".m.Description");
					}
				}
			}
		}
	});

	::Localization.getLoc <- function( _key, _vars = null )
	{
		if (_key.find("/") == null)
		{
			local dotIdx = _key.find(".");
			local fileName = _key.slice(0, dotIdx);

			if (fileName in this.ScriptFilenameMap)
			{
				fileName = this.ScriptFilenameMap[fileName];
				_key = fileName + _key.slice(dotIdx);
			}
		}

		local language = ::Localization.Language[::Localization.LanguageSetting.getValue()];	
		if (::Localization.Loc[_key].len() <= language) language = ::Localization.Language.English;

		local text = ::Localization.Loc[_key][language];

		if (text == "") text = ::Localization.Loc[_key][::Localization.Language.English];

		return _vars == null ? text : this.buildTextFromTemplate(text, _vars);
	}

	::Localization.locsToAdd <- [];

	::Localization.addLoc <- function( _language, _key, _text )
	{
		this.locsToAdd.push([
			_language,
			_key,
			_text
		]);
	}

	::Localization.addLocCore <- function( _language, _key, _text )
	{
		if (_key.find("/") == null)
		{
			local dotIdx = _key.find(".");
			local fileName = _key.slice(0, dotIdx);

			if (fileName in this.ScriptFilenameMap)
			{
				fileName = this.ScriptFilenameMap[fileName];
				_key = fileName + _key.slice(dotIdx);
			}
		}

		if (!(_key in ::Localization.Loc)) ::Localization.Loc[_key] <- array(_language, "");

		while(::Localization.Loc[_key].len() <= _language)
		{
			::Localization.Loc[_key].push("");
		}

		if (_key.find("scripts/skills/skill") != null)
		{
			::logInfo("Adding localization key " + _key + " for language " + _language + " with text: " + _text);
		}

		::Localization.Loc[_key][_language] = _text;
	}

	::Localization.addLocs <- function( _language, _table )
	{
		foreach (key, text in _table)
		{
			this.addLoc(_language, key, text);
		}
	}

	::Localization.addLanguage <- function( _name )
	{
		if (_name in ::Localization.Language) throw ::MSU.Exception.DuplicateKey(_name);		
		::Localization.Language[_name] <- ::Localization.Language.len();
		::Localization.LanguageSetting.Array.push(_name);
	}

	::Localization.printKeys <- function()
	{
		local keys = ::MSU.Table.keys(this.Loc);
		keys.sort();

		foreach (key in keys)
		{
			::logInfo(key);
		}
	}

	::Localization.ScriptFilenameMap <- {};

	::Localization.IsDone <- false;

	foreach (script in ::IO.enumerateFiles("mod_localization_framework/localization"))
	{
		::include(script);
	}

	local getFileName = function( _string )
	{
		for (local i = _string.len() - 1; i > 0; i--)
		{
			if (_string.slice(i, i + 1) == "/")
			{
				return _string.slice(i + 1);
			}
		}
	}

	foreach (script in ::IO.enumerateFiles("scripts"))
	{
		local fileName = getFileName(script);
		if (!(fileName in ::Localization.ScriptFilenameMap)) ::Localization.ScriptFilenameMap[fileName] <- script;
	}

	::mods_addHook("root_state.onInit", function(r) {
		foreach (script in ::IO.enumerateFiles("scripts/skills"))
		{
			if (script == "scripts/skills/skill" || script == "scripts/skills/skill_container") continue;

			local skill = ::new(script);
			if (skill == null || skill.len() == 0)
			{
				::logError("Script file \'" + script + "\' does not instantiate correctly");
				continue;
			}

			local id = skill.getID();
			if (id != "")
			{
				::Localization.addLoc(::Localization.Language.English, script + ".m.Name", skill.m.Name);
				::Localization.addLoc(::Localization.Language.English, script + ".m.Description", skill.m.Description);
			}
		}

		foreach (script in ::IO.enumerateFiles("scripts/events/events"))
		{
			local event = ::new(script);
			if (event == null || event.len() == 0)
			{
				::logError("Script file \'" + script + "\' does not instantiate correctly");
				continue;
			}

			local id = event.getID();
			if (id != "")
			{
				::Localization.addLoc(::Localization.Language.English, script + ".m.Title", event.m.Title);
				foreach (screen in event.m.Screens)
				{
					::Localization.addLoc(::Localization.Language.English, script + ".m.Screens." + screen.ID + "." + "Text", screen.Text);
					foreach (i, option in screen.Options)
					{
						::Localization.addLoc(::Localization.Language.English, script + ".m.Screens." + screen.ID + "." + "Options" + "." + i, option.Text);
					}
				}
			}
		}

		foreach (perk in ::Const.Perks.LookupMap)
		{
			::Localization.addLoc(::Localization.Language.English, perk.Script + ".Name", perk.Name);
			::Localization.addLoc(::Localization.Language.English, perk.Script + ".Tooltip", perk.Tooltip);
		}

		foreach (loc in ::Localization.locsToAdd)
		{
			::Localization.addLocCore(loc[0], loc[1], loc[2]);
		}

		foreach (perk in ::Const.Perks.LookupMap)
		{
			perk.Name = ::Localization.getLoc(perk.Script + ".Name");
			perk.Tooltip = ::Localization.getLoc(perk.Script + ".Tooltip");
		}

		delete ::Localization.locsToAdd;

		::Localization.IsDone = true;
		// ::Localization.printKeys();
	});

	foreach (script in ::IO.enumerateFiles("scripts/events/events"))
	{
		::mods_hookExactClass(script.slice(8), function(o) {
			if ("create" in o)
			{
				local create = o.create;
				o.create = function()
				{
					create();
					if (::Localization.IsDone && this.getID() != "")
					{
						local script = ::IO.scriptFilenameByHash(this.ClassNameHash);
						this.m.Title = ::Localization.getLoc(script + ".m.Title");
						foreach (screen in this.m.Screens)
						{
							screen.Text = ::Localization.getLoc(script + ".m.Screens." + screen.ID + "." + "Text");
							foreach (i, option in screen.Options)
							{
								option.Text = ::Localization.getLoc(script + ".m.Screens." + screen.ID + "." + "Options" + "." + i);
							}
						}
					}
				}
			}
		});
	}

	foreach (script in ::IO.enumerateFiles("scripts/skills"))
	{
		::mods_hookExactClass(script.slice(8), function(o) {
			if ("create" in o)
			{
				local create = o.create;
				o.create = function()
				{
					create();
					if (::Localization.IsDone && this.getID() != "")
					{
						local script = ::IO.scriptFilenameByHash(this.ClassNameHash);
						this.m.Name = ::Localization.getLoc(script + ".m.Name");
						this.m.Description = ::Localization.getLoc(script + ".m.Description");
					}
				}
			}
		});
	}

	// ---------------------- Testing Start ----------------------

	::Localization.addLoc(::Localization.Language.German, "strong_trait.m.Name", "German Strong");

	::Localization.addLocs(::Localization.Language.German, {
		"skill.getDefaultTooltip.DamageDirect": "Verursacht [color=" + ::Const.UI.Color.DamageValue + "]%damage_direct_min%[/color] - [color=" + ::Const.UI.Color.DamageValue + "]%damage_direct_max%[/color] Schaden, der Rüstung ignoriert",
		"skill.getDefaultTooltip.DamageRegularAndDirect": "Verursacht [color=" + ::Const.UI.Color.DamageValue + "]%damage_regular_min%[/color] - [color=" + ::Const.UI.Color.DamageValue + "]%damage_regular_max%[/color] Schaden an Lebenspunkten, von denen [color=" + ::Const.UI.Color.DamageValue + "]%damage_direct_min%[/color] - [color=" + ::Const.UI.Color.DamageValue + "]%damage_direct_max%[/color] die Rüstung ignorieren können",
		"skill.getDefaultTooltip.DamageRegular": "Verursacht [color=" + ::Const.UI.Color.DamageValue + "]%damage_regular_min%[/color] - [color=" + ::Const.UI.Color.DamageValue + "]%damage_regular_max%[/color] Schaden an Lebenspunkten",
		"skill.getDefaultTooltip.DamageArmor": "Verursacht [color=" + ::Const.UI.Color.DamageValue + "]%damage_armor_min%[/color] - [color=" + ::Const.UI.Color.DamageValue + "]%damage_armor_max%[/color] Schaden an der Rüstung",
		"skill.getDefaultTooltip.OathOfHonor": "[color=" + ::Const.UI.Color.NegativeValue + "]Kann nicht verwendet werden, da dieser Charakter einen Eid geleistet hat, der die Verwendung von Fernkampfwaffen oder -werkzeugen ausschließt[/color]",

		"skill.getCostString": "[i]Kostet [b][color=%color_AP%]%AP_cost% AP[/color][/b] zu verwenden und baut [b][color=%color_fatigue%]%fatigue_cost% Müdigkeit[/color][/b][/i]\n"

		"slash.m.Name": "Hau",
		"slash.m.Description": "Ein schneller Hiebangriff, der durchschnittlichen Schaden verursacht.",
		"slash.m.KilledString": "Cut down",
		"slash.getTooltip.HitChance": "Hat [color=" + ::Const.UI.Color.PositiveValue + "]+%hitchance%%[/color] Chance zu treffen",

		"perk_mastery_sword.Name": "German Sword Mastery"
	});

	::mods_hookExactClass("skills/actives/slash", function(o) {
		o.getTooltip = function()
		{
			local ret = this.getDefaultTooltip();
			ret.push({
				id = 6,
				type = "text",
				icon = "ui/icons/hitchance.png",
				text = ::Localization.getLoc("scripts/skills/actives/slash.getTooltip.HitChance", [
						[
							"hitchance",
							10
						]
					])
			});
			return ret;
		}
	});

	::mods_hookBaseClass("skills/skill", function(o) {
		o = o[o.SuperName];
		o.getCostString = function()
		{
			return ::Localization.getLoc("skill.getCostString", [
					[
						"color_AP",
						this.isAffordableBasedOnAPPreview() ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue,
					],
					[
						"AP_cost",
						this.getActionPointCost(), 
					],
					[
						"color_fatigue",
						this.isAffordableBasedOnFatiguePreview() ? ::Const.UI.Color.PositiveValue : ::Const.UI.Color.NegativeValue, 
					],
					[
						"fatigue_cost",
						this.getFatigueCost()
					],
				]);
		}

		local getDefaultTooltip = o.getDefaultTooltip;
		o.getDefaultTooltip = function()
		{
			local ret = getDefaultTooltip();
			foreach (entry in ret)
			{
				if (entry.id >= 4)
				{
					local matches = [];
					local startIndex = 0;
					while (true)
					{
						local capture = regexp("]\\d+").capture(entry.text, startIndex);
						if (capture == null) break;

						matches.push(::MSU.regexMatch(capture, entry.text, 0).slice(1));
						startIndex = capture[0].end;
					}

					if (matches.len() != 0)
					{
						if (entry.text.find("that ignores armor") != null)
						{
							entry.text = ::Localization.getLoc("skill.getDefaultTooltip.DamageDirect", [
								[
									"damage_direct_min",
									matches[0]
								],
								[
									"damage_direct_max",
									matches[1]
								]
							]);
						}
						else if (entry.text.find("can ignore armor") != null)
						{
							entry.text = ::Localization.getLoc("skill.getDefaultTooltip.DamageRegularAndDirect", [
								[
									"damage_regular_min",
									matches[0]
								],
								[
									"damage_regular_max",
									matches[1]
								],
								[
									"damage_direct_min",
									matches[2]
								],
								[
									"damage_direct_max",
									matches[3]
								]
							]);
						}
						else if (entry.text.find("to hitpoints[/color]") != null)
						{
							entry.text = ::Localization.getLoc("skill.getDefaultTooltip.DamageRegular", [
								[
									"damage_regular_min",
									matches[0]
								],
								[
									"damage_regular_max",
									matches[1]
								]
							]);
						}
						else if (entry.text.find("to armor") != null)
						{
							entry.text = ::Localization.getLoc("skill.getDefaultTooltip.DamageArmor", [
								[
									"damage_armor_min",
									matches[0]
								],
								[
									"damage_armor_max",
									matches[1]
								]
							]);
						}
					}
					else
					{
						if (entry.text.find("oath") != null)
						{
							entry.text = ::Localization.getLoc("skill.getDefaultTooltip.OathOfHonor");
						}
					}
				}
			}
			return ret;
		}
	});	

	// ---------------------- Testing End ----------------------
});
