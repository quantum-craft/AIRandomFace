Shader "UEngine/UE Blend Makeup"
{
    Properties
    {
        _MainTex("Don't set this tex while used in Graphics.Blit", 2D) = "white" {}

        _TattooTex("Tattoo (RGBA)", 2D) = "white" {}
        _Hue("Hue", Range(0, 1.0)) = 0
        _Saturation("Saturation", Range(0, 1.0)) = 0.5
        _Brightness("Brightness", Range(0, 1.0)) = 0.5
        _Contrast("Contrast", Range(0, 1.0)) = 0.5
        _TattooColor("Tattoo Color", Color) = (1, 1, 1, 1)
    }

	SubShader
	{
		// Tags { "RenderType"="Opaque" }
		// LOD 100

		Pass
		{
            CGPROGRAM
            #pragma vertex vert_img
            #pragma fragment frag
			
            #include "UnityCG.cginc"

            inline float3 applyHue(float3 aColor, float aHue)
            {
                float angle = radians(aHue);
                float3 k = float3(0.57735, 0.57735, 0.57735);
                float cosAngle = cos(angle);

                // Rodrigues' rotation formula
                return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
            }

            inline float4 applyHSBCEffect(float4 startColor, fixed4 hsbc)
            {
                float hue = 360 * hsbc.r;
                float saturation = hsbc.g * 2;
                float brightness = hsbc.b * 2 - 1;
                float contrast = hsbc.a * 2;

                float4 outputColor = startColor;
                outputColor.rgb = applyHue(outputColor.rgb, hue);
                outputColor.rgb = (outputColor.rgb - 0.5f) * contrast + 0.5f;
                outputColor.rgb = outputColor.rgb + brightness;
                float3 intensity = dot(outputColor.rgb, float3(0.39, 0.59, 0.11));
                outputColor.rgb = lerp(intensity, outputColor.rgb, saturation);

                return outputColor;
            }

            sampler2D _MainTex;
            sampler2D _TattooTex;
            fixed _Hue, _Saturation, _Brightness, _Contrast;
            float4 _TattooColor;
			
            fixed4 frag (v2f_img i) : COLOR
            {
                // Matrix of skin color and tattoo color.
                // half2x4 colorMatrix = half2x4(tex2D(_MainTex, i.uv), tex2D(_TattooTex, i.uv));
                // half2 blendParam = half2(1 - colorMatrix[1][3], colorMatrix[1][3]);

                // return fixed4(mul(blendParam, colorMatrix).rgb, colorMatrix[0][3]);

                half4 tattooColor = tex2D(_TattooTex, i.uv) * _TattooColor;
                tattooColor = applyHSBCEffect(tattooColor, fixed4(_Hue, _Saturation, _Brightness, _Contrast));

                half4 faceColor = tex2D(_MainTex, i.uv);

                fixed4 outColor = lerp(faceColor, tattooColor, tattooColor.a);
                outColor.a = faceColor.a;

                return outColor;
            }
            ENDCG
		}
	}
    FallBack "Diffuse"
}
