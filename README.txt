This mod implements a simple approach to making the various liquid node types (water, lava) behave in a more realistic manner. In a nutshell, it sets an Active Block Modifier running for liquid nodes that implements the following behavior:

* If there is a "flowing" node below the "source" liquid block, swap the liquid block with the flowing node (the liquid drops)
* Else if there is at least one "flowing" node beside the "source" liquid block, swap with a random flowing node beside it.

This causes "source" blocks for liquids to randomly shuffle around when they don't completely fill a horizontal layer, and causes them to drain rapidly down holes or flow rapidly down hillsides. Normal "flowing" behaviour is unchanged so even though this mod is just moving cubes around the surface of the water looks reasonably smooth. The ABM only runs for blocks that are adjacent to flowing nodes and does very few calculations so it's also reasonably lightweight - I'm essentially borrowing the engine's built-in liquid flow detection to determine when my own code needs to run.

Each type of liquid can have this behaviour enabled independently of each other. By default lava is configured to flow more slowly than water, but this can be changed in the mod's settings.

Damp Clay Counters Ocean Loss
=============================

If basic water is set as dynamic, it loses its "renewability" - water nodes don't replicate like they normally do. If you are concerned about the global water level dropping over time as water pours down into undersea caverns, or just generally don't like the idea of water being a finite resource (even with an ocean's worth to start with), this mod includes an optional feature that turns natural clay deposits into "springs". Clay deposits get an Active Block Modifier that checks if there's air or shallow water above them and refills them with newly spawned water source blocks.

If this clay is dug out by players and reconstituted into clay blocks elsewhere, the "spring" behaviour won't occur for these - it only happens for clay spawned by mapgen while this feature is enabled. (In technical terms, when clay springs are enabled the map generator replaces generated clay with an otherwise identical "damp clay" node type that drops regular clay when dug. The ABM only affects this "damp clay" node type.)

There's also a "spring" block that's available only via the creative menu or /give command. This block has an ABM that ensures there's always a single block of water generated directly above it, regardless of where the block is placed.

Note that other than this clay spring feature and the override of water's "renewability" this mod doesn't affect any default node definitions, so any other mods dealing with liquids should still function as they did before. If you disable any of the liquid types they will just "freeze" in whatever position they were in at the time.