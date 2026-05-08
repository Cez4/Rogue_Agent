import urllib.request, json
u='http://localhost:3571/call-tool'
h={'Content-Type':'application/json'}

def call(tool,args,timeout=35):
    req=urllib.request.Request(u,data=json.dumps({'tool_name':tool,'tool_args':args}).encode('utf-8'),headers=h)
    return urllib.request.urlopen(req,timeout=timeout).read().decode('utf-8')

print(call('stop_running_scene', {}))
print(call('open_scene', {'file_path':'res://cenas/wildcat_1.tscn'}))
print(call('clear_output_logs', {}))
print(call('play_scene', {'scene_type':'current'}))

print('POS1', call('get_node_properties', {'mode':'running_scene','node_path':'/root/Rat1','properties':['position','global_position','velocity']}))
print(call('simulate_input', {'commands':[{'wait_ms':3000}]}))
print('POS2', call('get_node_properties', {'mode':'running_scene','node_path':'/root/Rat1','properties':['position','global_position','velocity']}))
print(call('simulate_input', {'commands':[{'wait_ms':3000}]}))
print('POS3', call('get_node_properties', {'mode':'running_scene','node_path':'/root/Rat1','properties':['position','global_position','velocity']}))
print(call('get_godot_errors', {'num_lines':220}))
