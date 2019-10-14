using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class Segmentation_data : MonoBehaviour
{

    public Material matOrigin,
        matFace,
        matUMouth,
        matLMouth,
        matNose,
        matEye,
        matLBrow,
        matRBrow;
    public SkinnedMeshRenderer smr;
    public Material eyeOrigin,yellowEye, blueEye;
    public AIFaceMorphing aiMorphing;

    //public void TrySaveSegmentationData(string filename)
    //{
    //    StartCoroutine(SaveSegmentationData(filename));
    //}

    public void BulkSegmentationData(int total)
    {
        StartCoroutine(BulkSaveSegmentationData(total));
    }

    IEnumerator BulkSaveSegmentationData(int total)
    {
        int count = 0;
        var tempMaterials = smr.materials;
        while (count < total)
        {
            aiMorphing.RandomizedByPart();
            aiMorphing.SavePart2Json(count.ToString("D5"));
            yield return null;
            smr.materials = new Material[] { matOrigin, eyeOrigin, tempMaterials[2] };
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5")+"_origin");
            smr.materials = new Material[] { matUMouth, yellowEye, tempMaterials[2] };
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_umouth");
            smr.material = matLMouth;
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_lmouth");
            smr.material = matNose;
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_nose");
            smr.material = matLBrow;
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_lbrow");
            smr.material = matRBrow;
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_rbrow");
            smr.materials = new Material[] { matEye, blueEye, tempMaterials[2] };
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_eye");
            smr.material = matFace;
            yield return null;
            aiMorphing.SaveTex2File(count.ToString("D5") + "_face");
            count++;
        }
    }

    //IEnumerator SaveSegmentationData(string filename)
    //{
    //    var tempMaterials = smr.materials;
    //    smr.materials = new Material[] { matOrigin, eyeOrigin, tempMaterials[2] };
    //    yield return null;
    //    aiMorphing.SaveTex2File("_origin");
    //    smr.materials = new Material[] { matMouth, yellowEye, tempMaterials[2] };
    //    yield return null;
    //    aiMorphing.SaveTex2File(filename + "_mouth");
    //    smr.material = matNose;
    //    yield return null;
    //    aiMorphing.SaveTex2File(filename + "_nose");
    //    //smr.material = matLEye;
    //    smr.materials = new Material[] { matEye, blueEye, tempMaterials[2] };
    //    yield return null;
    //    aiMorphing.SaveTex2File(filename + "_eye");
    //    //smr.material = matLBrow;
    //    smr.materials = new Material[] { matLBrow, yellowEye, tempMaterials[2] };
    //    yield return null;
    //    aiMorphing.SaveTex2File(filename + "_lbrow");
    //    smr.material = matRBrow;
    //    yield return null;
    //    aiMorphing.SaveTex2File(filename + "_rbrow");
    //}
}
