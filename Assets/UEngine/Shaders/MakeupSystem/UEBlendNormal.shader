Shader "UEngine/UE Blend Normal"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}
        _TattooTex("Tattoo (RGBA)", 2D) = "white" {}


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
				
        
                half4 normal = tex2D(_MainTex, i.uv);
                half4 srcNormalColor = tex2D(_TattooTex, filter_uv(i.targetUV, _UVRegion));
				half4 srcNormal = half4(srcNormalColor.rg, 1, normal.a);

                normal = lerp(normal, srcNormal, srcNormalColor.b);

                return normal;
            }
            ENDCG
		}
	}
    FallBack "Diffuse"
}
