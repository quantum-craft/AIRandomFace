#ifndef DM_ANISOTROPICS_HAIR_INCLUDED
#define DM_ANISOTROPICS_HAIR_INCLUDED

#include "DMCommon.cginc"
#include "DMPBRCommon.cginc"
#include "AutoLight.cginc"
#include "DMShadow.cginc"

fixed4 		_Color;
sampler2D 	_MainTex;
sampler2D	_AlphaTex;

#if defined(NORMALMAP) && !defined(_CHARACTOR_GRAPHIC_LOW)
sampler2D 	_BumpMap;
half 		_BumpScale;
#endif

sampler2D 	_PBRMap;


#ifdef DISSOLVE
half 		_TextureScale;
half 		_TriplanarBlendSharpness;

sampler2D 	_DissolveTex;
samplerCUBE _MaskCube;
sampler2D 	_Mask;
half 		_Dissolve;

uniform half 	_EdgeWidth;
uniform half 	_EdgeColorScale;
uniform half4 	_EdgeColor;
#endif

//#ifdef CUTOFF
fixed 		_Cutoff;
//#endif

float4 		_ShadowMapTexture_TexelSize;

half 		_Metallic;
half 		_AOStrength;

#ifdef SPEC_SHIFT
sampler2D 	_SpecShiftTex;
float4 		_SpecShiftTex_ST;
half 		_PrimarySpecShift;
half 		_PrimarySpecExp;
fixed4 		_PrimarySpecColor;
	#ifdef SECOND_SPEC_SHIFT
	half 	_SecondarySpecShift;
	half 	_SecondarySpecExp;
	fixed4 	_SecondarySpecColor;
		#ifdef SECOND_SPEC_SHIFT_MASK
		sampler2D 	_SecondarySpecMask;
		#endif
	#endif
#endif

struct appdata
{
	float4 vertex	: POSITION;
	float4 tangent	: TANGENT;
	float3 normal	: NORMAL;
	float2 uv		: TEXCOORD0;
};

struct v2f
{
	float4 pos		: SV_POSITION;
	float2 uv		: TEXCOORD0;
	half3 eyeVec	: TEXCOORD1;
	unityShadowCoord4 _ShadowCoord : TEXCOORD2;
#if defined(NORMALMAP) && !defined(_CHARACTOR_GRAPHIC_LOW)
	half4 TtoW[3]	: TEXCOORD3;
#else
	half3 posWorld		: TEXCOORD3;
	half3 normalWorld	: TEXCOORD4;
	half3 binormalWorld : TEXCOORD5;
#endif
};

half3 ShiftTangent(half3 T, half3 N, half shift)
{
	half3 shiftedT = T + shift * N;
	return normalize(shiftedT);
}

half StrandSpecular(half3 T, half3 V, half3 L, half exponent)
{
	half3 H = normalize(V + L);
	half TdotH = dot(T, H);
	half sinTH = sqrt(1 - TdotH*TdotH);
	half dirAtten = smoothstep(-1, 0, TdotH);
	return max(1e-4, dirAtten * pow(sinTH, exponent));
}

half3 Anisotropic(
	half3 diffColor,
	half3 specColor,
	half occlusion,
	half oneMinusReflectivity,
	half3 T,
	half3 N,
	half3 L,
	half3 V,
	half2 uv,
	UnityLight light,
	UnityIndirect gi)
{
	half3 H = normalize(light.dir + V);

	//half nh = saturate(dot(N, H));
	//half nl = saturate(dot(N, L));
	//half nv = saturate(dot(N, V));

	// diffuse
	//half3 diffuse = diffColor * light.color * saturate(lerp(0.25, 1.0, nl));
	half3 diffuse = diffColor * light.color;
	diffuse += diffColor * gi.diffuse;

#ifdef SPEC_SHIFT
	// shift tangents
	half shift = tex2D(_SpecShiftTex, TRANSFORM_TEX(uv, _SpecShiftTex)).r - 0.5;
	half3 t1 = ShiftTangent(T, N, _PrimarySpecShift + shift);
	// specular
	half3 specular = _PrimarySpecColor * StrandSpecular(t1, V, L, exp2(lerp(1, 11, _PrimarySpecExp)));

#if defined (_CHARACTOR_GRAPHIC_HIGH) 

	#ifdef SECOND_SPEC_SHIFT
		half3 t2 = ShiftTangent(T, N, _SecondarySpecShift + shift);
	#ifdef SECOND_SPEC_SHIFT_MASK
		// 2nd specular term, modulated with noise texture
		half specMask = tex2D(_SecondarySpecMask, uv).r;
	#else
		half specMask = 1;
	#endif
		specular += specMask * _SecondarySpecColor * StrandSpecular(t2, V, L, exp2(lerp(1, 11, _SecondarySpecExp)));
	#endif

#endif

#else
	half3 specular = 0;
#endif

	half3 final = diffuse + specular * light.color * occlusion;
	return final;
}

float3 AnisotropicNoSpec(
	half3 diffColor,
	float3 N,
	float3 L,
	UnityLight light,
	UnityIndirect gi)
{
	half nl = saturate(dot(N, L));

	// diffuse
	half3 diffuse = diffColor * light.color * saturate(lerp(0.25, 1.0, nl));
	diffuse += diffColor * gi.diffuse;

	return diffuse;
}

v2f vertZBuffer(appdata v)//1
{
	v2f o;		
	UNITY_INITIALIZE_OUTPUT(v2f, o);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;
	return o;
}

half4 fragZBuffer(v2f i) : SV_Target //1
{
	half alpha = tex2D(_AlphaTex, i.uv).a;
	clip(alpha - _Cutoff);
	return 0;
}
	
v2f vert(appdata v)
{
	v2f o;
	UNITY_INITIALIZE_OUTPUT(v2f, o);

	o.pos = UnityObjectToClipPos(v.vertex);
	o.uv = v.uv;

	float4 posWorld = mul(unity_ObjectToWorld, v.vertex);
	o.eyeVec = posWorld.xyz - _WorldSpaceCameraPos;
	float3 normalWorld = UnityObjectToWorldNormal(v.normal);
#if defined(NORMALMAP) && !defined(_CHARACTOR_GRAPHIC_LOW)
	float4 tangentWorld = float4(UnityObjectToWorldDir(v.tangent.xyz), v.tangent.w);
	half sign = tangentWorld.w * unity_WorldTransformParams.w;
	half3 binormal = cross(normalWorld, tangentWorld.xyz) * sign;
	float3x3 tangentToWorld = half3x3(tangentWorld.xyz, binormal, normalWorld);
	o.TtoW[0] = float4(tangentToWorld[0], posWorld.x);
	o.TtoW[1] = float4(tangentToWorld[1], posWorld.y);
	o.TtoW[2] = float4(tangentToWorld[2], posWorld.z);
#else
	o.posWorld = posWorld;
	o.normalWorld = normalWorld;
#endif
	//We need this for shadow receving
	o._ShadowCoord = mul(unity_WorldToShadow[0], mul(unity_ObjectToWorld, v.vertex));
	return o;
}

fixed4 frag(v2f i) : SV_Target
{
	fixed4 tBase = tex2D(_MainTex, i.uv);
	tBase.a = tex2D(_AlphaTex, i.uv).a;
	half3 pbrParams = tex2D(_PBRMap, i.uv).rgb;
	half roughness = pbrParams.r;
	half metallic = pbrParams.g;
	half occlusion = lerp(1.0, pbrParams.b, _AOStrength);

	FragmentCommonData s = RoughnessSetup(metallic, roughness, tBase.rgb, _Color);
	s.eyeVec = normalize(i.eyeVec);
#if defined(NORMALMAP) && !defined(_CHARACTOR_GRAPHIC_LOW)
	half3 binormalWorld = i.TtoW[1].xyz;// binormal
	half3 normalTangent = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
	s.normalWorld = PerPixelWorldNormal(normalTangent, i.TtoW);
	s.posWorld = half3(i.TtoW[0].w, i.TtoW[1].w, i.TtoW[2].w);
#else
	half3 binormalWorld = i.binormalWorld;
	s.normalWorld = i.normalWorld;
	s.posWorld = i.posWorld;
#endif
	UnityLight mainLight;
	mainLight.color = _MainLightColor.rgb;
	mainLight.dir = _MainLightPosition.xyz;

	// additive light
	BRDFData brdfData;
	InitializeBRDFData(tBase, metallic, s.smoothness, brdfData);

#if defined (_CHARACTOR_GRAPHIC_MEDIUM) || defined (_CHARACTOR_GRAPHIC_HIGH)
	fixed ambient = AdditiveLights(brdfData, 1.0, s.posWorld, s.normalWorld, -s.eyeVec);
#else
	fixed ambient = 0;
#endif

#if defined(SHADOWS_SCREEN)
#if defined(SHADOWS_NATIVE)
	//fixed atten = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, i._ShadowCoord.xyz);
	fixed atten = SampleShadowmap_PCF5x5Tent(i._ShadowCoord, 0);
	atten = _LightShadowData.r + atten * (1 - _LightShadowData.r);
#endif
#else
	fixed atten = 1.0;
#endif
	
	UnityGI gi = FragmentGI(s, occlusion, ambient, atten, mainLight);

	half4 color;
#if defined (_CHARACTOR_GRAPHIC_MEDIUM) || defined (_CHARACTOR_GRAPHIC_HIGH)
	color.rgb = Anisotropic(s.diffColor, s.specColor, occlusion, s.oneMinusReflectivity, binormalWorld, s.normalWorld, mainLight.dir, -s.eyeVec, i.uv, gi.light, gi.indirect);
#else
	color.rgb = AnisotropicNoSpec(s.diffColor, s.normalWorld, mainLight.dir, gi.light, gi.indirect);
#endif
	color.a = tBase.a * _Color.a;
#ifdef CUTOFF
	clip(color.a - _Cutoff);
#endif

#ifdef DISSOLVE
	float3 blending = abs(s.normalWorld.xyz);
	blending = normalize(pow(blending, _TriplanarBlendSharpness));
	blending /= (blending.x + blending.y + blending.z);

	float4 xAxis = tex2D(_DissolveTex, s.posWorld.yz / _TextureScale);
	float4 yAxis = tex2D(_DissolveTex, s.posWorld.xz / _TextureScale);
	float4 zAxis = tex2D(_DissolveTex, s.posWorld.xy / _TextureScale);
	fixed4 disst = xAxis * blending.x + yAxis * blending.y + zAxis * blending.z;
	half3 newWorldNormal = s.normalWorld * 0.5 + 0.5;
	disst.xyz += newWorldNormal;
	disst.xyz *= 0.5;

	half disStep = step(_Dissolve - _EdgeWidth, disst);
	half edge = max(min(_Dissolve, _EdgeWidth), 0.0001);
	edge = saturate((disst - _Dissolve) / edge);
	half4 maskTex = tex2D(_Mask, float2(edge, 0.5)) * _EdgeColorScale;
	maskTex *= _EdgeColor;
	maskTex.xyz = maskTex.xyz * disStep * maskTex.a + color.xyz * (1 - maskTex.a);
	color.xyz = lerp(color.xyz, maskTex.xyz * disStep, step(edge, 0.99));
	color.a = lerp(disStep, color.a, saturate(edge));
	color.a = color.a * disStep * saturate(edge);
	clip(color.a - _Cutoff);
#endif

	color.xyz = clamp(0, 1, color.xyz);

	return color;
}

half4 fragFront(v2f i) : SV_Target //2
{
	fixed4 tBase = tex2D(_MainTex, i.uv);
	tBase.a = tex2D(_AlphaTex, i.uv).a;
	half3 pbrParams = tex2D(_PBRMap, i.uv).rgb;
	half roughness = pbrParams.r;
	half metallic = pbrParams.g;
	half occlusion = lerp(1.0, pbrParams.b, _AOStrength);

	FragmentCommonData s = RoughnessSetup(metallic, roughness, tBase.rgb, _Color);
	s.eyeVec = normalize(i.eyeVec);
#if defined(NORMALMAP) && !defined(_CHARACTOR_GRAPHIC_LOW)
	half3 binormalWorld = i.TtoW[1].xyz;// binormal
	half3 normalTangent = UnpackScaleNormal(tex2D(_BumpMap, i.uv), _BumpScale);
	s.normalWorld = PerPixelWorldNormal(normalTangent, i.TtoW);
	s.posWorld = half3(i.TtoW[0].w, i.TtoW[1].w, i.TtoW[2].w);
#else
	half3 binormalWorld = i.binormalWorld;
	s.normalWorld = i.normalWorld;
	s.posWorld = i.posWorld;
#endif
	UnityLight mainLight;
	mainLight.color = _MainLightColor.rgb;
	mainLight.dir = _MainLightPosition.xyz;

	// additive light
	BRDFData brdfData;
	InitializeBRDFData(tBase, metallic, s.smoothness, brdfData);

	fixed ambient = AdditiveLights(brdfData, 1.0, s.posWorld, s.normalWorld, -s.eyeVec);

#if defined(SHADOWS_SCREEN)
#if defined(SHADOWS_NATIVE)
	//fixed atten = UNITY_SAMPLE_SHADOW(_ShadowMapTexture, i._ShadowCoord.xyz);
	fixed atten = SampleShadowmap_PCF5x5Tent(i._ShadowCoord, 0);
	atten = _LightShadowData.r + atten * (1 - _LightShadowData.r);
#endif
#else
	fixed atten = 1.0;
#endif
	UnityGI gi = FragmentGI(s, occlusion, ambient, atten, mainLight);

	half4 color;
	color.rgb = AnisotropicNoSpec(s.diffColor, s.normalWorld, mainLight.dir, gi.light, gi.indirect); // no need spec
	color.a = tBase.a * _Color.a;
#ifdef CUTOFF
	clip(color.a - _Cutoff);
#endif

#ifdef DISSOLVE
	float3 blending = abs(s.normalWorld.xyz);
	blending = normalize(pow(blending, _TriplanarBlendSharpness));
	blending /= (blending.x + blending.y + blending.z);

	float4 xAxis = tex2D(_DissolveTex, s.posWorld.yz / _TextureScale);
	float4 yAxis = tex2D(_DissolveTex, s.posWorld.xz / _TextureScale);
	float4 zAxis = tex2D(_DissolveTex, s.posWorld.xy / _TextureScale);
	fixed4 disst = xAxis * blending.x + yAxis * blending.y + zAxis * blending.z;
	half3 newWorldNormal = s.normalWorld * 0.5 + 0.5;
	disst.xyz += newWorldNormal;
	disst.xyz *= 0.5;

	half disStep = step(_Dissolve - _EdgeWidth, disst);
	half edge = min(_Dissolve, _EdgeWidth);
	edge = saturate((disst - _Dissolve) / edge);
	half4 maskTex = tex2D(_Mask, float2(edge, 0.5)) * _EdgeColorScale;
	maskTex *= _EdgeColor;
	maskTex.xyz = maskTex.xyz * disStep * maskTex.a + color.xyz * (1 - maskTex.a);
	color.xyz = lerp(color.xyz, maskTex.xyz * disStep, step(edge, 0.99));
	color.a = lerp(disStep, color.a, saturate(edge));
	color.a = color.a * disStep * saturate(edge);
	clip(color.a - _Cutoff);
#endif

	return color;
}
	
#endif //DM_ANISOTROPICS_HAIR_INCLUDED