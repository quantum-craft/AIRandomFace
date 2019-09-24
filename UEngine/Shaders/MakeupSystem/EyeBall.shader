Shader "Unlit/eyebase"
{
	Properties
	{
		[NoScaleOffset]_BaseTexture ("BaseTexture", 2D) = "white" {}
		[NoScaleOffset]_BumpTex ("NormalTexture", 2D) = "bump" {}//法线贴图
		[NoScaleOffset]_reftex ("ReflectTexture", Cube) = "_Skybox" {}
		[Header(________________________________________________________________________)]
		_moveupdown ("MoveUpDown", Range(0, 1)) = .5
		_moveleftright ("MoveLeftRight", Range(0, 1)) = .5
		[Header(________________________________________________________________________)]
		_speccol ("CatchLightsColor", Color) = (1,1,1,1)
		_Spec ("CatchLightsPow", Range(0, 1)) = 1
		_reflectalpha ("CatchLightsAlpha", Range(0, 1)) = .5
		[Header(________________________________________________________________________)]
		[NoScaleOffset]_irisTexture ("IrisTexture", 2D) = "white" {}
		_irisTexInfo("IrisInfo[X:COL,Y:ROW]", vector) = (1, 1, 1, 1)
		_iriscol ("IrisColor", Color) = (1,1,1,1)
		_irisalpha ("IrisAlpha", Range(0, 1)) = 1
		_irisscale ("IrisScale", Range(0, 1)) = .5
		_iris ("IrisID[LD2RU]", float ) = 1
        [Header(________________________________________________________________________)]
		[NoScaleOffset]_pupilTexture ("PupilTexture", 2D) = "white" {}
		_pupilTexInfo("PupilInfo[X:COL,Y:ROW]", vector) = (1, 1, 1, 1)
		_pupilcol ("PupilColor", Color) = (0,0,0,1)
		_pupilalpha ("PupilAlpha", Range(0, 1)) = 1
		_pupilscale ("PupilScale", Range(0, 1)) = .5
		_pupil ("PupilID[LD2RU]", float ) = 1
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" } LOD 100
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
			};
			sampler2D _BaseTexture,_BumpTex,_irisTexture,_pupilTexture;
			samplerCUBE _reftex;
			half _reflectalpha,_Spec,_irisscale,_pupilscale,_pupilalpha,_irisalpha;
			half _iris,_pupil;
			half _moveupdown,_moveleftright;
			half4 _speccol,_pupilcol,_iriscol,_irisTexInfo,_pupilTexInfo;

			float2 CustomUV (float2 uv,float RowNum,float ColumnNum,float ID)
			{
				float sourceX = 1 / RowNum;
                float sourceY = 1 / ColumnNum;
				uv *= float2(sourceX,sourceY);
				float col =  floor(ID / RowNum);
				float row =  floor(ID - col*RowNum);
                uv.x += row * sourceX;
				uv.y += col * sourceY;
				uv.x = clamp(uv.x, row * sourceX , (row + 1) * sourceX);
				uv.y = clamp(uv.y, col * sourceY , (col + 1) * sourceY);
                return uv;
            }
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				o.viewDir = normalize(WorldSpaceViewDir(v.vertex));
				o.lightDir = normalize(WorldSpaceLightDir(v.vertex));
				half3 N = UnityObjectToWorldNormal(v.normal);
				half3 T = UnityObjectToWorldDir(v.tangent.xyz);
				half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
				half3 B = cross(N, T)*tangentSign ;
				o.tspace0 = half3(T.x, B.x, N.x);
				o.tspace1 = half3(T.y, B.y, N.y);
				o.tspace2 = half3(T.z, B.z, N.z);
				o.vertexNormal = N;
				return o;
			}
			
			half4 frag (v2f i) : SV_Target
			{
				_irisscale = _irisscale*-4.2+5.0;
				_pupilscale = _pupilscale*-4.2+5.0;
				_moveupdown = (_moveupdown*2-1)*.12;
				_moveleftright =(_moveleftright*2-1)*-.12;

				half Spec = 1-_Spec;
				     Spec = (_Spec*112.0+16.0);

				half2 baseuv = i.uv;
				      i.uv += fixed2(_moveleftright,_moveupdown);
				//basecol-------------------------------------------------------------------------------------------------------
				half4 basecol = tex2D(_BaseTexture, baseuv);//眼白贴图采样
				//normal--------------------------------------------------------------------------------------------------------
				half2 hmuv = (i.uv*_irisscale+(1-_irisscale)*.5);//虹膜角膜uv缩放      _scale_copy1 = 1   _irisscale = 1.5
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
                half2 iriscoluvbase = i.uv *_irisscale*1.35+(1-_irisscale*1.35)*.5;

				half2 iriscoluv = CustomUV(iriscoluvbase,_irisTexInfo.x,_irisTexInfo.y,_iris-1);
                half4 irisTex = tex2D(_irisTexture,iriscoluv);

                //pupilTex--------------------------------------------------------------------------------------------------------
				half2 pupilcoluvbase = i.uv*_pupilscale+(1-_pupilscale)*.5;
				half2 pupilcoluv = CustomUV(pupilcoluvbase,_pupilTexInfo.x,_pupilTexInfo.y,_pupil-1);
                half4 pupilTex = tex2D(_pupilTexture,pupilcoluv);

                //lightmodle--------------------------------------------------------------------------------------------------------
				half NdotL = max(0.01,dot(hmworldN, i.lightDir))*0.9+0.1;//基础光照用虹膜凹法线
				 	 NdotL = pow(NdotL,(irisTex.a+0.6))*1.2;//基础光照用虹膜凹法线
				half3 H = normalize(i.lightDir + i.viewDir);
				half NdotH = saturate(dot(jmworldN, H));//高光用角膜凸法线

				//specular--------------------------------------------------------------------------------------------------------
				half specular = pow(NdotH, Spec*saturate(irisTex.a+.5))* saturate(irisTex.a+.5)*2;

				//rim--------------------------------------------------------------------------------------------------------
				half rim = saturate((1-pow(max(0.01,dot(jmworldN,i.viewDir)),0.1))*5);
				//reflect--------------------------------------------------------------------------------------------------------
				half reflectgloss = (1-_Spec)*1.5;

				half3 viewReflectDirection = reflect(-(i.viewDir),lerp(jmworldN,i.vertexNormal,.7));
                half4 reflectcoltemp = texCUBElod(_reftex,half4(viewReflectDirection,(reflectgloss+(1-irisTex.a))*4));
                half4 reflectcol = reflectcoltemp*_speccol*1;
                half reflectcolgray = (reflectcoltemp.r*0.3+reflectcoltemp.g*0.59+reflectcoltemp.b*0.11);
                half4 refcol = pow(lerp(reflectcolgray,reflectcol,.3),2)*5;

                half refrange = saturate(irisTex.a+.3)*saturate(1-pupilTex+0.3);

				//color--------------------------------------------------------------------------------------------------------
				half4 col = basecol;
					  col = lerp(basecol,irisTex*_iriscol,(irisTex.a)*(_irisalpha));
					  col = lerp(col,_pupilcol,pupilTex*_pupilalpha);

				half4 reffincol = saturate(refcol*rim*5)*_speccol;
				fixed4 fincol =lerp(col,col*saturate(1-_reflectalpha+0.5)+reffincol,refrange*_reflectalpha);

			//************************************************
			return half4(col.rgb,refrange);
			//************************************************
			
			//************************************************
			return normal;
			//************************************************
				
				return NdotL* saturate(fincol)+specular*_speccol*saturate(_reflectalpha+0.8);
			}
			ENDCG
		}
	}
	FallBack"Diffuse"
}
