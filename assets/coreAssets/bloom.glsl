#name Bloom
#renderQueue Lighting
#shaderModule compute
#version 450

const float epsilon = 1.0e-4;

layout(binding = 0) uniform ControlUniformBuffer {
    vec4 params;
    int stage;
    float LOD;
} ubo;

layout(binding = 1, rgba32f) restrict writeonly uniform image2D outImage;
layout(binding = 2) uniform sampler2D inImage1;
layout(binding = 3) uniform sampler2D inImage2;

vec4 QuadraticThreshold(vec4 color, float threshold, vec3 curve) {
    float brightness = max(max(color.r, color.g), color.b);
    float rq = clamp(brightness - curve.x, 0.0, curve.y);
    rq = (rq * rq) * curve.z;
    color *= max(rq, brightness - threshold) / max(brightness, epsilon);
    return color;
}

vec4 Prefilter(vec4 color, vec2 uv) {
    float clampValue = 20.0f;
    color = clamp(color, vec4(0.0f), vec4(clampValue));
    color = QuadraticThreshold(color, ubo.params.x, ubo.params.yzw);
    return color;
}

layout(local_size_x = 4, local_size_y = 4) in;
void main() {
    vec2 imgSize = vec2(imageSize(outImage));
    ivec2 invocID = ivec2(gl_GlobalInvocationID);
    vec2 texCoords = vec2(invocID.x / imgSize.x, invocID.y / imgSize.y);
	
	int blurSize = 16;
    vec4 blurredValue = vec4(0.0);
    for (int x = -blurSize; x < blurSize; ++x) {
        for (int y = -blurSize; y < blurSize; ++y) {
            vec2 offset = vec2(float(x), float(y)) / imgSize;
			vec2 sampleCoords = texCoords + offset;
            blurredValue += Prefilter(texture(inImage1, sampleCoords), sampleCoords);
        }
    }
	
	vec4 color = blurredValue / float(blurSize * blurSize);

    imageStore(outImage, invocID, color);
}
#endShaderModule
