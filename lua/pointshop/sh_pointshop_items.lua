--[[
Config file for the shop.

!!!!!!!!!!!!!HEAD DOWN to the Item Catalog section to edit the buyable items.

	Format:
		PS.Items = {
			buyable_class = {
				Name      = "Display Name",       -- optional, defaults to buyable_class
				BasePrice = 1000,                 -- cost in points
				Type      = "entity"/"weapon"/"bonus",
				BonusType = "Survivability"/"Offensive"/"Special", -- only used when Type = "bonus"; defaults to "Survivability" if omitted
				EntityCategory = "Base"/"Bombs",  -- only used when Type = "entity"; defaults to "Base" if omitted
				Icon      = "icon16/something.png", -- optional, shown on the shop button
				Description = "text here",       -- optional, shown as a tooltip
			},
			...
		}

	Type determines both which tab the item appears under and what happens when it's purchased.
		"entity" -> spawned in front of the player
		"weapon" -> given directly to the player
		"bonus"  -> applied via player:ApplyPassive(buyable_class)

	BonusType (bonus items only) determines which of the 3 side-by-side categories a passive appears under on the Bonuses tab.
	A player may only have one active passive per BonusType at a time.

	EntityCategory (entity items only) determines which of the 2 side-by-side columns an entity appears under on the Entities tab.
]]

PS = PS or {}
PS.Items = PS.Items or {}

PS.ITEM_TYPE_ENTITY = "entity"
PS.ITEM_TYPE_WEAPON = "weapon"
PS.ITEM_TYPE_BONUS  = "bonus"

local VALID_TYPES = {
	[PS.ITEM_TYPE_ENTITY] = true,
	[PS.ITEM_TYPE_WEAPON] = true,
	[PS.ITEM_TYPE_BONUS]  = true,
}

function PS.IsValidItemType(t)
	return VALID_TYPES[t] == true
end

PS.Config = PS.Config or {}

PS.BONUS_TYPE_SURVIVABILITY = "Survivability"
PS.BONUS_TYPE_OFFENSIVE     = "Offensive"
PS.BONUS_TYPE_SPECIAL       = "Special"

PS.BONUS_TYPE_DEFAULT = PS.BONUS_TYPE_SURVIVABILITY

PS.BONUS_TYPE_ORDER = {
	PS.BONUS_TYPE_SURVIVABILITY,
	PS.BONUS_TYPE_OFFENSIVE,
	PS.BONUS_TYPE_SPECIAL,
}

local VALID_BONUS_TYPES = {
	[PS.BONUS_TYPE_SURVIVABILITY] = true,
	[PS.BONUS_TYPE_OFFENSIVE]     = true,
	[PS.BONUS_TYPE_SPECIAL]       = true,
}

function PS.IsValidBonusType(t)
	return VALID_BONUS_TYPES[t] == true
end

function PS.GetItemBonusType(item)
	if item and PS.IsValidBonusType(item.BonusType) then
		return item.BonusType
	end
	return PS.BONUS_TYPE_DEFAULT
end

PS.ENTITY_CATEGORY_BASE = "Base"
PS.ENTITY_CATEGORY_BOMB = "Bombs"

PS.ENTITY_CATEGORY_DEFAULT = PS.ENTITY_CATEGORY_BASE

PS.ENTITY_CATEGORY_ORDER = {
	PS.ENTITY_CATEGORY_BASE,
	PS.ENTITY_CATEGORY_BOMB,
}

local VALID_ENTITY_CATEGORIES = {
	[PS.ENTITY_CATEGORY_BASE] = true,
	[PS.ENTITY_CATEGORY_BOMB] = true,
}

function PS.IsValidEntityCategory(t)
	return VALID_ENTITY_CATEGORIES[t] == true
end

function PS.GetItemEntityCategory(item)
	if item and PS.IsValidEntityCategory(item.EntityCategory) then
		return item.EntityCategory
	end
	return PS.ENTITY_CATEGORY_DEFAULT
end

------------------------------------------------- Item Catalog -------------------------------------------------

PS.Items = {

	---------------- Entities ----------------
	["sci_pointshop_base_beacon"] = {
		Name = "Beacon",
		BasePrice = 1250,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_beacon.png",
		Description = "Grants positive status effects to players in proximity. Players must be manually whitelisted to be considered friendly. Can be customized. Requires 125 power in order to run.",
	},
	["sci_pointshop_emplacement_cannon_chassis"] = {
		Name = "Cannon",
		BasePrice = 250,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_emplacement_cannon_chassis.png",
		Description = "A basic cannon that can fire some GBombs entities with moderate force. Loaded from the front. Interact with the handles to take control and aim. Alternate propellant force with mouse 2.",
	},
	["sci_pointshop_emplacement_howitzer_chassis"] = {
		Name = "Howitzer",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_emplacement_howitzer_chassis.png",
		Description = "An advanced artillery gun that can fire most GBombs entities at respectable distances. Loaded from the back. Interact with the right side handwheel to take control and aim. Alternate propellant force with mouse 2.",
	},
	["sci_pointshop_fuelgenerator"] = {
		Name = "Fuel Generator",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_fuelgenerator.png",
		Description = "Provides 250 power for your machines while active. Requires fuel in order to run. Can be placed anywhere.",
	},
	["sci_pointshop_fuel"] = {
		Name = "Fuel Can",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_fuel.png",
		Description = "Provides 10 minutes of fuel for the Fuel Generator.",
	},
	["sci_pointshop_power_turbine"] = {
		Name = "Wind Turbine",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_power_turbine.png",
		Description = "Provides 200 power for your machines while active. Must be unobstructed in order to run.",
	},
	["sci_pointshop_power_rtg"] = {
		Name = "Radioisotope Generator",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_power_rtg.png",
		Description = "Provides 125 power for your machines while active. Can be placed anywhere.",
	},
	["sci_pointshop_base_ewr_interceptor"] = {
		Name = "Interceptor",
		BasePrice = 1250,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_ewr_interceptor.png",
		Description = "Motion based SAM platform that intercepts players and incoming GBombs munitions. Can retain up to 4 targets at once. Players must be manually whitelisted to be considered friendly. Must be placed outside. Requires 200 power in order to run.",
	},
	["sci_pointshop_base_ewr_sentinel"] = {
		Name = "Sentinel",
		BasePrice = 800,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_ewr_sentinel.png",
		Description = "Motion based AAA platform that intercepts players and incoming GBombs munitions. Players must be manually whitelisted to be considered friendly. Must be placed outside. Requires 125 power in order to run.",
	},
	["lvs_vehicle_air_refil"] = {
		Name = "Ammo Refill Balloon",
		BasePrice = 250,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/lvs_vehicle_air_refil.png",
		Description = "Spawn a floating hot air balloon that refills your LVS vehicle's ammo when nearby.",
	},
	["sci_pointshop_base_ewr_screen"] = {
		Name = "EWR Screen",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_ewr_screen.png",
		Description = "Detects spawned munitions and displays their location in world coordinates. Requires 50 power in order to run.",
	},
	["sci_pointshop_base_mainframe"] = {
		Name = "Base Mainframe",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_mainframe.png",
		Description = "The heart of your base. Needed to link power generators and machines.",
	},
	["sci_pointshop_base_radar_screen"] = {
		Name = "Radar Screen",
		BasePrice = 2000,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_radar_screen.png",
		Description = "Displays the location of players relative to it. Players must be manually whitelisted to be considered friendly. Requires 50 power in order to run.",
	},
	["sci_pointshop_base_repair"] = {
		Name = "Auto-Repair Station",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_repair.png",
		Description = "Automatically repairs props and machines in a large radius around it. Requires 200 power in order to run. Does not stack if multiple are placed in the same radius.",
	},
	["sci_pointshop_base_turret"] = {
		Name = "Sentry Turret",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_ENTITY,
		Icon = "entities/sci_pointshop_base_turret.png",
		Description = "Automatically targets hostile players while active. Players must be manually whitelisted to be considered friendly. Requires 100 power in order to run.",
	},
	["sci_pointshop_base_nukedevice"] = {
		Name = "DIY Nuclear Bomb Kit",
		BasePrice = 35000,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/sci_pointshop_base_nukedevice.png",
		Description = "Assembles a random nuclear device over the course of 30 minutes. Requires 500 power in order to run.",
	},
	["gb5_heavy_b_t12"] = {
		Name = "T12 Cloudmaker",
		BasePrice = 5000,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_heavy_b_t12.png",
		Description = "Huge earthquake bomb with massive damage but a moderate blast radius. Meant for cracking the strongest of bases.",
	},
	["gb5_chemical_napalm"] = {
		Name = "Napalm Bomb",
		BasePrice = 650,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_chemical_napalm.png",
		Description = "Napalm bomb that ignites a large area. Will burn players to a crisp.",
	},
	["gb5_heavy_b_1000lb"] = {
		Name = "XMI HEB 1000lb",
		BasePrice = 3500,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_heavy_b_1000lb.png",
		Description = "Large bomb with high damage but a moderate blast radius. Will deal significant damage to bases.",
	},
	["gb5_heavy_b_thermobaric"] = {
		Name = "GXM-11 Thermobaric",
		BasePrice = 1500,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_heavy_b_thermobaric.png",
		Description = "Thermobaric bomb with a large blast radius. Will deal average damage to bases but high anti-personnel damage.",
	},
	["gb5_heavy_cbu"] = {
		Name = "CBU-52U",
		BasePrice = 1500,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_heavy_cbu.png",
		Description = "Free-fall cluster bomb for use against soft-skinned targets, light vehicles, and personnel.",
	},
	["gb5_proj_howitzer_shell_in"] = {
		Name = "Howitzer Shell (Incendiary)",
		BasePrice = 200,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_proj_howitzer_shell_in.png",
		Description = "Incendiary artillery shell, sets players on fire.",
	},
	["gb5_proj_howitzer_shell_cl"] = {
		Name = "Chlorine Shell",
		BasePrice = 300,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_proj_howitzer_shell_cl.png",
		Description = "Chlorine gas artillery shell, leaves a cloud of gas that blinds and damages players inside. Ignores armor.",
	},
	["gb5_nuclear_davycrockett"] = {
		Name = "Davy Crockett",
		BasePrice = 10000,
		Type = PS.ITEM_TYPE_ENTITY,
		EntityCategory = PS.ENTITY_CATEGORY_BOMB,
		Icon = "entities/gb5_nuclear_davycrockett.png",
		Description = "Miniature nuclear artillery shell with a devastating blast.",
	},
	---------------- Weapons ----------------
	["keypad_cracker"] = {
		Name = "Keypad Cracker",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "icon16/key_delete.png",
		Description = "Allows you to hack keypads and open base doors.",
	},
	["m9k_minigun"] = {
		Name = "M134 Minigun",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_minigun.png",
		Description = "Handheld minigun with extremely fast firerate and high ammo capacity. Very heavy.",
	},
	["m9k_usas"] = {
		Name = "USAS",
		BasePrice = 250,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_usas.png",
		Description = "Full auto shotgun with a 20 round drum mag. Has mediocre firerate but a fast reload.",
	},
	["m9k_striker12"] = {
		Name = "Striker 12",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_striker12.png",
		Description = "Full auto shotgun with a 12 round drum mag. Has a fast firerate but a slow reload and high recoil.",
	},
	["m9k_ex41"] = {
		Name = "EX41",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_ex41.png",
		Description = "Pump-action grenade launcher. Has a 3-round tubular magazine.",
	},
	["m9k_m202"] = {
		Name = "M202",
		BasePrice = 1500,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_m202.png",
		Description = "Multishot explosive rocket launcher. Mixed anti-infantry and anti-armor capability.",
	},
	["m9k_matador"] = {
		Name = "Matador",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_matador.png",
		Description = "Single shot rocket launcher specialized for anti-personnel use.",
	},
	["m9k_milkormgl"] = {
		Name = "Milkor Mk1",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_milkormgl.png",
		Description = "Six-shot revolver-type grenade launcher.",
	},
	["m9k_nerve_gas"] = {
		Name = "Nerve Gas",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_nerve_gas.png",
		Description = "Hand thrown capsule that releases a powerful nerve agent upon impact.",
	},
	["m9k_orbital_strike"] = {
		Name = "Orbital Strike Marker",
		BasePrice = 10000,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_orbital_strike.png",
		Description = "Mark a location on the map to be bombed by an orbtal strike system.",
	},
	["m9k_proxy_mine"] = {
		Name = "Proximity Mine",
		BasePrice = 125,
		Type = PS.ITEM_TYPE_WEAPON,
		Icon = "entities/m9k_proxy_mine.png",
		Description = "Can be attached to surfaces. Explodes when a valid target comes into proximity. Can be used as an anti-tank mine.",
	},
	---------------- Bonuses (passive effects) ----------------
	["sci_passive_lifeinsurance"] = {
		Name = "Life Insurance",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_lifeinsurance.png",
		Description = "Negates point loss on death.",
	},
	["sci_passive_luckyfive"] = {
		Name = "Lucky Five",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_luckyfive.png",
		Description = "25% chance to negate point loss on death.",
	},
	["sci_passive_payday"] = {
		Name = "Payday",
		BasePrice = 300,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_payday.png",
		Description = "Point gain increased by 25%.",
	},
	["sci_passive_doubledown"] = {
		Name = "Double Down",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_doubledown.png",
		Description = "Earn 2x points, but lose 2x points on death.",
	},
	["sci_passive_vulnerability"] = {
		Name = "Vulnerability",
		BasePrice = 475,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SPECIAL,
		Icon = "hudicons/sci_passive_vulnerability.png",
		Description = "Debuffs applied on target last twice as long.",
	},
	["sci_passive_extrahealth"] = {
		Name = "Extra Health",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_extrahealth.png",
		Description = "+25 max HP.",
	},
	["sci_passive_regeneration"] = {
		Name = "Regeneration",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_regeneration.png",
		Description = "Passive HP regeneration.",
	},
	["sci_passive_armorregeneration"] = {
		Name = "Armor Regeneration",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_armorregeneration.png",
		Description = "Passive Armor regeneration.",
	},
	["sci_passive_lifesteal"] = {
		Name = "Lifesteal",
		BasePrice = 700,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_lifesteal.png",
		Description = "Dealing bullet damage heals you.",
	},
	["sci_passive_pyromaniac"] = {
		Name = "Pyromaniac",
		BasePrice = 300,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_pyromaniac.png",
		Description = "+90% Fire damage resistance.",
	},
	["sci_passive_blastshield"] = {
		Name = "Blast Shield",
		BasePrice = 425,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_blastshield.png",
		Description = "+50% Explosive damage resistance.",
	},
	["sci_passive_fleetfoot"] = {
		Name = "Fleetfoot",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_fleetfoot.png",
		Description = "Immune to fall damage.",
	},
	["sci_passive_healingbooster"] = {
		Name = "Healing Booster",
		BasePrice = 450,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_healingbooster.png",
		Description = "Healing received is increased by 20%.",
	},
	["sci_passive_unstoppable"] = {
		Name = "Unstoppable",
		BasePrice = 275,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_unstoppable.png",
		Description = "Immune to debuffs.",
	},
	["sci_passive_concussion"] = {
		Name = "Concussion",
		BasePrice = 1000,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_concussion.png",
		Description = "Your explosive weapons apply Concussion to targets.",
	},
	["sci_passive_backstabber"] = {
		Name = "Backstabber",
		BasePrice = 100,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_backstabber.png",
		Description = "Melee attacks from behind deal lethal damage.",
	},
	["sci_passive_flashbang"] = {
		Name = "Flashbang",
		BasePrice = 800,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_flashbang.png",
		Description = "Blast damage blinds targets instead of dealing damage.",
	},
	["sci_passive_bleed"] = {
		Name = "Bleed",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_bleed.png",
		Description = "Small chance to make target bleed when shot.",
	},
	["sci_passive_hollowpoint"] = {
		Name = "Hollow Point",
		BasePrice = 750,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_hollowpoint.png",
		Description = "Your bullets apply a stacking debuff to targets that causes them to take increased damage. +5% per stack.",
	},
	["sci_passive_dartcrossbow"] = {
		Name = "Dart Crossbow",
		BasePrice = 350,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_dartcrossbow.png",
		Description = "Replaces your crossbow bolts with poisonous darts that deal less damage but prevent healing and reduce their outgoing damage.",
	},
	["sci_passive_stealth"] = {
		Name = "Stealth",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_OFFENSIVE,
		Icon = "hudicons/sci_passive_stealth.png",
		Description = "Attacking does not reveal your position on the minimap. Does not work while in vehicles.",
	},
}


--[[
BONUS_TYPE_SURVIVABILITY
BONUS_TYPE_OFFENSIVE
BONUS_TYPE_SPECIAL

Surv: sci_passive_extrahealth, sci_passive_regeneration, sci_passive_extraarmor, sci_passive_armorregeneration, sci_passive_lifesteal, sci_passive_pyromaniac, sci_passive_blastshield, sci_passive_fleetfoot, sci_passive_healingbooster, sci_passive_unstoppable

Off: sci_passive_concussion, sci_passive_backstabber, sci_passive_flashbang, sci_passive_bleed, sci_passive_slowdown, sci_passive_vulnerability, 

Special: sci_passive_lifeinsurance, sci_passive_luckyfive, sci_passive_payday, sci_passive_doubledown,
]]--

-- Helpers

function PS.GetItemDisplayName(buyable_class)
	local item = PS.Items[buyable_class]
	if not item then return buyable_class end
	return item.Name or buyable_class
end

function PS.GetItemsByType(item_type)
	local results = {}
	for class, data in pairs(PS.Items) do
		if data.Type == item_type then
			table.insert(results, { class = class, data = data })
		end
	end
	return results
end

function PS.GetBonusItemsByCategory()
	local grouped = {}
	for _, bonus_type in ipairs(PS.BONUS_TYPE_ORDER) do
		grouped[bonus_type] = {}
	end

	for class, data in pairs(PS.Items) do
		if data.Type == PS.ITEM_TYPE_BONUS then
			local bonus_type = PS.GetItemBonusType(data)
			table.insert(grouped[bonus_type], { class = class, data = data })
		end
	end

	return grouped
end

function PS.GetEntityItemsByCategory()
	local grouped = {}
	for _, category in ipairs(PS.ENTITY_CATEGORY_ORDER) do
		grouped[category] = {}
	end

	for class, data in pairs(PS.Items) do
		if data.Type == PS.ITEM_TYPE_ENTITY then
			local category = PS.GetItemEntityCategory(data)
			table.insert(grouped[category], { class = class, data = data })
		end
	end

	return grouped
end

--[[
	["sci_passive_extraarmor"] = {
		Name = "Extra Armor",
		BasePrice = 500,
		Type = PS.ITEM_TYPE_BONUS,
		BonusType = PS.BONUS_TYPE_SURVIVABILITY,
		Icon = "hudicons/sci_passive_extraarmor.png",
		Description = "+25 max Armor",
	},
]]--
