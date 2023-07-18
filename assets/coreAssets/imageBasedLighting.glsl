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
layout(set = 1, binding = 1) uniform sampler2D brdfLUT;
layout(set = 2, binding = 0) uniform sampler2D specularMap;

const float pi = 3.14159f;

vec3 Light_F(in vec3 f0, in float f90, in float VH) {
	return f0 + (f90-f0) * pow(1-VH, 5.0f);
}

vec3 FresnelSchlickRoughness(float cosTheta, vec3 F0, float roughness) {
	return F0 + (max(vec3(1.0 - roughness), F0) - F0) * pow(clamp(1.0 - cosTheta, 0.0, 1.0), 5.0);
}   

const vec2 invAtan = vec2(0.1591, 0.3183);
vec2 SampleSphericalMap(vec3 v) {
	vec2 uv = vec2(atan(v.z, v.x), asin(v.y));
	uv *= invAtan;
	uv += 0.5;
	uv.y = -uv.y;
	return uv;
}

vec3 sphericalHarmonics[] = {
	// First Band
	vec3(.38, .43, .45),
	// Second Band
	vec3(.29, .36, .41),
	vec3(-0.04,  0.03,  0.01),
	vec3(-0.10, -0.10, -0.09),
	// Third Band
	vec3(-0.06, -0.06, -0.04),
	vec3(-0.01, -0.01, -0.05),
	vec3(-0.09, -0.13, -0.15),
	vec3(-0.06, -0.05, -0.04),
	vec3(-0.02, -0.00, -0.05)
};

vec3 GetIrradiance(vec3 normal) {
	float x = normal.x;
	float y = normal.y;
	float z = normal.z;

	float c[] = {
		0.282095,
		0.488603,
		1.092548,
		0.315392,
		0.546274
	};
	
	vec3 result = (
		sphericalHarmonics[0] * c[0] +

		sphericalHarmonics[1] * c[1] * x +
		sphericalHarmonics[2] * c[1] * y +
		sphericalHarmonics[3] * c[1] * z +

		sphericalHarmonics[4] * c[2] * z * x +
		sphericalHarmonics[5] * c[2] * y * z +
		sphericalHarmonics[6] * c[2] * y * x +
		sphericalHarmonics[7] * c[3] * (3.0 * z * z - 1.0) +
		sphericalHarmonics[8] * c[4] * (x*x - y*y)
	);

	return max(result, vec3(0.0));
}

void main() {
	vec4 gbuffer3Value = texture(gbuffer3, fragmentTexCoord);

	vec3 position = texture(gbuffer0, fragmentTexCoord).rgb;
	vec3 albedo = texture(gbuffer1, fragmentTexCoord).rgb;
	vec3 normal = texture(gbuffer2, fragmentTexCoord).rgb;
	vec3 specularInput = gbuffer3Value.rgb;
	float roughness = gbuffer3Value.a * gbuffer3Value.a;
	float ao = texture(ssao, fragmentTexCoord).r;
	
	vec3 eyeDir = normalize(ubo.eyePos - position);
	vec3 reflectRay = reflect(-eyeDir, normal);
	vec2 reflectUv = SampleSphericalMap(reflectRay);
	
	float NV = max(dot(normal, eyeDir), 0.0);
	
	const float MAX_REFLECTION_LOD = 4.0;
	vec3 f0 = 0.32 * specularInput * specularInput;
	float f90 = clamp(50 * dot(f0, vec3(0.33)), 0, 1);
	vec3 F = Light_F(f0, f90, NV);
	vec3 prefilteredColor = textureLod(specularMap, reflectUv, roughness * MAX_REFLECTION_LOD).rgb;   
	vec2 envBRDF  = texture(brdfLUT, vec2(NV, roughness)).rg;
	vec3 specular = prefilteredColor * (F * envBRDF.x + envBRDF.y);

	vec3 irradiance = GetIrradiance(normal);

	vec3 kS = F;
	vec3 kD = 1.0 - kS;
	vec3 diffuse    = irradiance * albedo;
	vec3 ambient    = (kD * diffuse + specular) * ao;

	outColor = vec4(ambient, 1);
}
#endShaderModule
