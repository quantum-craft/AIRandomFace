Shader "UEngine/UE Blend Hair"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}
        _TattooTex("Tattoo (RGBA)", 2D) = "white" {}

        _blendColor ("BlendColor", Color) = (1,0,1,1)
		_blendAlpha ("BlendAlpha", Range(0, 1)) = 1

        _saturation ("Saturation", Range(0, 1)) = 1
        _brightness ("Brightness", Range(0, 1)) = .5

		_TattooPositionX("Tattoo Position X", Range(-1.0, 1.0)) = 0.0
        _TattooPositionY("Tattoo Position Y", Range(-1.0, 1.0)) = 0.0
        _TattooRotation("Tattoo Rotation", Range(0.0, 360.0)) = 0.0
        _TattooScaleX("Tattoo Scale X", Range(0.0, 100.0)) = 1.0
        _TattooScaleY("Tattoo Scale Y", Range(0.0, 100.0)) = 1.0
        _TattooFlipX("Tattoo Flip X", Int) = 0
        _TattooFlipY("Tattoo Flip Y", Int) = 0
       
        // _TattooTileIndex("Tattoo Tile Index", Int) = -1 // Not used in shader

        _FaceWH("Original tattoo texture size", Vector) = (0, 0, 0, 0)
        _RectOffset("Original tattoo rect position", Vector) = (0, 0, 0, 0)
        _AtlasOffset("Atlas tattoo rect position", Vector) = (0, 0, 0, 0)
        _AtlasWH("Atlas texture size", Vector) = (0, 0, 0, 0)

        _UVRegion("Tattoo Texture UV Region", Vector) = (0, 0, 0, 0) // (U_MIN, U_MAX, V_MIN, V_MAX)
        _UVCenter("Tattoo Texture UV Center", Vector) = (0, 0, 0, 0)
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
  
            float4 _blendColor;
            half _blendAlpha;

			half _TattooPositionX;
            half _TattooPositionY;

            float _TattooScaleX;
            float _TattooScaleY;

            float _TattooRotation;
            int _TattooFlipX;
            int _TattooFlipY;

            float2 _FaceWH;
            float2 _RectOffset;
            float2 _AtlasOffset;
            float2 _AtlasWH;

            vector _UVRegion;
            float2 _UVCenter;

            float _saturation,_brightness;

			struct v2f
			 {
				float4 pos : SV_POSITION;
				half2 uv   : TEXCOORD0;
				half2 targetUV : TEXCOORD1;
			 };

            v2f vert(appdata_img v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.texcoord;

				float2x2 rotationM = float2x2(
                    cos(radians(_TattooRotation)), -sin(radians(_TattooRotation)),
                    sin(radians(_TattooRotation)), cos(radians(_TattooRotation)));

				half2 targetUV = AtlasMapping(v.texcoord, _FaceWH, _RectOffset, _AtlasOffset, _AtlasWH);
                targetUV = UVToLocal(targetUV, _UVCenter);
                targetUV = UVTranslation(targetUV, _TattooPositionX, _TattooPositionY);
                targetUV = UVScale(targetUV, _TattooScaleX, _TattooScaleY);
                targetUV = UVRotation(targetUV, rotationM);
                targetUV = UVTryFlip(targetUV, _TattooFlipX, _TattooFlipY);
                targetUV = UVToGlobal(targetUV, _UVCenter);

				o.targetUV = targetUV;

                return o;
            }
			
            fixed4 frag (v2f i) : COLOR
            {
                _blendColor.xyz = lerp(.5,_blendColor.xyz, _saturation );
                _blendColor.xyz =  saturate(_blendColor.xyz + _brightness*2-1);

				half4 blendTex = tex2D(_TattooTex,filter_uv(i.targetUV, _UVRegion));//filter_uv(i.targetUV, _UVRegion)
                //half4 blendTex = tex2D(_TattooTex,i.uv);
				half blendLerp = saturate(blendTex.r*_blendAlpha*1+blendTex.g*(_blendAlpha*.5+1.5)*2);

				float4 srcColor = tex2D(_MainTex, i.uv);

				srcColor.rgb = lerp(srcColor.rgb,(srcColor.rgb*_blendColor.rgb*0.2 + _blendColor.rgb*0.8), blendLerp);
				return srcColor;
            }
            ENDCG
		}
	}
    FallBack "Diffuse"
}
