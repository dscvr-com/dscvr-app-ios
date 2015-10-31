attribute vec4 aPosition;
varying vec2 xy;
uniform float uTextureCoordScale;
uniform vec2 uViewportOffset;

void main() {
    gl_Position = aPosition;
    xy = aPosition.xy * uTextureCoordScale + uViewportOffset * 0.5 * uTextureCoordScale;
}