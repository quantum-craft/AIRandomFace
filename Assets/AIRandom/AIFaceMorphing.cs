using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Windows;

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

    private int m_currentEyeBrow = 1;

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

        string path = Application.persistentDataPath + "/AI_Data/" + fileName + ".jpg";
        System.IO.File.WriteAllBytes(path, bytes);
    }

    public void SaveBlendShape2Json(string fileName)
    {
        var data = new BlendShapeData
        {
            ShapeName = fileName,
            Values = new float[m_BlendShapeCount],
            Names = new string[m_BlendShapeCount]
        };

        for (int i = 0; i < m_BlendShapeCount; i++)
        {
            data.Values[i] = m_FaceSMR.GetBlendShapeWeight(i);
            data.Names[i] = m_FaceSMR.sharedMesh.GetBlendShapeName(i).Split('.')[1];
        }

        string jsonData = JsonUtility.ToJson(data, true);

        string path = Application.persistentDataPath + "/AI_Data/" + fileName + ".json";

        var bytes = System.Text.Encoding.UTF8.GetBytes(jsonData);
        File.WriteAllBytes(path, bytes);
    }

    public void RandomizedBlendShape()
    {
        ResetBlendShape();

        int randomCount = rnd.Next(0, m_BlendShapeCount + 1);

        for (int i = 0; i < randomCount; i++)
        {
            int r = rnd.Next(m_BlendShapeCount);
            int v = rnd.Next(0, 101);

            var name = m_FaceSMR.sharedMesh.GetBlendShapeName(r).Split('.')[1];

            if (name.Contains("tone"))
            {
                i = i - 1;
                continue;
            }

            m_FaceSMR.SetBlendShapeWeight(r, v);
        }
    }

    private IEnumerator recording(int count)
    {
        for (int i = 0; i < count; i++)
        {
            if (i == 0)
            {
                ResetBlendShape();

                yield return 0; // save files in next frame

                SaveTex2File("face_" + i);
                SaveBlendShape2Json("face_" + i);
            }
            else
            {
                RandomizedBlendShape();

                yield return 0; // save files in next frame

                SaveTex2File("face_" + i);
                SaveBlendShape2Json("face_" + i);
            }
        }
    }

    public void StartRecording(int count)
    {
        StartCoroutine(recording(count));
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
