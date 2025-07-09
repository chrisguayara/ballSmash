extern Image outlineTex;
extern Image fillTex;
extern Image maskTex;

extern vec2 velocity;
extern number time;

vec4 effect(vec4 color, Image texture, vec2 uv, vec2 screen_coords)
{
    vec4 outlinePixel = Texel(outlineTex, uv);

    // Draw rim (black outline) where outline alpha is strong
    if (outlinePixel.a > 0.8) {
        return outlinePixel * color;
    }

    // Offset UVs for fill only
    vec2 dir = normalize(velocity);
    vec2 uv_offset = dir * time * 0.1; // tweak 0.1 for scroll speed
    vec2 scrolledUV = uv + uv_offset;

    vec4 fillPixel = Texel(fillTex, scrolledUV);
    float maskAlpha = Texel(maskTex, uv).r;

    if (maskAlpha > 0.00) {
        return fillPixel * color;
    }

    return vec4(0.0);
}
