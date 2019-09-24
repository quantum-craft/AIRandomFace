#ifndef DM_PBR_COMMON_INCLUDED
#define DM_PBR_COMMON_INCLUDED

#include "UnityCG.cginc"
#include "UnityLightingCommon.cginc"
#include "AutoLight.cginc"
#include "DMShadow.cginc"

#define HALF_MIN 6.103515625e-5  // 2^-14, the same value for 10, 11 and 16-bit: https://www.khronos.org/opengl/wiki/Small_Float_Formats

// Must match check of use compute buffer in LightweightPipeline.cs
// GLES check here because of WebGL 1.0 support
// TODO: check performance of using StructuredBuffer on mobile as well
#define USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA 0

struct GIInput
{
	UnityLight light; // pixel light, sent from the engine

	float3 worldPos;
	half3 worldViewDir;
	half atten;
	half3 ambient;

	// interpolated lightmap UVs are passed as full float precision data to fragment shaders
	// so lightmapUV (which is used as a tmp inside of lightmap fragment shaders) should
	// also be full float precision to avoid data loss before sampling a texture.
	float4 lightmapUV; // .xy = static lightmap UV, .zw = dynamic lightmap UV

	float4 boxMin;
	float4 boxMax;
	float4 probePosition;
	// HDR cubemap properties, use to decompress HDR texture
	float4 probeHDR;
};

// Light Indices block feature
// These are set internally by the engine upon request by RendererConfiguration.
// Check GetRendererSettings in LightweightPipeline.cs
half4 unity_LightIndicesOffsetAndCount;
half4 unity_4LightIndices0;
half4 unity_4LightIndices1;

float4 _MainLightPosition;
half4 _MainLightColor;

half4 _AdditionalLightsCount;
float4 _AdditionalLightsPosition[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsColor[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsAttenuation[MAX_VISIBLE_LIGHTS];
half4 _AdditionalLightsSpotDir[MAX_VISIBLE_LIGHTS];

#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
StructuredBuffer<int> _LightIndexBuffer;
#endif

half4 _SHCoefficients[7];

///////////////////////////////////////////////////////////////////////////////
//                          Light Helpers                                    //
///////////////////////////////////////////////////////////////////////////////

// Abstraction over Light shading data.
struct Light
{
	half3   direction;
	half3   color;
	half    distanceAttenuation;
	half    shadowAttenuation;
};

int GetPerObjectLightIndex(int index)
{
#if USE_STRUCTURED_BUFFER_FOR_LIGHT_DATA
	return _AdditionalLightsBuffer[unity_LightIndicesOffsetAndCount.x + index];
#else
	// The following code is more optimal than indexing unity_4LightIndices0.
	// Conditional moves are branch free even on mali-400
	half2 lightIndex2 = (index < 2.0h) ? unity_4LightIndices0.xy : unity_4LightIndices0.zw;
	half i_rem = (index < 2.0h) ? index : index - 2.0h;
	return (i_rem < 1.0h) ? lightIndex2.x : lightIndex2.y;
#endif
}

///////////////////////////////////////////////////////////////////////////////
//                        Attenuation Functions                               /
///////////////////////////////////////////////////////////////////////////////
// Matches Unity Vanila attenuation
// Attenuation smoothly decreases to light range.
half DistanceAttenuation(half distanceSqr, half2 distanceAttenuation)
{
	// We use a shared distance attenuation for additional directional and puctual lights
	// for directional lights attenuation will be 1
	half lightAtten = 1.0h / distanceSqr;

#if defined(SHADER_HINT_NICE_QUALITY)
	// Use the smoothing factor also used in the Unity lightmapper.
	half factor = distanceSqr * distanceAttenuation.x;
	half smoothFactor = saturate(1.0h - factor * factor);
	smoothFactor = smoothFactor * smoothFactor;
#else
	// We need to smoothly fade attenuation to light range. We start fading linearly at 80% of light range
	// Therefore:
	// fadeDistance = (0.8 * 0.8 * lightRangeSq)
	// smoothFactor = (lightRangeSqr - distanceSqr) / (lightRangeSqr - fadeDistance)
	// We can rewrite that to fit a MAD by doing
	// distanceSqr * (1.0 / (fadeDistanceSqr - lightRangeSqr)) + (-lightRangeSqr / (fadeDistanceSqr - lightRangeSqr)
	// distanceSqr *        distanceAttenuation.y            +             distanceAttenuation.z
	half smoothFactor = saturate(distanceSqr * distanceAttenuation.x + distanceAttenuation.y);
#endif

	return lightAtten * smoothFactor;
}

half AngleAttenuation(half3 spotDirection, half3 lightDirection, half2 spotAttenuation)
{
	// Spot Attenuation with a linear falloff can be defined as
	// (SdotL - cosOuterAngle) / (cosInnerAngle - cosOuterAngle)
	// This can be rewritten as
	// invAngleRange = 1.0 / (cosInnerAngle - cosOuterAngle)
	// SdotL * invAngleRange + (-cosOuterAngle * invAngleRange)
	// SdotL * spotAttenuation.x + spotAttenuation.y

	// If we precompute the terms in a MAD instruction
	half SdotL = dot(spotDirection, lightDirection);
	half atten = saturate(SdotL * spotAttenuation.x + spotAttenuation.y);
	return atten * atten;
}

///////////////////////////////////////////////////////////////////////////////
//                      Light Abstraction                                    //
///////////////////////////////////////////////////////////////////////////////

Light GetMainLight()
{
	Light light;
	light.direction = _MainLightPosition.xyz;
	light.distanceAttenuation = 1.0;
	light.shadowAttenuation = 1.0;
	light.color = _MainLightColor.rgb;

	return light;
}

Light GetMainLight(float4 shadowCoord)
{
    Light light = GetMainLight();
    light.shadowAttenuation = MainLightRealtimeShadowAttenuation(shadowCoord);
    return light;
}

Light GetAdditionalLight(int i, float3 positionWS)
{
	int perObjectLightIndex = GetPerObjectLightIndex(i);

	// The following code will turn into a branching madhouse on platforms that don't support
	// dynamic indexing. Ideally we need to configure light data at a cluster of
	// objects granularity level. We will only be able to do that when scriptable culling kicks in.
	// TODO: Use StructuredBuffer on PC/Console and profile access speed on mobile that support it.
	// Abstraction over Light input constants
	float3 lightPositionWS = _AdditionalLightsPosition[perObjectLightIndex].xyz;
	half4 distanceAndSpotAttenuation = _AdditionalLightsAttenuation[perObjectLightIndex];
	half4 spotDirection = _AdditionalLightsSpotDir[perObjectLightIndex];

	float3 lightVector = lightPositionWS - positionWS;
	float distanceSqr = max(dot(lightVector, lightVector), HALF_MIN);

	half3 lightDirection = half3(lightVector * rsqrt(distanceSqr));
	half attenuation = DistanceAttenuation(distanceSqr, distanceAndSpotAttenuation.xy);
	attenuation *= AngleAttenuation(spotDirection.xyz, lightDirection, distanceAndSpotAttenuation.zw);

	Light light;
	light.direction = lightDirection;
	light.distanceAttenuation = attenuation;

#if defined(_CHARACTOR_GRAPHIC_LOW)
	light.shadowAttenuation = 1;
#else
	light.shadowAttenuation = LocalLightRealtimeShadowAttenuation(perObjectLightIndex, positionWS);
#endif
	
	light.color = _AdditionalLightsColor[perObjectLightIndex].rgb;

	return light;
}

int GetAdditionalLightsCount()
{
	// TODO: we need to expose in SRP api an ability for the pipeline cap the amount of lights
	// in the culling. This way we could do the loop branch with an uniform
	// This would be helpful to support baking exceeding lights in SH as well
	return min(_AdditionalLightsCount.x, unity_LightIndicesOffsetAndCount.y);
}

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Setups                                      //
///////////////////////////////////////////////////////////////////////////////

inline half OneMinusReflectivityFromMetallic(half metallic)
{
	// We'll need oneMinusReflectivity, so
	//   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
	// store (1-dielectricSpec) in unity_ColorSpaceDielectricSpec.a, then
	//   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
	//                  = alpha - metallic * alpha
	half oneMinusDielectricSpec = unity_ColorSpaceDielectricSpec.a;
	return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline half3 DiffuseAndSpecularFromMetallic(half3 albedo, half metallic, out half3 specColor, out half oneMinusReflectivity)
{
	specColor = lerp(unity_ColorSpaceDielectricSpec.rgb, albedo, metallic);
	oneMinusReflectivity = OneMinusReflectivityFromMetallic(metallic);
	return albedo * oneMinusReflectivity;
}

struct FragmentCommonData
{
	half3 diffColor, specColor;
	// Note: smoothness & oneMinusReflectivity for optimization purposes, mostly for DX9 SM2.0 level.
	// Most of the math is being done on these (1-x) values, and that saves a few precious ALU slots.
	half oneMinusReflectivity, smoothness;
	half3 normalWorld, eyeVec;
	half alpha;
	float3 posWorld;
};

inline FragmentCommonData RoughnessSetup(half metal, half rough, fixed3 base, fixed3 color)
{
	half oneMinusReflectivity;
	half3 specColor;
	half3 albedo = color * base;
	half3 diffColor = DiffuseAndSpecularFromMetallic(albedo, metal, /*out*/ specColor, /*out*/ oneMinusReflectivity);

	FragmentCommonData o;
	o.diffColor = diffColor;
	o.specColor = specColor;
	o.oneMinusReflectivity = oneMinusReflectivity;
	o.smoothness = 1 - rough;
	return o;
}

half SmoothnessToPerceptualRoughness(half smoothness)
{
	return (1 - smoothness);
}

half PerceptualRoughnessToRoughness(half perceptualRoughness)
{
	return perceptualRoughness * perceptualRoughness;
}

inline half PerceptualRoughnessToSpecPower(half perceptualRoughness)
{
	half m = PerceptualRoughnessToRoughness(perceptualRoughness);   // m is the true academic roughness.
	half sq = max(1e-4f, m*m);
	half n = (2.0 / sq) - 2.0;                          // https://dl.dropboxusercontent.com/u/55891920/papers/mm_brdf.pdf
	n = max(n, 1e-4f);                                  // prevent possible cases of pow(0,0), which could happen when roughness is 1.0 and NdotH is zero
	return n;
}

inline half3 FresnelTerm(half3 F0, half cosA)
{
	half t = Pow5(1 - cosA);   // ala Schlick interpoliation
	return F0 + (1 - F0) * t;
}

// approximage Schlick with ^4 instead of ^5
inline half3 FresnelLerpFast(half3 F0, half3 F90, half cosA)
{
	half t = Pow4(1 - cosA);
	return lerp(F0, F90, t);
}

// ---------------------------------------------------------------------------
// Shifted Gamma Distribution
// ---------------------------------------------------------------------------

inline half ShiftedGama_D(half NdotH, half alpha, half theta, half gamma)
{
	half alpha2 = alpha * alpha;
	half x = 1.0 / (NdotH * NdotH) - 1.0;
	half p22 = pow(alpha, theta - 1.0) * pow(E, -(alpha2 + x) / alpha) / (pow(alpha2 + x, theta) * gamma);
	return p22 / (PI * Pow4(NdotH));
}

inline half ShiftedGama_V(half NdotL, half NdotV, half alpha)
{
	half k = 2.0 / sqrt(PI * (alpha + 2.0));
	return 1.0 / ((NdotL * (1.0 - k) + k) * (NdotV * (1.0 - k) + k));
}

// ---------------------------------------------------------------------------
// GGX
// ---------------------------------------------------------------------------

inline half GGX_D(half NdotH, half alpha)
{
	half alpha2 = alpha * alpha;
	half denom = (NdotH * alpha2 - NdotH) * NdotH + 1.0;
	return alpha2 / max(PI * denom * denom, 1e-4f);//safe
}

inline float GGX_V(half NdotL, half NdotV, half alpha)
{
	half tmp = alpha + 1.0;
	float k = tmp * tmp / 8.0;
	float G1L = 1.0 / (NdotL * (1.0 - k) + k);
	float G1V = 1.0 / (NdotV * (1.0 - k) + k);
	return G1L * G1V;
}

// ---------------------------------------------------------------------------
// Optimizing GGX Shaders with dot(L,H)
// ref: http://filmicworlds.com/blog/optimizing-ggx-shaders-with-dotlh/
// ---------------------------------------------------------------------------

inline float GGXOpt1_D(half NdotH, half alpha)
{
	float alpha2 = alpha * alpha;
	float denom = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
	return alpha2 / (PI * denom * denom);
}

inline float3 GGXOpt1_FV(half LdotH, half alpha, half F0)
{
	// F
	half F_a = 1.0;
	float F_b = Pow5(1.0 - LdotH);

	// V
	float k2 = alpha * alpha *0.25;
	float V = 1.0 / (LdotH * LdotH * (1.0 - k2) + k2);
	
	// according to Stephen Hill's optimization, 
	// origin: F0 * F_a * V + (1.0 - F0) * F_b * V
	return F0 * F_a * V + F_b * V;
}

// ----------------------------------------------------------------------------
// GGX Distribution multiplied by combined approximation of Visibility and Fresnel
// See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
// https://community.arm.com/events/1155
// ----------------------------------------------------------------------------

inline float GGXOpt2_D(half NdotH, half alpha)
{
	float alpha2 = alpha * alpha;
	float denom = NdotH * NdotH * (alpha2 - 1.0) + 1.0;
	return alpha2 / (4.0 * denom * denom);
}

inline float GGXOpt2_FV(half LdotH, half roughness)
{
	return 1.0 / (max(LdotH * LdotH, 1e-4f) * (roughness + 0.5));
}

// ----------------------------------------------------------------------------
// GlossyEnvironment - Function to integrate the specular lighting with default sky or reflection probes
// ----------------------------------------------------------------------------
struct GlossyEnvironmentData
{
	// Surface properties use for cubemap integration
	half    roughness; // CAUTION: This is perceptualRoughness but because of compatibility this name can't be change :(
	half3   reflUVW;
};

GlossyEnvironmentData GlossyEnvironmentSetup(half Smoothness, half3 worldViewDir, half3 Normal, half3 fresnel0)
{
	GlossyEnvironmentData g;

	g.roughness /* perceptualRoughness */ = SmoothnessToPerceptualRoughness(Smoothness);
	g.reflUVW = reflect(-worldViewDir, Normal);

	return g;
}

inline UnityGI GI_Base(GIInput data, half occlusion, half3 normalWorld)
{
	UnityGI o_gi;
	o_gi.light = data.light;
	o_gi.light.color *= data.atten;
	o_gi.indirect.diffuse = data.ambient * occlusion;
	return o_gi;
}

#ifdef SPECIBL
#define UNITY_SPECCUBE_LOD_STEPS 6

//-----------------------------------------------------------------------------
// Util image based lighting
//-----------------------------------------------------------------------------

// The *approximated* version of the non-linear remapping. It works by
// approximating the cone of the specular lobe, and then computing the MIP map level
// which (approximately) covers the footprint of the lobe with a single texel.
// Improves the perceptual roughness distribution.
half PerceptualRoughnessToMipmapLevel(half perceptualRoughness, uint mipMapCount)
{
    perceptualRoughness = perceptualRoughness * (1.7 - 0.7 * perceptualRoughness);

    return perceptualRoughness * mipMapCount;
}

half PerceptualRoughnessToMipmapLevel(half perceptualRoughness)
{
    return PerceptualRoughnessToMipmapLevel(perceptualRoughness, UNITY_SPECCUBE_LOD_STEPS);
}

half3 DecodeHDREnvironment(half4 encodedIrradiance, half4 decodeInstructions)
{
    // Take into account texture alpha if decodeInstructions.w is true(the alpha value affects the RGB channels)
    half alpha = max(decodeInstructions.w * (encodedIrradiance.a - 1.0) + 1.0, 0.0);

    // If Linear mode is not supported we can skip exponent part
    return (decodeInstructions.x * pow(abs(alpha), decodeInstructions.y)) * encodedIrradiance.rgb;
}

half3 GlossyEnvironmentReflection(half occlusion, GlossyEnvironmentData glossIn)
{
    half mip = PerceptualRoughnessToMipmapLevel(glossIn.roughness);
    half4 encodedIrradiance = UNITY_SAMPLE_TEXCUBE_SAMPLER_LOD(unity_SpecCube0, unity_SpecCube0, glossIn.reflUVW, mip);

#if !defined(UNITY_USE_NATIVE_HDR)
    half3 irradiance = DecodeHDREnvironment(encodedIrradiance, unity_SpecCube0_HDR);
#else
    half3 irradiance = encodedIrradiance.rbg;
#endif

    return irradiance * occlusion;
}
#endif

inline UnityGI GlobalIllumination(GIInput data, half occlusion, half3 normalWorld, GlossyEnvironmentData glossIn)
{
	UnityGI o_gi = GI_Base(data, occlusion, normalWorld);
#if defined(SPECIBL)
	o_gi.indirect.specular = GlossyEnvironmentReflection(occlusion, glossIn);
#else
	o_gi.indirect.specular = 0;
#endif
	return o_gi;
}

inline UnityGI FragmentGI(FragmentCommonData s, half occlusion, half3 ambient, half atten, UnityLight light)
{
	GIInput d;
	d.light = light;
	d.worldPos = s.posWorld;
	d.worldViewDir = -s.eyeVec;
	d.atten = atten;
	d.ambient = ambient;
	d.lightmapUV = 0;

	d.probeHDR = unity_SpecCube0_HDR;
	d.boxMin = unity_SpecCube0_BoxMin;
	d.boxMax = unity_SpecCube0_BoxMax;
	d.probePosition = unity_SpecCube0_ProbePosition;

#if defined(_CHARACTOR_GRAPHIC_LOW)
	UnityGI o_gi = GI_Base(d, occlusion, s.normalWorld);
	o_gi.indirect.specular = 0;
	return o_gi;
#else
	GlossyEnvironmentData g = GlossyEnvironmentSetup(s.smoothness, -s.eyeVec, s.normalWorld, s.specColor);
	return GlobalIllumination(d, occlusion, s.normalWorld, g);
#endif
}

inline float FresnelReflectance(half3 H, half3 V, half F0)
{
	half base = 1.0 - dot(V, H);
	float exponential = pow(base, 5.0);
	return exponential + F0 * (1.0 - exponential);
}

half SpecularKSK(sampler2D kelemenLUT, half3 N, half3 L, half3 V, half smoothness)
{
	half3 H = normalize(L + V);
	half NdotH = dot(N, H);
	float PH = pow(2.0 * tex2D(kelemenLUT, float2(NdotH, smoothness)).r, 10.0);
	half F = 0.028;// FresnelReflectance(H, V, 0.028);
	return max(PH * F / dot(H, H), 0);
}

///////////////////////////////////////////////////////////////////////////////
//                         BRDF Functions                                    //
///////////////////////////////////////////////////////////////////////////////

#define kDieletricSpec half4(0.04, 0.04, 0.04, 1.0 - 0.04) // standard dielectric reflectivity coef at incident angle (= 4%)

struct BRDFData
{
    half3 diffuse;
    half3 specular;
    half perceptualRoughness;
    half roughness;
    half roughness2;
    half grazingTerm;

    // We save some light invariant BRDF terms so we don't have to recompute
    // them in the light loop. Take a look at DirectBRDF function for detailed explaination.
    half normalizationTerm;     // roughness * 4.0 + 2.0
    half roughness2MinusOne;    // roughness² - 1.0
};

half ReflectivitySpecular(half3 specular)
{
#if defined(SHADER_API_GLES)
    return specular.r; // Red channel - because most metals are either monocrhome or with redish/yellowish tint
#else
    return max(max(specular.r, specular.g), specular.b);
#endif
}

half OneMinusReflectivityMetallic(half metallic)
{
    // We'll need oneMinusReflectivity, so
    //   1-reflectivity = 1-lerp(dielectricSpec, 1, metallic) = lerp(1-dielectricSpec, 0, metallic)
    // store (1-dielectricSpec) in kDieletricSpec.a, then
    //   1-reflectivity = lerp(alpha, 0, metallic) = alpha + metallic*(0 - alpha) =
    //                  = alpha - metallic * alpha
    half oneMinusDielectricSpec = kDieletricSpec.a;
    return oneMinusDielectricSpec - metallic * oneMinusDielectricSpec;
}

inline void InitializeBRDFData(half3 albedo, half metallic, half smoothness, out BRDFData outBRDFData)
{
    half oneMinusReflectivity = OneMinusReflectivityMetallic(metallic);
    half reflectivity = 1.0 - oneMinusReflectivity;

    outBRDFData.diffuse = albedo * oneMinusReflectivity;
    outBRDFData.specular = lerp(kDieletricSpec.rgb, albedo, metallic);

    outBRDFData.grazingTerm = saturate(smoothness + reflectivity);
    outBRDFData.perceptualRoughness = SmoothnessToPerceptualRoughness(smoothness);
    outBRDFData.roughness = PerceptualRoughnessToRoughness(outBRDFData.perceptualRoughness);
    outBRDFData.roughness2 = outBRDFData.roughness * outBRDFData.roughness;

    outBRDFData.normalizationTerm = outBRDFData.roughness * 4.0h + 2.0h;
    outBRDFData.roughness2MinusOne = outBRDFData.roughness2 - 1.0h;
}

half3 EnvironmentBRDF(BRDFData brdfData, half3 indirectDiffuse, half3 indirectSpecular, half fresnelTerm)
{
    half3 c = indirectDiffuse * brdfData.diffuse;
    float surfaceReduction = 1.0 / (brdfData.roughness2 + 1.0);
    c += surfaceReduction * indirectSpecular * lerp(brdfData.specular, brdfData.grazingTerm, fresnelTerm);
    return c;
}

// Based on Minimalist CookTorrance BRDF
// Implementation is slightly different from original derivation: http://www.thetenthplanet.de/archives/255
//
// * NDF [Modified] GGX
// * Modified Kelemen and Szirmay-​Kalos for Visibility term
// * Fresnel approximated with 1/LdotH
half3 DirectBDRF(BRDFData brdfData, half3 normalWS, half3 lightDirectionWS, half3 viewDirectionWS)
{
#ifndef _SPECULARHIGHLIGHTS_OFF
    half3 halfDir = normalize(lightDirectionWS + viewDirectionWS);

    half NoH = saturate(dot(normalWS, halfDir));
    half LoH = saturate(dot(lightDirectionWS, halfDir));

    // GGX Distribution multiplied by combined approximation of Visibility and Fresnel
    // BRDFspec = (D * V * F) / 4.0
    // D = roughness² / ( NoH² * (roughness² - 1) + 1 )²
    // V * F = 1.0 / ( LoH² * (roughness + 0.5) )
    // See "Optimizing PBR for Mobile" from Siggraph 2015 moving mobile graphics course
    // https://community.arm.com/events/1155

    // Final BRDFspec = roughness² / ( NoH² * (roughness² - 1) + 1 )² * (LoH² * (roughness + 0.5) * 4.0)
    // We further optimize a few light invariant terms
    // brdfData.normalizationTerm = (roughness + 0.5) * 4.0 rewritten as roughness * 4.0 + 2.0 to a fit a MAD.
    half d = NoH * NoH * brdfData.roughness2MinusOne + 1.00001h;

    half LoH2 = LoH * LoH;
    half specularTerm = brdfData.roughness2 / ((d * d) * max(0.1h, LoH2) * brdfData.normalizationTerm);

    // on mobiles (where half actually means something) denominator have risk of overflow
    // clamp below was added specifically to "fix" that, but dx compiler (we convert bytecode to metal/gles)
    // sees that specularTerm have only non-negative terms, so it skips max(0,..) in clamp (leaving only min(100,...))
#if defined (SHADER_API_MOBILE)
    specularTerm = clamp(specularTerm, 0.0, 100.0); // Prevent FP16 overflow on mobiles
#endif

    half3 color = specularTerm * brdfData.specular + brdfData.diffuse;
    return color;
#else
    return brdfData.diffuse;
#endif
}

///////////////////////////////////////////////////////////////////////////////
//                      Lighting Functions                                   //
///////////////////////////////////////////////////////////////////////////////
half3 LightingLambert(half3 lightColor, half3 lightDir, half3 normal)
{
    half NdotL = saturate(dot(normal, lightDir));
    return lightColor * NdotL;
}

half3 LightingSpecular(half3 lightColor, half3 lightDirectionWS, half3 normalWS, half3 viewDirectionWS, half4 specularGloss, half shininess)
{
    half3 halfVec = normalize(lightDirectionWS + viewDirectionWS);
    half NdotH = saturate(dot(normalWS, halfVec));
    half modifier = pow(NdotH, shininess) * specularGloss.a;
    half3 specularReflection = specularGloss.rgb * modifier;
    return lightColor * specularReflection;
}

half3 LightingPhysicallyBased(BRDFData brdfData, half3 lightColor, half3 lightDirectionWS, half lightAttenuation, half3 normalWS, half3 viewDirectionWS)
{
    half NdotL = saturate(dot(normalWS, lightDirectionWS));
    half3 radiance = lightColor * (lightAttenuation * NdotL);
    return DirectBDRF(brdfData, normalWS, lightDirectionWS, viewDirectionWS) * radiance;
}

half3 LightingPhysicallyBased(BRDFData brdfData, Light light, half3 normalWS, half3 viewDirectionWS)
{
    return LightingPhysicallyBased(brdfData, light.color, light.direction, light.distanceAttenuation * light.shadowAttenuation, normalWS, viewDirectionWS);
}

inline half3 AdditiveLights(BRDFData brdfData, half atten, float3 posWorld, half3 normalWorld, half3 viewDirectionWorld)
{
	half3 color = half3(0.0, 0.0, 0.0);

 //#if defined(_ADDITIONAL_LIGHTS)
    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, posWorld);
#if defined(_CHARACTOR_GRAPHIC_LOW)
		half3 lightColor = light.color * light.distanceAttenuation;
		color += LightingLambert(lightColor, light.direction, normalWorld);
#else
		color += LightingPhysicallyBased(brdfData, light, normalWorld, viewDirectionWorld);
#endif
    }
 //#endif

    return color;
}

half3 VertexLighting(float3 positionWS, half3 normalWS)
{
    half3 vertexLightColor = half3(0.0, 0.0, 0.0);

    int pixelLightCount = GetAdditionalLightsCount();
    for (int i = 0; i < pixelLightCount; ++i)
    {
        Light light = GetAdditionalLight(i, positionWS);
        half3 lightColor = light.color * light.distanceAttenuation;
        vertexLightColor += LightingLambert(lightColor, light.direction, normalWS);
    }

    return vertexLightColor;
}

///////////////////////////////////////////////////////////////////////////////
//                      LIGHTPROBE Illumination                              //
///////////////////////////////////////////////////////////////////////////////

#define DECLARE_LIGHTMAP_OR_SH(lmName, shName, index) half3 shName : TEXCOORD##index
#define OUTPUT_SH(normalWS, OUT) OUT.xyz = SampleSHVertex(normalWS)

#if defined(SHADER_API_GLES) || !defined(_NORMALMAP)
    // Evaluates SH fully in vertex
    #define EVALUATE_SH_VERTEX
#else
    // Evaluates L2 SH in vertex and L0L1 in pixel
    #define EVALUATE_SH_MIXED
#endif

half3 SHEvalLinearL0L1(half3 N, half4 shAr, half4 shAg, half4 shAb)
{
    half4 vA = half4(N, 1.0);

    half3 x1;
    // Linear (L1) + constant (L0) polynomial terms
    x1.r = dot(shAr, vA);
    x1.g = dot(shAg, vA);
    x1.b = dot(shAb, vA);

    return x1;
}

half3 SHEvalLinearL2(half3 N, half4 shBr, half4 shBg, half4 shBb, half4 shC)
{
    half3 x2;
    // 4 of the quadratic (L2) polynomials
    half4 vB = N.xyzz * N.yzzx;
    x2.r = dot(shBr, vB);
    x2.g = dot(shBg, vB);
    x2.b = dot(shBb, vB);

    // Final (5th) quadratic (L2) polynomial
    half vC = N.x * N.x - N.y * N.y;
    half3 x3 = shC.rgb * vC;

    return x2 + x3;
}

half3 SampleSH9Direct(half4 SHCoefficients[7], half3 N)
{
    half4 shAr = SHCoefficients[0];
    half4 shAg = SHCoefficients[1];
    half4 shAb = SHCoefficients[2];
    half4 shBr = SHCoefficients[3];
    half4 shBg = SHCoefficients[4];
    half4 shBb = SHCoefficients[5];
    half4 shCr = SHCoefficients[6];

    // Linear + constant polynomial terms
    half3 res = SHEvalLinearL0L1(N, shAr, shAg, shAb);

    // Quadratic polynomials
    res += SHEvalLinearL2(N, shBr, shBg, shBb, shCr);

    return res;
}

// Samples SH L0, L1 and L2 terms
half3 SampleSH(half3 normalWS)
{
    // LPPV is not supported in Ligthweight Pipeline
    half4 SHCoefficients[7];
    SHCoefficients[0] = unity_SHAr;
    SHCoefficients[1] = unity_SHAg;
    SHCoefficients[2] = unity_SHAb;
    SHCoefficients[3] = unity_SHBr;
    SHCoefficients[4] = unity_SHBg;
    SHCoefficients[5] = unity_SHBb;
    SHCoefficients[6] = unity_SHC;

    return max(half3(0, 0, 0), SampleSH9Direct(SHCoefficients, normalWS));
}

// SH Vertex Evaluation. Depending on target SH sampling might be
// done completely per vertex or mixed with L2 term per vertex and L0, L1
// per pixel. See SampleSHPixel
half3 SampleSHVertex(half3 normalWS)
{
#if defined(EVALUATE_SH_VERTEX)
    return max(half3(0, 0, 0), SampleSH(normalWS));
#elif defined(EVALUATE_SH_MIXED)
    // no max since this is only L2 contribution
    return SHEvalLinearL2(normalWS, unity_SHBr, unity_SHBg, unity_SHBb, unity_SHC);
#endif

    // Fully per-pixel. Nothing to compute.
    return half3(0.0, 0.0, 0.0);
}

// SH Pixel Evaluation. Depending on target SH sampling might be done
// mixed or fully in pixel. See SampleSHVertex
half3 SampleSHPixel(half3 L2Term, half3 normalWS)
{
#if defined(EVALUATE_SH_VERTEX)
    return L2Term;
#elif defined(EVALUATE_SH_MIXED)
    half3 L0L1Term = SHEvalLinearL0L1(normalWS, unity_SHAr, unity_SHAg, unity_SHAb);
    return max(half3(0, 0, 0), L2Term + L0L1Term);
#endif

    // Default: Evaluate SH fully per-pixel
    return SampleSH(normalWS);
}

fixed3 CalculateAmbientLight(half4 ambientSky, half4 ambientEquator, half4 ambientGround, fixed3 normalWorld)
{
#if false
	//Flat ambient is just the sky color
	fixed3 ambient = ambientSky.rgb * 0.75;
	return ambient;
#else

	//Magic constants used to tweak ambient to approximate pixel shader spherical harmonics 
	fixed3 worldUp = fixed3(0, 1, 0);
	half skyGroundDotMul = 2.5;
	half minEquatorMix = 0.5;
	half equatorColorBlur = 0.33;

	half upDot = dot(normalWorld, worldUp);

	//Fade between a flat lerp from sky to ground and a 3 way lerp based on how bright the equator light is.
	//This simulates how directional lights get blurred using spherical harmonics

	//Work out color from ground and sky, ignoring equator
	half adjustedDot = upDot * skyGroundDotMul;
	fixed3 skyGroundColor = lerp(ambientGround, ambientSky, saturate((adjustedDot + 1.0) * 0.5));

	//Work out equator lights brightness
	half equatorBright = saturate(dot(ambientEquator.rgb, ambientEquator.rgb));

	//Blur equator color with sky and ground colors based on how bright it is.
	fixed3 equatorBlurredColor = lerp(ambientEquator, saturate(ambientEquator + ambientGround + ambientSky), equatorBright * equatorColorBlur);

	//Work out 3 way lerp inc equator light
	half smoothDot = abs(upDot);
	fixed3 equatorColor = lerp(equatorBlurredColor, ambientGround, smoothDot) * step(upDot, 0) + lerp(equatorBlurredColor, ambientSky, smoothDot) * step(0, upDot);

	return lerp(skyGroundColor, equatorColor, saturate(equatorBright + minEquatorMix)) * 0.75;
#endif
}

#endif //DM_PBR_COMMON_INCLUDED