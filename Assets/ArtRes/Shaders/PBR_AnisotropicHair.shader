Shader "DM PBR/Anisotropic Hair"
{
	Properties
	{
		_Color("Color", Color) = (1.0,1.0,1.0,1.0)
		_MainTex ("Texture", 2D) = "white" {}
		_AlphaTex("Alpha Texture", 2D) = "white" {}

		_BumpMap("Normal Map", 2D) = "bump" {}
		_BumpScale("Normal Scale", Range(0, 2)) = 1.0

		_PBRMap("PBR Map", 2D) = "white" {}
		_Metallic("Metallic", Range(0.0, 1.0)) = 0
		_AOStrength("Strength", Range(0.0, 1.0)) = 1.0

		_SpecShiftTex("Specular Shift Texture", 2D) = "white" {}
		_PrimarySpecShift("Primary Shift", Range(-1.0, 1.0)) = 0
		_PrimarySpecColor("Primary Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_PrimarySpecExp("Primary Specular Exponent", Range(0.0, 2.0)) = 1.0
		_SecondarySpecShift("Secondary Shift", Range(-1.0, 1.0)) = 0.0
		_SecondarySpecColor("Secondary Specular Color", Color) = (1.0,1.0,1.0,1.0)
		_SecondarySpecExp("Secondary Specular Exponent", Range(0.0, 2.0)) = 1.0
		_SecondarySpecMask("Secondary Specular Mask", 2D) = "white" {}

		_Cutoff("Cutoff", Range(0.0, 1.0)) = 0.0

		// ------------------xray--------------------
		_RimXRayColor("Rim Color",Color) = (0.0,0.0,1.0,1.0)
		_RimXRayPower("Rim Power",Range(0.1,10)) = 3.0
		_RimXRayIntensity("Rim Intensity",Range(0,100)) = 10
		// ------------------xray--------------------

		// ------------dissolve------------------
		_DissolveTex("DissolveTex", 2D) = "white" {}
		_TextureScale("Texture Scale",Float) = 1
		_TriplanarBlendSharpness("Blend Sharpness",Float) = 1

		_Mask("Mask",2D) = "white" {}
		_Dissolve("Dissove",Range(0,1.0)) = 0.0

		_DissolveControl("_DissolveControl",Vector) = (1,1,0,0)

		_EdgeWidth("EdgeWidth",Range(0.001,0.5)) = 0.1
		[HDR]_EdgeColor("EdgeColor",Color) = (1,1,1,1)
		_EdgeColorScale("EdgeColorScale",Range(0.5,2)) = 1
		// ------------dissolve------------------

		[HideInInspector]_Level("__level", Float) = 0.0

		// Blending state
		[HideInInspector]_SrcBlend("__src", Float) = 1.0
		[HideInInspector]_DstBlend("__dst", Float) = 0.0
		[HideInInspector]_ZWrite("__zw", Float) = 1.0
	}

	SubShader
	{
		Tags{ "Queue" = "Transparent+95" "IgnoreProjector" = "True" "RenderType" = "Transparent" }

		// depth only parts
		Pass
		{
			Tags{ "LightMode" = "DepthOnly" }
            // Cull Off
			ColorMask 0

			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vertZBuffer
			#pragma fragment fragZBuffer

            #include "AnisotropicHair/DMAnisotropicHair.cginc"
			ENDCG
		}

		// opaque parts
		Pass
		{
			Tags{ "LightMode" = "LightweightForward" }
			ZTest Equal
            // Cull Back
            Blend[_SrcBlend][_DstBlend], Zero Zero
			ZWrite[_ZWrite]

            Stencil {  
                Ref 254 
                Comp Always
                Pass Replace
                ZFail Keep
            }

			CGPROGRAM
            //#pragma multi_compile_fwdbase
			#pragma multi_compile __ NORMALMAP
			#pragma multi_compile __ SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT_MASK
			#pragma multi_compile __ DISSOLVE
			#pragma multi_compile _CHARACTOR_GRAPHIC_HIGH _CHARACTOR_GRAPHIC_MEDIUM _CHARACTOR_GRAPHIC_LOW

			// #define CUTOFF

			#pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "AnisotropicHair/DMAnisotropicHair.cginc"
			ENDCG
		}

		// opaque parts
		Pass
		{
			Tags{ "LightMode" = "LightweightForward" }
            ZTest Equal
            // Cull Off
            Blend[_SrcBlend][_DstBlend], Zero Zero
			ZWrite[_ZWrite]

            Stencil {  
                Ref 254 
                Comp Always
                Pass Replace
                ZFail Keep
            }

			CGPROGRAM
            //#pragma multi_compile_fwdbase
			#pragma multi_compile __ NORMALMAP
			#pragma multi_compile __ SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT_MASK
			#pragma multi_compile __ DISSOLVE
			#pragma multi_compile _CHARACTOR_GRAPHIC_HIGH _CHARACTOR_GRAPHIC_MEDIUM _CHARACTOR_GRAPHIC_LOW

			// #define CUTOFF

			#pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag

            #include "AnisotropicHair/DMAnisotropicHair.cginc"
			ENDCG
		}

        // transparent parts
		Pass
        {
            Tags{ "LightMode" = "LightweightForward" }
            ZWrite Off
            ZTest Less
            Cull Off
            Blend SrcAlpha OneMinusSrcAlpha, Zero OneMinusSrcAlpha
            //Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            //#pragma multi_compile_fwdbase
			#pragma multi_compile __ NORMALMAP
			#pragma multi_compile __ SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT
			#pragma multi_compile __ SECOND_SPEC_SHIFT_MASK
			#pragma multi_compile __ DISSOLVE
			#pragma multi_compile _CHARACTOR_GRAPHIC_HIGH _CHARACTOR_GRAPHIC_MEDIUM _CHARACTOR_GRAPHIC_LOW

			#pragma target 3.0
            #pragma vertex vert  
            #pragma fragment frag

            #include "AnisotropicHair/DMAnisotropicHair.cginc"
            ENDCG
        }

        // Pass to render object's xray
		Pass
		{
			Name "XRAY"
			Tags{ "LightMode" = "SRPDefaultUnlit" }

			Blend SrcAlpha One
			ZWrite Off
			ZTest Greater

			Stencil {  
                Ref 254         
                Comp NotEqual             
                Pass Keep 
                ZFail Keep
            }

			CGPROGRAM
			#pragma vertex vert_xray
			#pragma fragment frag_xray

			#include "DMXRay.cginc"
			
			ENDCG
		}


		// Pass to render object as a shadow caster
		Pass
		{
			Name "ShadowCaster"
			Tags{ "LightMode" = "ShadowCaster" }
			Cull Off

			CGPROGRAM
			#pragma vertex vert_shadow
			#pragma fragment frag_shadow
			#define ALPHA_TEST 1

			#include "DMShadow.cginc"
			ENDCG

		}
	}

	CustomEditor "PBRAnisotropicHairEditor"
}
