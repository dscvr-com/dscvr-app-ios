uniform sampler2D _MainTex;
varying vec2 uv;

vec2 distort(vec2 p)
{
    vec3 coefficients = vec3(1.0, 0.22, 0.24);
    float rSq = p.y * p.y + p.x * p.x;
    p = p * (coefficients.x + rSq * coefficients.y + rSq * rSq * coefficients.z);
    return 0.5 * (p + 1.0);
}

void main() {
    vec2 xy = 2.0 * uv - 1.0;
    vec2 nuv = distort(xy);
    float d = length(nuv);

    if (!all(equal(clamp(nuv, vec2(0.0, 0.0), vec2(1.0, 1.0)), nuv))) {
        gl_FragColor = vec4(0.0);
    } else {
        gl_FragColor = texture2D(_MainTex, nuv);
    }
}