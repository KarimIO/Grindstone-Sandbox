#name Tonemap Post-Processing
#renderQueue Lighting
#shaderModule vertex
#version 450

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) out vec3 fragmentTexCoord;
layout(location = 1) out vec2 fragmentTexCoordDot;

layout(binding = 1) uniform sampler2D litSceneTexture;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

void main() {
	// TODO: Move these to uniform bufer
	// Lens distortion params

	vec2 resolution = textureSize(litSceneTexture, 0).xy;

	const float strength = 0.5f;			// s: 0 = perspective, 1 = stereographic
	const float height = tan(45.0f / 2.0f);			// h: tan(verticalFOVInRadians / 2)
	float aspectRatio = resolution.x / resolution.y;		// a: screenWidth / screenHeight
	const float cylindricalRatio = 0.5f;	// c: cylindrical distortion ratio. 1 = spherical


	gl_Position = vec4(vertexPosition, 0.0, 1.0);
	vec2 uv = (vertexPosition * 0.5f) + vec2(0.5f);
	
	{
		float scaledHeight = strength * height;
		float cylAspectRatio = aspectRatio * cylindricalRatio;
		float aspectDiagSq = aspectRatio * aspectRatio + 1.0;
		float diagSq = scaledHeight * scaledHeight * aspectDiagSq;
		vec2 signedUV = (2.0 * uv + vec2(-1.0, -1.0));

		float z = 0.5 * sqrt(diagSq + 1.0) + 0.5;
		float ny = (z - 1.0) / (cylAspectRatio * cylAspectRatio + 1.0);

		fragmentTexCoordDot = sqrt(ny) * vec2(cylAspectRatio, 1.0) * signedUV;
		fragmentTexCoord = vec3(0.5, 0.5, 1.0) * z + vec3(-0.5, -0.5, 0.0);
		fragmentTexCoord.xy += uv;
	}

	// This was used for reconstructing position from depth
	// vec3 positionVS = vec4(gl_Position * inverse(ubo.proj)).xyz;
	// fragmentViewRay = vec3(positionVS.xy / positionVS.z, 1.0f);
}
#endShaderModule
#shaderModule fragment
#version 450

layout(location = 0) in vec3 fragmentTexCoord;
layout(location = 1) in vec2 fragmentTexCoordDot;
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

vec3 applyVignette(vec3 color, vec2 screenOffset) {
	float distanceFromCenter = length(screenOffset);

	float radius = 1.6f;
	float softness = 0.8f;
	float vignette = smoothstep(radius, radius - softness, distanceFromCenter);

	return color * clamp(vignette, 0, 1);
}

vec2 redOffset   = vec2( 0.009);
vec2 greenOffset = vec2( 0.006);
vec2 blueOffset  = vec2(-0.006);

vec3 applyChromaticAbberation(sampler2D colorTexture, vec2 texCoord, vec2 direction) {
	float chromaticAbberationStrength = 0.5f;
	vec2 directionWithStrength = direction * chromaticAbberationStrength;

	vec3 color = vec3(0.0f);
	color.r  = texture(colorTexture, texCoord + (directionWithStrength * redOffset)).r;
	color.g  = texture(colorTexture, texCoord + (directionWithStrength * greenOffset)).g;
	color.b = texture(colorTexture, texCoord + (directionWithStrength * blueOffset)).b;

	return color;
}

void main() {
	// TODO: Lens distortion here
	// vec2 texCoordToSample = fragmentTexCoord;
	// texCoordToSample = distortUV(texCoordToSample);
	vec2 texCoordToSample = (dot(fragmentTexCoordDot, fragmentTexCoordDot) * vec3(-0.5, -0.5, -1.0) + fragmentTexCoord).xy;

	vec2 resolution = textureSize(litSceneTexture, 0).xy;
	vec2 screenOffset = (texCoordToSample) - vec2(0.5f);
	screenOffset = screenOffset * 2.0f * (resolution.x / resolution.y);

	vec3 sceneColor = vec3(0.0f);

	// Get color directly if not using chromatic abberation.
	// vec3 sceneColor = texture(litSceneTexture, distortedUV).rgb;
	sceneColor = applyChromaticAbberation(litSceneTexture, texCoordToSample, screenOffset);

	sceneColor = sceneColor + texture(bloomTexture, texCoordToSample).rgb;
	// sceneColor = applyVignette(sceneColor, screenOffset);
	// TODO: Do grain here
	sceneColor = hdrTransform(sceneColor);
	sceneColor = linearToSRGB(sceneColor);

	outColor = vec4(sceneColor, 1);
}
#endShaderModule
