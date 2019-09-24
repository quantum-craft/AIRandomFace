using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UEUtils;

public class UEBlendShapesControl
{
    private List<Dictionary<string, UEBlendShapesUtils.AxisPair[]>> m_blendShapesMapList;
    private List<SkinnedMeshRenderer> m_sMRList;

    public UEBlendShapesControl()
    {
        m_blendShapesMapList = new List<Dictionary<string, UEBlendShapesUtils.AxisPair[]>>();
        m_sMRList = new List<SkinnedMeshRenderer>();
    }

    public void Clear()
    {
        m_blendShapesMapList = new List<Dictionary<string, UEBlendShapesUtils.AxisPair[]>>();
        m_sMRList = new List<SkinnedMeshRenderer>();
    }

    public void ResetAllValue()
    {
        for (int index = 0; index < m_sMRList.Count; index++)
        {
            SkinnedMeshRenderer smr = m_sMRList[index];
            int blendShapeCount = smr.sharedMesh.blendShapeCount;
            for (int blendShapeIndex = 0; blendShapeIndex < blendShapeCount; blendShapeIndex++)
            {
                smr.SetBlendShapeWeight(blendShapeIndex, 0);
            }
        }
    }

    public void AddBlendShapes(SkinnedMeshRenderer smr)
    {
        m_sMRList.Add(smr);
        var blendShapes = UEBlendShapesUtils.ConstructBlendShapes(smr);
        var blendShapesMap = UEBlendShapesUtils.ConstructBlendShapesMap(blendShapes);
        m_blendShapesMapList.Add(blendShapesMap);
    }

    public bool SetValue(UEBlendShapesUtils.Part part, UEBlendShapesUtils.Operation operation, UEBlendShapesUtils.Axis axis, float value)
    {
        string key = UEBlendShapesUtils.BlendShape.ToMapKey(part, operation);
        UEBlendShapesUtils.AxisPair[] axisPair = null;
        SkinnedMeshRenderer smr = null;

        for (int index = 0; index < m_blendShapesMapList.Count; index++)
        {
            if (m_blendShapesMapList[index].ContainsKey(key))
            {
                axisPair = m_blendShapesMapList[index][key];
                smr = m_sMRList[index];

                int addIdx = axisPair[(int)axis].Add;
                int subIdx = axisPair[(int)axis].Sub;

                UEBlendShapesUtils.SetBlendShapeAxisValue(smr, value, addIdx, subIdx);
            }
        }

        if (axisPair == null)
        {
            Debug.LogError("BlendShapesMap doesn't contain key" + key);
            return false;
        }

        return true;
    }

    public float GetValue(UEBlendShapesUtils.Part part, UEBlendShapesUtils.Operation operation, UEBlendShapesUtils.Axis axis)
    {
        string key = UEBlendShapesUtils.BlendShape.ToMapKey(part, operation);
        UEBlendShapesUtils.AxisPair[] axisPair = null;
        SkinnedMeshRenderer smr = null;

        for (int index = 0; index < m_blendShapesMapList.Count; index++)
        {
            if (m_blendShapesMapList[index].ContainsKey(key))
            {
                axisPair = m_blendShapesMapList[index][key];
                smr = m_sMRList[index];
                break;
            }
        }

        if (axisPair == null)
        {
            Debug.LogError("BlendShapesMap doesn't contain key" + key);
            return 0.0f;
        }

        int addIdx = axisPair[(int)axis].Add;
        int subIdx = axisPair[(int)axis].Sub;

        return UEBlendShapesUtils.GetBlendShapeAxisValue(smr, addIdx, subIdx);
    }

    public List<UECharacterCustomData.BlendShapeData> GetBlendShapesDataList()
    {
        List<UECharacterCustomData.BlendShapeData> blendShapesDataList = new List<UECharacterCustomData.BlendShapeData>();
        foreach (var smr in m_sMRList)
        {
            int blendShapeCount = smr.sharedMesh.blendShapeCount;
            UECharacterCustomData.BlendShapeData blendShapesData = new UECharacterCustomData.BlendShapeData
            {
                m_PartName = smr.gameObject.name,
                m_Value = new float[blendShapeCount]
            };
            for (int index = 0; index < blendShapeCount; index++)
            {
                blendShapesData.m_Value[index] = smr.GetBlendShapeWeight(index);
            }
            blendShapesDataList.Add(blendShapesData);
        }

        return blendShapesDataList;
    }

    public void SetBlendShapesDataByList(List<UECharacterCustomData.BlendShapeData> blendShapesDataList)
    {
        foreach (var blendShapesData in blendShapesDataList)
        {
            SkinnedMeshRenderer smr = null;
            foreach (var s in m_sMRList)
            {
                if (s.gameObject.name == blendShapesData.m_PartName)
                {
                    smr = s;
                    break;
                }
            }
            if (smr == null)
            {
                Debug.LogError(blendShapesData.m_PartName + " not in SMR list");
                continue;
            }
            int blendShapeCount = smr.sharedMesh.blendShapeCount;
            for (int index = 0; index < blendShapeCount; index++)
            {
                smr.SetBlendShapeWeight(index, blendShapesData.m_Value[index]);
            }
        }
    }

    public void InGameMode()
    {
        if(m_sMRList.Count <= 0)
        {
            return;
        }

        Transform rootTransform = m_sMRList[0].transform.root;
        Vector3 originalScale = rootTransform.transform.localScale;
        rootTransform.transform.localScale = new Vector3(1.0f, 1.0f, 1.0f);
        
        foreach(var s in m_sMRList)
        {
            var bindposes = s.sharedMesh.bindposes;
            var boneWeights = s.sharedMesh.boneWeights;

            s.sharedMesh.bindposes = null;
            s.sharedMesh.boneWeights = null;

            Mesh bakedMesh = new Mesh();
            s.BakeMesh(bakedMesh);

            bakedMesh.bindposes = bindposes;
            bakedMesh.boneWeights = boneWeights;

            s.sharedMesh.bindposes = bindposes;
            s.sharedMesh.boneWeights = boneWeights;

            s.sharedMesh = bakedMesh;
        }

        rootTransform.transform.localScale = originalScale;
    }
}
