#version 450

layout(binding = 2, std140) uniform MaterialUbo
{
    vec4 color;
} materialUbo;

layout(binding = 3) uniform sampler2D albedoTexture;
layout(binding = 4) uniform sampler2D normalTexture;
layout(binding = 5) uniform sampler2D metalnessTexture;
layout(binding = 6) uniform sampler2D roughnessTexture;

layout(location = 3) in vec2 fragmentTexCoord0;
layout(location = 1) in vec3 fragmentNormal;
layout(location = 2) in vec3 fragmentTangent;
layout(location = 0) out vec4 gbuffer0;
layout(location = 0) in vec3 fragmentPosition;
layout(location = 1) out vec4 gbuffer1;
layout(location = 2) out vec4 gbuffer2;
layout(location = 3) out vec4 gbuffer3;

vec3 TransformNormalToWorldSpace(vec3 vertexNormalValue, vec3 normalTextureSample, vec3 vertexTangentValue)
{
    vec3 bumpMapNormal = normalTextureSample;
    if (all(equal(normalTextureSample, vec3(0.0))))
    {
        return vertexNormalValue;
    }
    vec3 newNormal = normalize(vertexNormalValue);
    vec3 newTangent = normalize(vertexTangentValue);
    newTangent = normalize(newTangent - (newNormal * dot(newTangent, newNormal)));
    vec3 bitangent = cross(newTangent, newNormal);
    bumpMapNormal = (bumpMapNormal * 2.0) - vec3(1.0);
    bumpMapNormal = vec3(-bumpMapNormal.xy, bumpMapNormal.z);
    mat3 tangentBitangentNormalMatrix = mat3(vec3(newTangent), vec3(bitangent), vec3(newNormal));
    return normalize(tangentBitangentNormalMatrix * bumpMapNormal);
}

void main()
{
    vec4 albedo = materialUbo.color * texture(albedoTexture, fragmentTexCoord0);
    vec3 textureSpaceNormal = texture(normalTexture, fragmentTexCoord0).xyz;
    float metalness = texture(metalnessTexture, fragmentTexCoord0).x;
    float roughness = texture(roughnessTexture, fragmentTexCoord0).x;
    vec3 specular = mix(vec3(0.039999999105930328369140625), albedo.xyz, vec3(metalness));
    vec3 param = fragmentNormal;
    vec3 param_1 = textureSpaceNormal;
    vec3 param_2 = fragmentTangent;
    vec3 worldSpaceNormal = TransformNormalToWorldSpace(param, param_1, param_2);
    gbuffer0 = vec4(fragmentPosition, 1.0);
    gbuffer1 = albedo;
    gbuffer2 = vec4(worldSpaceNormal, 1.0);
    gbuffer3 = vec4(specular, roughness);
}

