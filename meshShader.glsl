varying vec3 normal;

#ifdef VERTEX
uniform mat4 modelToScreen;

attribute vec3 VertexNormal;

vec4 position(mat4 loveTransform, vec4 homogenVertexPosition) {
	normal = VertexNormal;
	return modelToScreen * homogenVertexPosition;
}
#endif

#ifdef PIXEL

vec4 effect(vec4 colour, sampler2D image, vec2 textureCoords, vec2 windowCoords) {
	return vec4(normal/2.+0.5, 1.0);
}
#endif
