using UnityEditor;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.IO;


public class UEGenerateBlendMatWindow : EditorWindow
{
    private UECharacterData m_targetCharData;
    private string m_makeupTypeName = "";
    private string m_info = "";
    private string m_materialName = "";
    private bool m_useSpriteAtlas = false;
    private bool m_useTexOperations = false;

    public static void Init(UECharacterData target)
    {
        var window = GetWindow<UEGenerateBlendMatWindow>(false, "Generate Blend Material", true);

        window.position = new Rect(80, 120, 300, 200);
        window.m_targetCharData = target;
    }

    void OnGUI()
    {
        EditorGUILayout.Space();

        m_makeupTypeName = EditorGUILayout.TextField("Makeup Type Name", m_makeupTypeName);
        m_materialName = EditorGUILayout.TextField("New Material Name", m_materialName);
        
        m_useSpriteAtlas = EditorGUILayout.Toggle("Use SpriteAtlas", m_useSpriteAtlas);
        m_useTexOperations = EditorGUILayout.Toggle("Use Texture Operations", m_useTexOperations);

        var generateButton = GUILayout.Button("Generate Material");

        EditorGUILayout.Space();
        EditorGUILayout.LabelField(m_info);

        if (generateButton)
        {
            if (m_materialName == "")
            {
                m_info = "Please enter the material name ...";
                return;
            }

            var matchedMakeups = Filter(m_targetCharData.m_MakeupDataList, m_makeupTypeName);
            if (matchedMakeups.Length == 0)
            {
                m_info = "There is no makeup named " + "\'" + m_makeupTypeName + "\' ...";
                return;
            }

            if (matchedMakeups.Length > 1)
            {
                m_info = "There are more than one " + "\'" + m_makeupTypeName + "\' ...";
                return;
            }

            m_info = "";

            var makeupData = matchedMakeups[0];

            makeupData.m_Mode = UECharacterData.MaterialMode.Blend;

            var path = AssetDatabase.GetAssetPath(m_targetCharData);
            string[] paths = path.Split('/');

            var assetFileName = paths[paths.Length - 1].Split('.')[0];

            Array.Resize(ref paths, paths.Length - 1);

            var dirPath = String.Join("/", paths) + "/" + assetFileName + "_AutoGen";
            if (!Directory.Exists(dirPath))
            {
                Directory.CreateDirectory(dirPath);
            }

            Material material = UEShaderGenerator.GetTemplateMaterial(m_materialName, m_makeupTypeName, m_useSpriteAtlas, m_useTexOperations, dirPath);

            AssetDatabase.CreateAsset(material, dirPath + "/" + m_materialName + ".mat");
            makeupData.m_BlendMaterial = material;

            m_info = m_materialName + " has been created and assigned ...";

            return;
        }
    }

    public UECharacterData.MaterialData[] Filter(UECharacterData.MaterialData[] input, string typeName)
    {
        var availableMakeups = new List<UECharacterData.MaterialData>();
        foreach (var makeup in input)
        {
            if (makeup.m_TypeName == typeName)
            {
                availableMakeups.Add(makeup);
            }
        }

        return availableMakeups.ToArray();
    }
}
