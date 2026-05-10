shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 1.0;
uniform float trail_level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.15, 0.85, 0.2, 0.95);
uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 border_color : source_color = vec4(0.95, 0.95, 1.0, 0.95);
uniform vec4 background_color : source_color = vec4(0.55, 0.05, 0.05, 0.95);
uniform vec4 glass_tint : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float border_thickness : hint_range(0.0, 0.2) = 0.12;
uniform float wobble_strength : hint_range(0.0, 0.2) = 0.035;
uniform float wobble_speed : hint_range(0.0, 8.0) = 2.2;
uniform float vibration : hint_range(0.0, 1.0) = 0.0;
uniform bool selected = false;
uniform vec4 selected_color : source_color = vec4(1.0, 0.75, 0.15, 1.0);
uniform float selection_pulse_speed : hint_range(0.0, 10.0) = 4.0;
uniform bool danger_alert = false;
uniform vec4 danger_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float danger_pulse_speed : hint_range(0.0, 15.0) = 8.0;

void fragment() {
    vec2 uv = UV * 2.0 - vec2(1.0);
    float r = length(uv);
    if (r > 1.2) {
        COLOR = vec4(0.0);
    } else {
        float base_wobble = sin((uv.x * 8.0) + TIME * wobble_speed) * wobble_strength;
        
        // Violent liquid slosh/tilt effect based on vibration
        // Using 'vibration' inside the sin() guarantees it settles perfectly at 0 when vibration hits 0.
        float slosh = uv.x * sin(vibration * 25.0) * vibration * 1.5;
        float splash = sin(uv.x * 12.0 + vibration * 40.0) * vibration * 0.25;
        float total_wobble = base_wobble + slosh + splash;
        
        float liquid_line = mix(1.0, -1.0, fill_level) + total_wobble;
        float trail_line = mix(1.0, -1.0, trail_level) + total_wobble;
        
        float liquid_mask = step(liquid_line, uv.y) * step(r, 0.96);
        float trail_mask = step(trail_line, uv.y) * (1.0 - step(liquid_line, uv.y)) * step(r, 0.96);

        // Start with background
        vec4 col = background_color * step(r, 0.96);
        
        // Blend Trail (Ghost Bar)
        col.rgb = mix(col.rgb, trail_color.rgb, trail_mask * trail_color.a);
        col.a = max(col.a, trail_mask * trail_color.a);
        
        // Blend Liquid Fill
        col.rgb = mix(col.rgb, fill_color.rgb, liquid_mask * fill_color.a);
        col.a = max(col.a, liquid_mask * fill_color.a);

        float ring_border = smoothstep(0.96 - border_thickness, 0.96 - border_thickness * 0.25, r);
        col.rgb = mix(col.rgb, border_color.rgb, ring_border * step(r, 0.96) * border_color.a);
        col.a = max(col.a, ring_border * step(r, 0.96) * border_color.a);

        float highlight = smoothstep(0.0, 0.45, 1.0 - length(uv - vec2(-0.28, -0.36)));
        col.rgb += highlight * 0.18 * step(r, 0.96);

        col.rgb += glass_tint.rgb * (1.0 - max(liquid_mask, trail_mask)) * glass_tint.a * step(r, 0.96);

        // Danger Ring Logic
        if (danger_alert) {
            float d_pulse = sin(TIME * danger_pulse_speed) * 0.5 + 0.5;
            float danger_inner = 0.98 - d_pulse * 0.02;
            float danger_outer = 1.04 + d_pulse * 0.02;
            
            float danger_ring = smoothstep(danger_inner, danger_inner + 0.01, r) * 
                               (1.0 - smoothstep(danger_outer, danger_outer + 0.01, r));
            
            col.rgb = mix(col.rgb, danger_color.rgb, danger_ring * danger_color.a);
            col.a = max(col.a, danger_ring * danger_color.a);
        }

        // Target Lock Ring Logic
        if (selected) {
            float pulse = sin(TIME * selection_pulse_speed) * 0.5 + 0.5;
            float target_inner = 1.02 - pulse * 0.02;
            float target_outer = 1.10 + pulse * 0.02;
            
            float target_ring = smoothstep(target_inner, target_inner + 0.01, r) * 
                               (1.0 - smoothstep(target_outer, target_outer + 0.01, r));
            
            // 4 Mira/Crosshair markers
            float angle = atan(uv.y, uv.x);
            float marks = abs(sin(angle * 2.0));
            float cut = smoothstep(0.15, 0.35, marks);
            target_ring *= cut;
            
            col.rgb = mix(col.rgb, selected_color.rgb, target_ring * selected_color.a);
            col.a = max(col.a, target_ring * selected_color.a);
        }

        COLOR = vec4(col.rgb, clamp(col.a, 0.0, 1.0));
    }
}
