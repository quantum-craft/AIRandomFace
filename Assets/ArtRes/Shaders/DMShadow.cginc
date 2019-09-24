#ifndef DM_SHADOW_INCLUDED
#define DM_SHADOW_INCLUDED

#include "UnityCG.cginc"

#define MAX_SHADOW_CASCADES 4
#define MAX_VISIBLE_LIGHTS 16
#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats

#if defined(SHADER_API_D3D11) || defined(SHADER_API_PSSL) || defined(SHADER_API_XBOXONE) || defined(SHADER_API_METAL) || defined(SHADER_API_VULKAN) || defined(SHADER_API_SWITCH)
#define UNITY_RAW_FAR_CLIP_VALUE (0.0)
#else
#define UNITY_RAW_FAR_CLIP_VALUE (1.0)
#endif

//CBUFFER_START(_DirectionalShadowBuffer)
#ifdef _SHADOWS_CASCADE
	float4x4 _WorldToShadow[MAX_SHADOW_CASCADES + 1];
#else
	float4x4 _WorldToShadow;
#endif

#ifdef _UNIQUE_CHAR_SHADOW
	float4x4 _WorldToShadowUnique;
#endif

half4 _DirShadowSplitSpheres0;
half4 _DirShadowSplitSpheres1;
half4 _DirShadowSplitSpheres2;
half4 _DirShadowSplitSpheres3;
half4 _DirShadowSplitSphereRadii;
half4 _ShadowData;
half4 _ShadowOffset0;
half4 _ShadowOffset1;
half4 _ShadowOffset2;
half4 _ShadowOffset3;
half4 _ShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
texture2D _DirectionalShadowmapTexture;
SamplerComparisonState sampler_DirectionalShadowmapTexture;

#ifdef _UNIQUE_CHAR_SHADOW
texture2D _ShadowCasterMap;
SamplerComparisonState sampler_ShadowCasterMap;
#endif
//CBUFFER_END

//CBUFFER_START(_LocalShadowBuffer)
float4x4    _LocalWorldToShadowAtlas[MAX_VISIBLE_LIGHTS];
half        _LocalShadowStrength[MAX_VISIBLE_LIGHTS];
half4       _LocalShadowOffset0;
half4       _LocalShadowOffset1;
half4       _LocalShadowOffset2;
half4       _LocalShadowOffset3;
half4		_LocalShadowmapSize; // (xy: 1/width and 1/height, zw: width and height)
texture2D	_LocalShadowmapTexture;
SamplerComparisonState sampler_LocalShadowmapTexture;
//CBUFFER_END

// x: global clip space bias, y: normal world space bias
float4 _ShadowBias;
float3 _LightDirection;

#ifdef ALPHA_TEST
	sampler2D _MainTex;
	half  _Cutoff;
#endif


struct v2f_shadow
{
	float4 pos : SV_POSITION;

	#ifdef ALPHA_TEST

		float2 tex : TEXCOORD1;
	#endif
		
};

float4 ClipSpaceShadowCasterPos(float4 vertex, float3 normal)
{
	float4 wPos = mul(unity_ObjectToWorld, vertex);
	float3 wNormal = UnityObjectToWorldNormal(normal);

	float invNdotL = 1.0 - saturate(dot(_LightDirection, wNormal));
    float scale = max(_ShadowBias.y * invNdotL * 2, _ShadowBias.y * 0.2);

    // normal bias is negative since we want to apply an inset normal offset
    wPos.xyz -= wNormal * scale.xxx;
    float4 clipPos = mul(UNITY_MATRIX_VP, wPos);

    // _ShadowBias.x sign depens on if platform has reversed z buffer
    clipPos.z += _ShadowBias.x;

#if UNITY_REVERSED_Z
    clipPos.z = min(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#else
    clipPos.z = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
#endif

    return clipPos;
}

v2f_shadow vert_shadow(appdata_base v)
{
	v2f_shadow o;
	o.pos = ClipSpaceShadowCasterPos(v.vertex, v.normal);

	#ifdef ALPHA_TEST
		o.tex = v.texcoord;
	#endif


	return o;
}

fixed4 frag_shadow(v2f_shadow i) : SV_Target
{	
	#ifdef ALPHA_TEST
		half4 alpha = tex2D(_MainTex, i.tex);
		clip(alpha.a - _Cutoff);
	#endif
	return 0;
}

struct ShadowSamplingData
{
    half4 shadowOffset0;
    half4 shadowOffset1;
    half4 shadowOffset2;
    half4 shadowOffset3;
    half4 shadowmapSize;
};

ShadowSamplingData GetMainLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _ShadowOffset0;
    shadowSamplingData.shadowOffset1 = _ShadowOffset1;
    shadowSamplingData.shadowOffset2 = _ShadowOffset2;
    shadowSamplingData.shadowOffset3 = _ShadowOffset3;
    shadowSamplingData.shadowmapSize = _ShadowmapSize;
    return shadowSamplingData;
}

ShadowSamplingData GetLocalLightShadowSamplingData()
{
    ShadowSamplingData shadowSamplingData;
    shadowSamplingData.shadowOffset0 = _LocalShadowOffset0;
    shadowSamplingData.shadowOffset1 = _LocalShadowOffset1;
    shadowSamplingData.shadowOffset2 = _LocalShadowOffset2;
    shadowSamplingData.shadowOffset3 = _LocalShadowOffset3;
    shadowSamplingData.shadowmapSize = _LocalShadowmapSize;
    return shadowSamplingData;
}

half LerpWhiteTo(half b, half t)
{
	half oneMinusT = 1.0 - t;
	return oneMinusT + b * t;
}

half GetMainLightShadowStrength()
{
    return _ShadowData.x;
}

half GetLocalLightShadowStrenth(int lightIndex)
{
    return _LocalShadowStrength[lightIndex];
}

#if UNITY_REVERSED_Z
#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z <= UNITY_RAW_FAR_CLIP_VALUE
#else
#define BEYOND_SHADOW_FAR(shadowCoord) shadowCoord.z >= UNITY_RAW_FAR_CLIP_VALUE
#endif

half SampleShadowmap(float4 shadowCoord, texture2D ShadowMap, SamplerComparisonState sampler_ShadowMap, ShadowSamplingData samplingData, half shadowStrength, bool isPerspectiveProjection = true)
{
    // Compiler will optimize this branch away as long as isPerspectiveProjection is known at compile time
    if (isPerspectiveProjection)
        shadowCoord.xyz /= shadowCoord.w;

    half attenuation;

#ifdef _IS_SHADOW_ENABLED
    // 4-tap hardware comparison
    half4 attenuation4;
	attenuation4.x = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData.shadowOffset0.xy, shadowCoord.z + samplingData.shadowOffset0.z);
	attenuation4.y = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData.shadowOffset1.xy, shadowCoord.z + samplingData.shadowOffset1.z);
	attenuation4.z = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData.shadowOffset2.xy, shadowCoord.z + samplingData.shadowOffset2.z);
	attenuation4.w = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy + samplingData.shadowOffset3.xy, shadowCoord.z + samplingData.shadowOffset3.z);
    attenuation = dot(attenuation4, 0.25);
#else
    // 1-tap hardware comparison
    attenuation = ShadowMap.SampleCmpLevelZero(sampler_ShadowMap, shadowCoord.xy, shadowCoord.z);
#endif

    attenuation = LerpWhiteTo(attenuation, shadowStrength);

    // Shadow coords that fall out of the light frustum volume must always return attenuation 1.0
    return BEYOND_SHADOW_FAR(shadowCoord) ? 1.0 : attenuation;
}

half ComputeCascadeIndex(float3 positionWS)
{
    // TODO: profile if there's a performance improvement if we avoid indexing here
    float3 fromCenter0 = positionWS - _DirShadowSplitSpheres0.xyz;
    float3 fromCenter1 = positionWS - _DirShadowSplitSpheres1.xyz;
    float3 fromCenter2 = positionWS - _DirShadowSplitSpheres2.xyz;
    float3 fromCenter3 = positionWS - _DirShadowSplitSpheres3.xyz;
    float4 distances2 = float4(dot(fromCenter0, fromCenter0), dot(fromCenter1, fromCenter1), dot(fromCenter2, fromCenter2), dot(fromCenter3, fromCenter3));

    half4 weights = half4(distances2 < _DirShadowSplitSphereRadii);
    weights.yzw = saturate(weights.yzw - weights.xyz);

    return 4 - dot(weights, half4(4, 3, 2, 1));
}

float4 TransformWorldToShadowCoord(float3 positionWS)
{
#ifdef _UNIQUE_CHAR_SHADOW
	return mul(_WorldToShadowUnique, float4(positionWS, 1.0));
#endif

#ifdef _SHADOWS_CASCADE
    half cascadeIndex = ComputeCascadeIndex(positionWS);
    return mul(_WorldToShadow[cascadeIndex], float4(positionWS, 1.0));
#else
    return mul(_WorldToShadow, float4(positionWS, 1.0));
#endif
}

half MainLightRealtimeShadowAttenuation(float4 shadowCoord)
{
#if !defined(_IS_SHADOW_ENABLED)
    return 1.0h;
#endif

    ShadowSamplingData shadowSamplingData = GetMainLightShadowSamplingData();
    half shadowStrength = GetMainLightShadowStrength();

#ifdef _UNIQUE_CHAR_SHADOW
    return SampleShadowmap(shadowCoord, _ShadowCasterMap, sampler_ShadowCasterMap, shadowSamplingData, shadowStrength, false);
#else
	return SampleShadowmap(shadowCoord, _DirectionalShadowmapTexture, sampler_DirectionalShadowmapTexture, shadowSamplingData, shadowStrength, false);
#endif
}

half LocalLightRealtimeShadowAttenuation(int lightIndex, float3 positionWS)
{
#if !defined(_IS_SHADOW_ENABLED)
    return 1.0h;
#else
    float4 shadowCoord = mul(_LocalWorldToShadowAtlas[lightIndex], float4(positionWS, 1.0));
    ShadowSamplingData shadowSamplingData = GetLocalLightShadowSamplingData();
    half shadowStrength = GetLocalLightShadowStrenth(lightIndex);
    return SampleShadowmap(shadowCoord, _LocalShadowmapTexture, sampler_LocalShadowmapTexture, shadowSamplingData, shadowStrength, true);
#endif
}

#endif //DM_SHADOW_INCLUDED