#name Image-Based Lighting
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
layout(location = 0) out vec4 outColor;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

layout(binding = 1) uniform sampler2D gbuffer0;
layout(binding = 2) uniform sampler2D gbuffer1;
layout(binding = 3) uniform sampler2D gbuffer2;
layout(binding = 4) uniform sampler2D gbuffer3;
layout(binding = 5) uniform sampler2D gbuffer4;
layout(set = 1, binding = 0) uniform sampler2D ssao;
layout(set = 1, binding = 1) uniform sampler2D irradianceMap;

const float pi = 3.14159f;

vec3 Fresnel(in vec3 f0, in float f90, in float VH) {
	return f0 + (f90-f0) * pow(1-VH, 5.0f);
}

vec3 fresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness)
{
    return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}   

void main() {
	vec4 gbuffer3Value = texture(gbuffer3, fragmentTexCoord);

	vec3 position = texture(gbuffer0, fragmentTexCoord).rgb;
	vec3 albedo = texture(gbuffer1, fragmentTexCoord).rgb;
	vec3 normal = texture(gbuffer2, fragmentTexCoord).rgb;
	vec3 specular = gbuffer3Value.rgb;
	float roughness = gbuffer3Value.a;
	float ao = texture(ssao, fragmentTexCoord).r;
	
	vec3 eyeDir = normalize(ubo.eyePos - position);

	vec3 f0 = vec3(0.04);
	vec3 kS = fresnelSchlickRoughness(max(dot(normal, eyeDir), 0.0), f0, roughness * roughness); 
	vec3 kD = 1.0 - kS;
	vec3 irradiance = vec3(0.05, 0.1, 0.15);
	vec3 diffuse    = irradiance * albedo;
	vec3 ambient    = (kD * diffuse) * ao;

	outColor = vec4(ambient, 1);
}
#endShaderModule