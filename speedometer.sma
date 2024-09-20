#include <amxmodx>
#include <cstrike>
#include <engine>
#include <fakemeta>
#include <get_user_fps>

#define PLUGIN "Speedometer"
#define VERSION "1.0"
#define AUTHOR "MrShark45"

#define FREQ 0.1

new Fps[33];
new Keys[33];

new bool:g_bShowSpeed[33];
new bool:g_bShowFps[33];
new bool:g_bShowKeys[33];

new TaskEnt, SyncHud, g_pCvarColor;
new g_iColors[3];
new g_iPlayerColors[33][3];

public plugin_init() {
	register_plugin(PLUGIN, VERSION, AUTHOR)
	register_forward(FM_Think, "Think")
	
	TaskEnt = engfunc(EngFunc_CreateNamedEntity, engfunc(EngFunc_AllocString, "info_target"))	
	set_pev(TaskEnt, pev_classname, "speedometer_think")
	set_pev(TaskEnt, pev_nextthink, get_gametime() + 1.01)

	register_clcmd("say /keys", "toggleKeys");
	register_clcmd("say /speed", "toggleSpeed");
	register_clcmd("say /fps", "toggleFps");
	
	g_pCvarColor = register_cvar("speed_colors", "255 255 255")

	set_task( 1.0, "colors_reload", _, _, _, "b" );
	
	SyncHud = CreateHudSyncObj()
	
	colors_reload();
}

public plugin_natives(){
	register_library("speedometer");

	register_native("set_user_colors", "native_set_user_colors");

	register_native("toggle_speed", "native_toggle_speed");
	register_native("toggle_fps", "native_toggle_fps");
	register_native("toggle_keys", "native_toggle_keys");

	register_native("get_bool_speed", "native_get_bool_speed");
	register_native("get_bool_fps", "native_get_bool_fps");
	register_native("get_bool_keys", "native_get_bool_keys");
}

public native_get_bool_speed(NumParams){
	new id = get_param(1);
	return g_bShowSpeed[id];
}

public native_get_bool_fps( NumParams){
	new id = get_param(1);
	return g_bShowFps[id];
}

public native_get_bool_keys(NumParams){
	new id = get_param(1);
	return g_bShowKeys[id];
}

public native_toggle_speed(NumParams){
	new id = get_param(1);
	toggleSpeed(id);
}

public native_toggle_fps(NumParams){
	new id = get_param(1);
	toggleFps(id);
}

public native_toggle_keys(NumParams){
	new id = get_param(1);
	toggleKeys(id);
}

public native_set_user_colors(NumParams){
	new id = get_param(1);
	g_iPlayerColors[id][0] = get_param(2);
	g_iPlayerColors[id][1] = get_param(3);
	g_iPlayerColors[id][2] = get_param(4);
}


public colors_reload(){
	new colors[16], red[4], green[4], blue[4];
	get_pcvar_string(g_pCvarColor, colors, charsmax(colors));
	parse(colors, red, 3, green, 3, blue, 3);
	g_iColors[0] = str_to_num(red);
	g_iColors[1] = str_to_num(green);
	g_iColors[2] = str_to_num(blue);
}

public Think(ent)
{
	if(ent == TaskEnt) 
	{
		SpeedTask();
		set_pev(ent, pev_nextthink,  get_gametime() + FREQ);
	}
}

public client_putinserver(id)
{
	g_bShowSpeed[id] = true;
	g_bShowFps[id] = true;

	g_iPlayerColors[id] = g_iColors;

	set_task(0.5, "get_fps", id, "", 0, "b");
}

public client_disconnected(id) remove_task(id);


public toggleSpeed(id)
{
	g_bShowSpeed[id] = !g_bShowSpeed[id];
	return PLUGIN_HANDLED;
}

public toggleFps(id)
{
	g_bShowFps[id] = !g_bShowFps[id];
	return PLUGIN_CONTINUE;
}

public toggleKeys(id){
	g_bShowKeys[id] = !g_bShowKeys[id];
}

SpeedTask()
{
	new target
	new Float:velocity[3]
	new Float:speed
	new message[84];
	new Float:height;
	
	for(new i=1; i<MAX_PLAYERS; i++)
	{
		if(!is_user_connected(i)) continue

		target = i;

		if(!is_user_alive(i))
			target = entity_get_int(i, EV_INT_iuser2);

		if(!target)
			continue;

		format(message, charsmax(message), "");
		get_buttons(target)
		get_user_velocity(target, velocity);
		speed = floatsqroot(floatpower(velocity[0], 2.0) + floatpower(velocity[1], 2.0))
		height = 0.75;
		
		if(!is_user_alive(i) || g_bShowKeys[i]){
			format(message, charsmax(message), "^t%s^t^t^t%s^n%s^t%s^t%s^t^t%s^n^n", 
			Keys[target] & IN_FORWARD ? "W" : "^t",
			Keys[target] & IN_JUMP ? "JUMP" : "  ^t^t^t^t^t",
			Keys[target] & IN_MOVELEFT ? "A" : "^t",
			Keys[target] & IN_BACK ? "S" : "^t",
			Keys[target] & IN_MOVERIGHT ? "D" : "^t",
			Keys[target] & IN_DUCK ? "DUCK" : " ^t^t^t^t^t");
			height = 0.69;
		}
			
		
		set_hudmessage(g_iPlayerColors[target][0], g_iPlayerColors[target][1], g_iPlayerColors[target][2], -1.0, height, 0, 0.01, FREQ, 0.01, 0.01, 3)
		if(g_bShowSpeed[i])
			format(message, charsmax(message), "%s%3.2f ups^n", message, speed);
		if(g_bShowFps[i])
			format(message, charsmax(message), "%s%d fps", message, Fps[target]);

		ShowSyncHudMsg(i, SyncHud, message);

		Keys[target] = 0;
	}
}

public get_buttons(id)
{

	if( get_user_button( id ) & IN_FORWARD )
		Keys[id] |= IN_FORWARD;
	if( get_user_button( id ) & IN_BACK )
		Keys[id] |= IN_BACK;
	if( get_user_button( id ) & IN_MOVELEFT )
		Keys[id] |= IN_MOVELEFT;
	if( get_user_button( id ) & IN_MOVERIGHT )
		Keys[id] |= IN_MOVERIGHT;
	if( get_user_button( id ) & IN_DUCK )
		Keys[id] |= IN_DUCK;
	if( get_user_button( id ) & IN_JUMP )
		Keys[id] |= IN_JUMP;

	return PLUGIN_CONTINUE
}

public get_fps(id)
{
	Fps[id] = get_user_fps(id);
}

