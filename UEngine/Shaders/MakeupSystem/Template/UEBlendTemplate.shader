Shader "UEngine/UE Blend Template"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}

        _TattooTex("Tattoo(RGBA)", 2D) = "white" {}

        // ==== SpriteAtlas Properties ====
        _FaceWH("Original tattoo texture size", Vector) = (0, 0, 0, 0)
        _RectOffset("Original tattoo rect position", Vector) = (0, 0, 0, 0)
        _AtlasOffset("Atlas tattoo rect position", Vector) = (0, 0, 0, 0)
        _AtlasWH("Atlas texture size", Vector) = (0, 0, 0, 0)
        // ==== SpriteAtlas End ====

        // ==== Common Properties ====
        _UVRegion("Tattoo Texture UV Region", Vector) = (0, 0, 0, 0) // (U_MIN, U_MAX, V_MIN, V_MAX)
        _UVCenter("Tattoo Texture UV Center", Vector) = (0, 0, 0, 0)
        // ==== Common End ====

        // ==== Texture Operation Properties ====
        _TattooPositionX("Tattoo Position X", Range(-1.0, 1.0)) = 0.0
        _TattooPositionY("Tattoo Position Y", Range(-1.0, 1.0)) = 0.0
        _TattooRotation("Tattoo Rotation", Range(0.0, 360.0)) = 0.0
        _TattooScaleX("Tattoo Scale X", Range(0.0, 100.0)) = 1.0
        _TattooScaleY("Tattoo Scale Y", Range(0.0, 100.0)) = 1.0
        _TattooFlipX("Tattoo Flip X", Int) = 0
        _TattooFlipY("Tattoo Flip Y", Int) = 0
        // ==== Texture Operation End ====

        // ==== Your Properties here ====

        // ==== End of your Properties ====
    }

    SubShader
    {
        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "Assets/UEngine/Shaders/MakeupSystem/CGIncludes/UETextureOperations.cginc"
            #include "Assets/UEngine/Shaders/MakeupSystem/CGIncludes/UEHSBCEffect.cginc"

            sampler2D _MainTex;
            sampler2D _TattooTex;
            int _ShouldRender = 0;

            // ==== SpriteAtlas Uniforms ====
            float2 _FaceWH;
            float2 _RectOffset;
            float2 _AtlasOffset;
            float2 _AtlasWH;
            // ==== SpriteAtlas End ====

            // ==== Common Uniforms ====
            vector _UVRegion;
            float2 _UVCenter;
            // ==== Common End ====

            // ==== Texture Operation Uniforms ====
            half _TattooPositionX;
            half _TattooPositionY;
            float _TattooScaleX;
            float _TattooScaleY;
            float _TattooRotation;
            int _TattooFlipX;
            int _TattooFlipY;
            // ==== Texture Operation End ====

            // ==== Your Uniforms here ====

            // ==== End of your Uniforms ====

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

                return o;
            }

            fixed4 frag(v2f i) : COLOR
            {
                float4 faceRGBA = tex2D(_MainTex, i.uv);

                // ==== Makeup TypeName:  ====
                half2 targetUV = AtlasMapping(i.uv, _FaceWH, _RectOffset, _AtlasOffset, _AtlasWH);
                targetUV = ApplyTexOps(targetUV, _UVCenter, _TattooPositionX, _TattooPositionY,
                    _TattooScaleX, _TattooScaleY, _TattooRotation,
                    _TattooFlipX, _TattooFlipY);
                float4 tattooRGBA = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));
                // float4 tattooRGBA = tex2D(_TattooTex, i.uv);

                float lerp_coeff = 0.0f;
                float3 blendRGB = float3(1.0f, 0.0f, 1.0f);
                // if (_ShouldRender) {
                // ==== Your Fragment Shader codes here ====

                lerp_coeff = 0.0f;
                blendRGB = float3(1.0f, 0.0f, 1.0f);
                // ==== End of your Fragment Shader codes ====
                // }
                // ======== End:  ========

                float3 outColor = lerp(faceRGBA.rgb, blendRGB.rgb, lerp_coeff);

                return float4(outColor, faceRGBA.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
