# Forsaken-Brainrot

An **asymmetric horror** experience (1 killer vs survivors) with brainrot/meme theming. Features unique killer abilities, stamina/sprint system, and full round lifecycle. Rojo-synced project.

## Systems

- **Role Assignment** — Random killer selection per round
- **Killer Abilities** — 4 unique abilities:
  - **Frighten** — Area-of-effect fear
  - **TeleportGrab** — Teleport and seize survivors
  - **MarkTarget** — Track a marked survivor
  - **ShadowStrike** — Stealth attack
- **Killer Attack** — Melee attack system with hit detection
- **Stamina & Sprint** — Survivor stamina bar, sprint toggle, exhaustion
- **Health System** — Player health, damage, healing
- **Round Lifecycle** — Pre-round, active, post-round, role assignment
- **Inventory System** — Killer selection and loadout
- **Glassmorphic UI** — Cooldown HUD, stamina display, hitmarkers, round timer

## Architecture

| Component | Role |
|---|---|
| `RoundSystem` | Match lifecycle, phase management |
| `KillerAbilitySystem` | 4 ability implementations + cooldowns |
| `KillerAttackSystem` | Melee attack processing |
| `PlayerStatsSystem` | Stamina, sprint, health management |
| `InventorySystem` | Killer selection and equipment |
| `DeathHandler` | Player elimination flow |

## Tech

- **Language:** Luau
- **Engine:** Roblox
- **Build:** Rojo (`default.project.json`)
- **UI:** Glassmorphic design with circular elements
