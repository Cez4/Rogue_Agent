shader_type canvas_item;

uniform float fill_level : hint_range(0.0, 1.0) = 1.0;
uniform float trail_level : hint_range(0.0, 1.0) = 1.0;
uniform vec4 fill_color : source_color = vec4(0.9, 0.15, 0.18, 0.95);
uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 1.0, 0.4);
uniform vec4 border_color : source_color = vec4(0.95, 0.95, 1.0, 0.95);
uniform vec4 glass_tint : source_color = vec4(1.0, 1.0, 1.0, 0.12);
uniform float border_thickness : hint_range(0.0, 0.2) = 0.06;
uniform float wobble_strength : hint_range(0.0, 0.2) = 0.035;
uniform float wobble_speed : hint_range(0.0, 8.0) = 2.2;
uniform float vibration : hint_range(0.0, 1.0) = 0.0;
uniform bool selected = false;
uniform vec4 selected_color : source_color = vec4(1.0, 0.75, 0.15, 1.0);
uniform float selection_pulse_speed : hint_range(0.0, 10.0) = 4.0;

void fragment() {
    vec2 uv = UV * 2.0 - vec2(1.0);
    float r = length(uv);
    if (r > 1.2) {
        COLOR = vec4(0.0);
    } else {
        float vib_wobble = sin(TIME * 45.0) * vibration * 0.05;
        float base_wobble = sin((uv.x * 8.0) + TIME * wobble_speed) * wobble_strength;
        float total_wobble = base_wobble + vib_wobble;
        
        float liquid_line = mix(1.0, -1.0, fill_level) + total_wobble;
        float trail_line = mix(1.0, -1.0, trail_level) + total_wobble;
        
        float liquid_mask = step(liquid_line, uv.y) * step(r, 0.96);
        float trail_mask = step(trail_line, uv.y) * step(r, 0.96);

        vec4 col = vec4(0.0);
        col = mix(col, trail_color, trail_mask);
        col = mix(col, fill_color, liquid_mask);

        float ring_border = smoothstep(0.96 - border_thickness, 0.96 - border_thickness * 0.25, r);
        col = mix(col, border_color, ring_border * step(r, 0.96));

        float highlight = smoothstep(0.0, 0.45, 1.0 - length(uv - vec2(-0.28, -0.36)));
        col.rgb += highlight * 0.18 * step(r, 0.96);

        col += glass_tint * (1.0 - max(liquid_mask, trail_mask)) * 0.75 * step(r, 0.96);

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
            
            col = mix(col, selected_color, target_ring);
            col.a = max(col.a, target_ring * selected_color.a);
        }

        COLOR = vec4(col.rgb, clamp(col.a, 0.0, 1.0));
    }
}
