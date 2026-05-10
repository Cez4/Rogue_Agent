shader_type canvas_item;
render_mode blend_mix;

uniform float fill_level : hint_range(0.0, 1.0) = 1.0;
uniform float trail_level : hint_range(0.0, 1.0) = 1.0;

// RPG Colors
uniform vec4 fill_color : source_color = vec4(0.15, 0.85, 0.2, 1.0);
uniform vec4 trail_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 border_color : source_color = vec4(0.95, 0.95, 1.0, 1.0);
uniform vec4 background_color : source_color = vec4(0.55, 0.05, 0.05, 1.0);

// Authentic Liquid Physics
uniform float water_wave_speed : hint_range(0.0, 10.0) = 2.5;
uniform float water_wave_amp : hint_range(0.0, 0.2) = 0.04;
uniform float wave_num : hint_range(0.0, 8.0) = 2.0;
uniform float border_thickness : hint_range(0.0, 0.2) = 0.12;
uniform float vibration : hint_range(0.0, 1.0) = 0.0;

// UI State Rings
uniform bool selected = false;
uniform vec4 selected_color : source_color = vec4(1.0, 0.75, 0.15, 1.0);
uniform float selection_pulse_speed : hint_range(0.0, 10.0) = 4.0;
uniform bool danger_alert = false;
uniform vec4 danger_color : source_color = vec4(1.0, 0.1, 0.1, 1.0);
uniform float danger_pulse_speed : hint_range(0.0, 15.0) = 8.0;

void fragment() {
    vec2 uv = UV * 2.0 - vec2(1.0); // -1.0 (top/left) to 1.0 (bottom/right)
    float r = length(uv);
    
    if (r > 1.2) {
        COLOR = vec4(0.0);
    } else {
        // suv is used for authentic 3D curvature mapping
        vec2 suv = UV - vec2(0.5); // -0.5 to 0.5
        
        // 1. Violent liquid slosh/tilt effect based on vibration
        // Multiplying by uv.x tilts the liquid line physically.
        float slosh = uv.x * sin(vibration * 25.0) * vibration * 0.8;
        
        // 2. Add chaos to the wave amplitude when vibrating
        float current_amp = water_wave_amp + (vibration * 0.1);
        
        // 3. Authentic 3D surface waves using cosine
        // cos(suv.x * PI) makes the wave curve down at the edges of the sphere
        float front_wave = sin((cos(suv.x * PI) + TIME * water_wave_speed) * wave_num) * current_amp;
        float back_wave = sin((cos(suv.x * PI + PI * 0.5) + TIME * water_wave_speed) * wave_num) * current_amp;

        // Map fill level (0.0 to 1.0) to screen coordinates (1.0 to -1.0)
        float liquid_line = mix(1.0, -1.0, fill_level) + slosh;
        float trail_line = mix(1.0, -1.0, trail_level) + slosh;

        // Create masks for Front and Back liquids to give 3D depth
        float liquid_front_mask = step(liquid_line + front_wave, uv.y) * step(r, 0.96);
        float liquid_back_mask = step(liquid_line + back_wave, uv.y) * step(r, 0.96);
        
        float trail_front_mask = step(trail_line + front_wave, uv.y) * step(r, 0.96);
        float trail_back_mask = step(trail_line + back_wave, uv.y) * step(r, 0.96);

        // --- RENDER PASSES ---
        
        // A. Start with 100% Opaque Background
        vec4 col = background_color * step(r, 0.96);
        
        // B. Draw Trail Back (Darker)
        float tb_mask = trail_back_mask * (1.0 - liquid_back_mask);
        col.rgb = mix(col.rgb, trail_color.rgb * 0.7, tb_mask);
        
        // C. Draw Trail Front (Brighter)
        float tf_mask = trail_front_mask * (1.0 - liquid_front_mask);
        col.rgb = mix(col.rgb, trail_color.rgb, tf_mask);

        // D. Draw Liquid Back (Darker for depth)
        col.rgb = mix(col.rgb, fill_color.rgb * 0.6, liquid_back_mask);
        
        // E. Draw Liquid Front (Main color)
        col.rgb = mix(col.rgb, fill_color.rgb, liquid_front_mask);

        // F. Glass highlight (Top Left) to make it look like a sphere
        float highlight = smoothstep(0.0, 0.45, 1.0 - length(uv - vec2(-0.28, -0.36)));
        col.rgb += vec3(1.0) * highlight * 0.25 * step(r, 0.96);
        
        // G. Inner Shadow (Bottom Right) to ground the liquid
        float shadow = smoothstep(0.7, 1.0, r) * smoothstep(0.0, 1.0, length(uv - vec2(0.3, 0.3)));
        col.rgb -= shadow * 0.3 * step(r, 0.96);

        // H. Border
        float ring_border = smoothstep(0.96 - border_thickness, 0.96 - border_thickness * 0.25, r);
        col.rgb = mix(col.rgb, border_color.rgb, ring_border * step(r, 0.96));

        // I. Danger Ring Logic
        if (danger_alert) {
            float d_pulse = sin(TIME * danger_pulse_speed) * 0.5 + 0.5;
            float danger_inner = 0.98 - d_pulse * 0.02;
            float danger_outer = 1.04 + d_pulse * 0.02;
            float danger_ring = smoothstep(danger_inner, danger_inner + 0.01, r) * (1.0 - smoothstep(danger_outer, danger_outer + 0.01, r));
            col.rgb = mix(col.rgb, danger_color.rgb, danger_ring * danger_color.a);
            col.a = max(col.a, danger_ring * danger_color.a);
        }

        // J. Target Lock Ring Logic
        if (selected) {
            float pulse = sin(TIME * selection_pulse_speed) * 0.5 + 0.5;
            float target_inner = 1.02 - pulse * 0.02;
            float target_outer = 1.10 + pulse * 0.02;
            float target_ring = smoothstep(target_inner, target_inner + 0.01, r) * (1.0 - smoothstep(target_outer, target_outer + 0.01, r));
            
            // 4 Mira/Crosshair markers
            float angle = atan(uv.y, uv.x);
            float marks = abs(sin(angle * 2.0));
            float cut = smoothstep(0.15, 0.35, marks);
            target_ring *= cut;
            
            col.rgb = mix(col.rgb, selected_color.rgb, target_ring * selected_color.a);
            col.a = max(col.a, target_ring * selected_color.a);
        }

        // Ensure alpha is fully opaque inside the orb
        col.a = max(col.a, step(r, 0.96));

        COLOR = col;
    }
}