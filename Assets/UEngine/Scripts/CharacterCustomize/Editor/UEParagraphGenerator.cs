using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEditor;
using System;
using System.IO;
using System.Text;

public class UEParagraphGenerator
{
    public static string generatePropertyParagraph(string shaderPath, string typeName, string head, string tail, ref List<string> dictionary)
    {
        return generateParagraph(shaderPath, typeName, head, tail, ref dictionary,
                    line => line.Trim(' ') == "Properties",
                    line => line.Contains("_MainTex(\"Don't set,") || line.Trim(' ') == "Properties",
                    line => line.Trim(' ') == "}",
                    modifyProperty);
    }

    private static string modifyProperty(string line, string type_name, ref List<string> dictionary)
    {
        var index = line.Trim(' ').IndexOf("(\"");
        if (index > 0)
        {
            var propertyName = line.Trim(' ').Substring(0, index).Trim(' ');
            line = line.Replace(propertyName, propertyName + "_" + type_name);
        }

        return line;
    }

    public static string generateUniformParagraph(string shaderPath, string typeName, string head, string tail, ref List<string> dictionary)
    {
        return generateParagraph(shaderPath, typeName, head, tail, ref dictionary,
                    line => line.Contains("sampler2D _MainTex"),
                    line => line.Contains("sampler2D _MainTex"),
                    line => line.Trim(' ') == "// ==== End of your Uniforms ====",
                    modifyUniform);
    }

    private static string modifyUniform(string line, string type_name, ref List<string> dictionary)
    {
        var words = line.Trim(' ').Split(' ');

        if (words.Length == 2 && words[1][words[1].Length - 1] == ';')
        {
            line = line.Replace(words[1].Trim(';'), words[1].Trim(';') + "_" + type_name);
            dictionary.Add(words[1].Trim(';'));
        }

        if (words.Length == 3 && words[2] == ";")
        {
            line = line.Replace(words[1], words[1] + "_" + type_name);
            dictionary.Add(words[1]);
        }

        if (words.Length == 4 && words[3] == "0;")
        {
            line = line.Replace(words[1], words[1] + "_" + type_name);
            dictionary.Add(words[1]);
        }

        return line;
    }

    public static string generateFragmentShaderParagraph(string shaderPath, string typeName, string head, string tail, ref List<string> dictionary)
    {
        dictionary.Add("tattooRGBA");
        dictionary.Add("targetUV");
        dictionary.Add("lerp_coeff");
        dictionary.Add("blendRGB");

        return generateParagraph(shaderPath, typeName, head, tail, ref dictionary,
                    line => line.Contains("// ==== Makeup TypeName:"),
                    line => false,
                    line => line.Contains("// ======== End:"),
                    modifyFragmentShader);
    }

    private static string modifyFragmentShader(string line, string type_name, ref List<string> dictionary)
    {
        if (line.Contains("// ==== Makeup TypeName:"))
        {
            var spaceCount = line.IndexOf("// ==== Makeup TypeName:");
            line = new String(' ', spaceCount) + "// ==== Makeup TypeName: " + type_name + " ====";
        }

        if (line.Contains("// ======== End:"))
        {
            var spaceCount = line.IndexOf("// ======== End:");
            line = new String(' ', spaceCount) + "// ======== End: " + type_name + " ========";
        }

        if (line.Contains("// if (_ShouldRender) {"))
        {
            var spaceCount = line.IndexOf("// if (_ShouldRender) {");
            line = new String(' ', spaceCount) + "if (_ShouldRender) {";
        }

        if (line.Contains("// }"))
        {
            var spaceCount = line.IndexOf("// }");
            line = new String(' ', spaceCount) + "}";
        }

        foreach (var word in dictionary)
        {
            line = line.Replace(word, word + "_" + type_name);
        }

        return line;
    }

    public delegate string ModifyDelegate(string line, string typeName, ref List<string> dictionary);
    public static string generateParagraph(string shaderPath, string typeName, string head, string tail, ref List<string> dictionary,
        Func<string, bool> shouldStart,
        Func<string, bool> shouldSkip,
        Func<string, bool> shouldEnd,
        ModifyDelegate modify)
    {
        var sb = new StringBuilder();
        try
        {
            using (StreamReader sr = new StreamReader(shaderPath))
            {
                string line;
                bool started = false;
                while ((line = sr.ReadLine()) != null)
                {
                    if (shouldStart(line))
                    {
                        started = true;
                        if (head != "") { sb.AppendLine(head); }
                    }

                    if (started)
                    {
                        if (shouldSkip(line)) { continue; }

                        line = modify(line, typeName, ref dictionary);
                        sb.AppendLine(line);
                    }

                    if (shouldEnd(line))
                    {
                        if (tail != "") { sb.AppendLine(tail); }
                        break;
                    }
                }
            }
        }
        catch (Exception e) { Debug.LogError(e.Message); }

        return sb.ToString();
    }
}
