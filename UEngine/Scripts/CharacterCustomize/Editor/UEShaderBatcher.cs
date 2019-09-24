using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text;
using System.Linq;

public class UEShaderBatcher
{
    public static void BatchMaterials(UECharacterData target, string targetPath)
    {
        // Clear previous data
        foreach (var matData in target.m_MakeupDataList) { matData.m_BatchedMaterial = null; }

        var renderGroups = target.m_MakeupDataList.GroupBy(o => o.Hash).ToDictionary(o => o.Key, o => o.ToList());
        foreach (var renderGroup in renderGroups)
        {
            var selected = (from m in renderGroup.Value
                            where m.m_Mode == UECharacterData.MaterialMode.Blend &&
                                  m.m_BlendMaterial != null &&
                                  checkBatchable(AssetDatabase.GetAssetPath(m.m_BlendMaterial.shader))
                            select m).ToList();

            var shaderProperties = new Dictionary<string, string>();
            var shaderUniforms = new Dictionary<string, string>();
            var shaderFragments = new Dictionary<string, string>();

            string renderGroupFileKey = "";

            foreach (var m in selected)
            {
                renderGroupFileKey = m.FileHash;

                var shaderPath = AssetDatabase.GetAssetPath(m.m_BlendMaterial.shader);
                var dictionary = new List<string>();

                // Properties
                var properties = UEParagraphGenerator.generatePropertyParagraph(shaderPath, m.m_TypeName, "", "", ref dictionary);
                shaderProperties.Add(m.m_TypeName, properties);

                // Uniforms
                var uniforms = UEParagraphGenerator.generateUniformParagraph(shaderPath, m.m_TypeName, "{", "}", ref dictionary);
                shaderUniforms.Add(m.m_TypeName, uniforms);

                // Fragments
                var fragmentshader = UEParagraphGenerator.generateFragmentShaderParagraph(shaderPath, m.m_TypeName, "{", "}", ref dictionary);
                shaderFragments.Add(m.m_TypeName, fragmentshader);
            }

            if (selected.Count > 0)
            {
                var templatePath = "Assets/UEngine/Shaders/MakeupSystem/Template/UEBlendTemplate_All.shader";
                var shaderName = "Blend_All_" + renderGroup.Key;
                StringBuilder sb = GenerateShader_AllStream(shaderName, templatePath, shaderProperties, shaderUniforms, shaderFragments);
                var blendAllShaderPath = targetPath + "/" + "UE" + "Blend_All_" + renderGroupFileKey + ".shader";
                try
                {
                    using (StreamWriter sw = new StreamWriter(blendAllShaderPath))
                    {
                        sw.WriteLine(sb.ToString());
                    }
                }
                catch (Exception e)
                {
                    Debug.LogError(e.Message);
                }

                AssetDatabase.ImportAsset(blendAllShaderPath);

                var batchedMaterial = new Material(Shader.Find("UEngine/UE " + shaderName + " (Auto-generated)"));
                AssetDatabase.CreateAsset(batchedMaterial, targetPath + "/" + "Blend_All_" + renderGroupFileKey + ".mat");

                foreach (var m in selected) { m.m_BatchedMaterial = batchedMaterial; }
            }
        }
    }

    private static bool checkBatchable(string shaderPath)
    {
        bool autoSignature = false;
        bool typeNameSignature = false;

        try
        {
            using (StreamReader sr = new StreamReader(shaderPath))
            {
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    if (line.Contains("(Auto-generated)"))
                    {
                        autoSignature = true;
                    }

                    if (line.Contains("Makeup TypeName:"))
                    {
                        typeNameSignature = true;
                    }
                }
            }
        }
        catch (Exception e)
        {
            Debug.LogError(e.Message);
        }

        if (autoSignature && typeNameSignature) { return true; }
        else { return false; }
    }

    public static StringBuilder GenerateShader_AllStream(string shaderName, string templatePath,
        Dictionary<string, string> shaderProperties,
        Dictionary<string, string> shaderUniforms,
        Dictionary<string, string> shaderFragments)
    {
        var sb = new StringBuilder();
        try
        {
            using (StreamReader sr = new StreamReader(templatePath))
            {
                string line;
                while ((line = sr.ReadLine()) != null)
                {
                    if (line.Contains("Shader \"UEngine/UE Blend Template All\""))
                    {
                        sb.AppendLine(line.Substring(0, line.IndexOf("/UE ") + 4) + shaderName + " (Auto-generated)" + "\"");
                        continue;
                    }

                    if (line.Contains("// ==== Your Properties here ===="))
                    {
                        foreach (var property in shaderProperties)
                        {
                            var addLines = property.Value;
                            if (addLines.TrimStart(' ').StartsWith("{"))
                            {
                                addLines = addLines.TrimStart(' ', '{');
                            }

                            if (addLines.TrimEnd(' ').EndsWith("}") || addLines.TrimEnd(' ').EndsWith("}\r\n"))
                            {
                                addLines = addLines.TrimEnd(' ', '}', '\r', '\n');
                            }

                            sb.AppendLine(addLines);
                        }

                        continue;
                    }

                    if (line.Contains("// ==== End of your Properties ===="))
                    {
                        continue;
                    }

                    if (line.Contains("// ==== Your Uniforms here ===="))
                    {
                        foreach (var uniform in shaderUniforms)
                        {
                            var addLines = uniform.Value;
                            if (addLines.TrimStart(' ').StartsWith("{"))
                            {
                                addLines = addLines.TrimStart(' ', '{');
                            }

                            if (addLines.TrimEnd(' ').EndsWith("}") || addLines.TrimEnd(' ').EndsWith("}\r\n"))
                            {
                                addLines = addLines.TrimEnd(' ', '}', '\r', '\n');
                            }

                            sb.AppendLine(addLines);
                        }

                        continue;
                    }

                    if (line.Contains("// ==== End of your Uniforms ===="))
                    {
                        continue;
                    }

                    if (line.Contains("// ==== Your Fragment Shader codes here ===="))
                    {
                        foreach (var fragment in shaderFragments)
                        {
                            var addLines = fragment.Value;
                            if (addLines.TrimStart(' ').StartsWith("{"))
                            {
                                addLines = addLines.TrimStart(' ', '{');
                            }

                            if (addLines.TrimEnd(' ').EndsWith("}") || addLines.TrimEnd(' ').EndsWith("}\r\n"))
                            {
                                addLines = addLines.TrimEnd(' ', '}', '\r', '\n');
                            }

                            sb.AppendLine(addLines);
                        }

                        continue;
                    }

                    if (line.Contains("// ==== End of your Fragment Shader codes ===="))
                    {
                        var spaceCount = line.IndexOf("// ==== End of your Fragment Shader codes ====");
                        int cnt = 1;
                        foreach (var fragment in shaderFragments)
                        {
                            if (cnt == 1)
                            {
                                sb.AppendLine(new string(' ', spaceCount) +
                                    "float3 outColor" + cnt + " = lerp(faceRGBA.rgb, blendRGB_" + fragment.Key + ".rgb, lerp_coeff_" + fragment.Key + ");");
                            }
                            else
                            {
                                sb.AppendLine(new string(' ', spaceCount) +
                                    "float3 outColor" + cnt + " = lerp(outColor" + (cnt - 1) + ", blendRGB_" + fragment.Key + ".rgb, lerp_coeff_" + fragment.Key + ");");
                            }

                            cnt++;
                        }

                        if (shaderFragments.Count > 0)
                        {
                            sb.AppendLine(new string(' ', spaceCount) +
                                "return float4(outColor" + (cnt - 1) + ", faceRGBA.a);");
                        }
                        else
                        {
                            sb.AppendLine(new string(' ', spaceCount) +
                                "return float4(1.0f, 0.0f, 1.0f, faceRGBA.a);");
                        }

                        continue;
                    }

                    if (line.Contains("float3 outColor = float3(1.0f, 0.0f, 1.0f);"))
                    {
                        continue;
                    }

                    if (line.Contains("return float4(outColor, faceRGBA.a);"))
                    {
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

        return sb;
    }
}
