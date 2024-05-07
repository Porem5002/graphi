#version 330

in vec2 fragTexCoord;
in vec4 fragColor;

out vec4 finalColor;

#define RADIUS 0.45
#define BORDER_THICKNESS 0.05
#define BORDER_COLOR vec3(1)

void main()
{
    vec2 coords = fragTexCoord - vec2(0.5);
    float d = length(coords);
    
    float t1 = 1.0 - smoothstep(RADIUS - BORDER_THICKNESS, RADIUS, d);
    float t2 = 1.0 - smoothstep(RADIUS, RADIUS + BORDER_THICKNESS, d);
    
    vec3 rgb = mix(BORDER_COLOR, fragColor.rgb, t1);
    finalColor = vec4(rgb, t2);
}