Shader "DM/Character/skin_full"
{
	Properties
	{
		_Tint("Color", color) = (1.0,1.0,1.0,1.0)
												   
														
																
		_Diffuse("Diffuse", 2D) = "white" {}
		[HideInInspector]_DiffuseScale("_DiffuseScale", float) = 1
		//_SkinContrast("Skin Contrast", float) = 0.6
		_NormalMap("Normal Map",2D) = "bump" {}
		_DetailNormal("Detail Normal",2D) = "bump" {}
		_DetailNormalStrength("Detail Normal Strength", Range(0,2)) = 1
		_LookUpMap("LUT",2D) = "white" {}
		_MaterialTex("Curature Smoothness Specular AO",2D) = "white" {}
		//_Mask("_Mask",2D) = "black" {}
		//[HDR]_CameraLightColor("Scene Light Color", color) = (1.0,1.0,1.0,1.0)

		_SmoothnessScale("Smoothness Scale",float) = 0.5
		_SpecularScale("Specular Scale",float) = 0.5
		_SmoothnessScaleView("View Smoothness Scale",float) = 0.5
		_SpecularScaleView("View Specular Scale",float) = 0.5

		_CurvatureScale("Curvature Scale", Range(0,1)) = 0.2

		_RimLightRate("Rim Light Rate", float) = 1
		_RimLightScale("Rim Light Scale", float) = 1

		[Header(_______________Make Up__________________)]
		_makeupmask("makeupmask",2D) = "black" {}
		_lightpow("_lightpow", Range(0,1)) = 0
		
		[Header(_______________Area__________________)]
		_areaMask("AreaMask",2D) = ""{}
		_areaID("AreaID",Range(0,30)) = 30
		_areaAlpha("AreaAlpha",Range(0,1)) = 1

		_Color("Color", color) = (1.0,1.0,1.0,1.0)

		

	}
		SubShader
		{
			Tags { "RenderType" = "Opaque" "PerformanceChecks" = "False" "Queue" = "Geometry+10" }
			LOD 300
			Blend One Zero, Zero Zero

		Pass
		{
			Tags{ "LightMode" = "DepthOnly" }
			ColorMask 0

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vertZBuffer
			#pragma fragment fragZBuffer

			struct appdata
			{
				float4 vertex	: POSITION;
				float4 tangent	: TANGENT;
				float3 normal	: NORMAL;
				float2 uv		: TEXCOORD0;
			};

			struct v2f
			{
				float4 pos		: SV_POSITION;
				float2 uv		: TEXCOORD0;
			};
			
			v2f vertZBuffer(appdata v)//1
			{
				v2f o;
				UNITY_INITIALIZE_OUTPUT(v2f, o);

				o.pos = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}

			half4 fragZBuffer(v2f i) : SV_Target //1
			{
				return 0;
			}
			ENDCG
		}

			Pass
			{
				Name "FORWARD"
				Tags { "LightMode" = "LightweightForward" }

				/*Stencil { 
                Ref 254
                Comp Always
                Pass Replace
                ZFail Keep
				}*/

				CGPROGRAM
// Upgrade NOTE: excluded shader from OpenGL ES 2.0 because it uses non-square matrices
#pragma exclude_renderers gles

				//#pragma target 3.0
				#pragma multi_compile _CHARACTOR_GRAPHIC_HIGH _CHARACTOR_GRAPHIC_MEDIUM _CHARACTOR_GRAPHIC_LOW

				#ifndef _CHARACTOR_GRAPHIC_LOW
					#ifndef _CHARACTOR_GRAPHIC_MEDIUM
						#define _CHARACTOR_GRAPHIC_HIGH 1
					#endif
				#endif
				#pragma multi_compile __ _UNIQUE_CHAR_SHADOW //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				#pragma multi_compile __ SELFSHADOW //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
				#define _IS_SHADOW_ENABLED 1//(defined(SHADOWS_SCREEN) || defined(SHADOWS_DEPTH) || defined(SHADOWS_CUBE))
				#pragma multi_compile  _FINALCOLOR _DIFFUSE_ON _SPECULAR_ON _INSPECULAR_ON 

				#pragma vertex vert
				#pragma fragment frag

				#define SELFSHADOW 1

				#include "DMCommon.cginc"
				#include "DMPBRCommon.cginc"
				#include "DMShadow.cginc"
				#include "AutoLight.cginc"


				inline half3 GetEffectLight(float3 posWorld, half3 normalWorld)
				{
					half3 color = half3(0.0, 0.0, 0.0);

					//#if defined(_ADDITIONAL_LIGHTS)
					int pixelLightCount = GetAdditionalLightsCount();
					for (int i = 0; i < pixelLightCount; ++i)
					{
						Light light = GetAdditionalLight(i, posWorld);
						half3 lightColor = light.color * light.distanceAttenuation;
						color += LightingLambert(lightColor, light.direction, normalWorld);
					}
					//#endif

					return color;
				}

				half3 MyUnityGI_IndirectSpecular(half roughness, half3 reflUVW, half _metalness)
				{
					half perceptualRoughness = roughness;
					perceptualRoughness = perceptualRoughness * (1.3 - 0.7*perceptualRoughness);
					half mip = perceptualRoughness * 6;
					//half mip = perceptualRoughnessToMipmapLevel(perceptualRoughness);
					half3 R = reflUVW;
					half4 rgbm = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, mip);
					return DecodeHDR(rgbm, unity_SpecCube0_HDR);
				}

				half3 EnvBRDFApprox(half3 SpecularColor, half Roughness, half NoV)
				{
					const half4 c0 = { -1, -0.0275, -0.572, 0.022 };
					const half4 c1 = { 1, 0.0425, 1.04, -0.04 };

					float4 r = Roughness * c0 + c1;
					half a004 = min((r.x * r.x), exp2((-9.28 * NoV))) * r.x + r.y;
					half2 AB = half2(-1.04, 1.04) * a004 + r.zw;
					return SpecularColor * AB.x + AB.y;
				}

				struct appdata
				{
					float4 vertex : POSITION;
					float2 uv : TEXCOORD0;
					float3 normal : NORMAL;
					float4 tangent : TANGENT;
				};

				struct v2f
				{
					float2 uv : TEXCOORD0;
					float4 vertex : SV_POSITION;
					float3x4 TBN : TEXCOORD1;

				#ifdef SELFSHADOW
					float4 shadowCoord : TEXCOORD5;
				#endif
				};

				sampler2D _Diffuse;
				float4 _Diffuse_ST;
				sampler2D _NormalMap;
				float4 _NormalMap_ST;

				sampler2D _DetailNormal;
				float4 _DetailNormal_ST;
				sampler2D _MaterialTex;

				sampler2D _LookUpMap;

					
				//float4 _Mask_ST;

				fixed4 _Tint;
				uniform half4 _CharactorAmbientSky;
				uniform half4 _CharactorAmbientEquator;
				uniform half4 _CharactorAmbientGround;
				uniform fixed4 _CameraLightColor;

				float _SmoothnessScale;
				float _SpecularScale;
				float _SmoothnessScaleView;
				float _SpecularScaleView;
				float _CurvatureScale;
				float _DiffuseScale;
				float _DetailNormalStrength;
				float _RimLightRate;
				float _RimLightScale;
					 
						   
							  

				//--makeup----------------------------
				sampler2D _makeupmask;
				float _lightpow;
				float4 _Color;



		v2f vert(appdata v)
		{
			v2f o;
			o.vertex = UnityObjectToClipPos(v.vertex);
			o.uv = v.uv;
			float3 worldNormal = UnityObjectToWorldNormal(v.normal);
			float3 worldTangent = UnityObjectToWorldDir(v.tangent);
			half tangentSign = v.tangent.w * unity_WorldTransformParams.w;
			half3 worldBitangent = cross(worldNormal, worldTangent) * tangentSign;
			float3 worldPos = mul(unity_ObjectToWorld, v.vertex);
			

			o.TBN[0] = float4(worldTangent, worldPos.x);
			o.TBN[1] = float4(worldBitangent, worldPos.y);
			o.TBN[2] = float4(worldNormal, worldPos.z);

			#ifdef SELFSHADOW
				//We need this for shadow receving
				o.shadowCoord = TransformWorldToShadowCoord(worldPos);
			#endif
			return o;
		}

		fixed4 frag(v2f i) : SV_Target
		{
			//-------------------------
			half4 col = tex2D(_Diffuse, i.uv.xy);//albedo
			col.xyz *= _Tint.xyz;

			float colalphaglossiness = 0.35;
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			// colalphaglossiness = tex2D(_Diffuse, i.uv.xy * 0.02 + float2(0.96,0.02)).a;
			// colalphaglossiness = saturate(colalphaglossiness - col.a * 2) * 2;
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------

			fixed3 detaiNormalMap = UnpackNormal(tex2Dbias(_DetailNormal, float4(i.uv.xy *_DetailNormal_ST.xy + _DetailNormal_ST.zw,0,-1.5)));
			fixed3 normalMap = UnpackNormal(tex2Dbias(_NormalMap, float4(i.uv.xy,0, - 1.5)));

			float4 material = tex2D(_MaterialTex, i.uv.xy);
			half curvature = material.x + _CurvatureScale;
			half ao = material.w;

			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			float4 makeupmask = tex2D(_makeupmask, i.uv.xy);
			float eyeshadowunlightmask = makeupmask.b*makeupmask.r;
			//float eyeshadowlightmask = detaiNormalMap.r*saturate(col.a*10)*makeupmask.r*_lightpow;
			float eyeshadowlightmask = eyeshadowunlightmask;
			float lipmask = makeupmask.b*makeupmask.g;
			makeupmask.b = eyeshadowunlightmask+lipmask;

			float makeupGlossinessArea = makeupmask.b*(1-saturate(eyeshadowlightmask));
			//float makeupGlossinessArea = 0;
			//float makeupGlossiness = (col.a*0.8+0.2)*(makeupmask.r*.6+makeupmask.g);
			float makeupGlossiness = makeupmask.b;//(col.a*0.8+0.2)*(makeupmask.r*.6+makeupmask.g);
			material.y = lerp(material.y, (material.y * makeupGlossiness * .2 + makeupGlossiness * .8)*1, makeupGlossinessArea);
			material.z = lerp(material.z, (material.z * makeupGlossiness * .2 + makeupGlossiness * .8)*1, makeupGlossinessArea);
			//return material.z;
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------

			float specularCol = max(material.z , 0.002) * 0.04;
			float F0 = specularCol * _SpecularScale;
			float F0_View = specularCol * 10 * _SpecularScaleView;

			float smoothnessScaleColalphaglossiness = _SmoothnessScale * colalphaglossiness; // +mask.r;
			float smoothness = material.y *  (1.0 + smoothnessScaleColalphaglossiness - 0.35);
			//smoothness = material.y *_SmoothnessScale;

			
			
			smoothnessScaleColalphaglossiness = _SmoothnessScaleView * colalphaglossiness; // +mask.r;
			float smoothnessView = material.y * (1.0 + smoothnessScaleColalphaglossiness - 0.35);

			//smoothnessView = material.y *_SmoothnessScaleView;

			//Normal
			float3 tNormal = normalMap;


			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			tNormal = lerp(normalMap, tNormal, (1-(makeupGlossinessArea*.8+.2)*(makeupmask.r*.5+makeupmask.g)));
			//return float4(tNormal,1);
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------

			float3 N = float3(0, 0, 0);
										   
											
										  
			float3 tangent = normalize(i.TBN[0].xyz);
			float3 binormal = normalize(i.TBN[1].xyz);
			float3 normal = normalize(i.TBN[2].xyz);

			//reconstruct TBN
			tangent = normalize(tangent - normal* dot(tangent, normal) );
			float3 newB = cross(tangent, normal);
			binormal = newB * sign(dot(newB, binormal));
			N = normalize(tangent * tNormal.x + binormal * tNormal.y + normal * tNormal.z);
			

			float3 Ld = normalize(_MainLightPosition.xyz);
			float3 worldPos = float3(i.TBN[0].w, i.TBN[1].w, i.TBN[2].w);
			float3 Vd = normalize(UnityWorldSpaceViewDir(worldPos));
			float3 H = normalize(Ld + Vd);
			half NoV = max(dot(N, Vd), 0.001);

			half NoL = dot(N, Ld);
			half halfNoL = dot(N, Ld) * 0.5 + 0.5;

		#ifdef SELFSHADOW
			half atten = MainLightRealtimeShadowAttenuation(i.shadowCoord);
		#else
			half atten = 1.0;
		#endif
		//return atten;
			float3 mainLightColor = _MainLightColor;
			float3 sceneLightColor = _CameraLightColor;

			//diff=======================================================================
			float3 diffuseColor = float3(0,0,0);
			float3 lookUpColor = tex2D(_LookUpMap, float2(halfNoL, curvature));
			float3 sssDiff = lookUpColor * mainLightColor * atten;
			//return sssDiff.rgbb;

			float NovHalfChange =  lerp((NoV * NoV ), NoV, (N.x * 0.5 + 0.5) );
			lookUpColor = tex2D(_LookUpMap, float2(NovHalfChange * 0.5 + 0.5 , curvature));
			float3 sssDiff1 = lookUpColor * sceneLightColor;
   

							   


			diffuseColor = (sssDiff.xyz * 0.7 + sssDiff1 * 0.3) * _DiffuseScale;
			diffuseColor *= col.xyz ;
   

			//specular Data=======================================================================
			tNormal += detaiNormalMap * _DetailNormalStrength;// *0.3;
								
			N = normalize(N + (i.TBN[0] * tNormal.x) + (i.TBN[1] * tNormal.y));
				   
			half VoH = max(dot(Vd, H), 0.001);
			NoV = max(dot(Vd, N), 0.001);
			float NoH = max(dot(N, H),0.0);
			NoL = max(dot(N, Ld), 0.001);
			float3 refVN = reflect(-Vd, N);

			//specular=======================================================================
			
			float roughness = max((1.0 - smoothness), 0.02);

		#ifdef _CHARACTOR_GRAPHIC_HIGH
			float a2 = (roughness * roughness);
			float k = ((roughness +1) * (roughness +1)) / 8.0;
			half G = (NoV/(NoV * (1-k) +k)) * (NoL/(NoL * (1-k) +k));
			//half G = min((((2.0 * NoH) / VoH) * min(NoV, NoL)), 1.0);
			//G = min(min(1.0, (2.0 * NoH * NoV) / VoH), (2.0*NoH*NoL)/VoH);
			//half FV = 1.0 / (VoH * VoH * (roughness + 0.5));

			float D = (saturate(NoH * NoH) * (a2 - 1.0) + 1.0);
			D *= D ;
			//D *= 3.14159;
			D = (a2 / D);
			float F = F0 + (1.0 - F0) * pow(1.0 - VoH, 5);
			half specularTream = ((F * G) * D) / (4.0 * NoV);
			
			//specularTream *= NoL;
			//specularTream = (D / 4) * FV * NoL;

		#elif _CHARACTOR_GRAPHIC_MEDIUM//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			float gloss = 1 - roughness;
			gloss *= gloss;
			half specularTream = gloss * pow(NoH, 64 * gloss);
		#else
			half specularTream = 0;
		#endif

			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			specularTream += eyeshadowlightmask*makeupmask.r*makeupmask.b*_lightpow*.5;
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			half3 specular = specularTream * mainLightColor;// * atten;


			//-_Specular1=======================================================================
		#ifdef _CHARACTOR_GRAPHIC_HIGH
			roughness = max((1.0 - smoothnessView), 0.02);
			a2 = (roughness * roughness);
			float G2 = min((2.0 * NoV * NoV), 1.0);
			float D2 = (NoV * NoV) * (a2 - 1.0) + 1;
			D2 *= D2;
			//D2 *= 3.14159;
			D2 = a2 / D2;
			float specularTream1 = max((((F0_View * G2) * D2) / (4.0 * NoV)), 0.0);//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------
			specularTream1 += eyeshadowlightmask*makeupmask.r*makeupmask.b*_lightpow*.5;
			//MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------MAKEUP--------------------------

			specular += specularTream1 * sceneLightColor.rgb;// *saturate(1 - NoL);;
			specular = clamp(0,1,specular);
		#endif

			// ENV=======================================================================

			fixed3 pointLightCol = GetEffectLight(worldPos.xyz, N);
			float3 ambient = 0;
			// float3 ambient = 0;//pointLightCol;
			// #if LIGHTPROBE
			// 	// Sphere harmonic light probe
			// 	ambient += SampleSHPixel(i.vertexSH,N);
			// #else
			// 	ambient += SampleSH9Direct(_SHCoefficients, N);
			// #endif
			ambient = SampleSH(N) +CalculateAmbientLight(_CharactorAmbientSky, _CharactorAmbientEquator, _CharactorAmbientGround, N) + pointLightCol;
			float3 envMap = MyUnityGI_IndirectSpecular(roughness, refVN, 0.0);
			float envBRDF = EnvBRDFApprox(specularCol, roughness* roughness, NoV);

			//----rimLight=======================================================================
			float3 rimLight = float3(0, 0, 0);
			float maxClampNoV = max((1.0 - saturate(NoV)), 0.0);
			maxClampNoV *= N.y * 0.5 + 0.5;
			half pow_maxClamp_dotVN = pow(maxClampNoV, _RimLightRate)* _RimLightScale;
			rimLight = ambient * pow_maxClamp_dotVN * NoL * mainLightColor;

			//----Scene rimLigh=======================================================================
			float _powScene_dotVN = saturate(pow(maxClampNoV * halfNoL + 0.01, _RimLightRate)) * _RimLightScale;
			rimLight += sceneLightColor.xyz  * _powScene_dotVN * sceneLightColor;
			rimLight *= ao;

			//------------------------------------------------------------------------------------------------------
		#ifdef _DIFFUSE_ON
			return float4(diffuseColor, 1);
		#endif

		#ifdef _SPECULAR_ON
			return float4(specular * ao, 1);
		#endif

		#ifdef _INSPECULAR_ON
			return float4(envBRDF * envMap* sqrt(mainLightColor) * ao, 1);
		#endif

		#ifdef _CHARACTOR_GRAPHIC_HIGH
			half3 finalColor = diffuseColor.xyz  + (specular + envBRDF * envMap * sqrt(mainLightColor)) * ao + (ambient.xyz /** (N.y * 0.15 + 0.85)*/ * col.xyz * ao) + rimLight;
		#elif _CHARACTOR_GRAPHIC_MEDIUM
			half3 finalColor = diffuseColor.xyz  + specular * ao;
		#else
			half3 finalColor = diffuseColor.xyz + specular * ao;
		#endif
			return float4(finalColor.rgb, _Color.a);
			}
			ENDCG
		}

//------------------------------------------------------
		// Pass
   //     {
   //     	//Name "DEForwardkneadface"
   //     	Tags { "LightMode" = "LightweightForward" }//!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
   //     	ZWrite Off 
   //         Cull Back
   //         Blend One One
   //         CGPROGRAM
   //         #pragma vertex vertarea
   //         #pragma fragment fragarea
   //         #include "UnityCG.cginc"
 
   //         float _areaID;
   //         half _areaAlpha;
   //         sampler2D _areaMask;

   //         struct appdata
			//{
			//	float4 vertex	: POSITION;
			//	float4 tangent	: TANGENT;
			//	float3 normal	: NORMAL;
			//	float2 uv		: TEXCOORD0;
			//};

			//struct v2f
			//{
			//	float4 pos		: SV_POSITION;
			//	float2 uv		: TEXCOORD0;
			//};
 
   //         v2f vertarea(appdata v)
   //         {
   //             v2f o;
   //             o.pos = UnityObjectToClipPos(v.vertex);
   //             o.uv = v.uv;
   //             float4 view_vertex = mul(UNITY_MATRIX_MV,v.vertex);
   //             float3 view_normal = mul(UNITY_MATRIX_IT_MV,v.normal);
   //             view_vertex.xyz += normalize(view_normal) * .5*0.002; //_Factor
   //             o.pos = mul(UNITY_MATRIX_P,view_vertex);
   //             return o;
   //         }
 
   //         half4 fragarea(v2f IN):COLOR
   //         {
   //         	_areaID  *=0.1;
   //         	float _areaIDr = clamp(_areaID,0,1);
   //         	float _areaIDg = clamp(_areaID,1,2)-1;
   //         	float _areaIDb = clamp(_areaID,2,3)-2;


   //         	//fixed time = sin(frac(_Time.y*.4)*3.1416);
   //         	      //time = saturate(time+0.4)*.7;

   //         	half4 c = tex2D(_areaMask,IN.uv);

   //         	float arear = step(frac((c.r+_areaIDr)),0.95);
   //         	float areag = step(frac((c.g+_areaIDg)),0.95);
   //         	float areab = step(frac((c.b+_areaIDb)),0.95);

   //         	float base =saturate(c.a*2)*.00;

   //         	float area =(1-arear+1-areag+1-areab)*c.a;

   //         	return area*1*_areaAlpha+base;//time

   //         }
   //         ENDCG
   //     }
//------------------------------------------------------

		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }

			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow

			#include "DMShadow.cginc"
			
			ENDCG
		}

		}
}