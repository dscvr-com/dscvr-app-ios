// We will use two variables _MainTex contains
// the source texture
uniform sampler2D _MainTex;

// One Texture for each LUT (direction and color).
uniform sampler2D _LUTXTexR;
uniform sampler2D _LUTYTexR;
uniform sampler2D _LUTXTexG;
uniform sampler2D _LUTYTexG;
uniform sampler2D _LUTXTexB;
uniform sampler2D _LUTYTexB;

varying vec2 uv;

// mirror flag for right eye (textures are for left
// eye and mirrored for right eye)
bool _isMirrored = true;

// Decoding a color value from the
// texture into a float.  Similar to unitys
// DecodeFloatRGBA and DecodeFloatRG.
float DecodeFloatRGB(vec3 rgb) {
				return dot(rgb, vec3(1.0,1.0/255.0,1.0/65025.0));
}


float mirrored(float coord) {
				if (_isMirrored) {
                    return 1.0 - coord;
                }
				return coord;
}

// compute new lookup position from a LUT.
// For each color we extract the rgb value at the
// coordinate we are interested in.  This rgb value
// indicates which pixel (or interpolated pixel) we
// need to map.
// NOTE(ej) Due to our viewer orientation, we mirror y here.
vec2 LUTDistortionR(vec2 coord)
{
				vec3 lookupX = texture2D(_LUTXTexR, coord).xyz;
				vec3 lookupY = texture2D(_LUTYTexR, coord).xyz;
				return vec2(DecodeFloatRGB(lookupX),mirrored(DecodeFloatRGB(lookupY)));
}

vec2 LUTDistortionG(vec2 coord)
{
				vec3 lookupX = texture2D(_LUTXTexG, coord).rgb;
				vec3 lookupY = texture2D(_LUTYTexG, coord).rgb;
				return vec2(DecodeFloatRGB(lookupX),mirrored(DecodeFloatRGB(lookupY)));
}

vec2 LUTDistortionB(vec2 coord)
{
				vec3 lookupX = texture2D(_LUTXTexB, coord).rgb;
				vec3 lookupY = texture2D(_LUTYTexB, coord).rgb;
				return vec2(DecodeFloatRGB(lookupX),mirrored(DecodeFloatRGB(lookupY)));
}

void main() {
    //Original example
    //vec2 displacement = texture2D(_LUTXTexR, uv).rg - vec2(0.5, 0.5);
    //gl_FragColor = texture2D(_MainTex, uv + displacement * vec2(0.1,0.1));
    
    // our result will be initialized to 0/0/0.
				vec3 res = vec3(0.0,0.0,0.0);
				// Get the target (u,v) coordinate (i.uv)
				// which is where we will draw the pixel.
				// What we will draw, depends on the color
				// and the distortion, which we can look up in
				// the LUT.  We do this for each color and do
				// not put xy in rb or similar to allow us to
				// improve precision with the DecodeFloatRGB method,
				// as can be seen above.
				
				// since textures are for left eye only, we need to
				// "mirror" the input coordinate for the right eye.
				vec2 coord = vec2(uv.x, 1.0 - mirrored(uv.y));
    
				vec2 xyR = LUTDistortionR(coord);
				if (xyR.x <= 0.0 || xyR.y <= 0.0 || xyR.x >= 1.0 || xyR.y >= 1.0) {
                    // set alpha to 1 and return.
                    gl_FragColor = vec4(res, 1.0);
                    return;
                }
    
				vec2 xyG = LUTDistortionG(coord);
				if (xyG.x <= 0.0 || xyG.y <= 0.0 || xyG.x >= 1.0 || xyG.y >= 1.0) {
                    // set alpha to 1 and return.
                    gl_FragColor = vec4(res, 1.0);
                    return;
                }
    
				vec2 xyB = LUTDistortionB(coord);
				if (xyB.x <= 0.0 || xyB.y <= 0.0 || xyG.x >= 1.0 || xyG.y >= 1.0) {
                    // set alpha to 1 and return.
                    gl_FragColor = vec4(res, 1.0);
                    return;
                }
    
				res = vec3(texture2D(_MainTex,xyR).r,
                           texture2D(_MainTex,xyG).g,
                           texture2D(_MainTex,xyB).b);
    
				// set alpha to 1 and return.
				gl_FragColor = vec4(res, 1.0);
}