local Config = {}

Config.MinimumPlayers = 2
Config.IntermissionTime = 20
Config.RoundTime = 180
Config.EndDelay = 6

Config.Killers = {
	"Tralalero Tralala",
	"Bombardiro Crocodilo",
	"Tung Tung Tung Sahur",
	"Ballerina Cappuccina"
}

Config.SurvivorWalkSpeed = 16
Config.KillerWalkSpeed = 22

Config.SurvivorMaxHealth = 100
Config.KillerMaxHealth = 175

Config.SurvivorSprintSpeed = 24
Config.KillerSprintSpeed = 28

Config.MaxStamina = 100
Config.StaminaDrainPerSecond = 22
Config.StaminaRegenPerSecond = 16
Config.StaminaRegenDelay = 0.8
Config.MinimumSprintStamina = 8


Config.KillerAttackDamage = 35
Config.KillerAttackCooldown = 1.4
Config.KillerAttackRange = 7
Config.KillerAttackWidth = 5
Config.KillerAttackHeight = 5

-- Ability cooldowns per killer
Config.AbilityCooldowns = {
	["Tralalero Tralala"] = 8,
	["Bombardiro Crocodilo"] = 10,
	["Tung Tung Tung Sahur"] = 12,
	["Ballerina Cappuccina"] = 14,
}

-- Grito Sônico (Tralalero Tralala)
Config.SonicScreamRadius = 15
Config.SonicScreamDamage = 20
Config.SonicScreamSlowAmount = 0.5
Config.SonicScreamSlowDuration = 2

-- Investida Crocodilo (Bombardiro Crocodilo)
Config.ChargeSpeed = 75
Config.ChargeDistance = 45
Config.ChargeDamage = 35
Config.ChargeHitRadius = 6

-- Ritmo do Tambor (Tung Tung Tung Sahur)
Config.TeleportRange = 55
Config.TeleportMarkerDuration = 6

-- Dança Encantadora (Ballerina Cappuccina)
Config.PullRadius = 25
Config.PullDuration = 3
Config.PullStrength = 28
Config.KillerPullSlowMultiplier = 0.5

-- Killer display info for lobby
Config.KillerInfo = {
	["Tralalero Tralala"] = {
		Color = Color3.fromRGB(255, 200, 80),
		Icon = "📢",
		AbilityName = "Grito Sônico",
		Description = "Emita uma onda de choque que danifica e lentifica survivors num raio de 15 studs.",
	},
	["Bombardiro Crocodilo"] = {
		Color = Color3.fromRGB(100, 220, 255),
		Icon = "🐊",
		AbilityName = "Investida Crocodilo",
		Description = "Avance rapidamente 45 studs, causando dano e repulsão ao primeiro survivor atingido.",
	},
	["Tung Tung Tung Sahur"] = {
		Color = Color3.fromRGB(255, 150, 50),
		Icon = "🥁",
		AbilityName = "Ritmo do Tambor",
		Description = "Marque uma posição com Q e teletransporte-se para ela em até 6 segundos.",
	},
	["Ballerina Cappuccina"] = {
		Color = Color3.fromRGB(255, 100, 200),
		Icon = "🩰",
		AbilityName = "Dança Encantadora",
		Description = "Puxe todos os survivors num raio de 25 studs em sua direção por 3 segundos.",
	},
}

return Config