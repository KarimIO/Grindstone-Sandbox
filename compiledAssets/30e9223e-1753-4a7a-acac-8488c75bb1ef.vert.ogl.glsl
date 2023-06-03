#version 450

layout(binding = 0, std140) uniform EngineUbo
{
    mat4 proj;
    mat4 view;
    vec3 eyePos;
} ubo;

layout(location = 0) in vec2 vertexPosition;
layout(location = 0) out vec2 fragmentTexCoord;
layout(location = 1) out vec3 fragmentViewRay;

void main()
{
    gl_Position = vec4(vertexPosition, 0.0, 1.0);
    fragmentTexCoord = (vertexPosition * 0.5) + vec2(0.5);
    vec3 positionVS = vec4(gl_Position * inverse(ubo.proj)).xyz;
    fragmentViewRay = vec3(positionVS.xy / vec2(positionVS.z), 1.0);
}

