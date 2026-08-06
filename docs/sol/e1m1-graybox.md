# E1M1 Graybox Checklist

Working title: **Hangar: Arrival**

## Required zones

1. Arrival lock
2. Hangar floor
3. Security spine
4. Processing and maintenance
5. Reactor annex
6. Exterior breach
7. Command return
8. Transition seam

## Layout requirements

- The command balcony is visible from the first major room and reached near the end.
- The critical path remains legible without objective markers.
- At least two optional loops return to a known landmark.
- At least one earlier action creates a later shortcut.
- Windows or overlooks preview two future spaces.
- The final seam has a documented origin, angle, width, floor height, ceiling height, lighting direction, and door state for E1M2 alignment.

## Story requirements

- Three optional environmental records or scenes.
- Security measures face deeper into the base.
- Evacuation and containment instructions visibly conflict.
- The command return reveals that the event was detected before player arrival.
- Temporary story markers use stable IDs: `SOL.E1M1.STORY.<NAME>`.

## Encounter requirements

- Introductory contact and delayed flank.
- Security crossfire with elevation.
- Reinforcement event that reuses a traversed route.
- Reactor horde with front, rear, and elevated pressure stages.
- Command return that repopulates previously safe sightlines.
- Final encounter combines movement with an objective interaction.

Profiles:
- `story`: 70–100 total enemies.
- `standard`: 140–190 total enemies.
- `horde`: 260–400 total enemies with staged activation.

No ordinary encounter should exceed 80 fully active monsters without a recorded performance test.

## Validation requirements

- Start and finish from a clean game.
- Save/load before, during, and after each major event.
- Test doors with required enemies on both sides.
- Test sequence breaks and shortcut use.
- Confirm no unreachable enemy can permanently block progression.
- Record benchmark saves for major horde stages.
- Confirm package contains no commercial IWAD resources.

## v0.1.0 exit gate

- Complete critical path.
- No known soft locks.
- All required events have stable IDs.
- All profiles remain inside the active-monster budget.
- Transition seam metadata is ready for the two-map prototype.