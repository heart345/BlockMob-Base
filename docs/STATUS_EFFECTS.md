# BMB Status Effects

Server module: `gmod_addon/lua/bmb/sv_status_effects.lua`.

## Core Rules

- Effects live on the target entity in `ent.BMBStatusEffects`.
- `BMB.Status.Apply(target, effectType, params)` is the only public apply path.
- One global `Think` hook ticks all active effects. Do not add per-effect timers.
- Same effect type refreshes duration and keeps the strongest value; it does not stack duplicate rows.
- Stat effects must recompute from a captured baseline plus all active effects:
  - movespeed = baseline speed * all active movespeed multipliers + adds
  - attack damage = baseline damage * multipliers + adds
  - never multiply the current field repeatedly.

## Implemented Effects

- `poison`: DoT, defaults to `interval = 1.0`, `dps = 2`, nonlethal like MC poison.
- `slowness`: `stat_mult` on `movespeed`, default `mult = 0.6`.
- `weakness`: `stat_add` on `attack_damage`, default `delta = -4`.

## Weakness Caveat

BMB mobs can have `AttackDamage` / `MeleeDamage` recomputed directly. Players cannot: their melee damage is decided inside their active GMod weapon.

For players, weakness is handled only in the global `EntityTakeDamage` hook by checking whether `damageInfo:GetAttacker()` is a weak player and calling `damageInfo:ScaleDamage(scale)`. Do not try to mutate player weapon fields.

## First Consumer

`bmb_cave_spider` inherits `bmb_spider`, uses the converted `models/mcgm/cave_spider/cave_spider.mdl`, narrows collision to `Vector(-13, -13, 0)` / `Vector(13, 13, 22)`, and applies `poison` on confirmed melee hits.

The pathfinder already receives `mob = self`; passability calls `mob:IsBMBPathCellPassable(cell)`, which reads `CollisionMins/Maxs` through `GetBMBPathHullRadius()`. Cave spider's narrow collision therefore affects A* planning, not only movement-time traces.

## Second Consumer

`bmb_bogged` inherits `bmb_skeleton`, uses the converted `models/mcgm/bogged/bogged.mdl`, and keeps the shared skeleton ranged AI, bow drawing, strafe, retaliation, and arrow projectile.

Model note: `mc2source` keeps Bogged on the default `bogged.geo` geometry and composites `bogged.png + bogged_clothes.png` into one VTF; it intentionally does not merge `bogged_armor.geo`.

`bmb_arrow` now exposes `NotifyBMBArrowHit()` after a confirmed creature hit. Bogged implements `OnBMBArrowHit()` and applies `poison` with `source = self`; Stray applies `slowness` for 5 seconds; Parched applies `weakness` for 5 seconds. Ordinary Skeleton arrows do not define that hook, so their arrows remain plain damage. Player arrow hits also play the shared MC `bmb/damage/hit1-3.ogg` sounds.
