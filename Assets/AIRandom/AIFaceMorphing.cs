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

    private int m_currentEyeBrow = 3;

    private void Awake()
    {
        m_FaceSMR = GetComponent<SkinnedMeshRenderer>();
        m_BlendShapeCount = m_FaceSMR.sharedMesh.blendShapeCount;
    }

    public void ResetBlendShape()
    {
        for (int i = 0; i < m_BlendShapeCount; i++)
        {
            m_FaceSMR.SetBlendShapeWeight(i, 0.0f);
        }
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

    public void SavePart2Json(string fileName)
    {
        var characterLoader = GetComponent<UECharacterLoader>();
        var map = characterLoader.BlendShapesController.m_blendShapesMapList[0];

        var names = new List<string>();
        var values = new List<float>();

        foreach (var key in map.Keys)
        {
            if (key.Contains("tone ") || key.Contains("mouth03") || key.Contains("eyebrow02") || key.Contains("eyebrow03")
                || key.Contains("eyeball")||key.Contains("eye Rotation"))
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
            if (key.Contains("tone ") || key.Contains("mouth03") || key.Contains("eyebrow02") || key.Contains("eyebrow03")
                         || key.Contains("eyeball") || key.Contains("eye Rotation"))
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

                yield return 0; // save files in next frame

                SaveTex2File("face_" + i);
                SavePart2Json("face_" + i);
            }
            else
            {
                RandomizedByPart();

                yield return 0; // save files in next frame

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

    private void Start()
    {
        var characterLoader = GetComponent<UECharacterLoader>();

        characterLoader.InitializeEditModeCharacter();
        characterLoader.MakeupSystem.SetTextureState("eyebrow", m_currentEyeBrow);
    }
}
