/* UEngine Team: HSV(HSB) color effect sub-routines.
 * Author: Yuheng Chen(Henry)
 * Date: 2019/03/13
 * Updated: 2019/03/13
 */

#ifndef UE_HSBC_EFFECT_INCLUDED
#define UE_HSBC_EFFECT_INCLUDED

inline float3 applyHue(float3 aColor, float aHue)
{
    float angle = radians(aHue);
    float3 k = float3(0.57735, 0.57735, 0.57735);
    float cosAngle = cos(angle);

    // Rodrigues' rotation formula
    return aColor * cosAngle + cross(k, aColor) * sin(angle) + k * dot(k, aColor) * (1 - cosAngle);
}

inline float4 applyHSBCEffect(float4 startColor, fixed4 hsbc)
{
    float hue = 360 * hsbc.r;
    float saturation = hsbc.g * 2;
    float brightness = hsbc.b * 2 - 1;
    float contrast = hsbc.a * 2;

    float4 outputColor = startColor;
    outputColor.rgb = applyHue(outputColor.rgb, hue);
    outputColor.rgb = (outputColor.rgb - 0.5f) * contrast + 0.5f;
    outputColor.rgb = outputColor.rgb + brightness;
    float3 intensity = dot(outputColor.rgb, float3(0.39, 0.59, 0.11));
    outputColor.rgb = lerp(intensity, outputColor.rgb, saturation);

    return outputColor;
}

inline float4 rgb2hsv(float4 c)
{
    float4 K = float4(0.0, -1.0 / 3.0, 2.0 / 3.0, -1.0);
    float4 p = lerp(float4(c.bg, K.wz), float4(c.gb, K.xy), step(c.b, c.g));
    float4 q = lerp(float4(p.xyw, c.r), float4(c.r, p.yzx), step(p.x, c.r));

    float d = q.x - min(q.w, q.y);
    float e = 1.0e-10;
    return float4(abs(q.z + (q.w - q.y) / (6.0 * d + e)), d / (q.x + e), q.x, c.a);
}

inline float4 hsv2rgb(float4 c)
{
    float4 K = float4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    float3 p = abs(frac(c.xxx + K.xyz) * 6.0 - K.www);
    return float4(c.z * lerp(K.xxx, saturate(p - K.xxx), c.y), c.a);
}

inline float repeat(float t, float length)
{
    return clamp(t - floor(t / length) * length, 0.0f, length);
}

inline float lerp_angle(float a, float b, float t)
{
    float delta = repeat((b - a), 360);
    if (delta > 180)
        delta -= 360;
    return a + delta * saturate(t);
}

inline float4 hsv_lerp(float4 a, float4 b, float t)
{
    float h, s;

    //check special case black (color.z==0): interpolate neither hue nor saturation!
    //check special case grey (color.y==0): don't interpolate hue!
    if (a.b == 0)
    {
        h = b.x;
        s = b.y;
    }
    else if (b.b == 0)
    {
        h = a.x;
        s = a.y;
    }
    else
    {
        if (a.y == 0)
        {
            h = b.x;
        }
        else if (b.y == 0)
        {
            h = a.x;
        }
        else
        {
            // works around bug with LerpAngle
            float angle = lerp_angle(a.x * 360.0f, b.x * 360.0f, t);

            while (angle < 0.0f)
                angle += 360.0f;
            while (angle > 360.0f)
                angle -= 360.0f;

            h = angle / 360.0f;
        }
        s = lerp(a.y, b.y, t);
    }

    return float4(h, s, lerp(a.b, b.b, t), lerp(a.a, b.a, t));
}

#endif // UE_HSBC_EFFECT_INCLUDED
