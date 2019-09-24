Shader "Unlit/tempface" 
{
	Properties
	{
		_Diffuse("Diffuse", 2D) = "white" {}
		_NormalMap("NormalMap",2D) = "blue" {}
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		[Header(_______________MakeUp__________________)]
		_resolution ("DiffuseTexureSize,ZW(NotUsed)", Vector) = (1024,1024,0,0)
		_skinCol("SkinColor", color) = (1.0,1.0,1.0,1.0)
		[Header(_______________Blusher__________________)]
        [NoScaleOffset]_blusherTex ("BlusherTex", 2D) = "white" {}
        _blusher ("BlusherID", Int ) = 1
        _blusherCol ("BlusherColor", Color) = (1,0,1,1)
        _blusheralpha ("BlusherAlpha", Range(0, 1)) = 1
        _blusherarea ("BlusherArea", Range(0, 1)) = 1
        _blusherTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [Header(_______________EyeBrow__________________)]
        [NoScaleOffset]_eyebrowTex ("EyeBrowTex", 2D) = "white" {}
        _eyebrow ("EyeBrowID", Int ) = 1
		_eyebrowCol ("EyeBrowColor", Color) = (0,0,0,1)
		_eyebrowalpha ("EyeBrowAlpha", Range(0, 1)) = 1
        _eyebrowTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [Header(_______________EyeShadow__________________)]
        [NoScaleOffset]_eyeshadowTex ("EyeshadowTex", 2D) = "white" {}
        _eyeshadow ("EyeshadowID", Int ) = 1
        _eyeshadowCol ("EyeshadowColor", Color) = (0,0,0,1)
        _eyeshadowalpha ("EyeshadowAlpha", Range(0, 1)) = 1
        _eyeshadowarea ("EyeshadowArea", Range(0, 1)) = 1
        _eyeshadowroughness ("EyeshadowReflect", Range(0, 1)) = .2
        _eyeshadowshine ("EyeshadowShine", Range(0,1)) = 1
        _eyeshadowTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [Header(_______________EyeLine__________________)]
        [NoScaleOffset]_eyelineTex ("EyelineTex", 2D) = "white" {}
        _eyeline ("EyeLineID", Int ) = 1
        _eyelineCol ("EyeLineColor", Color) = (0,0,0,1)
		_eyelineTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [Header(_______________LipNormal__________________)]
        [NoScaleOffset]_lipNormalMap("LipNormalMap",2D) = "NORMAL" {}
        _lipnormal ("LipNormalID", Int ) = 1
		_lipnormalTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [NoScaleOffset]_lipTex ("LipTex", 2D) = "white" {}
        _lip ("LipID", Int ) = 1
        _lipCol ("LipColor", Color) = (0,0,0,1)
        _lipalpha ("LipAlpha", Range(0, 1)) = 1
        _liparea ("LipArea", Range(0, 1)) = 1
        _liproughness ("LipReflect", Range(0, 1)) = .2 
        _lipTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
		[Header(_______________Wrinkle__________________)]
		[NoScaleOffset]_wrinkleNormalMap("WrinkleNormalMap",2D) = "NORMAL" {}
		[NoScaleOffset]_wrinkleMask("WrinkleMask",2D) = "black" {}
		_raisedlinespow ("RaisedLinesPow", Range(0, 1)) = 1
		_fishtaillinespow ("FishtailLinesPow", Range(0, 1)) = 1
		_nasolabialfoldspow ("NasolabialFoldsPow", Range(0, 1)) = 1
		[Header(_______________Mustache__________________)]
        [NoScaleOffset]_mustacheTex ("MustacheTex", 2D) = "white" {}
        _mustache ("MustacheID", Int ) = 1
		_mustacheCol ("MustacheColor", Color) = (0,0,0,1)
		_mustachealpha ("MustacheAlpha", Range(0, 1)) = 1
        _mustacheTexInfo("Info[XY:Pixel:,Z:COL,W:ROW]", vector) = (1024,1024, 1, 1)
        [Header(_______________Tattoo__________________)]
        [NoScaleOffset]_TattooTex ("TattooTex", 2D) = "white" {}
        _TattooColor("Tattoo Color", Color) = (1, 1, 1, 1)
        _TattooDensity("Tattoo Density", Range(0, 1.0)) = 1.0
        _TattooPositionX("Tattoo Position X", Range(-1.0, 1.0)) = 0.0
        _TattooPositionY("Tattoo Position Y", Range(-1.0, 1.0)) = 0.0
        _TattooRotation("Tattoo Rotation", Range(0.0, 360.0)) = 0.0
        _TattooScaleX("Tattoo Scale X", Range(0.0, 100.0)) = 1.0
        _TattooScaleY("Tattoo Scale Y", Range(0.0, 100.0)) = 1.0
        _TattooFlipX("Tattoo Flip X", Int) = 0
        _TattooFlipY("Tattoo Flip Y", Int) = 0
        _UVRegion("Tattoo Texture UV Region", Vector) = (0, 0, 0, 0) // (U_MIN, U_MAX, V_MIN, V_MAX)
        _UVCenter("Tattoo Texture UV Center", Vector) = (0, 0, 0, 0)
        [HideInInspector]_TattooTileIndex("Tattoo Tile Index", Int) = -1 // Not used in shader
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

				Pass
		{
			Tags { "LightMode" = "BakeDiffuse" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "./CGIncludes/UETextureOperations.cginc"
            #include "./CGIncludes/UEHSBCEffect.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _Diffuse,_NormalMap;
			float4 _Diffuse_ST;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			sampler2D _eyeshadowTex,_lipTex,_eyelineTex,_wrinkleNormalMap,_wrinkleMask,_lipNormalMap,_eyebrowTex,_blusherTex,_mustacheTex;
			fixed4 _eyeshadowCol,_lipCol,_eyelineCol,_eyebrowCol,_blusherCol,_mustacheCol,_skinCol;
			fixed _eyeshadowarea,_eyeshadowalpha,_eyebrowalpha,_liparea,_lipalpha,_blusherarea,_blusheralpha,_mustachealpha;
			fixed _eyeshadowshine,_eyeshadowroughness,_lipsmoothness,_liproughness;
			fixed4 _resolution,_eyebrowTexInfo,_eyeshadowTexInfo,_eyelineTexInfo,_lipTexInfo,_lipnormalTexInfo,_blusherTexInfo,_mustacheTexInfo;
			int _eyebrow,_eyeshadow,_eyeline,_lip,_lipnormal,_blusher,_mustache;//ID
			fixed _raisedlinespow,_fishtaillinespow,_nasolabialfoldspow;

			sampler2D _TattooTex;
			float4 _TattooColor,_UVRegion,_UVCenter;
            half _TattooDensity,_TattooPositionX,_TattooPositionY,_TattooScaleX,_TattooScaleY,_TattooRotation;
            int _TattooFlipX,_TattooFlipY;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					
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
				o.uv = TRANSFORM_TEX(v.uv, _Diffuse);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			// TODO: Move out to C# codes.
                float2x2 rotationM = float2x2(
                    cos(radians(_TattooRotation)), -sin(radians(_TattooRotation)),
                    sin(radians(_TattooRotation)), cos(radians(_TattooRotation)));

                half2 targetUV = UVToLocal(i.uv, _UVCenter);
                targetUV = UVTranslation(targetUV, _TattooPositionX, _TattooPositionY);
                targetUV = UVScale(targetUV, _TattooScaleX, _TattooScaleY);
                targetUV = UVRotation(targetUV, rotationM);
                targetUV = UVTryFlip(targetUV, _TattooFlipX, _TattooFlipY);
                targetUV = UVToGlobal(targetUV, _UVCenter);
                float4 tattooTexColorAlpha = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    _blusheralpha = _blusheralpha*1 ;
				    _blusherarea = _blusherarea*2-1 ;

				    half2 blushercoluvbase = i.uv*float2(_resolution.x*_blusherTexInfo.z/_blusherTexInfo.x,_resolution.y*_blusherTexInfo.w/_blusherTexInfo.y);
				    	  blushercoluvbase -= float2(0.99,1.75)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 blushercoluv = CustomUV(blushercoluvbase,_blusherTexInfo.z,_blusherTexInfo.w,_blusher-1);
	                half4 blusherTex = tex2D(_blusherTex,blushercoluv);
				    half  blusherlerp = saturate(saturate(_blusherarea+blusherTex.g)*blusherTex.r*_blusheralpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    _eyeshadowroughness = _eyeshadowroughness*(-.9)+1;
				    _eyeshadowalpha = _eyeshadowalpha*2 ;
				    _eyeshadowarea = _eyeshadowarea*2-1 ;
				    _eyeshadowshine = _eyeshadowshine*20;

				    half2 eyeshadowcoluvbase = i.uv*float2(_resolution.x*_eyeshadowTexInfo.z/_eyeshadowTexInfo.x,_resolution.y*_eyeshadowTexInfo.w/_eyeshadowTexInfo.y);
				    	  eyeshadowcoluvbase -= float2(4.05,14.4)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 eyeshadowcoluv = CustomUV(eyeshadowcoluvbase,_eyeshadowTexInfo.z,_eyeshadowTexInfo.w,_eyeshadow-1);
	                half4 eyeshadowTex = tex2D(_eyeshadowTex,eyeshadowcoluv);
				    half  eyeshadowlerp = saturate(saturate(_eyeshadowarea+eyeshadowTex.g)*eyeshadowTex.r*_eyeshadowalpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 eyelinecoluvbase = i.uv*float2(_resolution.x*_eyelineTexInfo.z/_eyelineTexInfo.x,_resolution.y*_eyelineTexInfo.w/_eyelineTexInfo.y);
				    	  eyelinecoluvbase -= float2(4.05,14.2)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 eyelinecoluv = CustomUV(eyelinecoluvbase,_eyelineTexInfo.z,_eyelineTexInfo.w,_eyeline-1);
	                half4 eyelineTex = tex2D(_eyelineTex,eyelinecoluv);
				    half  eyelinelerp = eyelineTex.r;
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 eyebrowcoluvbase = i.uv*float2(_resolution.x*_eyebrowTexInfo.z/_eyebrowTexInfo.x,_resolution.y*_eyebrowTexInfo.w/_eyebrowTexInfo.y);
				    	  eyebrowcoluvbase -= float2(4.26,39.15)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 eyebrowcoluv = CustomUV(eyebrowcoluvbase,_eyebrowTexInfo.z,_eyebrowTexInfo.w,_eyebrow-1);
	                half4 eyebrowTex = tex2D(_eyebrowTex,eyebrowcoluv);
				    half  eyebrowlerp = saturate(eyebrowTex.r*_eyebrowalpha*1+eyebrowTex.g*(_eyebrowalpha*.5+1.5)*2);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					_lipalpha = _lipalpha*2;
					_liparea = _liparea*2-1 ;

				    half2 lipcoluvbase = i.uv*float2(_resolution.x*_lipTexInfo.z/_lipTexInfo.x,_resolution.y*_lipTexInfo.w/_lipTexInfo.y);
				    	  lipcoluvbase -= float2(10.58,4.68)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 lipcoluv = CustomUV(lipcoluvbase,_lipTexInfo.z,_lipTexInfo.w,_lip-1);
				    half4 lipTex = tex2D(_lipTex,lipcoluv);
				    half  liplerp = saturate(saturate(_liparea+lipTex.g)*lipTex.r*_lipalpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 mustachecoluvbase = i.uv*float2(_resolution.x*_mustacheTexInfo.z/_mustacheTexInfo.x,_resolution.y*_mustacheTexInfo.w/_mustacheTexInfo.y);
				    	  mustachecoluvbase -= float2(1.15,0.21)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 mustachecoluv = CustomUV(mustachecoluvbase,_mustacheTexInfo.z,_mustacheTexInfo.w,_mustache-1);
	                half4 mustacheTex = tex2D(_mustacheTex,mustachecoluv);
				    half  mustachelerp = saturate(mustacheTex.r*_mustachealpha*1+mustacheTex.g*(_mustachealpha*.5+1.5)*2);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

				// sample the texture
				half4 col = tex2D(_Diffuse, i.uv);

					//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				   _skinCol = _skinCol*0.25+0.75;
				   col.rgb *=_skinCol;
				   col.rgb = lerp(col.rgb,(col.rgb*_mustacheCol.rgb*.2+_mustacheCol.rgb*.8), mustachelerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_blusherCol.rgb), blusherlerp);
				   col.rgb = lerp(col.rgb,(col.rgb*_eyebrowCol.rgb*.2+_eyebrowCol.rgb*.8), eyebrowlerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_eyeshadowCol.rgb), eyeshadowlerp);
				   col.rgb = lerp(col.rgb,col.rgb*_eyelineCol.rgb, eyelinelerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_lipCol.rgb), liplerp);
				   col.rgb = col.rgb + col.rgb * tattooTexColorAlpha*_TattooColor;
				   //col.rgb = lerp(col.rgb,col.rgb*wrinkleNormalMap.b, wrinklelerp);

					return half4(col.rgb,1);

			}
			ENDCG	
		}

		Pass
		{
			Tags { "LightMode" = "BakeNormal" }
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "./CGIncludes/UETextureOperations.cginc"
            #include "./CGIncludes/UEHSBCEffect.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _Diffuse,_NormalMap;
			float4 _Diffuse_ST;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			sampler2D _eyeshadowTex,_lipTex,_eyelineTex,_wrinkleNormalMap,_wrinkleMask,_lipNormalMap,_eyebrowTex,_blusherTex,_mustacheTex;
			fixed4 _eyeshadowCol,_lipCol,_eyelineCol,_eyebrowCol,_blusherCol,_mustacheCol,_skinCol;
			fixed _eyeshadowarea,_eyeshadowalpha,_eyebrowalpha,_liparea,_lipalpha,_blusherarea,_blusheralpha,_mustachealpha;
			fixed _eyeshadowshine,_eyeshadowroughness,_lipsmoothness,_liproughness;
			fixed4 _resolution,_eyebrowTexInfo,_eyeshadowTexInfo,_eyelineTexInfo,_lipTexInfo,_lipnormalTexInfo,_blusherTexInfo,_mustacheTexInfo;
			int _eyebrow,_eyeshadow,_eyeline,_lip,_lipnormal,_blusher,_mustache;//ID
			fixed _raisedlinespow,_fishtaillinespow,_nasolabialfoldspow;

			sampler2D _TattooTex;
			float4 _TattooColor,_UVRegion,_UVCenter;
            half _TattooDensity,_TattooPositionX,_TattooPositionY,_TattooScaleX,_TattooScaleY,_TattooRotation;
            int _TattooFlipX,_TattooFlipY;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					
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
				o.uv = TRANSFORM_TEX(v.uv, _Diffuse);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				    half2 lipcoluvbase = i.uv*float2(_resolution.x*_lipTexInfo.z/_lipTexInfo.x,_resolution.y*_lipTexInfo.w/_lipTexInfo.y);
				    	  lipcoluvbase -= float2(10.58,4.68)*.1;//每个模块uv目标对应脸的uv位置不一样

					fixed3 NormalMap = tex2D(_NormalMap, i.uv.xy).rgb;

		//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 lipnormaluvbase = i.uv*float2(_resolution.x*_lipnormalTexInfo.z/_lipnormalTexInfo.x,_resolution.y*_lipnormalTexInfo.w/_lipnormalTexInfo.y);
					      lipnormaluvbase -= float2(10.58,4.68)*.1;//每个模块uv目标对应脸的uv位置不一样
				    half2 lipnormaluv = CustomUV(lipcoluvbase,_lipnormalTexInfo.z,_lipnormalTexInfo.w,_lipnormal-1);
				    half4 lipnormalTex = tex2D(_lipNormalMap,lipnormaluv);
				    half3 lipnormal = half3(lipnormalTex.rg,1);
				    	  NormalMap = lerp(NormalMap,lipnormal ,lipnormalTex.b);

					half4 wrinkleMask = tex2D(_wrinkleMask, i.uv.xy);
					half4 wrinkleNormalMap = tex2D(_wrinkleNormalMap, i.uv.xy);
					half3 wrinkleNormal = half3(wrinkleNormalMap.rg,1);
					half  wrinklelerp = saturate(wrinkleMask.r*_raisedlinespow+wrinkleMask.g*_fishtaillinespow+wrinkleMask.b*_nasolabialfoldspow);
					half3  NormalMapcol = lerp(NormalMap,wrinkleNormal,wrinklelerp).rgb;
					 	   NormalMap = NormalMapcol*2-1;

						return half4(NormalMapcol.rgb,1);

			}
			ENDCG	
		}

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			// make fog work
			#pragma multi_compile_fog
			
			#include "UnityCG.cginc"
			#include "./CGIncludes/UETextureOperations.cginc"
            #include "./CGIncludes/UEHSBCEffect.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				UNITY_FOG_COORDS(1)
				float4 vertex : SV_POSITION;
			};

			sampler2D _Diffuse,_NormalMap;
			float4 _Diffuse_ST;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
			sampler2D _eyeshadowTex,_lipTex,_eyelineTex,_wrinkleNormalMap,_wrinkleMask,_lipNormalMap,_eyebrowTex,_blusherTex,_mustacheTex;
			fixed4 _eyeshadowCol,_lipCol,_eyelineCol,_eyebrowCol,_blusherCol,_mustacheCol,_skinCol;
			fixed _eyeshadowarea,_eyeshadowalpha,_eyebrowalpha,_liparea,_lipalpha,_blusherarea,_blusheralpha,_mustachealpha;
			fixed _eyeshadowshine,_eyeshadowroughness,_lipsmoothness,_liproughness;
			fixed4 _resolution,_eyebrowTexInfo,_eyeshadowTexInfo,_eyelineTexInfo,_lipTexInfo,_lipnormalTexInfo,_blusherTexInfo,_mustacheTexInfo;
			int _eyebrow,_eyeshadow,_eyeline,_lip,_lipnormal,_blusher,_mustache;//ID
			fixed _raisedlinespow,_fishtaillinespow,_nasolabialfoldspow;

			sampler2D _TattooTex;
			float4 _TattooColor,_UVRegion,_UVCenter;
            half _TattooDensity,_TattooPositionX,_TattooPositionY,_TattooScaleX,_TattooScaleY,_TattooRotation;
            int _TattooFlipX,_TattooFlipY;
			//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					
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
				o.uv = TRANSFORM_TEX(v.uv, _Diffuse);
				UNITY_TRANSFER_FOG(o,o.vertex);
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
			// TODO: Move out to C# codes.
                float2x2 rotationM = float2x2(
                    cos(radians(_TattooRotation)), -sin(radians(_TattooRotation)),
                    sin(radians(_TattooRotation)), cos(radians(_TattooRotation)));

                half2 targetUV = UVToLocal(i.uv, _UVCenter);
                targetUV = UVTranslation(targetUV, _TattooPositionX, _TattooPositionY);
                targetUV = UVScale(targetUV, _TattooScaleX, _TattooScaleY);
                targetUV = UVRotation(targetUV, rotationM);
                targetUV = UVTryFlip(targetUV, _TattooFlipX, _TattooFlipY);
                targetUV = UVToGlobal(targetUV, _UVCenter);
                float4 tattooTexColorAlpha = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    _blusheralpha = _blusheralpha*1 ;
				    _blusherarea = _blusherarea*2-1 ;

				    half2 blushercoluvbase = i.uv*float2(_resolution.x*_blusherTexInfo.z/_blusherTexInfo.x,_resolution.y*_blusherTexInfo.w/_blusherTexInfo.y);
				    	  blushercoluvbase -= float2(0.99,1.75)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 blushercoluv = CustomUV(blushercoluvbase,_blusherTexInfo.z,_blusherTexInfo.w,_blusher-1);
	                half4 blusherTex = tex2D(_blusherTex,blushercoluv);
				    half  blusherlerp = saturate(saturate(_blusherarea+blusherTex.g)*blusherTex.r*_blusheralpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    _eyeshadowroughness = _eyeshadowroughness*(-.9)+1;
				    _eyeshadowalpha = _eyeshadowalpha*2 ;
				    _eyeshadowarea = _eyeshadowarea*2-1 ;
				    _eyeshadowshine = _eyeshadowshine*20;

				    half2 eyeshadowcoluvbase = i.uv*float2(_resolution.x*_eyeshadowTexInfo.z/_eyeshadowTexInfo.x,_resolution.y*_eyeshadowTexInfo.w/_eyeshadowTexInfo.y);
				    	  eyeshadowcoluvbase -= float2(4.05,14.4)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 eyeshadowcoluv = CustomUV(eyeshadowcoluvbase,_eyeshadowTexInfo.z,_eyeshadowTexInfo.w,_eyeshadow-1);
	                half4 eyeshadowTex = tex2D(_eyeshadowTex,eyeshadowcoluv);
				    half  eyeshadowlerp = saturate(saturate(_eyeshadowarea+eyeshadowTex.g)*eyeshadowTex.r*_eyeshadowalpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 eyelinecoluvbase = i.uv*float2(_resolution.x*_eyelineTexInfo.z/_eyelineTexInfo.x,_resolution.y*_eyelineTexInfo.w/_eyelineTexInfo.y);
				    	  eyelinecoluvbase -= float2(4.05,14.2)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 eyelinecoluv = CustomUV(eyelinecoluvbase,_eyelineTexInfo.z,_eyelineTexInfo.w,_eyeline-1);
	                half4 eyelineTex = tex2D(_eyelineTex,eyelinecoluv);
				    half  eyelinelerp = eyelineTex.r;
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 eyebrowcoluvbase = i.uv*float2(_resolution.x*_eyebrowTexInfo.z/_eyebrowTexInfo.x,_resolution.y*_eyebrowTexInfo.w/_eyebrowTexInfo.y);
				    	  eyebrowcoluvbase -= float2(4.26,39.15)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 eyebrowcoluv = CustomUV(eyebrowcoluvbase,_eyebrowTexInfo.z,_eyebrowTexInfo.w,_eyebrow-1);
	                half4 eyebrowTex = tex2D(_eyebrowTex,eyebrowcoluv);
				    half  eyebrowlerp = saturate(eyebrowTex.r*_eyebrowalpha*1+eyebrowTex.g*(_eyebrowalpha*.5+1.5)*2);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
					_lipalpha = _lipalpha*2;
					_liparea = _liparea*2-1 ;

				    half2 lipcoluvbase = i.uv*float2(_resolution.x*_lipTexInfo.z/_lipTexInfo.x,_resolution.y*_lipTexInfo.w/_lipTexInfo.y);
				    	  lipcoluvbase -= float2(10.58,4.68)*.1;//每个模块uv目标对应脸的uv位置不一样
					half2 lipcoluv = CustomUV(lipcoluvbase,_lipTexInfo.z,_lipTexInfo.w,_lip-1);
				    half4 lipTex = tex2D(_lipTex,lipcoluv);
				    half  liplerp = saturate(saturate(_liparea+lipTex.g)*lipTex.r*_lipalpha);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 mustachecoluvbase = i.uv*float2(_resolution.x*_mustacheTexInfo.z/_mustacheTexInfo.x,_resolution.y*_mustacheTexInfo.w/_mustacheTexInfo.y);
				    	  mustachecoluvbase -= float2(1.15,0.21)*.1;//每个模块uv目标对应脸的uv位置不一样  
					half2 mustachecoluv = CustomUV(mustachecoluvbase,_mustacheTexInfo.z,_mustacheTexInfo.w,_mustache-1);
	                half4 mustacheTex = tex2D(_mustacheTex,mustachecoluv);
				    half  mustachelerp = saturate(mustacheTex.r*_mustachealpha*1+mustacheTex.g*(_mustachealpha*.5+1.5)*2);
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

				// sample the texture
				half4 col = tex2D(_Diffuse, i.uv);

					//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				   _skinCol = _skinCol*0.25+0.75;
				   col.rgb *=_skinCol;
				   col.rgb = lerp(col.rgb,(col.rgb*_mustacheCol.rgb*.2+_mustacheCol.rgb*.8), mustachelerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_blusherCol.rgb), blusherlerp);
				   col.rgb = lerp(col.rgb,(col.rgb*_eyebrowCol.rgb*.2+_eyebrowCol.rgb*.8), eyebrowlerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_eyeshadowCol.rgb), eyeshadowlerp);
				   col.rgb = lerp(col.rgb,col.rgb*_eyelineCol.rgb, eyelinelerp);
				   col.rgb = lerp(col.rgb,((col.rgb*.3+.7)*_lipCol.rgb), liplerp);
				   col.rgb = lerp(col.rgb,col.rgb*tattooTexColorAlpha*_TattooColor*2, tattooTexColorAlpha.a);
				   //col.rgb = col.rgb + col.rgb * tattooTexColorAlpha*_TattooColor;
				   //col.rgb = lerp(col.rgb,col.rgb*wrinkleNormalMap.b, wrinklelerp);
	//************************************************
	//return half4(col.rgb,1);
	//************************************************
	//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
		fixed3 NormalMap = tex2D(_NormalMap, i.uv.xy).rgb;

		//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
				    half2 lipnormaluvbase = i.uv*float2(_resolution.x*_lipnormalTexInfo.z/_lipnormalTexInfo.x,_resolution.y*_lipnormalTexInfo.w/_lipnormalTexInfo.y);
					      lipnormaluvbase -= float2(10.58,4.68)*.1;//每个模块uv目标对应脸的uv位置不一样
				    half2 lipnormaluv = CustomUV(lipcoluvbase,_lipnormalTexInfo.z,_lipnormalTexInfo.w,_lipnormal-1);
				    half4 lipnormalTex = tex2D(_lipNormalMap,lipnormaluv);
				    half3 lipnormal = half3(lipnormalTex.rg,1);
				    	  NormalMap = lerp(NormalMap,lipnormal ,lipnormalTex.b);

					half4 wrinkleMask = tex2D(_wrinkleMask, i.uv.xy);
					half4 wrinkleNormalMap = tex2D(_wrinkleNormalMap, i.uv.xy);
					half3 wrinkleNormal = half3(wrinkleNormalMap.rg,1);
					half  wrinklelerp = saturate(wrinkleMask.r*_raisedlinespow+wrinkleMask.g*_fishtaillinespow+wrinkleMask.b*_nasolabialfoldspow);
					half3  NormalMapcol = lerp(NormalMap,wrinkleNormal,wrinklelerp).rgb;
					 	   NormalMap = NormalMapcol*2-1;
		//************************************************
		//return half4(NormalMapcol.rgb,1);
		//************************************************
		//--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

				// apply fog
				//UNITY_APPLY_FOG(i.fogCoord, col);
				return col;
			}

			ENDCG
		}
	}
}