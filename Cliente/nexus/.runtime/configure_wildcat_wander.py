import urllib.request, json
u='http://localhost:3571/call-tool'
h={'Content-Type':'application/json'}

def call(tool,args):
    req=urllib.request.Request(u,data=json.dumps({'tool_name':tool,'tool_args':args}).encode('utf-8'),headers=h)
    print(tool, urllib.request.urlopen(req,timeout=30).read().decode('utf-8'))

# player off wander
call('open_scene', {'file_path':'res://cenas/player.tscn'})
call('update_property', {'node_path':'.', 'property_path':'enable_wander', 'value':'false'})

# villager off wander
call('open_scene', {'file_path':'res://cenas/villager_1.tscn'})
call('update_property', {'node_path':'.', 'property_path':'enable_wander', 'value':'false'})

# wildcat on wander and setup state
call('open_scene', {'file_path':'res://cenas/wildcat_1.tscn'})
call('update_property', {'node_path':'.', 'property_path':'enable_wander', 'value':'true'})
call('update_property', {'node_path':'.', 'property_path':'wander_delay_min_sec', 'value':'1.5'})
call('update_property', {'node_path':'.', 'property_path':'wander_delay_max_sec', 'value':'3.5'})
call('update_property', {'node_path':'.', 'property_path':'wander_radius_min', 'value':'56.0'})
call('update_property', {'node_path':'.', 'property_path':'wander_radius_max', 'value':'180.0'})
call('add_node', {'parent_node_path':'LimboHSM','node_type':'LimboState','node_name':'WanderState'})
call('attach_script', {'node_path':'LimboHSM/WanderState','script_path':'res://Scripts/actors/state_wander_8dir.gd'})
