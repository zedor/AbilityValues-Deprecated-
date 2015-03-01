package  {	
	
	import flash.display.MovieClip;
	
	//valve imports
	import ValveLib.Globals;
	import ValveLib.ResizeManager;
	
	// other imports
	import flash.utils.getDefinitionByName;
	import flash.utils.getQualifiedClassName;
	import flash.utils.getQualifiedSuperclassName;
	import flash.events.MouseEvent;
	import flash.text.TextField;
	import flash.display.DisplayObject;
	import flash.display.Bitmap;
	import flash.geom.Point;
	import flash.text.TextFormat;
	import fl.motion.AdjustColor;
	import flash.filters.ColorMatrixFilter;
	import flash.events.TimerEvent;
	import flash.utils.Timer;
	
	public class abilityValues extends MovieClip {
		
		//valve elements
		public var gameAPI:Object;
		public var globals:Object;
		public var elementName:String;
		
		// maximum number of shown abilities and items per unit
		private var abMax:int = 6;
		private var itemMax:int = 6;
		
		// where we store our ability and item overlays
		private var lmCost:Object = new Object;
		private var itemCost:Object = new Object;
		private var holder:MovieClip = new MovieClip;
		
		// def txFormat
		private var txFormat:TextFormat = new TextFormat;
		
		//last selection
		private var lastSelect:int;
		private var lastArgs:Object;
		private var lastItemArgs:Object;
		
		// kv load vars
		private var defHue:int;
		private var defBri:int;
		private var serverCommand:String;
		private var debug:Boolean; // traces
		
		//volvo is stoopid so we use timers nao, and something that holds our arguments while we wait for valve to get their shit together
		private var bestTimer:Timer;
		private var holdArgs:Object;
		private var bestItemTimer:Timer;
		private var holdItemArgs:Object;
		
		// color stuff
		private var color:AdjustColor = new AdjustColor();
		private var filter:ColorMatrixFilter;
		
		// unused constructor
		public function abilityValues() {
		}
		
		// send command to server along with the entity, or use last selected if it didn't change
		// "dota_player_update_selected_unit"
		// "dota_player_update_query_unit"
		private function dotoEventHandle(args:Object) {
			var pID = globals.Players.GetLocalPlayer();
			if( debug ) trace("[AbilityValues] Unit click detected");
			if( globals.Players.GetQueryUnit(pID) != -1 ) {
				if( debug ) trace("[AbilityValues] Unit queried, hide overlay");
				hideMe();
			} else if( globals.Players.GetSelectedEntities(pID)[0]!=null && globals.Players.GetSelectedEntities(pID)[0]!=lastSelect ) {
				lastSelect = globals.Players.GetSelectedEntities(pID)[0];
				if( debug ) trace("[AbilityValues] sending server command ", serverCommand, " with entity #: ", lastSelect);
				gameAPI.SendServerCommand( serverCommand + " " + lastSelect );
			} else if( globals.Players.GetSelectedEntities(pID)[0]!=null && globals.Players.GetSelectedEntities(pID)[0]==lastSelect ) {
				if( lastArgs != null ) prepareDelay(lastArgs);
				if( lastItemArgs != null ) prepareItemDelay(lastItemArgs);
			}
		}
		
		// send command to server along with the entity, dont use last selected
		// "ability_values_force_check"
		private function sendEnt(args:Object) {
			var pID = globals.Players.GetLocalPlayer();
			
			if( pID == args.player_ID ) {
				if( debug ) trace("[AbilityValues] \"ability_values_force_check\" received");
				if( globals.Players.GetQueryUnit(pID) != -1 ) {
					if( debug ) trace("[AbilityValues] \"ability_values_force_check\" - Unit queried, hide overlay");
					hideMe();
				}  else if( globals.Players.GetSelectedEntities(pID)[0]!=null ) {
					lastSelect = globals.Players.GetSelectedEntities(pID)[0]; 
					if( debug ) trace("[AbilityValues] \"ability_values_force_check\" - sending server command ", serverCommand, " with entity #: ", lastSelect);
					gameAPI.SendServerCommand( serverCommand + " " + lastSelect );
				}
			}
		}
		
		// hide the abils
		public function hideMe() {
			var i = 0;
			while (i < abMax) {
				lmCost[i].visible = false;
				if( i < 6 ) itemCost[i].visible = false;
				i++;
			}
		}
		
		// iterates over the values provided by the ability event and handles them
		private function updateOverlay( args:Object ) {
			if( debug ) trace("[AbilityValues] updating overlay");
			lastArgs = args;
			var i = 0;
			while (i < abMax) {
				if( args["val_"+(i+1)]!= "0" ) {
					showAndPosOvr(args["val_"+(i+1)], i);
					if( args["hue_"+(i+1)]!= "0" ) {
						setHue(args["hue_"+(i+1)]);
					} else setHue(defHue);
					if( args["bri_"+(i+1)]!= "0" ) {
						setBri(args["bri_"+(i+1)]);
					} else setBri(defBri);
					updateFilter(i);
				} else lmCost[i].visible = false;
				i++;
			} 
		}
		
		// iterates over the values provided by the item event and handles them
		private function updateItemOverlay( args:Object ) {
			if( debug ) trace("[AbilityValues - Item] updating overlay");
			lastItemArgs = args;
			var i = 0;
			while (i < itemMax) {
				if( args["val_"+(i+1)]!= "0" ) {
					showAndPosItemOvr(args["val_"+(i+1)], i);
					if( args["hue_"+(i+1)]!= "0" ) {
						setHue(args["hue_"+(i+1)]);
					} else setHue(defHue);
					if( args["bri_"+(i+1)]!= "0" ) {
						setBri(args["bri_"+(i+1)]);
					} else setBri(defBri);
					updateItemFilter(i);
				} else itemCost[i].visible = false;
				i++;
			} 
		}
		
		// fire the ability overlay updating handler
		private function delayEvent(e:TimerEvent) {
			updateOverlay(holdArgs);
		}
		
		// fire the item overlay updating handler
		private function delayItemEvent(e:TimerEvent) {
			updateItemOverlay(holdItemArgs);
		}
		
		// fire the timer
		// "ability_values_send"
		private function prepareDelay(args:Object) {
			if( debug ) trace("[AbilityValues] Timer received, checking player ID");
			var pID = globals.Players.GetLocalPlayer();
			if( pID == args.player_ID ) {
				if( debug ) trace("[AbilityValues] Player ID OK! Firing timer!");
				holdArgs = args;
				bestTimer.reset();
				bestTimer.start();
			}
		}
		
		// fire the timer
		// "ability_values_send_item"
		private function prepareItemDelay(args:Object) {
			if( debug ) trace("[AbilityValues - Item] Timer received, checking player ID");
			var pID = globals.Players.GetLocalPlayer();
			if( pID == args.player_ID ) {
				if( debug ) trace("[AbilityValues - Item] Player ID OK! Firing timer!");
				holdItemArgs = args;
				bestItemTimer.reset();
				bestItemTimer.start();
			}
		}
		
		// handles huehue change
		private function setHue(val:int) {
			if( val < -180 ) val = -180; else if( val > 180 ) val = 180;
			// hue of 0 not working, FECK IT simple fix so pro Selena Gomez best aint no one got time for this shit
			if( val == 0 ) val = -1;
			color.hue = val;
		}
		
		// handles brightness change
		private function setBri(val:int) {
			if( val < -100 ) val = -100; else if( val > 100 ) val = 100;
			// assuming brightness of 0 wont work because huehue doesnt. maybe im an ass, but cba to test shit like this
			if( val == 0 ) val = -1;
			color.brightness = val;
		}
		
		// update ability filter and apply to image
		private function updateFilter(i:int) {
			filter = new ColorMatrixFilter(color.CalculateFinalFlatArray());
			lmCost[i].getChildByName("lumGfx").filters = [filter];
		}
		
		// update item filter and apply to image
		private function updateItemFilter(i:int) {
			filter = new ColorMatrixFilter(color.CalculateFinalFlatArray());
			itemCost[i].getChildByName("lumGfx").filters = [filter];
		}
		
		// handles showing, updating and positioning of the ability overlay
		private function showAndPosOvr(val:int, i:int) {
			// val of 0 hides the overlay, so i'm using -1 to show value of 0. thx Noya for the suggestion
			if( val == -1 ) val = 0;
			lmCost[i].visible = true;
			lmCost[i].getChildByName("txtField").text = val.toString();
			//this is redundant and you should probably use .defaultTextFormat on txtField setup but I cba to test that, no one lives forever, and this works 100%
			lmCost[i].getChildByName("txtField").setTextFormat(txFormat);
			lmCost[i].getChildByName("txtField").x = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].getChildAt(1).x;
			lmCost[i].getChildByName("txtField").y = -2; //globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].getChildAt(1).y;
			lmCost[i].y = globals.Loader_actionpanel.movieClip.middle.abilities["Ability"+i].y+2;
			
			if( countVisible() <= 4 ) lmCost[i].x = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].x-3;
			if( countVisible() > 4 ) lmCost[i].x = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].x;
			if( countVisible() == 5 ) lmCost[i].y = globals.Loader_actionpanel.movieClip.middle.abilities["Ability"+i].y+3;
		}
		
		// handles showing, updating and positioning of the item overlay
		private function showAndPosItemOvr(val:int, i:int) {
			// val of 0 hides the overlay, so i'm using -1 to show value of 0. thx Noya for the suggestion
			if( val == -1 ) val = 0;
			itemCost[i].visible = true;
			itemCost[i].getChildByName("txtField").text = val.toString();
			//this is redundant and you should probably use .defaultTextFormat on txtField setup but I cba to test that, no one lives forever, and this works 100%
			//lmCost[i].getChildByName("txtField").setTextFormat(txFormat);
			itemCost[i].getChildByName("txtField").x = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].getChildAt(1).x;
			itemCost[i].getChildByName("txtField").y = -2; //globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana"+i].getChildAt(1).y;
			itemCost[i].y = globals.Loader_inventory.movieClip.inventory.items["Item"+i].y;
			itemCost[i].x = globals.Loader_inventory.movieClip.inventory.items["Item"+i].x+globals.Loader_inventory.movieClip.inventory.items["Item"+i].width-itemCost[i].width-17.5;
		}
		
		// volvo is retarded and i am retarded and positioning has to be special cased, fuckit #yolo
		private function countVisible():int {
			var i = 0;
			var sum = 0;
			
			while (i < abMax) {
				if( globals.Loader_actionpanel.movieClip.middle.abilities["Ability"+i].visible ) sum++;
				i++;
			}
			
			return sum;
		}
	
		// handles creation of the overlay
		private function createOverlay(obj:Object, par:Object, max:int) {
			var i:int = 0;
			var buffMc:MovieClip;
			var lumGfx:Bitmap;
			while( i < max ) {
				buffMc = new MovieClip;
				lumGfx = new Bitmap(new lumberGfx());
				lumGfx.name = "lumGfx";

				buffMc.addChild(lumGfx);
				buffMc.addChild(addTextToOverlay());
				lumGfx.scaleX = 0.386;
				lumGfx.scaleY = 0.26;
				buffMc.name = "mClip";
				
				// add to volvo element so as not to worry about resizing
				par.addChild(buffMc);
				obj[i] = buffMc;
				obj[i].visible = false;
				i++;
			}
		}
		
		// adds the text field to the overlay
		private function addTextToOverlay():TextField {
			var txField:TextField = new TextField;
			txField.multiline = false;
			txField.wordWrap = false;
			txField.text = "";
			txField.autoSize = "none";
			txField.selectable = false;
			//txField.setTextFormat(txFormat);
			txField.defaultTextFormat = txFormat;
			txField.name = "txtField";
			txField.width = 24.7;
			txField.height = 17;
			txField.x = -1;
			txField.y = 0;
			
			return txField;
		}
		
		// the text format of the txtField of the overlay
		private function setTxFormat() {
			txFormat = globals.Loader_actionpanel.movieClip.middle.abilities["abilityMana0"].getChildAt(1).getTextFormat();
		}
		
		// load the values from the settings
		private function loadKV() {
			var _settings = Globals.instance.GameInterface.LoadKVFile('scripts/AbilityValues_settings.kv');
			defHue = int(_settings["defHue"]);
			defBri = int(_settings["defBri"]);
			serverCommand = _settings["serverCommand"];
			if( _settings["debug"]=="true" ) debug = true; else debug = false;
			trace("[AbilityValues] KV Loaded, default hue is ", defHue, ", the default brightness is ", defBri, " and ConVar is ", serverCommand);
			if( debug ) trace("[AbilityValues] Debugging: ON (inc tracespam)"); else trace("[AbilityValues] Debug: OFF (no tracespam)");
		}
		
		public function onLoaded() : void {			
			//make this UI visible
			visible = true;
			
			// basic setup
			setTxFormat();
			createOverlay(lmCost, globals.Loader_actionpanel.movieClip.middle.abilities, abMax);
			createOverlay(itemCost, globals.Loader_inventory.movieClip.inventory.items, itemMax);
			
			//let the client rescale the UI
			Globals.instance.resizeManager.AddListener(this);
			
			//add holder to stage
			this.addChild(holder);
			
			// load values from KV
			loadKV();
			
			// set color defs
			color.brightness = defBri;
			color.contrast = 0;
			color.hue = defHue;
			color.saturation = 0;
			
			//set timer because volvo
			bestTimer = new Timer(50, 1);
			bestItemTimer = new Timer(50, 1);
			
			//events
			gameAPI.SubscribeToGameEvent("dota_player_update_selected_unit", dotoEventHandle);
			gameAPI.SubscribeToGameEvent("dota_player_update_query_unit", dotoEventHandle);
			gameAPI.SubscribeToGameEvent("ability_values_force_check", sendEnt);
			gameAPI.SubscribeToGameEvent("ability_values_send", prepareDelay);
			gameAPI.SubscribeToGameEvent("ability_values_send_items", prepareItemDelay);
			bestTimer.addEventListener(TimerEvent.TIMER, delayEvent);
			bestItemTimer.addEventListener(TimerEvent.TIMER, delayItemEvent);
		}
		
		public function onResize(re:ResizeManager) : * {
			//scaling goes here
		}
	}
	
}