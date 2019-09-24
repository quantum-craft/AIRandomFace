// Unity built-in shader source. Copyright (c) 2016 Unity Technologies. MIT license (see license.txt)

// Unlit alpha-blended shader.
// - no lighting
// - no lightmap support
// - no per-material color

Shader "UEngine/UEEyeLash" {
Properties {
	_MainTex ("Base (RGB) Trans (A)", 2D) = "white" {}
	_blendColor ("EyeLashcol", Color) = (0,0,0,1)
	_saturation ("Saturation", Range(0, 1)) = 1
    _brightness ("Brightness", Range(0, 1)) = .5
	_curvature("EyeLasCurvature",Range(0,1)) = 0
	_lenght("EyeLasLenght",Range(0,1)) = 0
	_discard("Discard",Range(0,1)) = 0
	// [Toggle]_X("X", Int) = 0
	// [Toggle]_Y("Y", Int) = 0
	// [Toggle]_Z("Z", Int) = 0
	//_lenght11("Lenght11",Range(-1,1)) = 0
	//_lenght22("Lenght22",Range(-1,1)) = 0
	_Color("Color", color) = (1.0,1.0,1.0,1.0)
}

SubShader {
	Tags {"LightMode" = "LightweightForward"}
	LOD 100
	
	ZWrite Off
	//ZTest Off
	Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
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
			float4 _MainTex_ST,_blendColor;
			float _curvature;
			float _lenght,_lenght11,_lenght22;
			fixed _X,_Y,_Z;
			float _saturation,_brightness;
			float4 _Color;
			float _discard;

			v2f vert (appdata_t v)
			{
				v2f o;
				//UNITY_SETUP_INSTANCE_ID(v);
				//UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);

				//half3 N = mul(UNITY_MATRIX_IT_MV,v.normal);
				//half3 T = UnityObjectToWorldDir(v.tangent.xyz);
				//half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				//half3 B = cross(N, T)*tangentSign;

				float unpdown = v.color.r*2-1;

				//o.n = normalize(N);

				_curvature = (_curvature)*(-1.2);
				//float lenghtvs = _lenght*0.002;

				v.vertex.x  += (0+(0-.5)*_curvature*v.color.a) * sin(_curvature*v.color.a*unpdown*1.5) * 0.01;
				v.vertex.y  += (0+(0-.5)*_curvature*v.color.a) * cos(_curvature*v.color.a*unpdown*1.5) * 0.01;

                v.vertex.xyz += float3(0,1,0)*0*v.color.a;
                //v.vertex.xyz += _lenght* normalize(N);


                o.pos = UnityObjectToClipPos(v.vertex);
 
				o.texcoord = TRANSFORM_TEX(v.texcoord, _MainTex);
				o.color  = v.color ;  
				//UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				_blendColor.xyz = lerp(.5,_blendColor.xyz, _saturation );
                _blendColor.xyz =  saturate(_blendColor.xyz + _brightness*2-1);
                
				float lenghtps = _lenght*2-1;

				fixed4 col = tex2Dbias(_MainTex, float4(i.texcoord,0,-1.5));
				fixed4 col1 = tex2Dbias(_MainTex, float4(i.texcoord+fixed2(0.2,0),0,-1.5));
				fixed finalpha = saturate( saturate(lenghtps+col.g*1+col1.g*.5) * (col.b*1+col1.b*.5) );

				//fixed finalpha = saturate( saturate(lenghtps+col.g) * col.b );
				//UNITY_APPLY_FOG(i.fogCoord, col);
				//return i.color.a;
				clip(finalpha-(2*_discard-finalpha));
				//return (col.r*2-1);
				return fixed4(_blendColor.rgb,finalpha);
			}
		ENDCG
	}
}

}
