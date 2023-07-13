#name Screen-Space Ambient Occlusion
#renderQueue Lighting
#shaderModule vertex
#version 450

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) out vec2 fragmentTexCoord;
layout(location = 1) out vec3 fragmentViewRay;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

void main() {
	gl_Position = vec4(vertexPosition, 0.0, 1.0);
	fragmentTexCoord = (vertexPosition * 0.5f) + vec2(0.5f);

	vec3 positionVS = vec4(gl_Position * inverse(ubo.proj)).xyz;
	fragmentViewRay = vec3(positionVS.xy / positionVS.z, 1.0f);
}
#endShaderModule
#shaderModule fragment
#version 450

layout(location = 0) in vec2 fragmentTexCoord;
layout(location = 1) in vec3 fragmentViewRay;
layout(location = 0) out float outColor;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

const int kernelSize = 64;
layout(set = 1, binding = 0) uniform SSAOBufferObject {
	vec4 kernels[kernelSize];
	float radius;
	float bias;
} ssaoUbo;

layout(binding = 1) uniform sampler2D gbuffer0;
layout(binding = 2) uniform sampler2D gbuffer1;
layout(binding = 3) uniform sampler2D gbuffer2;
layout(binding = 4) uniform sampler2D gbuffer3;
layout(binding = 5) uniform sampler2D gbuffer4;
layout(set = 1, binding = 1) uniform sampler2D ssaoNoise;

vec3 ViewPosFromWorldPos(vec3 worldPos) {
	return (ubo.view * vec4(worldPos, 1)).xyz;
}

vec3 ViewNormal(vec3 inNorm) {
	return mat3(ubo.view) * normalize(inNorm);
}

void main() {
	ivec2 noiseScale = textureSize(gbuffer1, 0) / 4;

	vec3 position = ViewPosFromWorldPos(texture(gbuffer0, fragmentTexCoord).rgb);
	vec3 normal = ViewNormal(texture(gbuffer2, fragmentTexCoord).rgb);
	vec2 noise = texture(ssaoNoise, fragmentTexCoord * noiseScale).rg;
	vec3 randomVec  = vec3(noise, 0); 

	vec3 tangent   = normalize(randomVec - normal * dot(randomVec, normal));
	vec3 bitangent = cross(tangent, normal);
	mat3 TBN       = mat3(tangent, bitangent, normal);

	float occlusion = 0.0;

	float radius = ssaoUbo.radius;
	float bias = ssaoUbo.bias;

	for(int i = 0; i < kernelSize; i++) {
		vec3 sampleKernel = TBN * ssaoUbo.kernels[i].xyz;
		sampleKernel = position + sampleKernel * radius;

		vec4 offset = vec4(sampleKernel, 1.0);
		offset      = ubo.proj * offset;			// from view to clip-space
		offset.xyz /= offset.w;						// perspective divide
		offset.xyz  = offset.xyz * 0.5 + vec3(0.5);	// transform to range 0.0 - 1.0

        float sampleDepth = ViewPosFromWorldPos(texture(gbuffer0, offset.xy).xyz).z;
		float rangeCheck = smoothstep(0.0, 1.0, radius / abs(position.z - sampleDepth));
		occlusion += (sampleDepth >= sampleKernel.z + bias ? 1.0 : 0.0) * rangeCheck;
	}

	outColor = 1.0 - (occlusion / kernelSize);
}
#endShaderModule
