#name Tonemap Post-Processing
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

layout(binding = 1) uniform sampler2D litSceneTexture;
layout(binding = 2) uniform sampler2D bloomTexture;

vec3 linearToSRGB(vec3 inColor) {
	vec3 outColor;
	outColor.r = inColor.r <= 0.0031308 ? 12.92 * inColor.r : 1.055 * pow(inColor.r, 1.0/2.4) - 0.055;
	outColor.g = inColor.g <= 0.0031308 ? 12.92 * inColor.g : 1.055 * pow(inColor.g, 1.0/2.4) - 0.055;
	outColor.b = inColor.b <= 0.0031308 ? 12.92 * inColor.b : 1.055 * pow(inColor.b, 1.0/2.4) - 0.055;
	return outColor;
}

vec3 hdrTransform(vec3 color) {
	float a = 2.51f;
	float b = 0.03f;
	float c = 2.43f;
	float d = 0.59f;
	float e = 0.14f;

	return clamp((color*(a*color+b))/(color*(c*color+d)+e), 0, 1);
}

void main() {
	vec3 sceneColor = texture(litSceneTexture, fragmentTexCoord).rgb;
	vec3 bloomColor = texture(bloomTexture, fragmentTexCoord).rgb;
	vec3 tonemapped = hdrTransform(sceneColor + bloomColor);
	vec3 srgb = linearToSRGB(tonemapped);

	outColor = vec4(srgb, 1);
}
#endShaderModule
