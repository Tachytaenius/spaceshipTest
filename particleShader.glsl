varying vec3 fragmentPos; // in clip/screen space or eye/camera space
varying float dist;
varying float discardFragment;

#ifdef VERTEX
uniform mat4 cameraToScreen;
uniform bool eyeSpace;
uniform vec3 drawPos;
uniform vec3 lineVector;
uniform float startDist;
uniform float endDist;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	// homogenVertexPosition.xyz is either 0,0,0 or 1,1,1
	dist = homogenVertexPosition.x == 0 ? endDist : startDist;
	fragmentPos = homogenVertexPosition.xyz * lineVector + drawPos;
	vec4 ret = vec4(fragmentPos, homogenVertexPosition.w);
	// discardFragment = 0;
	if (eyeSpace) {
		ret = cameraToScreen * ret;
	} else {
		if (ret.z < 0 || ret.z > 1) {
			discardFragment = 1;
		}
	}
	return ret;
}
#endif

#ifdef PIXEL
uniform float renderDistance;
uniform float fogRange; // 0 to 1
uniform bool useFalloff;

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	if (discardFragment != 0) {
		discard;
	}
	float factor = useFalloff ? 1-min(1,max(0,(dist-(renderDistance-renderDistance*fogRange))/(renderDistance*fogRange))) : 1.0;
	return colour * vec4(1, 1, 1, factor);
}
#endif
