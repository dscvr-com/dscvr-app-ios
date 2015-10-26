uniform sampler2D uMainTex;
uniform vec2 uCoefficients;
uniform vec2 uEyeOffset;
uniform float uTextureCoordScale;

varying vec2 uv;

vec2 distort(vec2 position)
{
    vec2 p = position - uEyeOffset;
    p = p * uTextureCoordScale;
    
    float radiusSquared = p.y * p.y + p.x * p.x;
    float rad = 1.0 + radiusSquared * uCoefficients.x + radiusSquared * radiusSquared * uCoefficients.y;
    
    p = p * rad;
    p = p + uEyeOffset;
    return p;
}

void main() {
    
    vec2 xy = 2.0 * uv - 1.0;
    vec2 nuv = 0.5 * (distort(xy) + 1.0);
    float d = length(nuv);
    
    if (!all(equal(clamp(nuv, vec2(0.0, 0.0), vec2(1.0, 1.0)), nuv))) {
        gl_FragColor = vec4(0.0);
    } else {
        float light = 1.0;
        if (d > 0.95) {
            //light = 1.0 - (d - 0.95) / (1.0 - 0.95);
        }
        gl_FragColor = texture2D(uMainTex, nuv) * light;
    }
}