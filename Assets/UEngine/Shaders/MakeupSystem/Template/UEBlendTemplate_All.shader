Shader "UEngine/UE Blend Template All"
{
    Properties
    {
        _MainTex("Don't set, this is the face texture.", 2D) = "white" {}

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

                // ==== Your Fragment Shader codes here ====

                // ==== End of your Fragment Shader codes ====

                float3 outColor = float3(1.0f, 0.0f, 1.0f);

                return float4(outColor, faceRGBA.a);
            }
            ENDCG
        }
    }
    FallBack "Diffuse"
}
