# SOL phase-portal authoring

SOL phase portals are an opt-in, player-owned illusion primitive. They are for
one doorway that begins as normal local geometry and, after a deliberate forward
entry and turn-around, becomes a remote exit. They do not change the physical
map or automap.

## Source doorway

Author the source as an ordinary two-sided doorway between the approach and a
real local dead-end room. The source must be that room's only route back to the
ordinary map: do not leave a lateral local connection that lets the player
bypass the doorway. Give that linedef a stable normal map ID and the stock
teleport portal special:

```udmf
id = 1201;
special = 156; // Line_SetPortal
arg0 = 1202;   // destination anchor ID
arg1 = 0;
arg2 = 1;      // PORTT_TELEPORT
arg3 = 0;
arg4 = 0;
user_sol_phase_role = "source";
user_sol_phase_group = 7;
user_sol_phase_inside_side = 0;
user_sol_phase_arm_depth = 384.0;
user_sol_phase_entry_dot = 0.2;
user_sol_phase_reveal_dot = 0.3;
```

`PORTT_TELEPORT` traverses side 0 to side 1. Flip the linedef in the editor so
the room interior is side 0, then retain `user_sol_phase_inside_side = 0`.
The arm depth must fit inside the real local room before its dead end. Keep the
approach, doorway span, and the route through the arm depth free of solid props
so a failed walk is never mistaken for the phase predicate.

## Destination anchor

The remote location gets a matching two-sided linedef with a normal map ID and
only the destination metadata:

```udmf
id = 1202;
user_sol_phase_role = "destination";
user_sol_phase_group = 7;
```

Do not put `Line_SetPortal`, portal arguments, or a reverse destination on that
line. It remains a local doorway before, during, and after the phase traversal.
Its vertex/sidedef order is still significant: the stock teleport transform
uses the source and anchor spans to place the remote view and exit. Orient the
anchor for the desired source-to-anchor transform, then verify that the
revealed view is clean in both native renderers. Flipping this ordinary linedef
does **not** make it a reverse portal.

## Required behavior to verify

1. A player starts away from the source and sees an ordinary local doorway.
2. Forward movement while looking inward enters locally; moving past the arm
   depth still leaves the doorway local until the player looks outward.
3. Looking outward reveals the remote view and enables only the source's
   inside-to-outside traversal.
4. The successful traversal resets the player state in that tic. Turning around
   at the anchor shows its local geometry, and probing it in either direction
   stays local.
5. Returning to the source and backing in while looking outward leaves it
   dormant; a later genuine forward entry can run the cycle again.

The engine stores this state per player and phase group. In v0.4, non-player
movement, player-owned projectiles, unowned traces, sound, and AI sight remain
deterministically local; do not use a phase portal as shared multiplayer or AI
topology until that policy is expanded deliberately.
