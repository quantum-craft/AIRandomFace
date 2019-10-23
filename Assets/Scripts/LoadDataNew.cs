using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
using UEUtils;


public class LoadDataNew : MonoBehaviour
{
    string m_LoadFolderName = "AI_Data_Load";
    public SkinnedMeshRenderer smr;
    AIFaceMorphing morphing;
    UECharacterLoader characterLoader;
    private void Start()
    {
        characterLoader = smr.gameObject.GetComponent<UECharacterLoader>();
        morphing = smr.gameObject.GetComponent<AIFaceMorphing>();
    }

    void LoadJson2PartNew(string fileName)
    {
        string filePath = Application.persistentDataPath + "/" + m_LoadFolderName + "/" + fileName + ".json";
        //Debug.Log(filePath);
        if (File.Exists(filePath))
        {
            var bytes = File.ReadAllBytes(filePath);
            string dataAsJson = System.Text.Encoding.UTF8.GetString(bytes);
            var data = JsonUtility.FromJson<BlendShapeData>(dataAsJson);

            if (data.Names.Length != data.Values.Length)
            {
                Debug.Log("format wrong");
                return;
            }

            morphing.ResetBlendShape();

            for (int i = 0; i < data.Names.Length; i++)
            {
                if (data.Names[i] == "eyeiris Color")
                {
                    morphing.SetIrisColor((int)data.Values[i] - 1); // 1 based index
                    continue;
                }

                if (data.Names[i] == "faceskin Color")
                {
                    morphing.SetFaceSkinColor((int)data.Values[i] - 1); // 1 based index
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
            }
        }
    }

    public void ConvertJsonToImg()
    {
        StartCoroutine(DoConvertJsonToImg());
    }

    IEnumerator DoConvertJsonToImg()
    {
        var files = Directory.GetFiles(Application.persistentDataPath + "/" + m_LoadFolderName);
        foreach (var file in files)
        {
            var words = file.Split('\\');
            var filename = words[words.Length - 1];
            if (filename.Contains("json"))
            {
                filename = filename.Substring(0, filename.Length - 5);
                Debug.Log(filename);

                LoadJson2PartNew(filename);
                yield return new WaitForSeconds(0.05f);

                morphing.SaveTex2File(filename);
                // yield return new WaitForSeconds(0.05f);
            }
        }
    }
}
