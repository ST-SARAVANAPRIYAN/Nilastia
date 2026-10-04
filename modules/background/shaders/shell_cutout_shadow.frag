#version 440
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;

layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    float radius;
    vec2 resolution;
    vec4 border;
    vec4 shadowColor;
    vec4 highlightColor;
    float shadowSoftness;
    float contactSize;
    float shadowOpacity;
    float chamferEnabled;
};

float smax(float a, float b, float k) {
    float h = clamp(0.5 + 0.5 * (a - b) / k, 0.0, 1.0);
    return mix(b, a, h) + k * h * (1.0 - h);
}

float sdSmoothRoundedBox(vec2 p, vec2 center, vec2 halfSize, float r, float k) {
    vec2 d = abs(p - center) - halfSize + vec2(r);
    return length(max(d, vec2(0.0))) + min(smax(d.x, d.y, k), 0.0) - r;
}

void main() {
    vec2 pixel = qt_TexCoord0 * resolution;
    vec2 pos = vec2(border.x, border.y);
    vec2 size = resolution - vec2(border.x + border.z, border.y + border.w);
    vec2 center = pos + size * 0.5;
    vec2 halfSize = size * 0.5;

    // Polynomial smooth maximum factor: eliminates sharp 45-degree corner diagonal crease
    float k = max(radius * 0.6, 8.0);
    float d = sdSmoothRoundedBox(pixel, center, halfSize, radius, k);

    // Pixels outside the cutout towards the monitor edge:
    // Only extend 1.5px under the shell border to guarantee zero seam gap,
    // and discard anything further towards the monitor edge.
    if (d > 1.5) {
        fragColor = vec4(0.0);
        return;
    }

    if (d >= 0.0) {
        float seamAlpha = (1.0 - smoothstep(1.0, 1.5, d)) * shadowColor.a * shadowOpacity * qt_Opacity;
        fragColor = vec4(shadowColor.rgb * seamAlpha, seamAlpha);
        return;
    }

    float u = -d;
    float maxReach = max(shadowSoftness, contactSize) + 12.0;
    if (u >= maxReach) {
        fragColor = vec4(0.0);
        return;
    }

    // Tight contact shadow: quartic falloff (0..contactSize px)
    float cT = clamp(u / max(contactSize, 1.0), 0.0, 1.0);
    float cFalloff = 1.0 - cT * cT;
    float contact = cFalloff * cFalloff;

    // Ambient diffuse shadow: smooth bell curve (0..shadowSoftness px)
    float aT = clamp(u / max(shadowSoftness, 1.0), 0.0, 1.0);
    float aFalloff = 1.0 - aT * aT;
    float ambient = aFalloff * aFalloff;

    // Combine contact occlusion and ambient diffusion
    float shadowIntensity = clamp(contact * 0.60 + ambient * 0.40, 0.0, 1.0);
    float shadowAlpha = shadowIntensity * shadowColor.a * shadowOpacity * qt_Opacity;
    vec3 color = shadowColor.rgb;
    float outAlpha = shadowAlpha;

    // 1px micro-chamfer specular highlight lip along the inner rim
    if (chamferEnabled > 0.5 && u <= 2.2) {
        float c = 1.0 - abs(u - 0.6) / 0.8;
        float chamfer = clamp(c, 0.0, 1.0);
        chamfer = chamfer * chamfer;

        float hAlpha = chamfer * highlightColor.a * shadowOpacity * qt_Opacity;
        color = mix(color, highlightColor.rgb, hAlpha / max(outAlpha + hAlpha, 0.001));
        outAlpha = max(outAlpha, hAlpha);
    }

    fragColor = vec4(color * outAlpha, outAlpha);
}
