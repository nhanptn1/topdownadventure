# TopDownAdventure — Project Summary, Skills, and Next Checklist

*Written 2026-07-10 as a resumption reference, updated same-day after an auto-attack bugfix session, then again after adding a New Game+ postgame loop. This project has been dormant while work continued on the sibling "Endless Archer RPG" project — read this before touching TopDownAdventure again.*

## 0a. Session (2026-07-10): New Game+ / postgame loop

Beating the true final boss (The Withered Sovereign) used to just show a "Victory!"
popup that unpaused in place — no reason to keep playing. Added a real postgame loop:

- **`GlobalState.ng_plus_level: int`** (new field, persisted in save/load like every
  other field, defaults to 0 for old saves via `int(parsed.get("ng_plus_level", ...))`)
  and **`GlobalState.difficulty_multiplier() -> float`** = `1.0 + 0.5 * ng_plus_level`
  (NG+1 = 1.5x, NG+2 = 2.0x, ...). Only HP/damage scale — attack pacing is untouched,
  so NG+ hits harder without feeling twitchier.
- **`GlobalState.start_new_game_plus()`**: increments `ng_plus_level`, resets
  `boss_defeated` and clears `defeated_gate_bosses` (relocks all gates — they already
  live-check that array every `_process` frame in `gate.gd`, so no other scene state
  needed touching), resets `current_map_path` to `map.tscn`, heals to full, saves.
  Deliberately leaves `player_level`/`xp`/`storage`/`equipped`/`quick_slots` untouched
  — carrying character progression into the replay is the entire point.
- **`enemy.gd` `_ready()`**: `max_health`/`attack_damage` now multiply by
  `GlobalState.difficulty_multiplier()`. Covers every species and every gate
  boss/guardian (Dragon Sovereign, Gate Warden, Gate Overlord) automatically since
  they're all `enemy.gd` instances — zero `.tscn` edits needed.
- **`ultimate_boss.gd`**: `PHASE_ATTACK_DAMAGE` is a `const` array so it can't be
  rescaled in place; added an instance var `_phase_damage: Array[int]` computed once
  in `_ready()` from `PHASE_ATTACK_DAMAGE * difficulty_multiplier()`, and swapped all
  three read-sites (`_on_attack_body_entered`, `_on_attack_timer_timeout`,
  `_fire_ranged_attack`) to read `_phase_damage[phase]` instead. `max_health` (a plain
  `@export`, not const) is scaled directly in `_ready()`.
- **Entry point**: a new "Start New Game+" button next to "Continue Playing" on the
  existing victory screen (`player.tscn` → `VictoryScreen/Center/VBox`), wired to
  `player.gd`'s new `_on_new_game_plus_pressed()`. Only ever visible at the moment
  it's relevant, since `trigger_victory()` is only called from `ultimate_boss.gd`.
- **HUD**: a small `NGPlusLabel` under the level label, hidden at `ng_plus_level == 0`,
  showing `"NG+%d"` otherwise (set once in `player.gd _ready()`).
- No changes needed to `character_select.gd` or `gate.gd` — "Continue" already loads
  `GlobalState` and jumps to `current_map_path`, and gates already re-check
  `defeated_gate_bosses` live, so both work correctly against the reset fields as-is.
- Verified headlessly (disposable test, deleted after passing): a level-5 enemy's
  HP/damage scale by exactly 1.5x at `ng_plus_level=1`; the final boss's `max_health`
  and all three `_phase_damage` entries scale the same way; `start_new_game_plus()`
  resets `ng_plus_level`/`boss_defeated`/`defeated_gate_bosses`/`current_map_path`
  while leaving `player_level`/`storage` untouched.
- **Not yet manually playtested in-editor** — headless tests only cover the math and
  state transitions, not the actual button/UI feel. Worth a quick pass next session:
  beat (or debug-trigger) the final boss, click "Start New Game+", confirm the drop
  back into map 1 feels right and a map-1 slime is visibly tougher.

## 0. Latest session (2026-07-10): auto-attack timing fixes

Three chained bugs, found and fixed in one sitting, all in `player.gd`'s attack/movement logic:

1. **`d40c3a8`** — `attack_cooldown` (a plain Timer, `ATTACK_COOLDOWN_BASE=0.4s` adjusted by gear) and the swing *animation's* actual playtime (frame_count/fps, varies per character/direction) were two independent, unsynced timers. Whenever cooldown finished before the animation did, `_try_attack()` fired again mid-swing (it only checked `can_attack`, not `is_attacking`), restarting the sprite animation and desyncing `is_attacking` from the real animation state — the visible stutter. Fix: `_try_attack()` now also requires `not is_attacking`, and whichever finishes last (cooldown timer or animation) triggers the next auto-attack.
2. **Same commit** — facing direction was frozen for the whole swing, so turning mid-attack left the character visibly stuck facing the old direction. Fixed by making movement always take priority: facing now updates live every physics frame, and a direction change mid-swing calls the new `_cancel_attack()`, which cuts the pose short (the projectile already fired at swing-start, so no damage is lost) and re-fires immediately in the new direction if auto-attack's cooldown already allows it.
3. **`e6ae0c3`** — fixing #1 surfaced a *pre-existing* bug: `sprite.speed_scale` was hardcoded to `1.0`, so each swing animation always played at its fixed natural duration regardless of the cooldown. Mage's ~0.545s swing is longer than the 0.4s base cooldown, so blocking overlap (fix #1) silently slowed mage's baseline attack speed to ~0.55s: and attack-speed gear (which only ever shortens the cooldown, never the animation) became invisible once cooldown dropped below that fixed animation length. Fix: new `_attack_speed_scale_for()` computes `sprite.speed_scale` per-attack so the animation's real playtime always matches the current gear-adjusted cooldown.

All three verified with disposable headless functional tests (instantiate `player.tscn` in a real scene, drive `Input.action_press`/`_try_attack()` directly, measure real fire-event timestamps vs `ANIM_FINISHED` signals) — see [§2](#2-skills--lessons) for why raw `--script` mode wouldn't have worked here (autoloads like `GlobalState`/`AudioManager` only register in a real scene run).

**Correction to this doc's earlier claim**: `enemy.gd` already had a raycast line-of-sight check (`_has_line_of_sight()`) since the *initial* commit — the "no LOS check" gap noted below in §3 was stale/wrong. The real gap was a missing **field-of-view cone**: idle enemies aggro'd on anything unobstructed inside their detection radius regardless of which way they were facing, so approaching from directly behind was just as detectable as walking up in front. Added a `DETECTION_FOV_DEGREES := 140.0` constant and a `_within_fov()` check (angle between `facing_direction` and the direction to the player), gating the same `IDLE → CHASE` transition alongside the existing LOS check. Getting hit still force-aggros regardless of facing (unchanged, verified as a regression case). Applies uniformly to all species and bosses/guardians — no per-species tuning yet.

**Final-boss (The Withered Sovereign / `ultimate_boss.gd`) fixes, same session**:
- **Sprite border-line artifact**: all 24 `final_boss_{idle,enraged,death}_*.png` frames had a leftover sheet row/column-divider baked in as a fully-opaque, flat-colored line hugging one or more edges of the crop (not caught by the earlier `d04c138` extraction fix, which only handled lines *inside* the silhouette). Fixed in-place with a two-pass PowerShell cleanup: detect near-edge rows/columns that are either a large majority of that row's/column's opaque pixel count or a big local spike vs. their immediate neighbor (and low color-variance, since the divider is a flat wash vs. the character's shaded art), clear them to transparent, then a largest-connected-component pass mops up any now-isolated speckles. Canvas size deliberately left unchanged (no recrop) to avoid the per-frame recentering/jitter pitfall in [§2](#2-skills--lessons). Verified visually per-frame by compositing over magenta.
- **Melee attack range halved**: `AttackShape` radius 90 → 45 in `ultimate_boss.tscn` (a regular enemy's is 55, for scale), with `CHASE_STOP_DISTANCE` in `ultimate_boss.gd` scaled down to match (70 → 35) — leaving that at 70 while shrinking the attack radius would have made the boss stop chasing outside its own new attack range and never land a hit.
- **Removed all 4 `Rock*` decor instances from `map4.tscn`** (the final-boss arena) — they sat in the middle of the arena between player spawn and the boss and let the player path around one to make the boss's straight-line `move_and_slide()` chase get physically stuck against it. The 4 corner `Mountain*` decor instances were left alone (out of the fight's path, not implicated). The now-unused `decor_rock.tscn` ext_resource was also removed from the scene file.
- **Ranged attack now speeds up in Phase 3, matching melee**: the "enraged" animation (and the ranged bolt cast on its frame 6 each loop, via `_on_sprite_frame_changed()`) is set once via `sprite.play("enraged")` on entering Phase 2 and was never touched again on the Phase 3 transition, so it kept looping at the same fixed pace while melee's `attack_timer` interval sped up 1.7s → 1.2s → 0.8s across phases. Added `sprite.speed_scale = PHASE_ATTACK_INTERVAL[Phase.PHASE_2] / float(PHASE_ATTACK_INTERVAL[Phase.PHASE_3])` (1.5x) on the Phase 3 transition, and reset it to `1.0` on both the Phase 2 transition and `restore_full_health()` so a fresh fight attempt doesn't inherit a stale fast pace. Verified headlessly: 2 ranged shots/4s in Phase 2 vs. 5 shots/4s in Phase 3.

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

1. ~~Decide on the uncommitted `project.godot` diff~~ — resolved; tree is clean as of `e6ae0c3`.
2. **Manual playtest pass on the auto-attack fixes and the new enemy FOV** — headless tests proved the timing/angle math, but this is all feel; worth a few minutes in the actual editor: auto-attack as warrior/archer/mage (bare and with attack-speed gear) moving in circles around an enemy, plus approaching a few enemies from behind vs. head-on to confirm the FOV cone (140°) feels right, not too generous or too strict.
3. ~~Enemy AI line-of-sight upgrade~~ — done; see the correction note above. If enemies still feel too easy/too hard to sneak past, `DETECTION_FOV_DEGREES` in `enemy.gd` is the one knob to retune.
3a. **Manual playtest the New Game+ loop** (see §0a) — headless tests only covered the math/state reset, not the actual button/UI feel or whether 1.5x-per-cycle scaling feels right in practice. `GlobalState.difficulty_multiplier()` is the one knob to retune if NG+1 feels too easy or too brutal.
4. **No feature-parity backport expected** with Endless Archer RPG — the two projects have deliberately diverged (const-Dict vs per-Resource data, different combat pacing). If a specific polish technique from that project (e.g. the `ShakeCamera`/`offset`-tween pattern, `WorldEnvironment` Glow, or projectile pooling if this game ever needs a bullet-heavy skill) seems worth having here too, treat it as a fresh, deliberate decision each time — not an assumed sync.
5. **This doc itself** — update it directly the next time meaningful work lands here, rather than letting it drift stale; there's no separate memory-system record of this project's status, so this file is the authoritative one.
