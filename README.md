# AbilityValues

Adds an additional value to the ability icon

[Preview](http://puu.sh/ge6Bz/7c0b44adab.jpg)

###### Usage

* Put the files in their correct folders
* Example in Lua from the preview: ```FireGameEvent( 'ability_values_send', { player_ID = pID, hue_2 = -80, hue_3=90, hue_4 = 130, hue_5 = -140, val_1 = 352, val_2 = 35, val_3 = 45, val_4 = 180, val_5 = -1, } )```
* Huehue goes from -180 to 180. Leave empty or use 0 to use the default hue set in the AbilityValues_settings.kv
* Val_1 to 6 goes from 1 to iDontKnow. Leave empty or use 0 to hide, **use -1 to show value of 0!**

###### AbilityValues_settings.kv
* **defHue**: default hue. Leave 0 for green.
* **serverCommand**: the ConVar that needs to be registered in Lua. SWF sends the entity index.
