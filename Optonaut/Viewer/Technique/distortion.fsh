precision highp float;
varying vec2 vTextureCoord;

uniform sampler2D _MainTex;

void main() {
    gl_FragColor = texture2D(_MainTex, vTextureCoord);
}
