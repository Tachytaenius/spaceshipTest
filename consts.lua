local consts = {}

consts.spaceDustSectorSize = 10
consts.spaceDustPerSector = 2
consts.maxDistanceForExistingSpaceDustSectors = 2 -- well, this is actually compared along only one axis. measured in sectors
consts.distanceToCreateSpaceDustSectors = 2 -- '', also used for space dust render distance

consts.useEyeSpaceForParticlePositions = false -- else use clip space

consts.vertexFormat = {
	{"VertexPosition", "float", 3},
	{"VertexTexCoord", "float", 2},
	{"VertexNormal", "float", 3},
	-- {"VertexTangent", "float", 3},
	-- {"VertexBitangent", "float", 3}
}

return consts
