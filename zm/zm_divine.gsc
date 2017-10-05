#using scripts\codescripts\struct;

#using scripts\shared\array_shared;
#using scripts\shared\callbacks_shared;
#using scripts\shared\clientfield_shared;
#using scripts\shared\compass;
#using scripts\shared\exploder_shared;
#using scripts\shared\flag_shared;
#using scripts\shared\laststand_shared;
#using scripts\shared\math_shared;
#using scripts\shared\scene_shared;
#using scripts\shared\util_shared;

#insert scripts\shared\shared.gsh;
#insert scripts\shared\version.gsh;

#insert scripts\zm\_zm_utility.gsh;

#using scripts\zm\_load;
#using scripts\zm\_zm;
#using scripts\zm\_zm_audio;
#using scripts\zm\_zm_powerups;
#using scripts\zm\_zm_utility;
#using scripts\zm\_zm_weapons;
#using scripts\zm\_zm_zonemgr;

#using scripts\shared\ai\zombie_utility;

//Perks
#using scripts\zm\_zm_pack_a_punch;
#using scripts\zm\_zm_pack_a_punch_util;
#using scripts\zm\_zm_perk_additionalprimaryweapon;
#using scripts\zm\_zm_perk_doubletap2;
#using scripts\zm\_zm_perk_deadshot;
#using scripts\zm\_zm_perk_juggernaut;
#using scripts\zm\_zm_perk_quick_revive;
#using scripts\zm\_zm_perk_sleight_of_hand;
#using scripts\zm\_zm_perk_staminup;

//Powerups
#using scripts\zm\_zm_powerup_double_points;
#using scripts\zm\_zm_powerup_carpenter;
#using scripts\zm\_zm_powerup_fire_sale;
#using scripts\zm\_zm_powerup_free_perk;
#using scripts\zm\_zm_powerup_full_ammo;
#using scripts\zm\_zm_powerup_insta_kill;
#using scripts\zm\_zm_powerup_nuke;
//#using scripts\zm\_zm_powerup_weapon_minigun;

//Traps
#using scripts\zm\_zm_trap_electric;

#using scripts\zm\zm_usermap;

//*****************************************************************************
// MAIN
//*****************************************************************************

function main()
{
	zm_usermap::main();
	
	level thread intro_credits();
	
	level._zombie_custom_add_weapons =&custom_add_weapons;
	
	//Setup the levels Zombie Zone Volumes
	level.zones = [];
	level.zone_manager_init_func =&usermap_test_zone_init;
	init_zones[0] = "start_zone";
	level thread zm_zonemgr::manage_zones( init_zones );

	level.pathdist_type = PATHDIST_ORIGINAL;
	
	//Perk Lights
	level thread power_lights();
	
	//Zombie Counter
	_INIT_ZCOUNTER();
}

function power_lights()
{
    //level flag::wait_till( "power_on" );
	//level util::set_lighting_state( 0 );
	//level flag::wait_till( "power_off" );
	//level util::set_lighting_state( 1 );
	//power_lights();
	
	level util::set_lighting_state(0);
	level waittill("power_on");
	level util::set_lighting_state(1);
}

function usermap_test_zone_init()
{
	level flag::init( "always_on" );
	level flag::set( "always_on" );
}	

function custom_add_weapons()
{
	zm_weapons::load_weapon_spec_from_table("gamedata/weapons/zm/zm_levelcommon_weapons.csv", 1);
}

function intro_credits()
{
    thread creat_simple_intro_hud( " The Dante Comedy ", 50, 100, 3, 5 );
    thread creat_simple_intro_hud( " Map by ALPHA_CUBE ", 50, 75, 2, 5 );
    thread creat_simple_intro_hud( " Hell has many layers. much like an onion. -Dante ", 50, 50, 2, 5 );
}
 
function creat_simple_intro_hud( text, align_x, align_y, font_scale, fade_time )
{
    hud = NewHudElem();
    hud.foreground = true;
    hud.fontScale = font_scale;
    hud.sort = 1;
    hud.hidewheninmenu = false;
    hud.alignX = "left";
    hud.alignY = "bottom";
    hud.horzAlign = "left";
    hud.vertAlign = "bottom";
    hud.x = align_x;
    hud.y = hud.y - align_y;
    hud.alpha = 1;
    hud SetText( text );
    wait( 8 );
    hud fadeOverTime( fade_time );
    hud.alpha = 0;
    wait( fade_time );
    hud Destroy();
}

function _INIT_ZCOUNTER()
{
	ZombieCounterHuds = [];
	ZombieCounterHuds["LastZombieText"] 	= "Zombie Left";
	ZombieCounterHuds["ZombieText"]		= "Zombie's Left";
	ZombieCounterHuds["LastDogText"]	= "Dog Left";
	ZombieCounterHuds["DogText"]		= "Dog's Left";
	ZombieCounterHuds["DefaultColor"]	= (1,1,1);
	ZombieCounterHuds["HighlightColor"]	= (1, 0.55, 0);
	ZombieCounterHuds["FontScale"]		= 1.5;
	ZombieCounterHuds["DisplayType"]	= 0; // 0 = Shows Total Zombies and Counts down, 1 = Shows Currently spawned zombie count

	ZombieCounterHuds["counter"] = createNewHudElement("left", "top", 2, 10, 1, 1.5);
	ZombieCounterHuds["text"] = createNewHudElement("left", "top", 2, 10, 1, 1.5);

	ZombieCounterHuds["counter"] hudRGBA(ZombieCounterHuds["DefaultColor"], 0);
	ZombieCounterHuds["text"] hudRGBA(ZombieCounterHuds["DefaultColor"], 0);

	level thread _THINK_ZCOUNTER(ZombieCounterHuds);
}

function _THINK_ZCOUNTER(hudArray)
{
	level endon("end_game");
	for(;;)
	{
		level waittill("start_of_round");
		level _ROUND_COUNTER(hudArray);
		hudArray["counter"] SetValue(0);
		hudArray["text"] thread hudMoveTo((2, 10, 0), 4);
		
		hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 0, 1);
		hudArray["text"] SetText("End of round"); hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 0, 3);
	}
}

function _ROUND_COUNTER(hudArray)
{
	level endon("end_of_round");
	lastCount = 0;
	numberToString = "";

	hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 1.0, 1);
	hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 1.0, 1);
	hudArray["text"] SetText(hudArray["ZombieText"]);
	if(level flag::get("dog_round"))
		hudArray["text"] SetText(hudArray["DogText"]);

	for(;;)
	{
		zm_count = (zombie_utility::get_current_zombie_count() + level.zombie_total);
		if(hudArray["DisplayType"] == 1) zm_count = zombie_utility::get_current_zombie_count();
		if(zm_count == 0) {wait(1); continue;}
		hudArray["counter"] SetValue(zm_count);
		if(lastCount != zm_count)
		{
			lastCount = zm_count;
			numberToString = "" + zm_count;
			hudArray["text"] thread hudMoveTo((10 + (4 * numberToString.Size), 10, 0), 4);
			if(zm_count == 1 && !level flag::get("dog_round")) hudArray["text"] SetText(hudArray["LastZombieText"]);
			else if(zm_count == 1 && level flag::get("dog_round")) hudArray["text"] SetText(hudArray["LastDogText"]);

			hudArray["counter"].color = hudArray["HighlightColor"]; hudArray["counter"].fontscale = (hudArray["FontScale"] + 0.5);
			hudArray["text"].color = hudArray["HighlightColor"]; hudArray["text"].fontscale = (hudArray["FontScale"] + 0.5);
			hudArray["counter"] thread hudRGBA(hudArray["DefaultColor"], 1, 0.5); hudArray["counter"] thread hudFontScale(hudArray["FontScale"], 0.5);
			hudArray["text"] thread hudRGBA(hudArray["DefaultColor"], 1, 0.5); hudArray["text"] thread hudFontScale(hudArray["FontScale"], 0.5);
		}
		wait(0.1);
	}
}

function createNewHudElement(xAlign, yAlign, posX, posY, foreground, fontScale)
{
	hud = newHudElem();
	hud.horzAlign = xAlign; hud.alignX = xAlign;
	hud.vertAlign = yAlign; hug.alignY = yAlign;
	hud.x = posX; hud.y = posY;
	hud.foreground = foreground;
	hud.fontscale = fontScale;
	return hud;
}

function hudRGBA(newColor, newAlpha, fadeTime)
{
	if(isDefined(fadeTime))
		self FadeOverTime(fadeTime);

	self.color = newColor;
	self.alpha = newAlpha;
}

function hudFontScale(newScale, fadeTime)
{
	if(isDefined(fadeTime))
		self ChangeFontScaleOverTime(fadeTime);

	self.fontscale = newScale;
}

function hudMoveTo(posVector, fadeTime) // Just because MoveOverTime doesn't always work as wanted
{
	initTime = GetTime();
	hudX = self.x;
	hudY = self.y;
	hudVector = (hudX, hudY, 0);
	while(hudVector != posVector)
	{
		time = GetTime();
		hudVector = VectorLerp(hudVector, posVector, (time - initTime) / (fadeTime * 1000));
		self.x = hudVector[0];
		self.y = hudVector[1];
		wait(0.0001);
	}
}
