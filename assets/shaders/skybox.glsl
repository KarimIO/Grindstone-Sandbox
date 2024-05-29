#name Skybox (Cubemap)
#cullMode Front
#renderQueue Skybox
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
layout(location = 0) out vec3 fragCoord;

void main() {
    fragCoord = normalize(vertexPosition);

    gl_Position = ubo.proj * mat4(mat3(ubo.view)) * vec4(fragCoord, 1.0);
    gl_Position = gl_Position.xyww;
}
#endShaderModule
#shaderModule fragment
#version 450

layout(location = 0) in vec3 fragCoord;
layout(location = 0) out vec4 outColor;
layout(binding = 1) uniform samplerCube skybox;

void main() {
    outColor = textureLod(skybox, fragCoord, 0);
}
#endShaderModule
