Shader "UEngine/UEEyeBall"
{
	Properties
	{
		[NoScaleOffset]_BaseTexture ("BaseTexture", 2D) = "white" {}
		[NoScaleOffset]_BumpTex ("NormalTexture", 2D) = "bump" {}//法线贴图
		[NoScaleOffset]_reftex ("ReflectTexture", Cube) = "_Skybox" {}
		[Header(________________________________________________________________________)]
		_speccol ("SpecularColor", Color) = (1,1,1,1)
		_Spec ("SpecularPow", Range(8, 128)) = 128
		[Header(________________________________________________________________________)]
		[NoScaleOffset]_irisTexture ("IrisTexture", 2D) = "white" {}
		_iriscol ("IrisColor[A:Alpha]", Color) = (1,1,1,1)
		_irisscale ("IrisScale", Range(0.8, 5)) = 1.5
		_irisStartUV("IrisStartUV", Vector) = (0, 0, 0, 0)
		_irisUVDir("IrisUvDir", Vector) = (1, 0, 0, 1)

		
        [Header(________________________________________________________________________)]
		[NoScaleOffset]_pupilTexture ("PupilTexture", 2D) = "white" {}
		_pupilcol ("PupilColor[A:Alpha]", Color) = (0,0,0,1)
		_pupilscale ("PupilScale", Range(0.8, 5)) = 3
		_pupilStartUV("PupilStartUV", Vector) = (0, 0, 0, 0)
		_pupilUVDir("PupilUvDir", Vector) = (1, 0, 0, 1)

		_irisScale("_irisScale", Range(0, 1)) = .5
		_pupilScale("_pupilScale", Range(0, 1)) = .5
		_PositionX("_PositionX", Range(0, 1)) = .5
		_PositionY("_PositionY", Range(0, 1)) = .5
		_irisAlpha("_irisAlpha", Range(0, 1)) = 1
		_pupilAlpha("_pupilAlpha", Range(0, 1)) = 1

		_irissaturation ("irisSaturation", Range(0, 1)) = 1
        _irisbrightness ("irisBrightness", Range(0, 1)) = .5

        _pupilsaturation ("pupilSaturation", Range(0, 1)) = 1
        _pupilbrightness ("pupilBrightness", Range(0, 1)) = .5

        _Color("Color", color) = (1.0,1.0,1.0,1.0)

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "DEForward" } LOD 100
		Blend One Zero, Zero Zero
		Pass
		{
			CGPROGRAM
			#pragma vertex vert 
			#pragma fragment frag
			#pragma multi_compile_fwdbase
			#include "UnityCG.cginc"
			struct appdata
			{
				half4 vertex : POSITION;
				half2 uv : TEXCOORD0;
				half4 tangent 	: TANGENT;
			    half3 normal 	: NORMAL;
			};
			struct v2f
			{
				half4 vertex : SV_POSITION;
				half2 uv : TEXCOORD0;
				half3 viewDir 	: TEXCOORD1;
			    half3 lightDir 	: TEXCOORD2;
			    half3 tspace0 	: TEXCOORD3;
			    half3 tspace1 	: TEXCOORD4;
			    half3 tspace2 	: TEXCOORD5;
			    half3 vertexNormal 	: TEXCOORD6;
				half4 irisAndPupilUV: TEXCOORD7;
			};
			sampler2D _BaseTexture,_BumpTex,_irisTexture,_pupilTexture;
			samplerCUBE _reftex;
			half _Spec,_irisscale,_pupilscale;
			half2 _irisStartUV, _pupilStartUV;
			half4 _irisUVDir, _pupilUVDir;
			half4 _speccol,_pupilcol,_iriscol;
			float4 _MainLightPosition;
			float _irisScale,_pupilScale,_PositionX,_PositionY,_irisAlpha,_pupilAlpha;
			float _irissaturation,_irisbrightness,_pupilsaturation,_pupilbrightness;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				//UNITY_TRANSFER_FOG(o,o.vertex);

				//o.worldPos = mul(UNITY_MATRIX_M, v.vertex);
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				o.lightDir = normalize(_MainLightPosition.xyz);
				half3 N = UnityObjectToWorldNormal(v.normal);
				half3 T = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 B = cross(N, T)*tangentSign;
				o.tspace0 = half3(T.x, B.x, N.x);
				o.tspace1 = half3(T.y, B.y, N.y);
				o.tspace2 = half3(T.z, B.z, N.z);
				o.vertexNormal = N;

				float2x2 rotateScaleMatrix = float2x2(
					_irisUVDir.x, _irisUVDir.y,
					_irisUVDir.z, _irisUVDir.w
				);
				half2 scaledUV = clamp((v.uv - 0.5) * _irisscale + 0.5, 0, 1);
				half2 irisUV = mul(rotateScaleMatrix, scaledUV) + _irisStartUV;
				o.irisAndPupilUV.xy = irisUV;

				rotateScaleMatrix = float2x2(
					_pupilUVDir.x, _pupilUVDir.y,
					_pupilUVDir.z, _pupilUVDir.w
				);
				scaledUV = clamp((v.uv - 0.5) * _pupilscale + 0.5, 0, 1);
				half2 pupilUV = mul(rotateScaleMatrix, scaledUV) + _pupilStartUV;
				o.irisAndPupilUV.zw = pupilUV;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
                _iriscol.xyz = lerp(.5,_iriscol.xyz, _irissaturation );
                _iriscol.xyz =  saturate(_iriscol.xyz + _irisbrightness*2-1);

                _pupilcol.xyz = lerp(.5,_pupilcol.xyz, _pupilsaturation );
                _pupilcol.xyz =  saturate(_pupilcol.xyz + _pupilbrightness*2-1);

				
				 _irisScale = (_irisScale*-4.0+5.0);
				 _pupilScale = (_pupilScale*-6.0+8.0);
				 _PositionX = (_PositionX*0.2+-0.1);
				 _PositionY = (_PositionY*0.2+-0.1);
				//basecol-------------------------------------------------------------------------------------------------------
				half4 basecol = tex2D(_BaseTexture, i.uv);//眼白贴图采样
				//normal--------------------------------------------------------------------------------------------------------
				half2 moveuv = i.uv+float2(_PositionX,_PositionY);
				half2 hmuv = (moveuv*_irisScale+(1-_irisScale)*.5);//虹膜角膜uv缩放      _scale_copy1 = 1   _irisscale = 1.5

				half2 tkuv = (moveuv*_pupilScale+(1-_pupilScale)*.5);//虹膜角膜uv缩放      _scale_copy1 = 1   _irisscale = 1.5

				half4	normal = tex2D(_BumpTex, hmuv);
				half3	normalmaphm = half3(normal.rg,1) *2-1;//虹膜凹法线
				half3   hmworldN;
						hmworldN.x = dot(i.tspace0, normalmaphm);
						hmworldN.y = dot(i.tspace1, normalmaphm);
						hmworldN.z = dot(i.tspace2, normalmaphm);
						hmworldN = normalize(hmworldN);

				half3	normalmapjm = half3(normal.ba,1) *2-1;//角膜凸法线(光滑)
				half3   jmworldN;
						jmworldN.x = dot(i.tspace0, normalmapjm);
						jmworldN.y = dot(i.tspace1, normalmapjm);
						jmworldN.z = dot(i.tspace2, normalmapjm);
						jmworldN = normalize(jmworldN);


				//irisTex--------------------------------------------------------------------------------------------------------
				
				
                half4 irisTex = tex2D(_irisTexture, hmuv);

                //pupilTex--------------------------------------------------------------------------------------------------------

                half4 pupilTex = tex2D(_pupilTexture,tkuv);

                //lightmodle--------------------------------------------------------------------------------------------------------
				half NdotL = max(0.01,dot(hmworldN, i.lightDir))*0.6+0.4;//基础光照用虹膜凹法线
				 	 NdotL = pow(NdotL,(irisTex.a+0.6))*1.2;//基础光照用虹膜凹法线
				half3 H = normalize(i.lightDir + i.viewDir);
				half NdotH = saturate(dot(jmworldN, H));//高光用角膜凸法线

				//specular--------------------------------------------------------------------------------------------------------
				half specular = pow(NdotH, _Spec*saturate(irisTex.a+.5))* saturate(irisTex.a+.5)*2;

				//rim--------------------------------------------------------------------------------------------------------
				half rim = saturate((1-pow(max(0.01,dot(jmworldN,i.viewDir)),0.1))*5);
				//reflect--------------------------------------------------------------------------------------------------------
				half3 viewReflectDirection = reflect(-(i.viewDir),lerp(jmworldN,i.vertexNormal,.7));
                half4 reflectcol = texCUBElod(_reftex,half4(viewReflectDirection,(1-irisTex.a)*4));
                half reflectcolgray = (reflectcol.r*0.3+reflectcol.g*0.59+reflectcol.b*0.11);
                half4 reflectcollerp = lerp(reflectcolgray,reflectcol,.4);
                half4 refrange = saturate(irisTex.a+.5)*saturate(1-pupilTex+0.1);

				//color--------------------------------------------------------------------------------------------------------
				half4 col = basecol;
					  col = lerp(basecol,irisTex*_iriscol,(irisTex.a)*(_irisAlpha));
					  col = lerp(col,_pupilcol,pupilTex*_pupilAlpha);

				half4 refcol = saturate(reflectcollerp*rim)*refrange;

				//return irisTex;
				return NdotL*(col+refcol)+specular*_speccol;
			}
			ENDCG
		}
	}
	FallBack"Diffuse"
}
