using UnityEditor;
using UnityEngine;
using System;
using System.IO;
using System.Text;

[CustomEditor(typeof(UECharacterData))]
public class UECharacterDataEditor : Editor
{
    public override void OnInspectorGUI()
    {
        base.OnInspectorGUI();

        EditorGUILayout.Space();

        var style = new GUIStyle(GUI.skin.label) { alignment = TextAnchor.MiddleCenter };
        EditorGUILayout.LabelField("Makeup Tools", style, GUILayout.ExpandWidth(true));
        HorizontalLine(Color.grey);

        var generateButton = GUILayout.Button("Generate Blend Material for Makeup");
        EditorGUILayout.Space();
        EditorGUILayout.Space();

        EditorGUILayout.LabelField("Batch Tools", style, GUILayout.ExpandWidth(true));
        HorizontalLine(Color.grey);

        var batchButton = GUILayout.Button("Batch Materials");
        EditorGUILayout.Space();
        EditorGUILayout.Space();

        if (generateButton) { generateBlendMaterial(); }
        if (batchButton) { batchMaterials(); }
    }

    private void generateBlendMaterial()
    {
        var characterData = target as UECharacterData;

        UEGenerateBlendMatWindow.Init(characterData);
    }

    private void batchMaterials()
    {
        var characterData = target as UECharacterData;

        var path = AssetDatabase.GetAssetPath(characterData);
        string[] paths = path.Split('/');

        var assetFileName = paths[paths.Length - 1].Split('.')[0];

        Array.Resize(ref paths, paths.Length - 1);

        var dirPath = String.Join("/", paths) + "/" + assetFileName + "_AutoGen";
        if (!Directory.Exists(dirPath))
        {
            Directory.CreateDirectory(dirPath);
        }

        UEShaderBatcher.BatchMaterials(characterData, dirPath);
    }

    private static void HorizontalLine(Color color)
    {
        GUIStyle horizontalLine;
        horizontalLine = new GUIStyle();
        horizontalLine.normal.background = EditorGUIUtility.whiteTexture;
        horizontalLine.margin = new RectOffset(0, 0, 4, 4);
        horizontalLine.fixedHeight = 1;

        var c = GUI.color;
        GUI.color = color;
        GUILayout.Box(GUIContent.none, horizontalLine);
        GUI.color = c;
    }
}
