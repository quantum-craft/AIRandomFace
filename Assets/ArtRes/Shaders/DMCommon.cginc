#ifndef DM_COMMON_INCLUDED
#define DM_COMMON_INCLUDED

#define PI 3.14159f
#define E 2.71828f

inline float Pow3(half x)
{
	return x*x*x;
}

inline float Pow4(half x)
{
	return x*x*x*x;
}

inline float Pow5(half x)
{
	return x*x*x*x*x;
}

fixed4 EncodeRGBE8(in half3 rgb)
{
	fixed4 vEncoded;
	half maxComponent = max(max(rgb.r, rgb.g), rgb.b);
	half fExp = ceil(log2(maxComponent));
	vEncoded.rgb = rgb / exp2(fExp);
	vEncoded.a = (fExp + 128) / 255;
	return vEncoded;
}

half3 DecodeRGBE8(in fixed4 rgbe)
{
	half3 vDecoded;
	half fExp = rgbe.a * 255 - 128;
	vDecoded = rgbe.rgb * exp2(fExp);
	return vDecoded;
}

half4 EncodeRGBM(half3 rgb, half perc)
{
	rgb *= 1.0 / perc;
	half a = saturate(max(max(rgb.r, rgb.g), max(rgb.b, 1e-5)));
	a = ceil(a * 255.0) / 255.0;
	return half4(rgb / a, a);
} 

half3 DecodeRGBM(half4 rgbm, half perc)
{
    return perc * rgbm.rgb * rgbm.a;
}

half3 UnpackScaleNormal(half4 packedNormal, half bumpScale)
{
	half3 normal = packedNormal.xyz * 2 - 1;
	normal.xy *= bumpScale;
	return normal;
}

half3 PerPixelWorldNormal(half3 normalTangent, half4 tangentToWorld[3])
{
	half3 tangent = normalize(tangentToWorld[0].xyz);
	half3 binormal = normalize(tangentToWorld[1].xyz);
	half3 normal = normalize(tangentToWorld[2].xyz);

	tangent = normalize(tangent - normal*dot(tangent, normal));
	half3 newB = cross(tangent, normal);
	binormal = newB * sign(dot(newB, binormal));

	return normalize(tangent * normalTangent.x + binormal * normalTangent.y + normal * normalTangent.z);
}

#endif //DM_COMMON_INCLUDED