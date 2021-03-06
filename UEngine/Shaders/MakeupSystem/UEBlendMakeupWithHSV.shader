﻿Shader "UEngine/UE Blend Makeup (HSV Color)"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}
        _TattooTex("Tattoo (RGBA)", 2D) = "black" {}

        _HSVColorLerp("HSVColorLerp", Int) = 0
        _Hue("Hue", Range(0, 1.0)) = 0
        _Saturation("Saturation", Range(0, 1.0)) = 0.5
        _Brightness("Brightness", Range(0, 1.0)) = 0.5
        _Contrast("Contrast", Range(0, 1.0)) = 0.5

        _TattooColor("Tattoo Color", Color) = (1, 1, 1, 1)
        _TattooDensity("Tattoo Density", Range(0, 1.0)) = 1.0

        _TattooPositionX("Tattoo Position X", Range(0, 1.0)) = 0.0
        _TattooPositionY("Tattoo Position Y", Range(0, 1.0)) = 0.0
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

        _saturation ("Saturation", Range(0, 1)) = 1
        _brightness ("Brightness", Range(0, 1)) = .5
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
            int _HSVColorLerp;
            half _Hue, _Saturation, _Brightness, _Contrast;
            float4 _TattooColor;
            half _TattooDensity;
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

                _TattooPositionX = (_TattooPositionX*2-1)*.3;
                _TattooPositionY = (_TattooPositionY*2-1)*.3;

                float2x2 rotationM = float2x2(
                    cos(radians(_TattooRotation)), -sin(radians(_TattooRotation)),
                    sin(radians(_TattooRotation)), cos(radians(_TattooRotation)));
                
                // o.uv_t = v.vertex / half2(Image.width, Image.height) + half2(0.5, 0.5);
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
                // _TattooPositionX = (_TattooPositionX*2-1)*.3;
                // _TattooPositionY = (_TattooPositionY*2-1)*.3;

                _TattooColor.xyz = lerp(.5,_TattooColor.xyz, _saturation );
                _TattooColor.xyz =  saturate(_TattooColor.xyz + _brightness*2-1);
                
                // TODO: Move out to C# codes.
                /*float2x2 rotationM = float2x2(
                    cos(radians(_TattooRotation)), -sin(radians(_TattooRotation)),
                    sin(radians(_TattooRotation)), cos(radians(_TattooRotation)));

                half2 targetUV = AtlasMapping(i.uv, _FaceWH, _RectOffset, _AtlasOffset, _AtlasWH);
                targetUV = UVToLocal(targetUV, _UVCenter);
                targetUV = UVTranslation(targetUV, _TattooPositionX, _TattooPositionY);
                targetUV = UVScale(targetUV, _TattooScaleX, _TattooScaleY);
                targetUV = UVRotation(targetUV, rotationM);
                targetUV = UVTryFlip(targetUV, _TattooFlipX, _TattooFlipY);
                targetUV = UVToGlobal(targetUV, _UVCenter);*/
                float4 tattooTexColorAlpha = tex2D(_TattooTex, filter_uv(i.targetUV, _UVRegion));
                                                     
                float4 _modifiedTattooColor;
                if (!_HSVColorLerp)
                {
                    _modifiedTattooColor = applyHSBCEffect(_TattooColor, fixed4(_Hue, _Saturation, _Brightness, _Contrast));
                }
                else
                {
                    _modifiedTattooColor = hsv2rgb(hsv_lerp(rgb2hsv(tattooTexColorAlpha), rgb2hsv(_TattooColor), _TattooColor.a));
                }
               
                float4 tattooColor = _modifiedTattooColor * _TattooDensity * tattooTexColorAlpha.a;
                
                float4 faceColor = tex2D(_MainTex, i.uv);
                
                fixed4 outColor = faceColor + faceColor * tattooColor;
                
                //outColor.a = faceColor.a;

                return outColor;
            }
            ENDCG
		}
	}
    FallBack "Diffuse"
}
