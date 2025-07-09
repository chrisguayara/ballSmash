extern vec2 resolution;
extern float time;
extern float jitter;
extern float alpha_scissor;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    float animatedJitter = jitter + sin(time * 2.0) * 0.01;
    vec2 pixelSnap = floor((uv * resolution) * (1.0 - animatedJitter)) / (resolution * (1.0 - animatedJitter));

    vec4 texColor = Texel(tex, pixelSnap);

    float alpha = texColor.a * color.a;
    if (alpha < alpha_scissor) discard;

    vec3 finalColor = texColor.rgb * color.rgb;

    return vec4(finalColor, alpha);
}
