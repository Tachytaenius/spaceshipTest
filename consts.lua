local consts = {}

consts.spaceDustSectorSize = 10
consts.spaceDustPerSector = 3
consts.distanceToKeepSpaceDustSectors = 2 -- well, this is actually compared along only one axis. measured in sectors. also used for space dust render distance

consts.useEyeSpaceForParticlePositions = false -- else use clip space

consts.spaceDustFogRange = 0.25 -- how much towards the end of the way to renderDistance (distanceToKeepSpaceDustSectors * spaceDustSectorSize) is fog falloff for space dust

consts.vertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3},
	-- {"VertexTangent", "float", 3},
	-- {"VertexBitangent", "float", 3}
}

return consts
