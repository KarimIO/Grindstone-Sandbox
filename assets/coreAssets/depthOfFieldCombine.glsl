#name Depth of Field (Combine Stage)
#renderQueue Lighting
#shaderModule vertex
#version 450

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) out vec2 fragmentTexCoord;
layout(location = 1) out vec3 fragmentViewRay;

layout(binding = 1) uniform sampler2D litSceneTexture;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

void main() {
	gl_Position = vec4(vertexPosition, 0.0, 1.0);
	fragmentTexCoord = (vertexPosition * 0.5f) + vec2(0.5f);

	// This was used for reconstructing position from depth
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
layout(binding = 2) uniform sampler2D depthTexture;
layout(binding = 3) uniform sampler2D nearTexture;
layout(binding = 4) uniform sampler2D farTexture;

void main() {
	float depthFromTexture = texture(depthTexture, fragmentTexCoord).x;
	float m34 = ubo.proj[2][3];
	float m33 = ubo.proj[2][2];
	float near = m34 / (m33 - 1);
	float far = m34 / (m33 + 1);
	float ndc = depthFromTexture * 2.0 - 1.0;
	float linearDepth = (2.0 * near * far) / (far + near - ndc * (far - near));

	// DOF Params:
	float apertureF = 2.0f; // This is f/2
	float focalLength = 0.05f; // Distance between lens and sensor, 50mm
	float apertureSize = focalLength / apertureF; // Diameter of aperture in meters
	float focalDistance = 8.0f; // Distance in meters
	float sensorHeight = 0.0024f; // 24mm
	
	// COC Calculation from here: http://ivizlab.sfu.ca/papers/cgf2012.pdf
	float coc = -apertureSize * (focalLength * (focalDistance - linearDepth)) / (linearDepth * (focalDistance - focalLength));
	coc = (coc / sensorHeight);
	
	vec4 unblurredColor = texture(litSceneTexture, fragmentTexCoord);
	vec4 nearColor = texture(nearTexture, fragmentTexCoord);
	vec3 farColor = texture(farTexture, fragmentTexCoord).rgb;

	vec3 focusedFarMix = mix(unblurredColor.rgb, farColor, clamp(coc, 0, 1));
	
	outColor = vec4(mix(focusedFarMix, nearColor.rgb, nearColor.a), unblurredColor.a);
}
#endShaderModule
