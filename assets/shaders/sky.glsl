#name Sky Shader
#renderQueue Unlit
#shaderModule vertex
#version 450

layout(binding = 0) uniform EngineUbo {
	mat4 proj;
	mat4 view;
	vec3 eyePos;
} ubo;

layout(binding = 1) uniform MeshUbo {
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
	vec4 posVec4 = meshUbo.model * vec4(ubo.eyePos + vertexPosition, 1.0);
	gl_Position = ubo.proj * ubo.view * posVec4;
    gl_Position = gl_Position.xyww;

	fragmentPosition = posVec4.rgb;
	fragmentNormal = vertexNormal;
	fragmentTangent = vertexTangent;
	fragmentTexCoord0 = vertexTexCoord0;
}
#endShaderModule
#shaderModule fragment
#version 450

layout(binding = 2) uniform MaterialUbo {
	vec4 baseColor;
} materialUbo;

layout(location = 0) in vec3 fragmentPosition;
layout(location = 1) in vec3 fragmentNormal;
layout(location = 2) in vec3 fragmentTangent;
layout(location = 3) in vec2 fragmentTexCoord0;

layout(location = 0) out vec4 outColor;

void main() {
	outColor = materialUbo.baseColor;
}
#endShaderModule
