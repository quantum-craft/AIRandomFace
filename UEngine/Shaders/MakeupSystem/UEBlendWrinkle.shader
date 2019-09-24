Shader "UEngine/UE Blend Wrinkle"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}
        _TattooTex("Tattoo (RGBA)", 2D) = "white" {}
        _wrinkleMask("Wrinkle Mask", 2D) = "black" {}

		_raisedlinespow ("RaisedLinesPow", Range(0, 1)) = 1
		_fishtaillinespow ("FishtailLinesPow", Range(0, 1)) = 1
		_nasolabialfoldspow ("NasolabialFoldsPow", Range(0, 1)) = 1
    }

	SubShader
	{
		// Tags { "RenderType"="Opaque" }
		// LOD 100

		Pass
		{
            CGPROGRAM
            // #pragma vertex vert_img
            #pragma vertex vert
            #pragma fragment frag
			
            #include "UnityCG.cginc"
            #include "./CGIncludes/UETextureOperations.cginc"
            #include "./CGIncludes/UEHSBCEffect.cginc"

            sampler2D _MainTex;
            sampler2D _TattooTex;
            sampler2D _wrinkleMask;
  
			fixed _raisedlinespow,_fishtaillinespow,_nasolabialfoldspow;

            v2f_img vert(appdata_img v)
            {
                v2f_img o;
                UNITY_INITIALIZE_OUTPUT(v2f_img, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;
                return o;
            }
			
            fixed4 frag (v2f_img i) : COLOR
            {
				fixed3 NormalMap = tex2D(_MainTex, i.uv).rgb;
				half4 wrinkleMask = tex2D(_wrinkleMask, i.uv);
				half4 wrinkleNormalMap = tex2D(_TattooTex, i.uv);
				half3 wrinkleNormal = half3(wrinkleNormalMap.rg,1);
				half  wrinklelerp = saturate(wrinkleMask.r*_raisedlinespow+wrinkleMask.g*_fishtaillinespow+wrinkleMask.b*_nasolabialfoldspow);
				half3  NormalMapcol = lerp(NormalMap,wrinkleNormal,wrinklelerp).rgb;
			    return half4(NormalMapcol.rgb,1);

            }
            ENDCG
		}
	}
    FallBack "Diffuse"
}
