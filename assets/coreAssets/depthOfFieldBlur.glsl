#name Depth of Field (Blur Stage)
#renderQueue Lighting
#shaderModule vertex
#version 450

layout(location = 0) in vec2 vertexPosition;

layout(location = 0) out vec2 fragmentTexCoord;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

void main() {
	gl_Position = vec4(vertexPosition, 0.0, 1.0);
	fragmentTexCoord = (vertexPosition * 0.5f) + vec2(0.5f);
}
#endShaderModule
#shaderModule fragment
#version 450

layout(location = 0) in vec2 fragmentTexCoord;

layout(location = 0) out vec4 outBlurredTexture;

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

layout(binding = 1) uniform sampler2D unblurredTexture;

#define PI 3.1415926f
#define PI_OVER_2 1.5707963f
#define PI_OVER_4 0.785398f
#define EPSILON 0.000001f

// Code source: http://www.adriancourreges.com/blog/2018/12/02/ue4-optimized-post-effects/
vec2 unitSquareToUnitDiskPolar(vec2 inCoord) {
	float radius, angle;
	
	// First region (left and right quadrants of the disk)
	if (abs(inCoord.x) > abs(inCoord.y)) {
		radius = inCoord.x;
		angle = inCoord.y / (inCoord.x + EPSILON) * PI_OVER_4;
	}
	// Second region (top and bottom quadrants of the disk)
	else {
		radius = inCoord.y;
		angle = PI_OVER_2 - (inCoord.x / (inCoord.y + EPSILON) * PI_OVER_4);
	}

	if (radius < 0) { // Always keep radius positive
		radius *= -1.0f;
		angle += PI;
	}
	
	return vec2(radius, angle);
}

vec2 squareToPolygonMapping(vec2 uv, float edgeCount, float shapeRotation) {
	vec2 polarCoord = unitSquareToUnitDiskPolar(uv);

	polarCoord.x *=
		cos(PI / edgeCount) /
		cos(polarCoord.y - (2.0f * PI / edgeCount) * floor((edgeCount * polarCoord.y + PI) / 2.0f / PI ) );

	// Apply a rotation to the polygon shape
	polarCoord.y +=  shapeRotation;

	return vec2(polarCoord.x * cos(polarCoord.y), polarCoord.x * sin(polarCoord.y));
}

void main() {
	// Exposable
	const float edgeCount = 6.0f;
	const float shapeRotation = 0.0f;
	const float blurStrength = 1.0f;

	float coc01 = texture(unblurredTexture, fragmentTexCoord).a;

	if (coc01 == 0.0f) {
		discard;
	}

	float cocPixels = coc01 * blurStrength * textureSize(unblurredTexture, 0).x;

	vec3 blurredColor = vec3(0.0f);

	const uint numTapsInAxis = 4;
	float numTapsInAxisFloat = float(numTapsInAxis);

	for (uint x = 0; x < numTapsInAxis; x++) {
		for (uint y = 0; y < numTapsInAxis; y++) {
			vec2 squareCoord = vec2(float(x) / numTapsInAxisFloat, float(y) / numTapsInAxisFloat);
			vec2 sampleCoord = squareToPolygonMapping(squareCoord, edgeCount, shapeRotation);
			blurredColor += texture(unblurredTexture, fragmentTexCoord + (sampleCoord * cocPixels)).rgb;
		}
	}

	outBlurredTexture = vec4(blurredColor / numTapsInAxisFloat*numTapsInAxisFloat, coc01);
}
#endShaderModule
