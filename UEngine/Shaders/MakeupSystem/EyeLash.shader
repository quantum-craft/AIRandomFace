// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "Unlit/EyeLash" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_eyeLashcol ("EyeLashcol", Color) = (0,0,0,1)
	_curvature("EyeLasCurvature",Range(0,1)) = 0
	_lenght("EyeLasLenght",Range(0,1)) = 0
	//_lenght11("Lenght11",Range(-1,1)) = 0
	//_Factor2("factor2",Range(0,20)) = 1
}

SubShader {
	Tags {"LightMode" = "ForwardBase"}
	LOD 100
	
	ZWrite Off
	Blend SrcAlpha OneMinusSrcAlpha 
	Cull   Off 
	
	Pass {  
		CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			//#pragma target 2.0
			//#pragma multi_compile_fog
			
			#include "UnityCG.cginc"

			struct appdata_t {
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float4 color   : Color;
				float3 normal   : Normal;
				half4 tangent 	: TANGENT;
				//UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f {
				float4 pos : SV_POSITION;
				float2 texcoord : TEXCOORD0;
				float4 color   : color;
				float3 n : TEXCOORD1;
				//UNITY_FOG_COORDS(1)
				//UNITY_VERTEX_OUTPUT_STEREO
			};

			sampler2D _MainTex;
			float4 _MainTex_ST,_eyeLashcol;
			float _curvature;
			float _lenght;
			float _lenght11;

			v2f vert (appdata_t v)
			{
				v2f o;
				//UNITY_SETUP_INSTANCE_ID(v);
				//UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				//half3 N = mul(UNITY_MATRIX_IT_MV,v.normal);
				//half3 T = UnityObjectToWorldDir(v.tangent.xyz);
				//half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				//half3 B = cross(N, T)*tangentSign;

				float shangxia = v.color.r*2-1;

				//o.n = normalize(N);

				float curvature = (_curvature*0.6+0.2)*3.14159*(-1.4)*shangxia;
				float lenghtvs = _lenght*0.002;

				v.vertex.y  += (0+(lenghtvs+0.2)*curvature*v.color.a)*sin(curvature*v.color.a)*0.005;
				v.vertex.z  += (0+(lenghtvs+0.2)*curvature*v.color.a)*cos(curvature*v.color.a)*0.005;

                v.vertex.xyz += float3(0,1,0)*lenghtvs*v.color.a;
                //v.vertex.xyz += _lenght* normalize(N);


                o.pos = UnityObjectToClipPos(v.vertex);
 
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color  = v.color ;  
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				float lenghtps = _lenght*2-1;

				fixed4 col = tex2D(_MainTex, i.texcoord);
				fixed4 col1 = tex2D(_MainTex, i.texcoord+fixed2(0.2,0));
				fixed finalpha = saturate( saturate(lenghtps+col.g*1+col1.g*.5) * (col.b*1+col1.b*.5) );
				//fixed finalpha = saturate( saturate(lenghtps+col.g) * col.b );
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return i.color.a;
				return fixed4(_eyeLashcol.rgb,finalpha);
			}
		ENDCG
	}
}

}
