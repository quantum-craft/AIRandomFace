using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.IO;

public class BSSerializerTest : MonoBehaviour
{
    public void SerializeBS()
    {
        var SMR = GetComponent<SkinnedMeshRenderer>();
        var mesh = SMR.sharedMesh;

        var bytes = UEBlendShapeSerializer.GetCompressedBlendshapesData(mesh);

        string path = Application.persistentDataPath + "/bs_compressed.dat";
        System.IO.File.WriteAllBytes(path, bytes);
    }

    public void DeserializeBS()
    {
        string path = Application.persistentDataPath + "/bs_compressed.dat";

        if (File.Exists(path))
        {
            var bytes = File.ReadAllBytes(path);

            var SMR = GetComponent<SkinnedMeshRenderer>();
            var mesh = SMR.sharedMesh;

            mesh.ClearBlendShapes();

            UEBlendShapeSerializer.SetBlendshapesData(mesh, bytes);

            var aiFaceMorph = GetComponent<AIFaceMorphing>();
            aiFaceMorph.InitCharacter();
        }
    }

    public void SaveOriginalJson()
    {
        var SMR = GetComponent<SkinnedMeshRenderer>();

        UEBlendShapeToJson.SaveBlendShapes(SMR);
    }

    public void LoadOriginalJson()
    {
        var SMR = GetComponent<SkinnedMeshRenderer>();

        UEBlendShapeToJson.ClearBlendShapes(SMR);
        UEBlendShapeToJson.LoadBlendShapes(SMR);

        var aiFaceMorph = GetComponent<AIFaceMorphing>();
        aiFaceMorph.InitCharacter();
    }
}
