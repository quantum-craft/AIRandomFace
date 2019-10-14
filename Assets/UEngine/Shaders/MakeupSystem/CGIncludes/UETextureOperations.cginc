/* UEngine Team: Texture operation sub-routines.
 * Author: Yuheng Chen(Henry)
 * Date: 2019/03/13
 * Updated: 2019/04/02
 */

#ifndef UE_TEXTURE_OPERATIONS_INCLUDED
#define UE_TEXTURE_OPERATIONS_INCLUDED

inline half square_wave(half a, half b, half x)
{
    return step(a, x) * (1 - step(b, x));
}

inline half2 filter_uv(half2 uv, half4 region)
{
    if (region.x == 0.0f && region.y == 0.0f &&
        region.z == 0.0f && region.w == 0.0f)
    {
        return uv;
    }
    else
    {
        return uv * half2(square_wave(region.x, region.y, uv.x), square_wave(region.z, region.w, uv.y));
    }
}

inline half2 UVToLocal(half2 inUV, half2 uvCenter)
{
    return inUV - uvCenter;
}

inline half2 UVToGlobal(half2 inUV, half2 uvCenter)
{
    return inUV + uvCenter;
}

inline half2 UVTranslation(half2 inUV, half positionX, half positionY)
{
    return inUV + half2(positionX, -positionY);
}

inline half2 UVScale(half2 inUV, half scaleX, half scaleY)
{
    return inUV * half2(1 / scaleX, 1 / scaleY);
}

inline half2 UVRotation(half2 inUV, float2x2 rotationMatrix)
{
    return mul(inUV, rotationMatrix);
}

inline half2 UVTryFlip(half2 inUV, int flipX, int flipY)
{
    return half2(lerp(1, -1, flipX), lerp(1, -1, flipY)) * inUV;
}

inline half2 AtlasMapping(half2 faceUV, half2 faceWH, half2 rectOffset, half2 atlasOffset, half2 atlasWH)
{
    if (atlasWH.x == 0 && atlasWH.y == 0) { return faceUV; }

    half2 faceSpace = faceUV * faceWH;
    half2 rectSpace = faceSpace - rectOffset;
    half2 atlasSpace = rectSpace + atlasOffset;
    half2 atlasUV = atlasSpace / atlasWH;

    return atlasUV;
}

inline half2 ApplyTexOps(half2 inUV, half2 uvCenter, half positionX, half positionY, half scaleX, half scaleY, float rotation, int flipX, int flipY)
{
    half2 targetUV = UVToLocal(inUV, uvCenter);

    // positionX = (positionX * 2 - 1) * 0.3f;
    // positionY = (positionY * 2 - 1) * 0.3f;
    
    targetUV = UVTranslation(targetUV, positionX, positionY);
    targetUV = UVScale(targetUV, scaleX, scaleY);

    float2x2 rotationM = float2x2(
        cos(radians(rotation)), -sin(radians(rotation)),
        sin(radians(rotation)), cos(radians(rotation)));

    targetUV = UVRotation(targetUV, rotationM);
    targetUV = UVTryFlip(targetUV, flipX, flipY);
    targetUV = UVToGlobal(targetUV, uvCenter);

    return targetUV;
}

#endif // UE_TEXTURE_OPERATIONS_INCLUDED
