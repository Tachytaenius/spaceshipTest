varying vec3 fragmentPos;

#ifdef VERTEX
uniform mat4 cameraToScreen;
uniform bool eyeSpace;
uniform vec3 drawPos;
uniform vec3 lineVector;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	// homogenVertexPosition.xyz is either 0,0,0 or 1,1,1
	fragmentPos = homogenVertexPosition.xyz * lineVector + drawPos;
	vec4 ret = vec4(fragmentPos, homogenVertexPosition.w);
	if (eyeSpace) {
		ret = cameraToScreen * ret;
	}
	return ret;
}
#endif

#ifdef PIXEL
uniform float renderDistance;
uniform float fogRange; // 0 to 1
uniform bool useFalloff; // not sent yet

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	float factor = useFalloff ? 1-min(1,max(0,(length(fragmentPos)-(renderDistance-renderDistance*fogRange))/(renderDistance*fogRange))) : 1.0;
	return colour * vec4(1, 1, 1, factor);
}
#endif
