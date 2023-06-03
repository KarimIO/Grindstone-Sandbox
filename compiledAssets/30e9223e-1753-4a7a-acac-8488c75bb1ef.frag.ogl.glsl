#version 450

layout(binding = 0, std140) uniform EngineUbo
{
    mat4 proj;
    mat4 view;
    vec3 eyePos;
} ubo;

layout(binding = 1) uniform sampler2D litSceneTexture;

layout(location = 0) in vec2 fragmentTexCoord;
layout(location = 0) out vec4 outColor;
layout(location = 1) in vec3 fragmentViewRay;

vec3 hdrTransform(vec3 color)
{
    float a = 2.5099999904632568359375;
    float b = 0.02999999932944774627685546875;
    float c = 2.4300000667572021484375;
    float d = 0.589999973773956298828125;
    float e = 0.14000000059604644775390625;
    return clamp((color * ((color * a) + vec3(b))) / ((color * ((color * c) + vec3(d))) + vec3(e)), vec3(0.0), vec3(1.0));
}

vec3 linearToSRGB(vec3 inColor)
{
    float _25;
    if (inColor.x <= 0.003130800090730190277099609375)
    {
        _25 = 12.9200000762939453125 * inColor.x;
    }
    else
    {
        _25 = (1.05499994754791259765625 * pow(inColor.x, 0.4166666567325592041015625)) - 0.054999999701976776123046875;
    }
    vec3 outColor_1;
    outColor_1.x = _25;
    float _47;
    if (inColor.y <= 0.003130800090730190277099609375)
    {
        _47 = 12.9200000762939453125 * inColor.y;
    }
    else
    {
        _47 = (1.05499994754791259765625 * pow(inColor.y, 0.4166666567325592041015625)) - 0.054999999701976776123046875;
    }
    outColor_1.y = _47;
    float _65;
    if (inColor.z <= 0.003130800090730190277099609375)
    {
        _65 = 12.9200000762939453125 * inColor.z;
    }
    else
    {
        _65 = (1.05499994754791259765625 * pow(inColor.z, 0.4166666567325592041015625)) - 0.054999999701976776123046875;
    }
    outColor_1.z = _65;
    return outColor_1;
}

void main()
{
    vec3 litValues = texture(litSceneTexture, fragmentTexCoord).xyz;
    vec3 param = litValues;
    vec3 tonemapped = hdrTransform(param);
    vec3 param_1 = tonemapped;
    vec3 srgb = linearToSRGB(param_1);
    outColor = vec4(srgb, 1.0);
}

