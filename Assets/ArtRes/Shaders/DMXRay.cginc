// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef DM_XRAY_INCLUDED
#define DM_XRAY_INCLUDED

#include "UnityCG.cginc"

fixed4 	_RimXRayColor;
half 	_RimXRayPower;
half 	_RimXRayIntensity;

struct a2v{
	float4 vertex : POSITION;
	float3 normal : NORMAL;
};

struct v2f{
	float4 pos 			: SV_POSITION;
	float4 worldPos 	: TEXCOORD0;
	float3 worldNormal 	: TEXCOORD1;
};
 
v2f vert_xray(a2v v){
	v2f o;
	o.pos = UnityObjectToClipPos(v.vertex);
	o.worldPos = mul(unity_ObjectToWorld, v.vertex);
	o.worldNormal = UnityObjectToWorldNormal(v.normal);
	return o;
}

fixed4 frag_xray(v2f i) : SV_TARGET{
	fixed3 worldNormalDir = normalize(i.worldNormal);
	fixed3 worldViewDir = normalize(UnityWorldSpaceViewDir(i.worldPos));
	fixed rim = 1 - saturate(dot(worldNormalDir, worldViewDir));

	fixed3 col = _RimXRayColor.xyz * pow(rim, _RimXRayPower) * _RimXRayIntensity;
	return fixed4(col, 0.3);
}

#endif //DM_XRAY_INCLUDED