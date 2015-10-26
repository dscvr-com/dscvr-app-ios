uniform sampler2D uMainTex;
uniform vec2 uCoefficients;
uniform vec2 uEyeOffset;

varying vec2 uv;

vec2 distort(vec2 position)
{
    vec2 p = position - uEyeOffset;
    float radiusSquared = p.y * p.y + p.x * p.x;
    p = p * (1.0 + radiusSquared * uCoefficients.x + radiusSquared * radiusSquared * uCoefficients.y);
    return 0.5 * (p + uEyeOffset + 1.0);
}

void main() {
    vec2 xy = 2.0 * uv - 1.0;
    vec2 nuv = distort(xy);
    float d = length(nuv);
    
    if (!all(equal(clamp(nuv, vec2(0.0, 0.0), vec2(1.0, 1.0)), nuv))) {
        gl_FragColor = vec4(0.0);
    } else {
        gl_FragColor = texture2D(uMainTex, nuv);
    }
}