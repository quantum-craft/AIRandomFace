using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Windows;
using UEUtils;
using UnityEngine.UI;

struct BlendShapeData
{
    public string ShapeName;
    public float[] Values;
    public string[] Names;
}

public class AIFaceMorphing : MonoBehaviour
{
    static System.Random rnd = new System.Random();

    public SkinnedMeshRenderer m_FaceSMR;
    public int m_BlendShapeCount;
    public RenderTexture m_AIFaceTexture;
    public Text m_Message;

    [Space(10)]
    public string m_SaveFolderName = "AI_Data";
    public string m_LoadFolderName = "AI_Data_Load";

    [Space(10)]
    public string[] m_IgnoreKeys;

    private int m_currentEyeBrow = 0;
    private int m_currentEyeColor = 0;

    private const string m_irisTypeName = "iris";


    public void ResetBlendShape()
    {
        for (int i = 0; i < m_BlendShapeCount; i++)
        {
            m_FaceSMR.SetBlendShapeWeight(i, 0.0f);
        }

        // Eye iris color
        SetIrisColor(0);
    }

    public void SaveTex2File(string fileName)
    {
        RenderTexture.active = m_AIFaceTexture;

        Texture2D tex = new Texture2D(m_AIFaceTexture.width, m_AIFaceTexture.height, TextureFormat.RGB24, false);
        tex.ReadPixels(new Rect(0, 0, m_AIFaceTexture.width, m_AIFaceTexture.height), 0, 0);

        RenderTexture.active = null;

        byte[] bytes;
        bytes = tex.EncodeToJPG();
        // bytes = tex.EncodeToPNG();

        string path = Application.persistentDataPath + "/" + m_SaveFolderName + "/" + fileName + ".jpg";
        System.IO.File.WriteAllBytes(path, bytes);
    }

    public void LoadJson2Part(string fileName)
    {
        string filePath = Application.persistentDataPath + "/" + m_LoadFolderName + "/" + fileName + ".json";

        if (File.Exists(filePath))
        {
            var bytes = File.ReadAllBytes(filePath);
            string dataAsJson = System.Text.Encoding.UTF8.GetString(bytes);
            var data = JsonUtility.FromJson<BlendShapeData>(dataAsJson);

            if (data.Names.Length != data.Values.Length)
            {
                m_Message.text = fileName + ".json is mal-formatted";
                return;
            }

            ResetBlendShape();

            var characterLoader = GetComponent<UECharacterLoader>();
            for (int i = 0; i < data.Names.Length; i++)
            {
                if (data.Names[i] == "eyeiris Color")
                {
                    SetIrisColor((int)data.Values[i] - 1); // 1 based index
                    continue;
                }

                var part = UEBlendShapesUtils.BlendShape.KeyToPart(data.Names[i]);
                var operation = UEBlendShapesUtils.BlendShape.KeyToOperation(data.Names[i]);
                var axis = UEBlendShapesUtils.BlendShape.KeyToAxis(data.Names[i]);

                var set = characterLoader.BlendShapesController.SetValue(
                    part,
                    operation,
                    axis,
                    data.Values[i]);

                if (!set)
                {
                    m_Message.text = data.Names[i] + " is not set";
                    return;
                }
            }

            m_Message.text = fileName + ".json is loaded";
        }
        else
        {
            m_Message.text = fileName + ".json doesn't exit.";
        }
    }

    private bool _shouldIgnore(string key, string[] ignoreKeys)
    {
        foreach (var keyToIgnore in ignoreKeys)
        {
            if (key.Contains(keyToIgnore))
            {
                return true;
            }
        }

        return false;
    }

    public void SavePart2Json(string fileName)
    {
        var characterLoader = GetComponent<UECharacterLoader>();
        var map = characterLoader.BlendShapesController.m_blendShapesMapList[0];

        var names = new List<string>();
        var values = new List<float>();

        foreach (var key in map.Keys)
        {

            if (_shouldIgnore(key, m_IgnoreKeys))
            {
                continue;
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.X].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.X].Sub >= 0)
            {
                var v = characterLoader.BlendShapesController.GetValue(
                            UEBlendShapesUtils.BlendShape.KeyToPart(key),
                            UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                            UEBlendShapesUtils.Axis.X);

                var name = key + " X";

                names.Add(name);
                values.Add(v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Y].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Y].Sub >= 0)
            {
                var v = characterLoader.BlendShapesController.GetValue(
                        UEBlendShapesUtils.BlendShape.KeyToPart(key),
                        UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                        UEBlendShapesUtils.Axis.Y);

                var name = key + " Y";

                names.Add(name);
                values.Add(v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Z].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Z].Sub >= 0)
            {
                var v = characterLoader.BlendShapesController.GetValue(
                        UEBlendShapesUtils.BlendShape.KeyToPart(key),
                        UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                        UEBlendShapesUtils.Axis.Z);

                var name = key + " Z";

                names.Add(name);
                values.Add(v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Total].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Total].Sub >= 0)
            {
                var v = characterLoader.BlendShapesController.GetValue(
                        UEBlendShapesUtils.BlendShape.KeyToPart(key),
                        UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                        UEBlendShapesUtils.Axis.Total);

                var name = key + " T";

                names.Add(name);
                values.Add(v);
            }
        }

        // Eye iris color
        var curIdx = characterLoader.MakeupSystem.GetCurTexIndex(m_irisTypeName);
        names.Add("eyeiris Color");
        values.Add(curIdx + 1); // 1 based idx

        var data = new BlendShapeData
        {
            ShapeName = fileName,
            Values = values.ToArray(),
            Names = names.ToArray()
        };

        string jsonData = JsonUtility.ToJson(data, true);

        string path = Application.persistentDataPath + "/" + m_SaveFolderName + "/" + fileName + ".json";

        var bytes = System.Text.Encoding.UTF8.GetBytes(jsonData);
        File.WriteAllBytes(path, bytes);
    }

    public void RandomizedByPart()
    {
        ResetBlendShape();

        var characterLoader = GetComponent<UECharacterLoader>();
        var map = characterLoader.BlendShapesController.m_blendShapesMapList[0];

        var keys = map.Keys;
        var values = map.Values;

        foreach (var key in map.Keys)
        {
            if (_shouldIgnore(key, m_IgnoreKeys))
            {
                Debug.Log(key);
                continue;
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.X].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.X].Sub >= 0)
            {
                int v = rnd.Next(-100, 101);
                characterLoader.BlendShapesController.SetValue(
                    UEBlendShapesUtils.BlendShape.KeyToPart(key),
                    UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                    UEBlendShapesUtils.Axis.X,
                    v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Y].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Y].Sub >= 0)
            {
                int v = rnd.Next(-100, 101);
                characterLoader.BlendShapesController.SetValue(
                    UEBlendShapesUtils.BlendShape.KeyToPart(key),
                    UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                    UEBlendShapesUtils.Axis.Y,
                    v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Z].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Z].Sub >= 0)
            {
                int v = rnd.Next(-100, 101);
                characterLoader.BlendShapesController.SetValue(
                    UEBlendShapesUtils.BlendShape.KeyToPart(key),
                    UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                    UEBlendShapesUtils.Axis.Z,
                    v);
            }

            if (map[key][(int)UEBlendShapesUtils.Axis.Total].Add >= 0 && map[key][(int)UEBlendShapesUtils.Axis.Total].Sub >= 0)
            {
                int v = rnd.Next(-100, 101);
                characterLoader.BlendShapesController.SetValue(
                    UEBlendShapesUtils.BlendShape.KeyToPart(key),
                    UEBlendShapesUtils.BlendShape.KeyToOperation(key),
                    UEBlendShapesUtils.Axis.Total,
                    v);
            }
        }

        // Eye iris color
        var texCount = characterLoader.MakeupSystem.GetTextureCount(m_irisTypeName);
        var irisIdx = rnd.Next(0, texCount);

        SetIrisColor(irisIdx);
    }

    public void StartRecordByPart(int count)
    {
        StartCoroutine(recordingByPart(count));
    }

    private IEnumerator recordingByPart(int count)
    {
        for (int i = 0; i < count; i++)
        {
            if (i == 0)
            {
                ResetBlendShape();

                yield return new WaitForSeconds(0.05f);

                SaveTex2File("face_" + i);
                SavePart2Json("face_" + i);
            }
            else
            {
                RandomizedByPart();

                yield return new WaitForSeconds(0.05f);

                SaveTex2File("face_" + i);
                SavePart2Json("face_" + i);
            }
        }
    }

    public void ChangeEyeBrow()
    {
        m_currentEyeBrow = m_currentEyeBrow + 1;
        m_currentEyeBrow = m_currentEyeBrow % 5;

        var characterLoader = GetComponent<UECharacterLoader>();
        characterLoader.MakeupSystem.SetTextureState("eyebrow", m_currentEyeBrow);
    }

    public void ChangeEyeColor()
    {
        var characterLoader = GetComponent<UECharacterLoader>();

        var texCount = characterLoader.MakeupSystem.GetTextureCount(m_irisTypeName);

        m_currentEyeColor++;
        m_currentEyeColor %= texCount;

        SetIrisColor(m_currentEyeColor);
        // characterLoader.MakeupSystem.SetTextureState(m_irisTypeName, "_iriscol", new Color(0.0f, 0.0f, 1.0f, 1.0f));
    }

    private void Start()
    {
        InitCharacter();
    }

    public void InitCharacter()
    {
        m_FaceSMR = GetComponent<SkinnedMeshRenderer>();
        m_BlendShapeCount = m_FaceSMR.sharedMesh.blendShapeCount;

        var characterLoader = GetComponent<UECharacterLoader>();

        characterLoader.InitializeEditModeCharacter();
        characterLoader.MakeupSystem.SetTextureState("eyebrow", m_currentEyeBrow);

        SetIrisColor(0);
    }

    public void SetIrisColor(int texIdx)
    {
        m_currentEyeColor = texIdx;

        var characterLoader = GetComponent<UECharacterLoader>();

        var texName = characterLoader.MakeupSystem.SetTextureState(m_irisTypeName, m_currentEyeColor);
        if (m_Message != null)
        {
            m_Message.text = "eyeiris id: " + (m_currentEyeColor + 1) + ". " + texName;
        }
    }
}
