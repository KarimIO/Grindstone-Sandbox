#name Transparent Shader
#renderQueue Transparent
#geometryRenderer Mesh3d
#shaderModule vertex
#version 450

layout(set = 1, binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
} ubo;

layout(set = 2, binding = 0) uniform MeshUbo {
	mat4 model;
} meshUbo;

layout(location = 0) in vec3 vertexPosition;
layout(location = 1) in vec3 vertexNormal;
layout(location = 2) in vec3 vertexTangent;
layout(location = 3) in vec2 vertexTexCoord0;

layout(location = 0) out vec3 fragmentPosition;
layout(location = 1) out vec3 fragmentNormal;
layout(location = 2) out vec3 fragmentTangent;
layout(location = 3) out vec2 fragmentTexCoord0;

void main() {
	vec4 posVec4 = meshUbo.model * vec4(vertexPosition, 1.0);
	gl_Position = ubo.proj * ubo.view * posVec4;

	fragmentPosition = posVec4.rgb;
	fragmentNormal = vertexNormal;
	fragmentTangent = vertexTangent;
	fragmentTexCoord0 = vertexTexCoord0;
}
#endShaderModule
#shaderModule fragment
#version 450

layout(binding = 0) uniform MaterialUbo {
	vec4 color;
} materialUbo;

layout(binding = 1) uniform sampler2D albedoTexture;
layout(binding = 2) uniform sampler2D normalTexture;
layout(binding = 3) uniform sampler2D metalnessTexture;
layout(binding = 4) uniform sampler2D roughnessTexture;

layout(location = 0) in vec3 fragmentPosition;
layout(location = 1) in vec3 fragmentNormal;
layout(location = 2) in vec3 fragmentTangent;
layout(location = 3) in vec2 fragmentTexCoord0;

layout(location = 0) out vec4 outColor;

vec3 TransformNormalToWorldSpace(vec3 vertexNormalValue, vec3 normalTextureSample, vec3 vertexTangentValue) {
	vec3 bumpMapNormal = normalTextureSample;
	if (normalTextureSample == vec3(0)) {
		return vertexNormalValue;
	}

	vec3 newNormal = normalize(vertexNormalValue);
	vec3 newTangent = normalize(vertexTangentValue);
	newTangent = normalize(newTangent - dot(newTangent, newNormal) * newNormal);
	vec3 bitangent = cross(newTangent, newNormal);
	bumpMapNormal = 2.0 * bumpMapNormal - vec3(1.0, 1.0, 1.0);
	bumpMapNormal = vec3(-bumpMapNormal.xy, bumpMapNormal.z);
	mat3 tangentBitangentNormalMatrix = mat3(newTangent, bitangent, newNormal);
	return normalize(tangentBitangentNormalMatrix * bumpMapNormal);
}

void main() {
	vec4 albedo = materialUbo.color * texture(albedoTexture, fragmentTexCoord0);
	vec3 textureSpaceNormal = texture(normalTexture, fragmentTexCoord0).rgb;
	float metalness = texture(metalnessTexture, fragmentTexCoord0).r;
	float roughness = texture(roughnessTexture, fragmentTexCoord0).r;

	vec3 specular = mix(vec3(0.04), albedo.rgb, metalness);
	vec3 worldSpaceNormal = TransformNormalToWorldSpace(fragmentNormal, textureSpaceNormal, fragmentTangent);

	outColor = vec4(1,0,0,0.2);
}
#endShaderModule
