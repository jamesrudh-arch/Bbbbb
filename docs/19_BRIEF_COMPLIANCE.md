# LEVERAGE — Requirements Compliance Matrix
### Measured against the user's gameplay brief, 23 Nov 2026

Legend: **✅ BUILT** (works, verified) · **🟡 PARTIAL** (exists but below brief) · **❌ MISSING** (does not exist)

---

## 1. THE PROTAGONIST & MOVEMENT

| Brief requirement | Status | Evidence / gap |
|---|---|---|
| Third-person playable protagonist **Marcus** | ✅ | Renamed from Emeka this session. `content.gd` → `"marcus"`, 12 dialogue refs |
| Walk / run / sprint | ✅ | `player.gd` — SPRINT_SPEED, acceleration smoothing |
| Jump | ✅ | `Input.is_action_just_pressed("jump")` |
| Crouch | ✅ | `is_crouching`, CROUCH_SPEED |
| Dodge | ✅ | Dodge roll with i-frames |
| Climbing / **vaulting** | ❌ | No ledge detection, no vault. Needs a raycast + mantle system |
| Enter / exit vehicles | ✅ | `driver.gd` |
| Smooth animation transitions | 🟡 | Blend tree exists; run cycle is *walk at 1.55–2.35×* (real run clips unusable) |
| Camera: exploration / combat / aiming / driving | 🟡 | One rig, pitch-tuned. No combat or aim framing modes |

**Verdict: ~70%.** Movement is the strongest part of the project. Missing vault/climb and per-state camera.

---

## 2. COMBAT

| Brief requirement | Status | Evidence / gap |
|---|---|---|
| Light attacks | ✅ | |
| Heavy attacks | ✅ | |
| Punch combinations | 🟡 | Single punch clip reused; no true combo tree |
| Kicks | ✅ | Roundhouse clip |
| Blocking | 🟡 | Block state exists, no guard-break interactions |
| Dodging | ✅ | |
| **Parrying** | 🟡 | `_counter_window` exists; no parry window tuning, no flash/vfx |
| Counterattacks | 🟡 | Grappling branch only |
| Grappling | 🟡 | Branch exists; no grab animation |
| **Throws** | ❌ | No throw animation or state |
| **Ground combat** | ❌ | No downed state for enemies |
| **Environmental takedowns** | ❌ | Not implemented (Sleeping Dogs signature) |
| **Finishing moves** | ❌ | Not implemented |
| Different fighting disciplines | 🟡 | 5 named; share one code path with 3 multipliers |
| Weapon-based melee | 🟡 | `slash` clip on weapon discipline |
| Firearms | ✅ | Pistol verified 80→58→36 HP |
| Stealth takedowns | ❌ | No stealth state at all |
| Enemy awareness / reactions | 🟡 | 3 states only |
| Unlock new techniques | ❌ | No technique unlock tree |

**Verdict: ~40%.** This is the brief's most detailed section and the weakest system. The Style Rank addition is unbuilt.

---

## 3. ENEMY INTELLIGENCE

| Brief requirement | Status | Gap |
|---|---|---|
| Different enemy behaviours / difficulty | ❌ | All enemies identical except health |
| Investigate suspicious situations | ❌ | No investigate state |
| React to player behaviour | ❌ | Only proximity chase |
| Flanking / cover / reloading / retreating / calling help | ❌ | **None.** `actor.gd` = idle/wander/chase |

**Verdict: ~10%.** Currently enemies walk at you and swing. This breaks the "must not stand waiting to be hit" standard.

---

## 4. VEHICLES & DRIVING

| Brief requirement | Status | Gap |
|---|---|---|
| Cars | 🟡 | **7 Kenney models, ~2,000 tris each** — placeholder grade |
| Motorcycles | 🟡 | Present in `VEHICLE_TYPES` |
| Enter / exit | ✅ | |
| Acceleration / braking / steering | ✅ | VehicleBody3D |
| Collisions | ✅ | |
| Vehicle damage | 🟡 | Basic |
| Camera movement | ✅ | |
| **Vehicle variety & presentation (Forza-level)** | ❌ | No interior, no dash, no mirrors, no gears |
| Police pursuits with pressure | 🟡 | 92-line police system, spawns near player |

**Verdict: ~35%.** The single largest visual failure against "realistic."

---

## 5. THE SMARTPHONE — ★ strongest system

| Brief requirement | Status |
|---|---|
| Contacts | ✅ |
| Incoming calls with real ringing | ✅ verified screenshot |
| Answer / ignore | ✅ ANSWER / DECLINE |
| Outgoing calls | 🟡 |
| Text messages | ✅ threads, read/unread, timestamps |
| Notifications | ✅ |
| Mission communications | ⚠️ 7 call scripts written, **not yet triggered by missions** |
| Map access | ✅ (separate map, not inside phone shell) |
| Natural, not decorative | ✅ story-gated scheduler, quiet after combat |

**Verdict: ~85%.** The only system near brief standard.

---

## 6. MISSIONS & STORY

| Brief requirement | Status | Gap |
|---|---|---|
| Cinematic missions | ❌ | No cutscene system beyond static text |
| Objectives / progression / rewards | ✅ | 12 missions defined with objectives |
| Dialogue scenes | 🟡 | Text lines only, no staged scene |
| Investigation / rescue / negotiation / stealth mission types | ❌ | Objective types are reach/talk/fight/escape/drive/steal |
| Betrayals, alliances, consequences | 🟡 | Flags only, no branching |
| Side missions | ✅ | 10 side jobs defined |
| Story reveals the kidnapping | 🟡 | Premise now correct; **missions do not yet dramatise it** |

**Verdict: ~45%.**

---

## 7. WORLD — CINDER CITY

| Brief requirement | Status | Gap |
|---|---|---|
| Six+ connected districts | ✅ | **7 now** — added **Dockside** (waterfront) this session |
| Residential | ✅ | Ash Row |
| Commercial | ✅ | Guttermarket |
| Nightlife | ✅ | Neon Mile |
| Industrial | ✅ | Iron Yard |
| **Waterfront / docks** | ✅ | **Dockside — added this session** (brief required it) |
| Distinct atmosphere per district | 🟡 | Palettes defined; geometry still similar |
| Road networks | ✅ | 40 m block grid, real intersections |
| **Trees** | ❌ | **ZERO. None in the project.** Brief implies foliage |
| Neon signs / illuminated ads | 🟡 | Emissive materials, no signage geometry |
| Rain-soaked reflective streets | 🟡 | Weather exists; no wetness on materials |
| Detailed interiors | 🟡 | 8 exist, working, with vendors |
| Shipping docks | ✅ | District added; **geometry not yet built** |

**Verdict: ~50%.**

---

## 8. NPC & WORLD SIMULATION

| Brief requirement | Status | Gap |
|---|---|---|
| Pedestrians walk, talk, use phones | ❌ | 25 wanderers, no animations beyond walk |
| Visit locations / routines | ❌ | No schedule system |
| React to disturbances | ❌ | No reaction system |
| Traffic behaves appropriately | 🟡 | 46 lines, drives waypoints |
| Police respond to crimes | 🟡 | Heat threshold only |
| Important NPCs with identities | 🟡 | 16 named, no routines/dialogue trees |
| World alive without the player | ❌ | No simulation |

**Verdict: ~15%.** "Not populated by characters who simply stand around" — currently they simply walk around.

---

## 9. POLICE & CRIME

| Brief requirement | Status |
|---|---|
| Crime detection | 🟡 heat increments |
| Suspicion | ❌ |
| Pursuits | 🟡 |
| Search behaviour | ❌ |
| Escaping / hiding | 🟡 |
| **Not spawning beside the player** | ❌ **violates the brief** |
| Roadblocks / arrests / escalation | ❌ |

**Verdict: ~25%.**

---

## 10. PROGRESSION, ECONOMY, FACTIONS

| Brief requirement | Status |
|---|---|
| XP / levels / health / armour | ✅ |
| Money | ✅ |
| Reputation / trust | ✅ 6 factions with standing |
| Shops / purchases | ✅ 8 interiors, SHOP_ITEMS |
| Outfits / clothing | 🟡 |
| Weapon customisation | ❌ |
| Consequences between factions | 🟡 trust values only |

**Verdict: ~60%.**

---

## 11. UI / MOBILE

| Brief requirement | Status |
|---|---|
| Touch controls, correct layout | ✅ |
| X punch / Y heavy / A kick / B dodge | ✅ mandated layout held |
| Minimap | ✅ |
| Health / armour / ammo | ✅ |
| Consistent across states | 🟡 |
| Professional, clean | 🟡 functional, not premium |
| Full map with waypoints | ✅ built this session |

**Verdict: ~70%.**

---

## 12. AUDIO & CINEMATICS

| Brief requirement | Status |
|---|---|
| City ambience, traffic, weather | 🟡 generated loops |
| Weapons, engines, footsteps | 🟡 |
| Phone ringing | ✅ generated ringtone |
| Music reacting to state | 🟡 3 tracks |
| Studio intro | ❌ **not built** |
| Opening cinematic | ❌ **not built** |
| Dialogue | ❌ **none recorded** |
| Mission sequences / transitions | ❌ |

**Verdict: ~30%.** No dialogue at all is a major hole for a crime drama.

---

## OVERALL

| Area | Score |
|---|---|
| Phone | 85% |
| Map | 85% |
| Movement | 70% |
| UI | 70% |
| Progression | 60% |
| World | 50% |
| Missions | 45% |
| Combat | 40% |
| Vehicles | 35% |
| Audio/Cinematics | 30% |
| Police | 25% |
| NPC sim | 15% |
| Enemy AI | 10% |

**Weighted: roughly 45% of the brief.** A functioning prototype with a strong foundation and a long build ahead.

### The five things that most violate the brief
1. **Enemy AI** — 3 states. The brief demands tactics, flanking, cover, retreat, reinforcements.
2. **Vehicles** — 2,000-triangle placeholders against a Forza Horizon reference.
3. **Trees** — zero, in a city brief that requires atmospheric streets.
4. **Cinematics** — no intro, no dialogue, no staged scenes against a Mafia reference.
5. **NPC simulation** — 25 passive wanderers against Sims 4 / Hitman / Watch Dogs references.

### Fixed this session
- Protagonist renamed to **Marcus Adeyemi** everywhere (code + all dialogue)
- Story re-anchored: **Chidi kidnapped**, not a debt
- District name collision resolved: Cinder Line → **Railhead**
- **Dockside** waterfront district added (brief required docks; previously absent)
- Tests updated 6 → 7 districts: **112 passed, 0 failed**
