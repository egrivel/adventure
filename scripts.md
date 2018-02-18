# Scripts

In order to create an adventure, a script file must be created. The script
file is a JSON file (single-line `//` comments allowed) that defines the
adventure.

## Top-level elements

The top-level JSON object has the following attributes:

`type`: should be defaulted to `"planet"`. Not yet used.

`id`: should be a unique ID. Not yet used

`name`: name of the thing. Not yet used.

`default-location`: ID of the location where the game should start. This can
be the ID of any of the locations defined in the `locations` list.

`locations`: array of "Location" objects (see below).

## Location object

The Location object defines a single location ("room") in the game. It can
have the following attributes:

`id`: unique ID for the location. Required, should be unique within the
world.

`name`: (short) display name for the location. Required.

`descr`: (long) description for the location. Required.

`actions`: object with actions. The attribute name within the object is the
verb. The value is the action script that must be executed. See 
_Actions_ below.

`items`: array with items in the room. Optional. See the description of
_Items_ below.

`exits`: array with exits from the room. Optional, but without exits, how
can the player leave the room? See _Exits_ below.

## Item object

## Exit object

## Actions