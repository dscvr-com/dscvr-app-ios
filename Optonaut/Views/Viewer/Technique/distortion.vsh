attribute vec4 aPosition;
varying vec2 xy;
uniform float uTextureCoordScale;
uniform vec2 uViewportOffset;
uniform vec2 uEyeOffset;

void main() {
    gl_Position = aPosition;
    xy = aPosition.xy * uTextureCoordScale + uViewportOffset;
}