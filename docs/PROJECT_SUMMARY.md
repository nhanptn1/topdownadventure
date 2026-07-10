# TopDownAdventure — Project Summary, Skills, and Next Checklist

*Written 2026-07-10 as a resumption reference, updated same-day after an auto-attack bugfix session, then again after adding a New Game+ postgame loop, then again after adding NG+-exclusive mythic gear, then again after the entire weapon/armor/accessory roster was replaced with new art and items, then again after gear drops got randomized per-drop stat rolls. This project has been dormant while work continued on the sibling "Endless Archer RPG" project — read this before touching TopDownAdventure again.*

## 0d. Session (2026-07-10): randomized per-drop stat rolls for gear

Every copy of a gear item used to have identical stats (`item_database.gd`'s `ITEMS`
was a flat template). The user wanted drops to roll within a range instead (their
example: a "def +5" item should actually land around 3-5), applied across every stat
on every rarity tier, for more exciting/replayable loot.

- **Scope check before building**: `GlobalState.storage` is a flat `item_id -> count`
  stack with no per-copy identity at all (confirmed via `equip_item`/`unequip_slot`/
  `discard_item` in `player.gd`, which only ever move/remove by *whole count*, never
  distinguish individual copies), and only `player.gd`/`inventory_ui.gd` touch
  `storage`/`equipped` directly. A full per-instance inventory (so you could hold two
  different rolls of the same weapon and pick) would've meant converting that whole
  stacking model for a feature this game doesn't otherwise use. Went with a smaller,
  contained design instead.
- **The authored `stats` value is now the ceiling, not a fixed number.** New
  `ItemDatabase.STAT_ROLL_MIN_RATIO := 0.6` and `ItemDatabase.roll_stats(id)` roll
  each stat independently in `[0.6 * base, base]` -- 0.6 exactly matches the "def 5 ->
  3-5" example. `atk`/`def`/`hp` round to whole numbers, `crit_chance`/`attack_speed`/
  `stun_chance` round to 2 decimals, `speed` rounds to the nearest whole number. Zero
  changes needed to the already-tuned `ITEMS` dict itself.
- **One roll is remembered per item id, not per copy** -- matches how gear already
  behaved (no existing concept of distinguishing individual copies). New
  `GlobalState.rolled_stats: Dictionary` (`item_id -> {stat_key: rolled_value}`).
  `storage_add()` rolls fresh stats on every gear pickup and keeps whichever roll is
  *better*, via new `ItemDatabase.roll_power_ratio(id, rolled)` (mean of each stat's
  position in its own [min,max] range -- an apples-to-oranges-safe way to compare a
  roll that's high on atk but low on crit against one that's the reverse). So finding
  a duplicate is always either an upgrade or a no-op, never a downgrade. The stack
  *count* still increments normally and still drives the "x3" label in
  `inventory_ui.gd` -- only the displayed/used stat numbers change.
- **Every stat read for gameplay/display now goes through the rolled value.** New
  `GlobalState.get_rolled_stats(item_id)`/`get_rolled_stat(item_id, key)` (falls back
  to the base template if an id has no roll yet, e.g. an old save). `player.gd`'s
  `_recalculate_equipment_stats()` and `_total_hp_bonus()` swapped their
  `ItemDatabase.get_stat(...)` calls for `GlobalState.get_rolled_stat(...)`;
  `inventory_ui.gd`'s two `_format_stats(...)` call sites (equip row, gear row) now
  pass `GlobalState.get_rolled_stats(item_id)` instead of the item's raw `stats` dict.
  `_format_stats()` itself needed no change -- it already just renders whatever dict
  it's handed.
- `rolled_stats` persists in `save_game()`/`load_game()` following the existing field
  pattern; old saves default to `{}` and fall back to base-template stats until the
  player picks up a fresh copy of each item.
- Verified headlessly (disposable test, deleted after passing): 500 `roll_stats()`
  calls stayed within `[0.6*base, base]` per stat (with rounding fuzz for int stats)
  and produced real variance (7 distinct atk values seen out of a possible 7); 200
  simulated `storage_add()` pickups of the same id never let `rolled_stats` regress to
  a worse roll; stack count incremented normally throughout; a consumable pickup got
  no `rolled_stats` entry (gear-only, as intended); and `player.gd` correctly read a
  manually-set rolled value (including float-typed values, simulating what a save/
  load round-trip produces) rather than the base template.

## 0c. Session (2026-07-10): full weapon/armor/accessory roster replacement

The user supplied a reference sheet (`D:\WORK\PROJECT\GODOT\image\item-design.png`, 1024x1024,
a 3-row x 4-col grid: weapon/armor/ring rows x common/rare/epic/legendary columns,
rendered over a two-tone checkerboard) and asked for the 12 icons to be extracted and
wired into the game. `scripts/extract_sprite.ps1`, referenced by this doc and by the
`godot-2d-game-dev` skill as "the reusable extraction tool," **does not actually exist
in this repo** (verified via `git log --all` and a full workspace search) -- that was a
stale claim, corrected here. The extraction pipeline below was rebuilt from scratch in
the scratchpad directory instead.

**Extraction pipeline** (PowerShell + `System.Drawing`, not committed -- lived only in
the session scratchpad):
- The checkerboard turned out to be a crisp two-tone pattern (~163 and ~205 gray,
  found via a 20k-point random-pixel histogram), not the fine repeating pattern
  assumed at first. A naive multi-seed flood fill (this project's usual technique, see
  `godot-2d-game-dev` §2) doesn't cross a checkerboard's color jump between adjacent
  squares, and a "drift" flood fill (compare each pixel to its immediate neighbor,
  not a fixed reference) leaked straight through the art's own shading gradients,
  eating large chunks out of items. What actually worked: **direct per-pixel
  dual-reference matching** (pixel is background if it's within a tight tolerance of
  either exact checker shade) with no connectivity requirement -- this also correctly
  clears fully-enclosed background like a ring's donut hole, which a border-seeded
  flood fill can't reach at all.
- The epic/legendary items have a soft colored glow rendered as part of the flat
  image (not a separate alpha layer), so a rim of background near those items is
  checker-tinted toward the glow color and doesn't match the exact checker shades.
  Fixed with a second, **bounded-iteration dilation pass** (10 fixed passes, not
  unlimited BFS): each pass extends the background region by one more pixel only
  where a candidate pixel is within a loose tolerance (40) of an *already-confirmed*
  background neighbor. Bounding the iteration count (rather than growing until no
  more matches) is what keeps it from eating into real interior shading the way the
  unbounded drift version did.
- Two real PowerShell gotchas hit along the way: (1) `$bg[$idx % $w, [int]($idx / $w)]`
  inside multi-dimensional array indexer brackets fails with a bogus
  `op_Modulus`/array-coercion error -- compute the index arithmetic on separate lines
  first, never inline it inside `[...]`. (2) `[int]($idx / $w)` on two integers
  performs floating-point division then **banker's-rounds** the cast (not truncation),
  which occasionally rounded a row index up by 1 and threw
  `IndexOutOfRangeException` on an unlucky exact-.5 case -- fixed by never encoding
  (x,y) into a flat index at all for this loop, using two parallel lists instead.
- The bow icons (weapon column) extracted at a steep diagonal aspect ratio (~1.7-1.85)
  vs. this project's existing bow icons, which are already near-square (~1.0-1.1) --
  confirming the existing icons went through the same rotate-and-recrop treatment the
  `godot-2d-game-dev` skill documents for diagonal weapon art. Rotated each bow
  (-22 to -40 degrees, angle varies per bow's original slant) and re-cropped to match.

**Scope decision**: the first pass reskinned 8 existing items in place (same id/name/
stats, new icon only). The user clarified that wasn't what they wanted -- the entire
old weapon/armor/accessory roster (27 items, spanning multiple items per rarity per
slot) should be deleted outright and replaced with exactly 12 new items, one per
slot (weapon/armor/accessory) per rarity tier (common/rare/epic/mythic), matching the
reference sheet 1:1. Before deleting anything, a research pass grepped the whole
`scripts/`/`scenes/` tree for the 27 old ids as string literals to check for hardcoded
dependencies (starting equipment, scripted drops, tutorial text) -- found none outside
`item_database.gd` itself (only a couple of now-updated descriptive balance comments
in `ultimate_boss.gd`), so the roster swap was safe to do outright.

**Final roster** (`item_database.gd`'s `ITEMS`, weapon/armor/accessory entries only --
consumables/materials/quest items untouched):
- Weapon: `weathered_bow` (common) -> `frostwind_bow` (rare) -> `cursed_runebow`
  (epic) -> `sovereigns_bow` (mythic, NG+-only, see §0b).
- Armor: `travelers_tunic` (common) -> `steel_plate_armor` (rare) -> `voidscale_armor`
  (epic) -> `sovereigns_aegis` (mythic).
- Accessory: `iron_ring` (common) -> `sapphire_ring` (rare) -> `void_ring` (epic) ->
  `sovereigns_signet` (mythic).
- **Stat design, revised once more same session**: the user asked for tiers to feel
  more dramatically different, not just linearly bigger. Redesigned so each tier adds
  a stat *line*, not just bigger numbers on the same one or two stats -- common has 1
  stat, rare 2, epic 3, mythic 4 -- and each mythic item's 4th stat is a kind that
  tier normally doesn't carry (e.g. `sovereigns_bow` is the only weapon with
  `stun_chance`; `sovereigns_aegis` is the only armor with `crit_chance`), so the top
  tier reads as a genuinely different, more exciting item rather than a bigger number
  on the same template. Common/rare/epic tiers were kept close to the *old* roster's
  magnitudes (e.g. epic weapon still ~atk8) so the pre-NG+ game (up through beating
  the final boss the first time) stays balanced against `ultimate_boss.gd`'s existing
  DPS/HP calibration comments; the dramatic jump is concentrated in the mythic tier,
  which is already NG+-exclusive and offset by `GlobalState.difficulty_multiplier()`
  scaling enemies up too.
- **Bug found and fixed along the way**: instantiating `player.tscn` for the first
  time this session (previous tests never had a reason to) surfaced a real latent bug
  -- `NewGamePlusButton.pressed` was wired *twice*: once via `player.tscn`'s own
  `[connection]` block (matching the sibling `ContinueButton`'s existing convention)
  and again via a redundant `.connect()` call added in `player.gd _ready()` when NG+
  was first built (see §0b). Godot logs (but doesn't crash on) a duplicate-connection
  error every time the scene loads. Fixed by removing the redundant code-side connect
  and its now-unused `new_game_plus_button` onready var, leaving just the scene-file
  connection like `ContinueButton` already had.
- All 27 old items' icon PNGs (and their orphaned `.import` sidecars) were deleted;
  the reskin session's 8 renamed/reused files and the 3 mythic files were further
  renamed to match their new item ids exactly (e.g. `icon_hunting_bow.png` became
  `icon_weathered_bow.png`), plus the weapon/rare bow art that was extracted but
  unused last pass now became `icon_frostwind_bow.png`.
- Verified headlessly (disposable test, deleted after passing): all 12 new icon paths
  resolve and load; all 12 old ids listed above are confirmed gone from `ItemDatabase`;
  300 `roll_random_item_id()` rolls only ever produced the new ids; mythic items still
  never drop without `allow_mythic` (i.e. still NG+-exclusive per §0b).
- **Not yet manually eyeballed in the actual inventory UI** -- headless verification
  only proved the textures load and the data is correct, not how the art reads at
  actual in-game icon size/scale. Worth a quick look next session, alongside the other
  pending manual-playtest items below. The legendary bow icon in particular
  (`icon_sovereigns_bow.png`) has a very faint residual checker-fringe artifact right
  at its edge (visible zoomed-in, likely invisible at real icon size) that further
  cleanup passes started eating into real detail rather than improving -- left as-is
  rather than over-polishing.

## 0b. Session (2026-07-10): NG+-exclusive mythic gear

New Game+ (§0a) made enemies scale up, but had no reward beyond "do it again but
harder." Added a 4th rarity tier, gated to NG+ only, so the final boss gives a real
reason to keep replaying:

- **`ItemDatabase.MYTHIC_COLOR`** + 3 new `rarity: "mythic"` items in `ITEMS`:
  `windcutter_bow_ascended`, `dragonscale_armor_ascended`, `assassins_signet_ascended`
  — "reforged" upgrades of the 3 existing epic-tier items referenced in
  `ultimate_boss.gd`'s balance comment as "the best gear obtainable by this point."
  Each reuses its base item's existing icon PNG (no new art needed) and roughly
  scales its stats up ~30-50% (e.g. `windcutter_bow` atk 7/attack_speed 0.20 →
  `windcutter_bow_ascended` atk 11/attack_speed 0.30).
- **`ItemDatabase.roll_guardian_drop(map_tier, allow_mythic := false)`**: new second
  param. When `allow_mythic` is true, a `MYTHIC_DROP_CHANCE` (0.5) roll can return a
  random mythic item before falling through to the normal tier-weighted roll.
  `allow_mythic` is only ever passed `true` from `ultimate_boss.gd::_try_drop_item()`,
  as `GlobalState.ng_plus_level > 0` — so mythic gear is exclusively a "beat the final
  boss in New Game+" reward, never a regular gate-boss/guardian drop.
- No inventory UI or equip-stat-recalc changes needed: `inventory_ui.gd` already reads
  `item.get("color", ...)` generically for the rarity border, and
  `player.gd::_recalculate_equipment_stats()` already sums whatever's in an item's
  `stats` dict by existing stat keys (`atk`/`def`/`crit_chance`/`attack_speed`) — the
  new items are pure data, reusing both paths untouched.
- Verified headlessly (disposable test, deleted after passing): 500 rolls with
  `allow_mythic=false` produced zero mythic drops; 4000 rolls with `allow_mythic=true`
  landed at a 51.2% mythic ratio (expected ~50%); all 3 ascended items' stats confirmed
  strictly higher than their base counterparts.
- **Not yet manually verified in-editor** — same caveat as §0a: the math/rolls are
  proven, but seeing the mythic gold border and equipping one in the actual inventory
  UI hasn't been eyeballed yet.

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
- **Sprite extraction tooling**: despite this doc and the `godot-2d-game-dev` skill both describing `scripts/extract_sprite.ps1` as an existing reusable tool, it does **not** actually exist anywhere in this repo's history (checked via `git log --all -- scripts/extract_sprite.ps1` and a full workspace search) — a stale claim, corrected in §0c. If sprite extraction is needed again, the working technique from §0c (dual-reference checkerboard matching + bounded-iteration dilation for glow-tinted edges) lived only in a session scratchpad and was never committed here; it would need to be rebuilt or the scratchpad script recovered.
- **Enemy AI upgrade path already scoped**: `enemy.gd` currently only does radius-detection + chase. `Freedom-Hunter/src/entities/monster.gd` (a cloned 3D reference project) has a clean scout→detect(FOV+raycast LOS)→distance-based-combat-state pattern that was identified as the natural next step if smarter enemies are ever wanted here.
- **Editor staleness**: kill and relaunch the Godot editor after any external `.tscn`/`.gd` edit — hot-reload isn't trustworthy after out-of-editor changes, a recurring gotcha hit multiple times on this project.
- **GH Pages deploy traps**: never use the Actions UI's "Re-run failed jobs" button on this workflow — it can attach a stale duplicate artifact to the run. Trigger a genuinely fresh run (new push or `workflow_dispatch`) instead.
- **Filesystem search caution**: an unbounded `find /` on Windows Git Bash scans the entire drive (not scoped like on Linux) — always use `-maxdepth` or a specific starting path. This bit a headless-Godot-path search in the sibling project and applies equally here.

## 3. Next Working Checklist

1. ~~Decide on the uncommitted `project.godot` diff~~ — resolved; tree is clean as of `e6ae0c3`.
2. **Manual playtest pass on the auto-attack fixes and the new enemy FOV** — headless tests proved the timing/angle math, but this is all feel; worth a few minutes in the actual editor: auto-attack as warrior/archer/mage (bare and with attack-speed gear) moving in circles around an enemy, plus approaching a few enemies from behind vs. head-on to confirm the FOV cone (140°) feels right, not too generous or too strict.
3. ~~Enemy AI line-of-sight upgrade~~ — done; see the correction note above. If enemies still feel too easy/too hard to sneak past, `DETECTION_FOV_DEGREES` in `enemy.gd` is the one knob to retune.
3a. **Manual playtest the New Game+ loop** (see §0a) — headless tests only covered the math/state reset, not the actual button/UI feel or whether 1.5x-per-cycle scaling feels right in practice. `GlobalState.difficulty_multiplier()` is the one knob to retune if NG+1 feels too easy or too brutal.
3b. **Manual playtest mythic gear** (see §0b) — confirm the gold mythic border renders correctly in the inventory UI and that equipping an ascended item actually feels like a noticeable power jump. `ItemDatabase.MYTHIC_DROP_CHANCE` (0.5) is the knob if it feels too rare/too common.
3c. **Eyeball the new icon art in the actual inventory UI** (see §0c) — the whole 12-item weapon/armor/accessory roster only got a headless "does it load" check, not a real visual pass. Check the legendary bow icon (`icon_sovereigns_bow.png`) in particular for the faint edge fringe noted in §0c.
3d. **Manual playtest the stat-roll system** (see §0d) — headless tests proved the roll math and the "keep the better roll" logic, but not how it actually feels to pick up a few of the same item and watch the numbers change in the inventory UI. `ItemDatabase.STAT_ROLL_MIN_RATIO` (0.6) is the one knob to retune if drops feel too random or not random enough.
4. **No feature-parity backport expected** with Endless Archer RPG — the two projects have deliberately diverged (const-Dict vs per-Resource data, different combat pacing). If a specific polish technique from that project (e.g. the `ShakeCamera`/`offset`-tween pattern, `WorldEnvironment` Glow, or projectile pooling if this game ever needs a bullet-heavy skill) seems worth having here too, treat it as a fresh, deliberate decision each time — not an assumed sync.
5. **This doc itself** — update it directly the next time meaningful work lands here, rather than letting it drift stale; there's no separate memory-system record of this project's status, so this file is the authoritative one.
