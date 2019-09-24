using System;
using System.IO;
using System.Text;
using UnityEditor;
using UnityEngine;

public class UEShaderGenerator
{
    public static Material GetTemplateMaterial(string materialName, string makeupTypeName, bool useSpriteAtlas, bool useTexOperations, string targetPath)
    {
        var templatePath = "Assets/UEngine/Shaders/MakeupSystem/Template/UEBlendTemplate.shader";

        var shaderPath = targetPath + "/" + "UE" + materialName + ".shader";

        var sb = new StringBuilder();
        try
        {
            using (StreamReader sr = new StreamReader(templatePath))
            {
                bool skip = false;
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    if (line.Trim(' ').Contains("// ==== SpriteAtlas End ===="))
                    {
                        if (skip) { skip = false; }
                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Common End ===="))
                    {
                        if (skip) { skip = false; }
                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Texture Operation End ===="))
                    {
                        if (skip) { skip = false; }
                        continue;
                    }

                    if (line.Trim(' ').Contains("float lerp_coeff = 0.0f;"))
                    {
                        if (skip) { skip = false; }

                        sb.AppendLine("");
                        sb.AppendLine(line);
                        continue;
                    }

                    if (skip) { continue; }

                    if (line.Trim(' ').Contains("Shader \"UEngine/UE Blend Template\""))
                    {
                        sb.AppendLine(line.Substring(0, line.IndexOf("/UE ") + 4) + materialName + " (Auto-generated)" + "\"");
                        continue;
                    }

                    if (line.Trim(' ').Contains("// ======== End:  ========"))
                    {
                        sb.AppendLine(line.Substring(0, line.IndexOf("End: ") + 5) + makeupTypeName + " ========\"");
                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Makeup TypeName:"))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== Makeup TypeName:");

                        sb.AppendLine(line.Substring(0, line.IndexOf("Name: ") + 6) + makeupTypeName + " ====\"");

                        if (!useSpriteAtlas && !useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "float4 tattooRGBA = tex2D(_TattooTex, i.uv);");
                        }
                        else if (useSpriteAtlas && !useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "half2 targetUV = AtlasMapping(i.uv, _FaceWH, _RectOffset, _AtlasOffset, _AtlasWH);");
                            sb.AppendLine(new string(' ', spaceCount) + "float4 tattooRGBA = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));");
                        }
                        else if (!useSpriteAtlas && useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "half2 targetUV = ApplyTexOps(i.uv, _UVCenter, _TattooPositionX, _TattooPositionY,");
                            sb.AppendLine(new string(' ', spaceCount + 4) + "_TattooScaleX, _TattooScaleY, _TattooRotation,");
                            sb.AppendLine(new string(' ', spaceCount + 4) + "_TattooFlipX, _TattooFlipY);");
                            sb.AppendLine(new string(' ', spaceCount) + "float4 tattooRGBA = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));");
                        }
                        else
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "half2 targetUV = AtlasMapping(i.uv, _FaceWH, _RectOffset, _AtlasOffset, _AtlasWH);");
                            sb.AppendLine(new string(' ', spaceCount) + "targetUV = ApplyTexOps(targetUV, _UVCenter, _TattooPositionX, _TattooPositionY,");
                            sb.AppendLine(new string(' ', spaceCount + 4) + "_TattooScaleX, _TattooScaleY, _TattooRotation,");
                            sb.AppendLine(new string(' ', spaceCount + 4) + "_TattooFlipX, _TattooFlipY);");
                            sb.AppendLine(new string(' ', spaceCount) + "float4 tattooRGBA = tex2D(_TattooTex, filter_uv(targetUV, _UVRegion));");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== SpriteAtlas Properties ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== SpriteAtlas Properties ====");

                        if (useSpriteAtlas)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "_FaceWH(\"Original tattoo texture size\", Vector) = (0, 0, 0, 0)");
                            sb.AppendLine(new string(' ', spaceCount) + "_RectOffset(\"Original tattoo rect position\", Vector) = (0, 0, 0, 0)");
                            sb.AppendLine(new string(' ', spaceCount) + "_AtlasOffset(\"Atlas tattoo rect position\", Vector) = (0, 0, 0, 0)");
                            sb.AppendLine(new string(' ', spaceCount) + "_AtlasWH(\"Atlas texture size\", Vector) = (0, 0, 0, 0)");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Common Properties ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== Common Properties ====");

                        if (useSpriteAtlas || useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "_UVRegion(\"Tattoo Texture UV Region\", Vector) = (0, 0, 0, 0) // (U_MIN, U_MAX, V_MIN, V_MAX)");
                            sb.AppendLine(new string(' ', spaceCount) + "_UVCenter(\"Tattoo Texture UV Center\", Vector) = (0, 0, 0, 0)");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Texture Operation Properties ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== Texture Operation Properties ====");

                        if (useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooPositionX(\"Tattoo Position X\", Range(-1.0, 1.0)) = 0.0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooPositionY(\"Tattoo Position Y\", Range(-1.0, 1.0)) = 0.0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooRotation(\"Tattoo Rotation\", Range(0.0, 360.0)) = 0.0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooScaleX(\"Tattoo Scale X\", Range(0.0, 100.0)) = 1.0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooScaleY(\"Tattoo Scale Y\", Range(0.0, 100.0)) = 1.0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooFlipX(\"Tattoo Flip X\", Int) = 0");
                            sb.AppendLine(new string(' ', spaceCount) + "_TattooFlipY(\"Tattoo Flip Y\", Int) = 0");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== SpriteAtlas Uniforms ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== SpriteAtlas Uniforms ====");

                        if (useSpriteAtlas)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "float2 _FaceWH;");
                            sb.AppendLine(new string(' ', spaceCount) + "float2 _RectOffset;");
                            sb.AppendLine(new string(' ', spaceCount) + "float2 _AtlasOffset;");
                            sb.AppendLine(new string(' ', spaceCount) + "float2 _AtlasWH;");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Common Uniforms ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== Common Uniforms ====");

                        if (useSpriteAtlas || useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "vector _UVRegion;");
                            sb.AppendLine(new string(' ', spaceCount) + "float2 _UVCenter;");
                        }

                        continue;
                    }

                    if (line.Trim(' ').Contains("// ==== Texture Operation Uniforms ===="))
                    {
                        skip = true;
                        var spaceCount = line.IndexOf("// ==== Texture Operation Uniforms ====");

                        if (useTexOperations)
                        {
                            sb.AppendLine(new string(' ', spaceCount) + "half _TattooPositionX;");
                            sb.AppendLine(new string(' ', spaceCount) + "half _TattooPositionY;");
                            sb.AppendLine(new string(' ', spaceCount) + "float _TattooScaleX;");
                            sb.AppendLine(new string(' ', spaceCount) + "float _TattooScaleY;");
                            sb.AppendLine(new string(' ', spaceCount) + "float _TattooRotation;");
                            sb.AppendLine(new string(' ', spaceCount) + "int _TattooFlipX;");
                            sb.AppendLine(new string(' ', spaceCount) + "int _TattooFlipY;");
                        }

                        continue;
                    }

                    sb.AppendLine(line);
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogError(e.Message);
        }

        try
        {
            using (StreamWriter sw = new StreamWriter(shaderPath))
            {
                sw.WriteLine(sb.ToString());
            }
        }
        catch (Exception e)
        {
            Debug.LogError(e.Message);
        }

        AssetDatabase.ImportAsset(shaderPath);

        return new Material(Shader.Find("UEngine/UE " + materialName + " (Auto-generated)"));
    }
}
