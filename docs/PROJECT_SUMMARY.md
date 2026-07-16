# TopDownAdventure — Project Summary, Skills, and Next Checklist

*Written 2026-07-10 as a resumption reference, updated same-day after an auto-attack bugfix session, then again after adding a New Game+ postgame loop, then again after adding NG+-exclusive mythic gear, then again after the entire weapon/armor/accessory roster was replaced with new art and items, then again after gear drops got randomized per-drop stat rolls, then again after adding a character skill system (active skill + passive per character), then again after the skill system got level-gating, a passive leveling curve, base defense, and auto-cast, then again after the active skill got its own visual effect, then again after a full player/enemy/boss balance review, then again after fixing overlapping/clipped stat text in the inventory UI, then again after fixing the skill effect landing near the player instead of the enemy, then again (2026-07-14) after a bug-fix pass covering skill auto-cast firing at nothing, the final boss's unreachable Phase 1 melee attack, a one-shot-only victory popup, and a rework of gear stat rolls to per-copy instances, then again same day after New Game+ was changed to actually reset level/gear instead of carrying everything over. This project has been dormant while work continued on the sibling "Endless Archer RPG" project — read this before touching TopDownAdventure again.*

## 0l. Session (2026-07-14): New Game+ now resets level and wipes all gear/items

§0a's original NG+ design deliberately kept `player_level`/`xp`/`storage`/`equipped`/`quick_slots` untouched -- "carrying character progression into the replay is the entire point," per that session's own note. The user reported this made NG+ uninteresting: with full end-game gear and level already in hand, the higher `difficulty_multiplier()` scaling barely registers. Reversed that decision -- `GlobalState.start_new_game_plus()` now resets `player_level` to 1, `player_xp` to 0, `player_max_health`/`player_health` back to the level-1 baseline (100, duplicated from `player.gd`'s `BASE_MAX_HEALTH` since there's no clean cross-script const reference), and clears `storage`, `quick_slots`, `gear_instances`, `gear_bag`, and `equipped` entirely. `selected_character` is deliberately left alone -- NG+ is still the same character, just starting over. Map/gate progress reset was already correct and is unchanged.

No other code needed to change: `player.gd`'s `_ready()` already re-reads `level`/`xp`/`max_health`/`health` fresh from `GlobalState` on every scene load (including the `change_scene_to_file("res://scenes/map.tscn")` NG+ already does), and `_recalculate_equipment_stats()` already recomputes everything from `GlobalState.equipped`/passive-by-level from scratch each time -- an empty `equipped` and `level = 1` naturally fall out to base stats with zero gear bonus.

**Not yet manually playtested** -- worth checking that a level-1, no-gear character actually stands a chance against a `difficulty_multiplier()`-scaled map-1 slime; NG+'s enemy scaling was tuned against the old "keep everything" design where the player was already overleveled for map 1, so first-few-minutes-of-NG+ difficulty is an open question now that both sides of that equation changed at once.

## 0k. Session (2026-07-14): four-bug fix pass -- auto-cast whiffing, final boss geometry, one-shot victory popup, gear roll rework

**None of this session's changes have had an in-editor playtest yet** (this project's standing rule is no proactive headless Godot runs either -- see the `godot-2d-game-dev` skill's general default, overridden here). Verified by re-reading the code paths carefully instead; treat all four as needing a real playtest before considering them confirmed.

- **Skill auto-cast no longer fires into empty air.** `player.gd`'s auto-attack-mode auto-cast (`_physics_process()`) previously called `_try_skill()` unconditionally whenever off cooldown, and `_skill_target_position()` silently fell back to a point in front of the player when no enemy was in range -- so with auto-attack on and nothing nearby, the skill kept firing (burning its cooldown, spawning its visual effect, AoE-querying empty space) at a point in front of the player over and over. Added `_find_nearest_enemy_in_range()`/`_skill_search_range()` (refactored out of the existing target-search logic) and gated the auto-cast call on an actual enemy being in range. A manual `R`-press/HUD-button cast still swings at empty air like a normal attack does -- only the automatic path requires a real target.
- **Final boss Phase 1 (and every phase) couldn't actually land its melee hit, and kept shoving into the player.** The boss's own body collision (`BodyShape` radius 50) plus the player's body (radius 8) means the two `CharacterBody2D` shapes can physically never get closer than 58px center-to-center -- a hard floor set by Godot's own collision resolution, not something `move_and_slide()` can be pushed past. A previous session (`704804f`, "fix boss stuck-on-decor bugs") halved `AttackShape`'s radius 90 -> 45 and `CHASE_STOP_DISTANCE` 70 -> 35 without accounting for that floor, so both ended up *below* it: the attack hitbox was smaller than the closest the player could ever physically get (so it could never trigger, in any phase, not just Phase 1), and the chase logic kept trying to close a gap physics wouldn't allow, which reads as the boss endlessly shoving into the player's body. Bumped `AttackShape` to 70 (`ultimate_boss.tscn`) and `CHASE_STOP_DISTANCE` to 60 (`ultimate_boss.gd`) -- both now comfortably clear the 58px floor, mirroring the margin a regular enemy's own body/attack-radius pair already has.
- **The victory/New-Game+ popup only ever showed once.** `trigger_victory()` was only ever called from `ultimate_boss.gd`'s `_die()`, so a player who picked "Continue Playing" (or just left the arena) had no way to ever reach the "Start New Game+" option again -- the boss's own `_ready()` just `queue_free()`s itself silently whenever `GlobalState.boss_defeated` is already true. Now that early-return also calls `player.trigger_victory()` before freeing, so walking back into the final-boss map after already beating it re-opens the same popup.
- **Gear stat rolls reworked from "one roll per item id" to real per-copy instances**, per the user's choice among three options after a probability simulation confirmed the old "always keep the better roll" design converges to a near-max roll within 1-2 duplicate pickups and then never changes again -- which is exactly why epic gear (the only tier worth farming pre-NG+, with just one item per slot) felt completely fixed after a little farming, while common/rare were rarely held long enough to notice. `global_state.gd`'s flat `item_id -> count` gear storage and single `rolled_stats` roll-per-id are replaced by `gear_instances` (instance id -> `{item_id, stats}`, each copy independently rolled) and `gear_bag` (item_id -> array of unequipped instance ids); `equipped[slot]` now holds an instance id instead of an item id. `player.gd`'s `equip_item()`/`unequip_slot()`/`_recalculate_equipment_stats()`/`_total_hp_bonus()` and every `inventory_ui.gd` gear row now operate on instance ids, and the inventory list shows **one row per individual copy** (not grouped/collapsed by item id) so multiple rolls of the same weapon show their own distinct stats side by side and can be equipped/discarded independently. Consumables/materials/quest items are untouched (still flat `storage` counts). **Old saves are not migrated** -- any gear held/equipped before this change is dropped on first load under the new format (`storage`'s legacy gear entries are filtered out, `equipped` slots pointing at now-nonexistent instances reset to empty), the same tradeoff this project already accepted when the whole item roster was replaced in §0c.

## 0j. Session (2026-07-10): skill effect/damage now lands on the enemy, not the player

The user reported the active skill's visual effect (see §0g) appearing at/near the
player's own position instead of on the enemy being hit. Root cause:
`_skill_target_position()` only had Meteor search for the nearest enemy -- Flame
Slash unconditionally returned a fixed point 40px in front of the *player*,
regardless of where any enemy actually was, so both its damage and its visual
effect were always anchored to the player rather than the target.

- **Both skills now search for the nearest enemy** in `_skill_target_position()`
  (Flame Slash at ~150px, roughly its melee knife range; Meteor still at 400px,
  matching its ranged-spell identity) and only fall back to a point in front of the
  player when nothing is in range at all (e.g. swinging at empty air) -- unified
  into one function instead of Meteor being the only branch that did real targeting.
- **The visual effect is also raised to roughly head/upper-body height** on its
  target via a new `SKILL_EFFECT_HEAD_OFFSET := Vector2(0, -30)`, matching the exact
  offset `enemy.gd` already uses for its own floating damage numbers. This only
  affects where the *visual* spawns -- the AoE damage query itself still centers on
  the target's real, unraised position for correct hit detection.
- A real `:=` type-inference parse error hit *actual game code* this time (not a
  disposable test script, for once) on `var is_meteor := skill.get("id", "") == "meteor"`
  -- comparing a `Dictionary.get()` Variant result against a string literal doesn't
  resolve to a concrete type for inference purposes either, same family of gotcha as
  `.instantiate()`. Fixed with an explicit `var is_meteor: bool = ...` annotation.
- Verified headlessly (disposable test, deleted after passing): with an enemy placed
  60px from the player, Warrior's Flame Slash targets it exactly (not the player);
  casting it spawns the visual effect within 30px of the enemy's position (the head
  offset) and confirms that distance is smaller than the effect's distance to the
  player; and with two enemies at different distances, Meteor's targeting correctly
  picks the nearer one.

## 0i. Session (2026-07-10): fix clipped/overlapping item stat text in the inventory list

## 0i. Session (2026-07-10): fix clipped/overlapping item stat text in the inventory list

The user reported the inventory panel's item rows showing cut-off stat text (e.g.
"Frostwind Bow x2 (ATK +5, Atk S" -- truncated mid-word), reported as overlapping
with the Equip/Discard buttons. Root cause: `inventory_ui.gd`'s `_build_gear_row()`
used `label.clip_text = true` with a fixed `custom_minimum_size = Vector2(200, 0)`
and no wrapping -- fine when items had 1-2 short stats, but this session's item
redesign (§0c/§0d) gave gear up to 4 stat lines per rarity tier, especially mythic,
producing much longer strings than the layout was ever sized for. The *equipped*-slot
rows (`_build_equip_row()`) never had this problem because they already used
`autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` instead of clipping -- the inventory
list rows just hadn't been brought in line with that pattern.

- `_build_gear_row()`: swapped `clip_text = true` for the same
  `autowrap_mode = TextServer.AUTOWRAP_WORD_SMART` the equip rows already use, and
  dropped `size_flags_vertical = SIZE_SHRINK_CENTER` so a wrapped multi-line label can
  actually grow the row's height instead of being squashed into one line's worth of
  space. (`_build_consumable_row()`/`_build_material_row()` left as-is -- their text
  is just "Name xN", never long enough to clip.)
- `scenes/inventory_ui.tscn`: widened `PanelBG` from 800x600 to 920x640 (viewport is
  1280x720, confirmed this still fits comfortably centered) so wrapped mythic-tier
  stat lines don't wrap into an excessive number of short lines.
- Verified headlessly (disposable test, deleted after passing): built a gear row for
  a 4-stat mythic item and confirmed `clip_text` is now `false`,
  `autowrap_mode != AUTOWRAP_OFF`, and the full stat string (including the 4th stat)
  is present in `label.text` rather than being cut off.
- **Not yet visually re-confirmed in-editor** -- headless can prove the label's
  wrap/clip properties changed and the full text string is present, but not how the
  actual wrapped multi-line layout looks/scrolls in the real 920x640 panel. Worth a
  quick look next session, especially with a full inventory of mixed 1-4-stat items
  to check the `RightScroll` `ScrollContainer` still scrolls smoothly with taller rows.

## 0h. Session (2026-07-10): full balance review across player/enemy/boss stats

## 0h. Session (2026-07-10): full balance review across player/enemy/boss stats

A lot of interacting systems landed this session (NG+ scaling, the item roster
replacement, randomized rolls, the skill system, the Warrior range/defense change)
without a final holistic pass checking they still add up together. Gathered every
map's actual enemy `min_level`/`max_level`/guardian bonus-stat overrides, the gate
level requirements, and the XP curve as ground truth (not memory) and worked through
the numbers.

**What was checked and left alone (holds up fine):**
- Combined gear-DPS + skill-DPS at level ~35 in the best gear obtainable on a first
  playthrough (epic -- mythic can't drop before NG+) lands close to the ~180 DPS /
  ~60s-clear target `ultimate_boss.gd`'s HP was originally calibrated against, even
  though average-roll gear DPS alone (~154) sits under that target -- the active
  skill's own DPS contribution (~25-27 DPS at max level with auto-cast) closes the
  gap almost exactly. This wasn't planned to land there; it's a coincidence worth
  knowing about in case either side gets retuned independently later.
- `attack_speed_bonus`'s 0.9 clamp (`ATTACK_COOLDOWN_BASE * (1.0 - attack_speed_bonus)`)
  is a safe ceiling that's never actually reachable -- max realistic mythic-tier
  attack_speed sum is ~0.43, nowhere near the clamp.
- Gate boss hit-count-to-kill-player is consistent across all three gates (~3.2-3.7
  hits at their respective level thresholds), and mythic gear's *relative* power
  edge over epic shrinks a lot at high level (level itself dominates
  `total_attack_damage()`'s formula by then) -- both are naturally self-balancing,
  not something that needed a deliberate fix.
- Warrior's passive (`def`, unbounded growth with level) doesn't quietly trivialize
  damage taken even at very high levels/NG+ cycles, because NG+'s own damage
  multiplier grows unboundedly too and roughly keeps pace.
- The Warrior/Mage asymmetry the user specified directly (Warrior: more base
  defense + defensive passive + shorter range; Mage: less defense + speed passive +
  longer range) reads as a coherent tanky-bruiser vs. fragile-kiter pair, not an
  accidental imbalance -- left as specified.

**What was changed:** `ultimate_boss.gd`'s `PHASE_ATTACK_DAMAGE` was still `[45, 65, 90]`
from before this session's Warrior base_defense/passive-def additions pushed player
defense up. Once checked against the actual gate-boss pattern (Dragon Sovereign, the
guardian immediately before this fight, hits for a flat 132 -- *harder* than even this
boss's old Phase 3 of 90), the true final boss had drifted into hitting *softer* than
the boss guarding its own front door, undermining the intended climax. Re-tuned to
`[65, 100, 140]`, checked against the same ~3-4-hits-to-die pattern the three gate
bosses already establish: now ~10.6 hits in Phase 1 (room to learn the fight) down to
~3.4 hits in Phase 3 (matching/slightly exceeding Dragon Sovereign, restoring the
escalation). `RANGED_DAMAGE_FACTOR` (0.6, unchanged) scales proportionally with these,
so the ranged bolt attack's relative strength is untouched. Verified headlessly
(disposable test, deleted after passing): new base values load correctly, and NG+1's
`difficulty_multiplier()` scaling still applies correctly on top (`[98, 150, 210]`).

**Not changed, flagged as a judgment call the user can override**: whether the true
final boss *should* out-damage the gate boss right before it is a pacing opinion, not
an objective bug -- a "long endurance fight vs. a hard-hitting gatekeeper" split is
also a valid design. Went with escalating damage since that's the more common
expectation for a final boss, but worth a real playtest to confirm it feels right
rather than just "harder."

## 0g. Session (2026-07-10): visual effect for the active skill cast

## 0g. Session (2026-07-10): visual effect for the active skill cast

The active skill (§0e/§0f) was reusing the plain "attack" animation pose with no
visual tied to what it actually does -- the user asked for something that visually
matches the skill-design.png reference art instead.

- Building a real new animation set was ruled out as disproportionate: `CHARACTER_DATA`
  has no skill-cast animation slot at all, and Mage doesn't even have full
  directional *attack* poses today (see its `frame_counts` comment) -- a from-scratch
  skill animation would be a much bigger art project than what was asked.
- Instead, **the skill's own icon art (already extracted from skill-design.png) is
  spawned as a world-space pop-in/fade effect at the cast location** -- new
  `scripts/skill_effect.gd` + `scenes/skill_effect.tscn`, following the exact
  self-contained tween-then-`queue_free()` pattern `damage_number.gd` already
  established in this project (pop in with `TRANS_BACK`/`EASE_OUT` overshoot, hold
  briefly, fade out, free itself -- ~0.55s total). The icon's on-screen size is
  rescaled from its HUD-icon-sized source texture to roughly match the skill's real
  damage radius (`radius * 1.8` px), so a bigger AoE actually looks bigger.
  `player.gd`'s `_try_skill()` calls this right after `_deal_aoe_damage()`, at the
  same `target_pos` the damage query already used.
- Verified headlessly (disposable test, deleted after passing): casting the skill
  spawns a `skill_effect` node with a valid texture at the expected position, and it
  cleans itself up (no longer present in the tree) after its tween finishes.
- **Not yet manually eyeballed** -- confirm in-editor that the pop/fade reads well at
  actual gameplay zoom and doesn't look out of place next to the pixel-art character
  sprites (it's a static icon popping in, not an animated sprite).

## 0f. Session (2026-07-10): skill system leveling, base defense, auto-cast

## 0f. Session (2026-07-10): skill system leveling, base defense, auto-cast

Follow-up refinement to §0e's skill system, same session:

- **Active skill is now level-gated**, not available from level 1: locked below
  level 10 (`SkillDatabase.SKILL_UNLOCK_LEVEL`), unlocks at its base tier at 10,
  upgrades to a stronger tier at level 20 (`SKILL_LEVEL_2_AT`) -- bigger damage
  multiplier, shorter cooldown, larger radius, same icon/id (no new art per tier).
  `SkillDatabase.SKILLS[character]["skill_tiers"]` is now a 2-element array indexed
  by `skill_level_for(character_level) - 1`; `get_skill()` returns an empty dict
  while locked, which `_try_skill()` already treated as "no skill" so no new guard
  logic was needed there.
- **Passive is redesigned as a per-level scaling stat**, not a flat bonus: Warrior's
  Guardian's Resolve is `def`, Mage's Arcane Insight is `speed`, both starting at 1
  point from level 1 and gaining +1 point every 2 character levels
  (`SkillDatabase.passive_level_for()` = `1 + level/2` integer division). This
  replaced §0e's flat `+4 def`/`+10% crit_chance` design.
- **New flat per-character `base_defense`** in `player.gd`'s `CHARACTER_DATA` (5 for
  Warrior, 1 for Mage) -- folded into `_recalculate_equipment_stats()`'s `def`
  accumulator alongside gear and the passive. Warrior needed more baseline
  survivability now that its normal-attack range is halved (see §0e) and its
  passive is defense-flavored rather than the old flat bonus.
- **Passive/skill state now also refreshes on level-up**, not just on
  equip/unequip: `gain_xp()` re-runs `_recalculate_equipment_stats()` (and applies
  the resulting HP-bonus delta the same way `equip_item()`/`unequip_slot()` already
  did) whenever the level-up loop actually fires, so hitting level 10/20/every-even-
  level takes effect immediately instead of waiting for the next gear change.
- **Auto-attack mode now also auto-casts the active skill**: `_physics_process()`
  calls `_try_skill()` every frame once `GlobalState.auto_attack_enabled` is on and
  `skill_cooldown_remaining <= 0.0` and not `is_attacking` -- `_try_skill()` already
  no-ops gracefully while dead/mid-swing/on-cooldown/locked, so no new state
  tracking was needed, just an opportunistic call site next to the existing
  cooldown-ticking code.
- **HUD updated to reflect locked/leveled state live**: the Skill row shows
  "Skill: Locked (Lv. 10)" (and disables its Use button) below the unlock level,
  the current tier's name/cooldown countdown once unlocked; the Passive row now
  shows the live point value, e.g. "Passive: Guardian's Resolve (+6 def)" --
  recomputed on the same throttled timer as the quick-slot cooldown display, since
  the value now changes over time as the character levels.
- Verified headlessly (disposable test, deleted after passing): unlock/upgrade
  thresholds at exactly levels 10/20; skill stays locked and doesn't fire below 10;
  `passive_level_for()` matches the 1/2/2/3/3/6 sequence for levels 1-5,10; a fresh
  level-1 Warrior's defense is exactly `base_defense(5) + passive(1) = 6`; after
  reaching level 10 the same character's defense becomes `5 + 6 = 11` and its skill
  successfully fires; a Mage's `gain_xp()` call that levels it all the way to 100
  correctly refreshes `accessory_speed_bonus` to match `passive_level_for(100)` with
  no manual equip/unequip needed in between; and a single simulated
  `_physics_process()` tick with auto-attack on and the skill off cooldown
  auto-fired it. Two more `:=`-on-dynamic-access hangs hit again while writing
  *this* test (not the game code) -- same gotcha as §0e, same fix (plain `=`).

## 0e. Session (2026-07-10): character skill system (active skill + passive)

## 0e. Session (2026-07-10): character skill system (active skill + passive)

The user supplied a second reference sheet (`D:\WORK\PROJECT\GODOT\image\skill-design.png`,
1024x1024, a 3-col x 2-row grid: Normal Attack / Skill / Passive columns x Warrior/Mage
rows) and asked for a real skill system: each character keeps its existing normal
attack, plus a new active skill (own cooldown) and a new always-on passive.

- **Existing combat architecture researched first** (`player.gd`): both Warrior and
  Mage's "normal attack" already work identically under the hood -- `_try_attack()`
  spawns a projectile scene (`projectile_knife.tscn` vs `projectile_bolt.tscn`), there
  is no melee-vs-ranged branch in code, just different projectile scenes/ranges. There
  was no skill/passive concept anywhere and `CHARACTER_DATA` has no spare animation
  slot for one, so the new skill **reuses the existing "attack" animation pose**
  rather than requiring a whole new character sprite-sheet extraction project --
  the new reference sheet's icons are for a UI hotbar, not new character frames.
- **New `scripts/skill_database.gd`** (mirrors `item_database.gd`'s static-class
  pattern): `SKILLS` dict keyed by character id (`"warrior"`/`"mage"`), each with a
  `skill` (name, icon, description, cooldown, damage_multiplier, radius) and a
  `passive` (name, icon, description, flat `stats` bonus dict using the same stat
  keys gear already uses -- `def`/`crit_chance`/etc.).
  - Warrior: **Flame Slash** (2.5x attack damage, 55px radius in front of the
    player, 8s cooldown) / **Guardian's Resolve** (+4 def, always on).
  - Mage: **Meteor** (3x attack damage, 80px radius, targets the nearest enemy in
    400px range or a point ahead if none, 10s cooldown) / **Arcane Insight** (+10%
    crit chance, always on).
- **`player.gd` additions**: `_try_skill()` (own `skill_cooldown_remaining` float,
  ticked in `_physics_process` alongside the existing quick-slot cooldowns; gated by
  `is_attacking` the same as normal attacks so a skill cast still gets cut short by a
  movement-direction change via the existing `_cancel_attack()` path -- no new state
  machine needed). `_deal_aoe_damage()` reuses `thrown_bomb.gd`'s proven
  `PhysicsShapeQueryParameters2D` circle-query-against-the-enemy-hurtbox-layer
  pattern rather than inventing a new one. New `KEY_R` binding (following the
  existing raw-physical-keycode pattern already used for attack/quick-slots) plus a
  HUD button, both routed through the same `_try_skill()`.
  Passive stats fold into `_recalculate_equipment_stats()`/`_total_hp_bonus()`
  alongside gear bonuses -- always active regardless of what's equipped.
- **Balance ask, same session**: reduce the Warrior's normal-attack range by half so
  the new skill doesn't stack on top of an already mage-equivalent ranged normal
  attack. `projectile.gd`'s `MAX_RANGE` was a shared script-level `const` (300 for
  *both* the knife and the bolt, since they're the same script) -- changed to an
  `@export var max_range`, with `projectile_knife.tscn` overriding it to 150 and
  `projectile_bolt.tscn` left at the 300 default.
- **HUD**: new `SkillBar` section (icon + name + live cooldown countdown for Skill,
  icon + name for Passive, no cooldown) added below the existing `QuickSlotBar`,
  following its exact text-row layout/style. Icons are set once in `_ready()` based
  on `GlobalState.selected_character` (never changes mid-session).
- **Bug found and fixed opportunistically**: `RARITY_RANK` (used to decide whether a
  newly-picked-up item is an "upgrade" worth auto-prompting equip for) only had
  `common`/`rare`/`epic` -- missing `mythic` entirely (added when mythic gear shipped
  in §0b but this table was never updated), so a mythic drop's rank fell back to `0`,
  same as common, and would never trigger the upgrade prompt over an equipped
  rare/epic item. Added `"mythic": 3`.
- **Extraction pipeline reused, but the checker colors were different**: this sheet's
  checkerboard is a darker two-tone pattern (~85/~135 gray) than the item sheet's
  (~163/~205) -- had to re-histogram and update the reference values before reusing
  the same dual-reference-match + bounded-dilation pipeline from §0c. One icon
  (`skill_icon_flame_slash.png`) needed a manual follow-up crop: the largest-connected-
  component pass kept a thin, disconnected-looking black rectangle (almost certainly a
  cell-divider-line remnant bridged into the main blob via a stray pixel path) below
  the actual sword art -- fixed by hard-cropping to the real content's row-opacity
  profile rather than trusting the component result for that one frame. The two
  "Normal Attack" icons (dagger, purple bolt) were extracted but are unused for now --
  there's no existing HUD slot for the normal attack, only Skill/Passive got new UI.
- Verified headlessly (disposable test, deleted after passing -- and after killing two
  zombie Godot processes caused by the now-familiar `:=` type-inference silent-hang
  gotcha hitting `var x := y.instantiate()` and `var x := dynamically_typed_var.field`
  patterns *inside the test script itself*, not the game code): both characters'
  skill/passive data load correctly; knife `max_range` is 150, bolt's is still 300;
  `RARITY_RANK` ranks mythic above epic; Warrior's passive `+4 def` applies with zero
  gear equipped; casting Flame Slash on a nearby enemy actually reduced its HP by the
  expected `roundi(3 * 2.5) = 8` damage; and calling `_try_skill()` again immediately
  after did not reset or re-trigger the cooldown.
- **Not yet manually playtested in-editor** -- headless tests proved the data and
  damage math, not how the `R` key/HUD button feel to actually use, whether Flame
  Slash's 55px radius reads right visually with no dedicated VFX (it reuses the
  normal attack animation pose), or whether Meteor's nearest-enemy targeting picks
  sensible targets in a real fight.

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
3e. **Manual playtest the skill system, its leveling curve, and the Warrior range/defense rebalance** (see §0e and §0f) — press `R` (and the HUD button) below and above level 10/20 to feel the lock/unlock/upgrade transitions and confirm the HUD text reads clearly; watch the Passive row's point value climb across a few level-ups; confirm auto-attack mode's auto-cast doesn't feel spammy or awkwardly timed; and confirm the Warrior's shorter knife range (`max_range = 150`) reads as intentionally melee-ish now that it also has more base defense (`base_defense: 5` in `CHARACTER_DATA`), rather than just feeling nerfed. `skill_database.gd`'s tier `cooldown`/`damage_multiplier`/`SKILL_UNLOCK_LEVEL`/`SKILL_LEVEL_2_AT` and `player.gd`'s `base_defense` values are the knobs to retune.
3f. **Eyeball the skill cast visual effect** (see §0g) — confirm the icon pop/fade at the cast location reads well at real gameplay zoom for both Flame Slash and Meteor, and doesn't feel visually disconnected from the pixel-art character sprite. `skill_effect.gd`'s `POP_DURATION`/`HOLD_DURATION`/`FADE_DURATION` and the `radius * 1.8` size formula in `player.gd`'s `_spawn_skill_effect()` are the knobs to retune.
3g. **Playtest the true final boss's damage rebalance** (see §0h) — the math checks out on paper (~3.4 hits to die in Phase 3 vs. the gate bosses' established ~3.2-3.7 pattern), but confirm it actually feels like an appropriately climactic final fight rather than just "harder than before" for its own sake. `ultimate_boss.gd`'s `PHASE_ATTACK_DAMAGE` (`[65, 100, 140]`) is the knob if it needs softening or a further push.
3h. **Eyeball the inventory panel with a full, mixed inventory** (see §0i) — open the bag with several 1-4-stat items at once, confirm the wrapped multi-line rows and the wider 920x640 panel look right and the list still scrolls cleanly.
3i. **Playtest the auto-cast target-check fix** (see §0k) — stand somewhere with no enemy nearby in auto-attack mode and confirm the skill no longer fires; then confirm it still auto-casts normally the instant an enemy wanders into range, and that a manual `R`-press still swings at empty air like before.
3j. **Playtest the final boss's reworked Phase 1 geometry** (see §0k) — confirm the boss can now actually land its melee hit in every phase (not just Phase 1) and no longer visibly overlaps/shoves into the player while chasing. `AttackShape`'s radius (70, `ultimate_boss.tscn`) and `CHASE_STOP_DISTANCE` (60, `ultimate_boss.gd`) are the knobs if the reach still feels off.
3k. **Confirm the victory popup reopens correctly** (see §0k) — beat the final boss, pick "Continue Playing", leave the map, then walk back in and confirm the victory/NG+ popup reappears rather than the boss silently not existing with no way to start NG+.
3l. **Playtest the reworked per-copy gear system end-to-end** (see §0k) — this is the biggest change of the session and touches equip/unequip/discard/save-load. Farm a few duplicates of the same epic item and confirm the inventory now shows them as separate rows with genuinely different stats (not one collapsed "x3" row); equip one, then the other, and confirm the swapped-out copy reappears in the bag with its original roll intact (not rerolled); discard a specific copy and confirm only that one disappears; save, reload, and confirm equipped gear and bag contents survive the round-trip. Note: gear equipped under the old save format will be empty on first load after this update (documented, not a bug) — re-loot it once.
3m. **Playtest NG+'s new full reset** (see §0l) — start New Game+, confirm level/gear/consumables are actually gone and the character starts at level 1 with base stats only, and play at least the first couple of map-1 fights to gauge whether `difficulty_multiplier()`'s scaling (originally tuned against an overleveled, fully-geared NG+ player) is still fair for a fresh level-1 character. `GlobalState.difficulty_multiplier()`'s `0.5 * ng_plus_level` formula is the knob if NG+1 now opens too hard.
4. **No feature-parity backport expected** with Endless Archer RPG — the two projects have deliberately diverged (const-Dict vs per-Resource data, different combat pacing). If a specific polish technique from that project (e.g. the `ShakeCamera`/`offset`-tween pattern, `WorldEnvironment` Glow, or projectile pooling if this game ever needs a bullet-heavy skill) seems worth having here too, treat it as a fresh, deliberate decision each time — not an assumed sync.
5. **This doc itself** — update it directly the next time meaningful work lands here, rather than letting it drift stale; there's no separate memory-system record of this project's status, so this file is the authoritative one.
