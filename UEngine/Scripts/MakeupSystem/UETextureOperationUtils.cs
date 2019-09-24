using UnityEngine;

public class UETextureOperationUtils
{
    public static Vector4 CalculateUVRegion(Vector4 tileOffset, Vector2 textureSize)
    {
        if (textureSize.x == 0.0f || textureSize.y == 0.0f)
        {
            return new Vector4(0.0f, 0.0f, 0.0f, 0.0f);
        }

        Vector2 uRegion = new Vector2(tileOffset.x, tileOffset.z + tileOffset.x) / textureSize.x;
        Vector2 vRegion = new Vector2(tileOffset.y, tileOffset.w + tileOffset.y) / textureSize.y;

        return new Vector4(uRegion.x, uRegion.y, vRegion.x, vRegion.y);
    }

    public static Vector2 CalculateUVCenter(Vector2 tileCenter, Vector2 textureSize)
    {
        if (textureSize.x == 0.0f || textureSize.y == 0.0f)
        {
            return new Vector2(0.0f, 0.0f);
        }

        return new Vector2(tileCenter.x / textureSize.x, tileCenter.y / textureSize.y);
    }

    public static Vector2 CalculateUVScale(float scaleX, float scaleY)
    {
        return new Vector2(1 / scaleX, 1 / scaleY);
    }

    public static Vector2 GetOriginalTattooTextureSize(Sprite sprite)
    {
        return new Vector2(sprite.rect.width, sprite.rect.height);
    }

    public static Vector2 GetOriginalTattooRectPosition(Sprite sprite)
    {
        return new Vector2(sprite.textureRectOffset.x, sprite.textureRectOffset.y);
    }

    public static Vector2 GetAtlasRectPosition(Sprite sprite)
    {
        return new Vector2(sprite.textureRect.position.x, sprite.textureRect.position.y);
    }

    public static Vector2 GetAtlasTextureSize(Sprite sprite)
    {
        return new Vector2(sprite.texture.width, sprite.texture.height);
    }

    public static Vector4 GetAtlasUVRegion(Sprite sprite)
    {
        // (U_MIN, U_MAX, V_MIN, V_MAX)
        return new Vector4(
            sprite.textureRect.xMin / sprite.texture.width,
            sprite.textureRect.xMax / sprite.texture.width,
            sprite.textureRect.yMin / sprite.texture.height,
            sprite.textureRect.yMax / sprite.texture.height);
    }

    public static Vector2 GetAtlasUVCenter(Sprite sprite)
    {
        return new Vector2(
            sprite.textureRect.center.x / sprite.texture.width,
            sprite.textureRect.center.y / sprite.texture.height);
    }
}
