uniform sampler2D uMainTex;
uniform vec2 uCoefficients;
uniform vec2 uEyeOffset;
uniform float uVignetteX;
uniform float uVignetteY;

varying vec2 xy;

vec2 distort(vec2 position)
{
    vec2 p = position.xy - (uEyeOffset);
    float radiusSquared = (p.y * p.y + p.x * p.x);
    float radDistorted = 1.0 + (uCoefficients.x + radiusSquared * uCoefficients.y) * radiusSquared;
    p = p * radDistorted + (uEyeOffset);
    return p;
}

void main() {
    
    vec2 nuv = 0.5 * (distort(xy) + 1.0);
    float d = length(nuv);
    
    if (!all(equal(clamp(nuv, vec2(0.0, 0.0), vec2(1.0, 1.0)), nuv))) {
        gl_FragColor = vec4(0.0);
    } else {
        vec2 center = nuv - vec2(0.5, 0.5);
        center = abs(center);
        float light = 1.0;
        float vX = max(center.x - (0.5 - uVignetteX), 0.0);
        float vY = max(center.y - (0.5 - uVignetteY), 0.0);
        
        if(vX * uVignetteY > vY * uVignetteX) {
            light = 1.0 - vX / uVignetteX;
        } else {
            light = 1.0 - vY / uVignetteY;
        }
        gl_FragColor = texture2D(uMainTex, nuv) * light;
    }
}