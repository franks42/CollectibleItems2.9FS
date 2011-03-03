"Slightly Altered" Lime's CollectibleItems Example
==================================================

*  You should be able to clone this and run it in the simulator after you added the missing lime-2.9 lua files. Make sure to copy this set of files inside a collectible items directory such that that directory is overwritten with what is in this archive - in that way you should have all needed files in place.

*  Uses a name-object registry to allow for a simple refer-by-name in Tiled-properties (NamedObject.lua)

*  All Button and Event Handlers are registered right after they are defined and referred to by name

*  ui.lua has been changed to allow one to pass display objects for the default and over properties, and to pass the button handlers by name, which are then resolved at the time the button is realized.

*  Lime property listener "registerNameObject" to register an object with a name

*  Lime property listener "localEventHandler" to register a local event handler with the object.sprite

*  Lime property listener "globalEventHandler" to register a global event handler with the object.sprite

*  Lime property listener "tableEventHandler" to register an handler as a table-property

*  All event handlers are stitched together thru declarations in the Tiled properties

*  No global variables are used but the name-object system to find your "player"

*  It uses the static tile layer for ground and walls

*  It uses tiled-object for the buttons and a special "UIButton" type handler to declare the button's associated tiles and handlers. It includes a tileset/spritesheet with the buttons used.

*  All tile-less objects have been removed

*  Started to use json-formatted property values - works very well as it gives you real Lua objects back with all the syntax and type checking and such - definitely recommended.

*  Only a few lines of code changes in the lime-map.lua code, which is included - small bug-fixes that had to do with a few lacking tonumber() castings/coercions. (Use kdiff3 to see the changes with respect to the lime-2.9 distro  -  "kdiff3" is very nice and useful tool!!!)

Issues
------

*  using individual tiles to make up the ground makes the ground "bumpy" as our little guy seems to fall over tile-borders - not sure why that is happening

*  the little guy is still a "tile" instead of a tile-object - should be a tile-object - needs more work - how can you incorporate tile property settings easily with tile-objects?  The property listeners do not seem to work with tile-objects...

*  event handlers are very sensitive to display objects that are "removeSelf'ed" behind their back. Ideally you would detect that inside the handler, and remove the handler - not so easy to do that generically as you cannot easily introspect the handler function you are in, and neither can you guess easily what the target was where it was registered...

*  the name-object system can help to detect "orphaned" display objects - meaning display objects that were removeSelf'ed, but are still around because the code is holding references to the skeleton that is left - this is a nasty problem though.

*  the next big problem to attack is a more formalized way to deal with state. The example code already tried to associate state with the named sprite-sequence, which is a good first step. But state is also associated with the active/installed event handlers and other state variables. It would be nice to be able to declare all that also and keep it outside of the imperative/procedural code... requires some form of standardization of names/structures...


