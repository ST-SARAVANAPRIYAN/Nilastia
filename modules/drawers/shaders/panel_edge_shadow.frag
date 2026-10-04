#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec2 resolution;
    vec2 center;
    vec2 halfSize;
    vec4 shadowColor;
    float shadowSoftness;
    float shadowOpacity;
};

float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}

float sdSmoothRoundedBox(vec2 p, vec2 c, vec2 hs, float r, float k) {
    vec2 d = abs(p - c) - hs + vec2(r);
    return length(max(d, vec2(0.0))) + min(smax(d.x, d.y, k), 0.0) - r;
}

void main() {
    vec2 pixel = qt_TexCoord0 * resolution;

    // Smooth corner maximum parameter: prevents diagonal creases
    float k = max(radius * 0.6, 8.0);
    float d = sdSmoothRoundedBox(pixel, center, halfSize, radius, k);

    // CRITICAL: Hollow interior! Discard all pixels deep under the component body.
    // Prevents solid black underlay from dulling translucent shell surfaces.
    if (d < -1.5) {
        fragColor = vec4(0.0);
        return;
    }

    // 1.5px under-edge seam lock: blends smoothly under the component perimeter edge
    // to guarantee zero light sliver or anti-aliasing gaps without bleeding inside.
    if (d <= 0.0) {
        float seamAlpha = smoothstep(-1.5, -0.5, d) * shadowColor.a * shadowOpacity * qt_Opacity;
        fragColor = vec4(shadowColor.rgb * seamAlpha, seamAlpha);
        return;
    }

    // Outside the component: drop shadow falloff
    if (d >= shadowSoftness) {
        fragColor = vec4(0.0);
        return;
    }

    // Tight contact shadow: quartic falloff (0..contactReach px)
    float contactReach = min(6.0, shadowSoftness * 0.5);
    float cT = clamp(d / max(contactReach, 1.0), 0.0, 1.0);
    float cFalloff = 1.0 - cT * cT;
    float contact = cFalloff * cFalloff;

    // Ambient diffuse shadow: smooth bell curve (0..shadowSoftness px)
    float aT = clamp(d / max(shadowSoftness, 1.0), 0.0, 1.0);
    float aFalloff = 1.0 - aT * aT;
    float ambient = aFalloff * aFalloff;

    // Combine contact occlusion and ambient diffusion
    float intensity = clamp(contact * 0.60 + ambient * 0.40, 0.0, 1.0);
    float alpha = intensity * shadowColor.a * shadowOpacity * qt_Opacity;

    fragColor = vec4(shadowColor.rgb * alpha, alpha);
}
