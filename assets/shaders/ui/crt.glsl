extern vec2 resolution;
extern float jitter;
extern float alpha_scissor;

vec4 effect(vec4 color, Image tex, vec2 uv, vec2 px) {
    // No animation, just static jitter
    float staticJitter = jitter;

    vec2 pixelSnap = floor((uv * resolution) * (1.0 - staticJitter)) / (resolution * (1.0 - staticJitter));
    vec4 texColor = Texel(tex, pixelSnap);

    float alpha = texColor.a * color.a;
    if (alpha < alpha_scissor) discard;

    vec3 finalColor = texColor.rgb * color.rgb;
    return vec4(finalColor, alpha);
}
