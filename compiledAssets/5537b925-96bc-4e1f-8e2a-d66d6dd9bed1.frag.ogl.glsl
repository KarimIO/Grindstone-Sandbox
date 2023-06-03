#version 450

layout(binding = 1, std140) uniform LightUbo
{
    vec3 color;
    float attenuationRadius;
    vec3 position;
    float intensity;
} light;

layout(binding = 0, std140) uniform EngineUbo
{
    mat4 proj;
    mat4 view;
    vec3 eyePos;
} ubo;

layout(binding = 5) uniform sampler2D gbuffer3;
layout(binding = 2) uniform sampler2D gbuffer0;
layout(binding = 3) uniform sampler2D gbuffer1;
layout(binding = 4) uniform sampler2D gbuffer2;
layout(binding = 6) uniform sampler2D gbuffer4;

layout(location = 0) in vec2 fragmentTexCoord;
layout(location = 0) out vec4 outColor;
layout(location = 1) in vec3 fragmentViewRay;

vec3 Light_F(vec3 f0, float f90, float VH)
{
    return f0 + ((vec3(f90) - f0) * pow(1.0 - VH, 5.0));
}

float Light_D(float alphaSqr, float NH)
{
    float denom = ((NH * NH) * (alphaSqr - 1.0)) + 1.0;
    return alphaSqr / ((3.141590118408203125 * denom) * denom);
}

float Light_V(float NL, float NV, float alphaSqr)
{
    float Lambda_GGXV = NL * sqrt(((((-NV) * alphaSqr) + NV) * NV) + alphaSqr);
    float Lambda_GGXL = NV * sqrt(((((-NL) * alphaSqr) + NL) * NL) + alphaSqr);
    return 0.25 / (Lambda_GGXV + Lambda_GGXL);
}

vec3 BSDF(float NV, float NL, float LH, float NH, float alpha, vec3 SpecularColor)
{
    vec3 f0 = (SpecularColor * 0.319999992847442626953125) * SpecularColor;
    float f90 = clamp(50.0 * dot(f0, vec3(0.3300000131130218505859375)), 0.0, 1.0);
    vec3 param = f0;
    float param_1 = f90;
    float param_2 = LH;
    vec3 F = Light_F(param, param_1, param_2);
    float param_3 = alpha;
    float param_4 = NH;
    float D = Light_D(param_3, param_4);
    float param_5 = NL;
    float param_6 = NV;
    float param_7 = alpha;
    float Vis = Light_V(param_5, param_6, param_7);
    return (F * D) * Vis;
}

float Diff_Disney(float NdotV, float NdotL, float LdotH, float linearRoughness)
{
    float energyBias = (0.0 * (1.0 - linearRoughness)) + (0.5 * linearRoughness);
    float energyFactor = (1.0 * (1.0 - linearRoughness)) + (linearRoughness / 1.5099999904632568359375);
    float fd90 = energyBias + (((2.0 * LdotH) * LdotH) * linearRoughness);
    vec3 f0 = vec3(1.0);
    vec3 param = f0;
    float param_1 = fd90;
    float param_2 = NdotL;
    float lightScatter = Light_F(param, param_1, param_2).x;
    vec3 param_3 = f0;
    float param_4 = fd90;
    float param_5 = NdotV;
    float viewScatter = Light_F(param_3, param_4, param_5).x;
    return (lightScatter * viewScatter) * energyFactor;
}

vec3 LightPointCalc(vec3 albedo, vec3 position, vec3 specularTexture, float roughness, vec3 normal, vec3 lightPos, float lightRadius, vec3 lightColor, vec3 eyePos)
{
    vec3 lightDir = position - lightPos;
    float lightDistance = length(lightDir);
    vec3 eyeDir = normalize(eyePos - position);
    vec3 eyeReflect = reflect(-eyeDir, normal);
    lightDir = -normalize(lightDir);
    float alpha = roughness * roughness;
    float alphaSqr = alpha * alpha;
    float NL = clamp(dot(normal, lightDir), 0.0, 1.0);
    float distSqr = lightDistance * lightDistance;
    float lightRadiusSqr = lightRadius * lightRadius;
    float attenuationFactor = distSqr / lightRadiusSqr;
    float attenuation = clamp(1.0 - (attenuationFactor * attenuationFactor), 0.0, 1.0);
    attenuation = (attenuation * attenuation) / (distSqr + 0.001000000047497451305389404296875);
    vec3 H = normalize(eyeDir + lightDir);
    float NV = abs(dot(normal, eyeDir)) + 9.9999997473787516355514526367188e-06;
    float NH = clamp(dot(normal, H), 0.0, 1.0);
    float LH = clamp(dot(lightDir, H), 0.0, 1.0);
    float VH = clamp(dot(eyeDir, H), 0.0, 1.0);
    float param = NV;
    float param_1 = NL;
    float param_2 = LH;
    float param_3 = NH;
    float param_4 = alpha;
    vec3 param_5 = specularTexture;
    vec3 specular = BSDF(param, param_1, param_2, param_3, param_4, param_5);
    float param_6 = NV;
    float param_7 = NL;
    float param_8 = LH;
    float param_9 = roughness;
    vec3 diffuse = (albedo * vec3(Diff_Disney(param_6, param_7, param_8, param_9))) / vec3(3.141590118408203125);
    vec3 lightModifier = lightColor * attenuation;
    vec3 BSDFValue = diffuse + specular;
    return vec3((BSDFValue * NL) * lightModifier);
}

void main()
{
    vec4 gbuffer3Value = texture(gbuffer3, fragmentTexCoord);
    vec3 position = texture(gbuffer0, fragmentTexCoord).xyz;
    vec3 diffuse = texture(gbuffer1, fragmentTexCoord).xyz;
    vec3 normal = texture(gbuffer2, fragmentTexCoord).xyz;
    vec3 specular = gbuffer3Value.xyz;
    float roughness = gbuffer3Value.w;
    vec3 lightPow = light.color * light.intensity;
    vec3 param = diffuse;
    vec3 param_1 = position;
    vec3 param_2 = specular;
    float param_3 = roughness;
    vec3 param_4 = normal;
    vec3 param_5 = light.position;
    float param_6 = light.attenuationRadius;
    vec3 param_7 = lightPow;
    vec3 param_8 = ubo.eyePos;
    vec3 litValues = LightPointCalc(param, param_1, param_2, param_3, param_4, param_5, param_6, param_7, param_8);
    outColor = vec4(litValues, 1.0);
}

