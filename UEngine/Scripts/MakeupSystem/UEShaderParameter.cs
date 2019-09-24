using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public enum EShaderFloatParameter
{
    IRIS_SCALE,
    PUPIL_SCALE,
    EYE_SPECULAR_POWER,
    BLEND_HUE,
    BLEND_SATURATION,
    BLEND_BRIGHTNESS,
    BLEND_CONTRAST,
    BLEND_TATTOO_DENSITY,
    BLEND_TATTOO_POS_X,
    BLEND_TATTOO_POS_Y,
    BLEND_TATTOO_ROTATION,
    BLEND_TATTOO_SCALE_X,
    BLEND_TATTOO_SCALE_Y,
    BLEND_ALPHA,
    BLEND_AREA,
    WRINKLE_RAISED_LINES_POWER,
    WRINKLE_FISTAIL_LINES_POWER,
    WRINKLE_NASOLABIAL_FLODS_POWER
}

public enum EShaderVectorParameter
{
    IRIS_TEXTURE_COORDINATE,
    PUPIL_TEXTURE_COORDINATE,
    IRIS_UV_DIRECTION,
    PUPIL_UV_DIRECTION,
    BLEND_ORIG_TATTOO_TEX_SIZE,
    BLEND_ORIG_TATTOO_RECT_POS,
    BLEND_ATLAS_TATTOO_RECT_POS,
    BLEND_ATLAS_TATTOO_TEX_SIZE,
    BLEND_TATTOO_TEX_UV_REGION,
    BLEND_TATTOO_TEX_UV_CENTER
}

public enum EShaderColorParameter
{
    IRIS_COLOR,
    PUPIL_COLOR,
    EYE_SPECULAR_COLOR,
    BLEND_TATTOO_COLOR,
    BLEND_COLOR
}

public enum EShaderIntParameter
{
    BLEND_HSV_COLOR_LERP,
    BLEND_TATTOO_FLIP_X,
    BLEND_TATTOO_FLIP_Y,
    BLEND_TATTOO_TILE_INDEX
}

public struct UEShaderParameterInfo
{
    public string m_Name;
}

public class UEShaderParamUtil
{
    public static UEShaderParameterInfo GetShaderParameterInfo(EShaderColorParameter shaderParam)
    {
        switch (shaderParam)
        {
            case (EShaderColorParameter.IRIS_COLOR):
                return new UEShaderParameterInfo
                {
                    m_Name = "_iriscol"
                };

            case (EShaderColorParameter.PUPIL_COLOR):
                return new UEShaderParameterInfo
                {
                    m_Name = "_pupilcol"
                };

            case (EShaderColorParameter.EYE_SPECULAR_COLOR):
                return new UEShaderParameterInfo
                {
                    m_Name = "_speccol"
                };

            case (EShaderColorParameter.BLEND_TATTOO_COLOR):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooColor"
                };

            case (EShaderColorParameter.BLEND_COLOR):
                return new UEShaderParameterInfo
                {
                    m_Name = "_blendColor"
                };
            default:
                throw new System.Exception("Unsupported shader parameter");
        }
    }

    public static UEShaderParameterInfo GetShaderParameterInfo(EShaderVectorParameter shaderParam)
    {
        switch (shaderParam)
        {
            case (EShaderVectorParameter.IRIS_TEXTURE_COORDINATE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_irisStartUV"
                };

            case (EShaderVectorParameter.PUPIL_TEXTURE_COORDINATE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_pupilStartUV"
                };

            case (EShaderVectorParameter.IRIS_UV_DIRECTION):
                return new UEShaderParameterInfo
                {
                    m_Name = "_irisUVDir"
                };

            case (EShaderVectorParameter.PUPIL_UV_DIRECTION):
                return new UEShaderParameterInfo
                {
                    m_Name = "_pupilUVDir"
                };

            case (EShaderVectorParameter.BLEND_ORIG_TATTOO_TEX_SIZE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_FaceWH"
                };

            case (EShaderVectorParameter.BLEND_ORIG_TATTOO_RECT_POS):
                return new UEShaderParameterInfo
                {
                    m_Name = "_RectOffset"
                };

            case (EShaderVectorParameter.BLEND_ATLAS_TATTOO_RECT_POS):
                return new UEShaderParameterInfo
                {
                    m_Name = "_AtlasOffset"
                };

            case (EShaderVectorParameter.BLEND_ATLAS_TATTOO_TEX_SIZE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_AtlasWH"
                };

            case (EShaderVectorParameter.BLEND_TATTOO_TEX_UV_REGION):
                return new UEShaderParameterInfo
                {
                    m_Name = "_UVRegion"
                };

            case (EShaderVectorParameter.BLEND_TATTOO_TEX_UV_CENTER):
                return new UEShaderParameterInfo
                {
                    m_Name = "_UVCenter"
                };

            default:
                throw new System.Exception("Unsupported shader parameter");
        }
    }

    public static UEShaderParameterInfo GetShaderParameterInfo(EShaderFloatParameter shaderParam)
    {
        switch (shaderParam)
        {
            case (EShaderFloatParameter.IRIS_SCALE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_irisscale"
                };

            case (EShaderFloatParameter.PUPIL_SCALE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_pupilscale"
                };

            case (EShaderFloatParameter.EYE_SPECULAR_POWER):
                return new UEShaderParameterInfo
                {
                    m_Name = "_Spec"
                };

            case (EShaderFloatParameter.BLEND_HUE):
                return new UEShaderParameterInfo
                {
                    m_Name = "_Hue"
                };

            case (EShaderFloatParameter.BLEND_SATURATION):
                return new UEShaderParameterInfo
                {
                    m_Name = "_Saturation"
                };

            case (EShaderFloatParameter.BLEND_BRIGHTNESS):
                return new UEShaderParameterInfo
                {
                    m_Name = "_Brightness"
                };

            case (EShaderFloatParameter.BLEND_CONTRAST):
                return new UEShaderParameterInfo
                {
                    m_Name = "_Contrast"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_DENSITY):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooDensity"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_POS_X):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooPositionX"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_POS_Y):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooPositionY"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_ROTATION):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooRotation"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_SCALE_X):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooScaleX"
                };

            case (EShaderFloatParameter.BLEND_TATTOO_SCALE_Y):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooScaleY"
                };

            case (EShaderFloatParameter.BLEND_ALPHA):
                return new UEShaderParameterInfo
                {
                    m_Name = "_blendAlpha"
                };

            case (EShaderFloatParameter.BLEND_AREA):
                return new UEShaderParameterInfo
                {
                    m_Name = "_blendArea"
                };

            case (EShaderFloatParameter.WRINKLE_RAISED_LINES_POWER):
                return new UEShaderParameterInfo
                {
                    m_Name = "_raisedlinespow"
                };

            case (EShaderFloatParameter.WRINKLE_FISTAIL_LINES_POWER):
                return new UEShaderParameterInfo
                {
                    m_Name = "_fishtaillinespow"
                };

            case (EShaderFloatParameter.WRINKLE_NASOLABIAL_FLODS_POWER):
                return new UEShaderParameterInfo
                {
                    m_Name = "_nasolabialfoldspow"
                };

            default:
                throw new System.Exception("Unsupported shader parameter");
        }
    }
    public static UEShaderParameterInfo GetShaderParameterInfo(EShaderIntParameter shaderParam)
    {
        switch (shaderParam)
        {
            case (EShaderIntParameter.BLEND_HSV_COLOR_LERP):
                return new UEShaderParameterInfo
                {
                    m_Name = "_HSVColorLerp"
                };

            case (EShaderIntParameter.BLEND_TATTOO_FLIP_X):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooFlipX"
                };

            case (EShaderIntParameter.BLEND_TATTOO_FLIP_Y):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooFlipY"
                };

            case (EShaderIntParameter.BLEND_TATTOO_TILE_INDEX):
                return new UEShaderParameterInfo
                {
                    m_Name = "_TattooTileIndex"
                };

            default:
                throw new System.Exception("Unsupported shader parameter");
        }
    }
}
