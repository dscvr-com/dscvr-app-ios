attribute vec4 aPosition;
varying vec2 uv;
uniform float uTextureCoordScale;

void main() {
    gl_Position = aPosition;
    uv = ((aPosition.xy + 1.0) * 0.5);
}