# TopDownAdventure — Project Summary, Skills, and Next Checklist

*Written 2026-07-10 as a resumption reference. This project has been dormant while work continued on the sibling "Endless Archer RPG" project — read this before touching TopDownAdventure again.*

## 1. Summary

**What it is**: a 2D top-down action RPG built in Godot 4.7 — the first of two Godot game projects in this workspace (Endless Archer RPG is the second, and deliberately uses a different architecture — see §2). Single flat `scripts/`/`scenes/` folder layout, no subfolders.

**Git state**: 9 commits, `d6996db` (initial scaffold) → `ee98417` ("Restore gate bosses/final boss/guardians to full HP on player respawn", the current tip). One trivial uncommitted change sits in `project.godot` right now — Godot's editor reordered the `[display]` section on last save; diffed and confirmed it's a pure reorder with no value changes. Safe to commit as-is or discard; doesn't affect behavior either way.

**Playable scope** (appears feature-complete against its original design):
- **3 characters** via `character_select.tscn`: Warrior (melee), Archer (ranged arrows), Mage (ranged bolts) — each with its own extracted sprite set and `CHARACTER_DATA` entry in `player.gd`.
- **Growth**: player stats (HP, damage, defense, crit, stun, attack speed) scale with level; `GlobalState` autoload persists stats/inventory/save across scene changes.
- **Enemies**: multi-species (slime/zombie/skeleton/dragon) via a `SPECIES_DATA` const dict in `enemy.gd`, per-enemy level scaling, a `dragon_spawner.gd` respawn loop. AI is deliberately simple: radius-based detection + chase, no line-of-sight or field-of-view check yet (see §3 for the already-scoped upgrade).
- **World**: 3 maps (`map.tscn` → `map2.tscn` → `map3.tscn`) of escalating difficulty, gated by `gate.tscn` instances requiring specific bosses defeated (Gate Warden, Gate Overlord) to pass, a `cave.tscn` sub-map reached via a cave entrance, 10 tree/foliage decor variants scattered procedurally, a Final Boss + victory screen in map3.
- **Items/economy**: `item_database.gd` (const-dict driven, not per-Resource files — see §2), multi-stat gear across weapon/armor/accessory slots, quick-slot consumables (bombs, potions, scrolls), rarity-weighted drop rolls, a discard flow with confirmation, world pickups with a light-beam/bob visual highlight.
- **Persistence**: save/load through `GlobalState`, autosave triggered at gates, Continue/New Game flow from `character_select`.
- **Combat polish**: damage numbers, camera shake, hit-flash, knockback, attack lunge, death fade — this is the same polish vocabulary that later got rebuilt (independently, slightly evolved) in Endless Archer RPG's `enemy_base.gd`/`boss_base.gd`.
- **Audio**: `AudioManager` autoload generating procedural chiptune SFX at runtime (no audio asset files) — the same technique was reused and extended for Endless Archer RPG's `AudioManager`.
- **HUD**: health bar, minimap, a 1.0x/1.3x zoom toggle button plus mouse-wheel zoom, with a camera/viewport scaling fix for large monitors.
- **Deployment**: `.github/workflows/deploy.yml` exports the Web build and publishes to GitHub Pages — confirmed working after two hardening passes (verbose export logging; fail loudly if `index.html` is missing rather than silently "succeeding" with a broken export).

**Known gaps**: none functional as of the last commit. The enemy AI's lack of line-of-sight (see §3) is a deliberate simplification, not a bug.

## 2. Skills & Lessons

The full general technique playbook distilled from building this project lives in the reusable skill **`godot-2d-game-dev`** (`C:\Users\nhanp\.claude\skills\godot-2d-game-dev\SKILL.md`) — invoke that skill rather than re-deriving any of this from scratch. It covers the headless verify-every-change loop, the `:=` type-inference gotcha, the multi-seed flood-fill sprite/icon extraction pipeline, the sliver-icon rotation fix, Plan Mode conventions, a Godot 4.x correctness checklist, and the GitHub Pages deploy workflow — all written *from* this project's history.

What's specific to *this* project and worth remembering on top of that:

- **Data pattern**: content lives in `const` Dictionaries (`CHARACTER_DATA`, `SPECIES_DATA`, `ITEMS`) directly inside the relevant script, not as individually-authored `.tres` Resource files. This is a real, deliberate architectural difference from Endless Archer RPG (which uses per-`.tres` `EnemyData`/`SkillData`/`ItemData` Resources) — the two projects are not meant to converge, and porting a technique from one to the other means translating the pattern, not copy-pasting.
- **Sprite extraction tooling**: `scripts/extract_sprite.ps1` — dot-source it and call `Extract-Icon` / `Rotate-AndRecrop` / `Show-GridOverlay`. Directly reusable if new sprite sheets ever get added here.
- **Enemy AI upgrade path already scoped**: `enemy.gd` currently only does radius-detection + chase. `Freedom-Hunter/src/entities/monster.gd` (a cloned 3D reference project) has a clean scout→detect(FOV+raycast LOS)→distance-based-combat-state pattern that was identified as the natural next step if smarter enemies are ever wanted here.
- **Editor staleness**: kill and relaunch the Godot editor after any external `.tscn`/`.gd` edit — hot-reload isn't trustworthy after out-of-editor changes, a recurring gotcha hit multiple times on this project.
- **GH Pages deploy traps**: never use the Actions UI's "Re-run failed jobs" button on this workflow — it can attach a stale duplicate artifact to the run. Trigger a genuinely fresh run (new push or `workflow_dispatch`) instead.
- **Filesystem search caution**: an unbounded `find /` on Windows Git Bash scans the entire drive (not scoped like on Linux) — always use `-maxdepth` or a specific starting path. This bit a headless-Godot-path search in the sibling project and applies equally here.

## 3. Next Working Checklist

1. **Decide on the uncommitted `project.godot` diff** — commit it (harmless) or `git checkout` it to discard (equally harmless); confirmed cosmetic only.
2. **Manual playtest pass before adding anything new** — the last commit only touched respawn HP-restore logic, and it's been a while since a full headless functional pass was run across the whole game. Worth a quick start-to-finish sanity check (character select → combat → a gate → the final boss → victory screen) before building on top, just to confirm nothing has quietly regressed.
3. **Enemy AI line-of-sight upgrade** (optional, scoped above in §2) — add an FOV + raycast check on top of the existing radius-chase, if you want enemies to feel smarter.
4. **No feature-parity backport expected** with Endless Archer RPG — the two projects have deliberately diverged (const-Dict vs per-Resource data, different combat pacing). If a specific polish technique from that project (e.g. the `ShakeCamera`/`offset`-tween pattern, `WorldEnvironment` Glow, or projectile pooling if this game ever needs a bullet-heavy skill) seems worth having here too, treat it as a fresh, deliberate decision each time — not an assumed sync.
5. **This doc itself** — update it directly the next time meaningful work lands here, rather than letting it drift stale; there's no separate memory-system record of this project's status, so this file is the authoritative one.
