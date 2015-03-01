# AbilityValues

Adds an additional value to the ability icon

[Preview](http://puu.sh/ge6Bz/7c0b44adab.jpg)

###### Usage

* Put the files in their correct folders
* Use `FireGameEvent( 'ability_values_force_check', { player_ID = pID } )` to force a check on the currently selected unit w/o waiting for dota selection events to fire.
* Use ```FireGameEvent( 'ability_values_send', { player_ID = pID, hue_1 = -80, val_1 = 90, bri_1 = -20 } )``` to show overlay over the 1st ability with hue of -80 and brightness of -20.
* Use ```FireGameEvent( 'ability_values_send', { player_ID = pID, <stuff> } )``` to show item overlay
* Huehue_1-6 goes from -180 to 180. Leave empty or use 0 to use the default hue set in the AbilityValues_settings.kv
* Bri_1-6 goes from -100 to 100. Leave empty or use 0 to use the default brightness set in the AbilityValues_settings.kv
* Val_1-6 goes from iHaveNoIdea to iDontKnow. Leave empty or use 0 to hide, **use -1 to show value of 0!**

###### AbilityValues_settings.kv
* **defHue**: default hue. Leave 0 for green.
* **defBri**: default brightness.
* **serverCommand**: the ConVar that needs to be registered in Lua. SWF sends the entity index.
* **debug**: set to true for trace spamming in console. Set to something else for no tracespam.

###### Example Convar
* **This is not the complete thing that works dynamically per unit. It's just an example that fires on every owned-unit selection.**
* Use [EntIndexToHScript](https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/API/Global.EntIndexToHScript) with the entity index received to do your logic

```
Convars:RegisterCommand( "<command_name_from_kv>", function(name, _entityIndex)
  local cmdPlayer = Convars:GetCommandClient()
  if cmdPlayer then
    FireGameEvent( 'ability_values_send', { player_ID = pID, hue_2 = -80, hue_3=90, hue_4 = 130, hue_5 = -140, val_1 = 352, val_2 = 35, val_3 = 45, val_4 = 180, val_5 = -1, bri_1 = -50, bri_4 = 25 } )
  end
end, "description", 0 )
```

###### Example by [Noya](https://github.com/mnoya)
* You can check the code [here](http://www.hastebin.com/wodiyidemo.lua)
*  +Noya • "Example to show the ability values defined under a *"lumber_cost"* AbilitySpecial for abilities of a unit named *human_peasant* ".
*  [Example result in Noya's case](http://puu.sh/gegQh/f9526c4adb.jpg)

###### Credits
* Thanks [Noya](https://github.com/mnoya) for the request and general counsel, along with the example
