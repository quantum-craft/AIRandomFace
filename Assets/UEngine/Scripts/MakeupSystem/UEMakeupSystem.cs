using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using System.Linq;

public class UEMakeupSystem
{
    private UEMakeupTextureSystem m_textureBackupSystem;
    private UEMakeupTextureSystem m_currentTexture;
    private UECharacterMakeupState m_makeupState;
    private UECharacterMakeupState m_originalState;
    private UECharacterData.MaterialData[] m_materialDataList;
    private Dictionary<string, List<SkinnedMeshRenderer>> m_bodyPartsSMRDict;
    private Dictionary<string, List<string>> m_dirtyStateDict;
    private GameObject m_character;

    public UEMakeupSystem()
    {
        m_textureBackupSystem = new UEMakeupTextureSystem();
        m_makeupState = new UECharacterMakeupState();
        m_originalState = new UECharacterMakeupState();
        m_currentTexture = new UEMakeupTextureSystem();
        m_bodyPartsSMRDict = new Dictionary<string, List<SkinnedMeshRenderer>>();
        m_dirtyStateDict = new Dictionary<string, List<string>>();
    }

    public void SetCharacter(GameObject character, UECharacterData characterData)
    {
        m_materialDataList = characterData.m_MakeupDataList;
        m_character = character;
        foreach (var makeupData in characterData.m_MakeupDataList)
        {
            var SMRs = GetSMRsByPartName(makeupData.m_BodyPartName);
            if (SMRs.Count == 0)
            {
                Debug.LogWarning("No object name contains \"" + makeupData.m_BodyPartName + "\" with SkinnedMeshRenderer was found");
            }


            if (makeupData.m_ReplaceTextureName.Length > 0)
            {
                foreach (var smr in SMRs)
                {
                    if (makeupData.m_MaterialIndex >= smr.materials.Length)
                    {
                        Debug.LogWarning("Material index out of range at " + makeupData.m_TypeName);
                        continue;
                    }
                    Material material = smr.materials[makeupData.m_MaterialIndex];
                    Texture texture = material.GetTexture(makeupData.m_ReplaceTextureName);
                    Debug.Assert(texture, makeupData.m_ReplaceTextureName + " does not exist in material" + makeupData.m_MaterialIndex);
                    m_textureBackupSystem.SetTexture(smr.name, makeupData.m_MaterialIndex, makeupData.m_ReplaceTextureName, texture);
                }
            }
        }
    }

    private List<SkinnedMeshRenderer> GetSMRsByPartName(string partName)
    {
        if (m_bodyPartsSMRDict.ContainsKey(partName))
        {
            return m_bodyPartsSMRDict[partName];
        }

        List<SkinnedMeshRenderer> SMRList = new List<SkinnedMeshRenderer>();

        var SMRs = m_character.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var smr in SMRs)
        {
            if (smr.name.Contains(partName))
            {
                SMRList.Add(smr);
            }
        }

        m_bodyPartsSMRDict.Add(partName, SMRList);
        return SMRList;
    }

    public int GetTextureCount(string name)
    {
        var material = GetMaterialData(name);

        if (material == null)
        {
            return -1;
        }

        return GetTextureCount(material);
    }

    public string SetTextureState(string name, int textureIndex)
    {
        var textureName = "";

        var material = GetMaterialData(name);
        var state = m_makeupState.GetState(name);
        int originalIndex = int.MaxValue;
        if (state != null)
        {
            originalIndex = state.m_TextureIndex;
        }
        if (textureIndex < 0)
        {
            m_makeupState.Remove(name);
        }
        else
        {
            var texture = GetTextureData(material, textureIndex);
            state = m_makeupState.SetState(name, textureIndex);

            textureName = texture.name;
        }

        if (originalIndex != textureIndex)
        {
            SetStateDirty(name, null);
        }

        return textureName;
    }

    public void ClearTextureState(string name)
    {
        var state = m_makeupState.GetState(name);
        if (state != null)
        {
            SetStateDirty(state.m_MakeupName, null);
            m_makeupState.Remove(name);
        }
    }

    public void SetTextureState(string name, EShaderFloatParameter parameter, float value)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        SetTextureState(name, paramInfo.m_Name, value);
    }

    public void SetTextureState(string name, EShaderColorParameter parameter, Color value)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        SetTextureState(name, paramInfo.m_Name, value);
    }

    public void SetTextureState(string name, EShaderVectorParameter parameter, Vector4 value)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        SetTextureState(name, paramInfo.m_Name, value);
    }

    public void SetTextureState(string name, EShaderIntParameter parameter, int value)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        SetTextureState(name, paramInfo.m_Name, value);
    }

    public void ClearTextureStateFloat(string name, EShaderFloatParameter parameter)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        ClearTextureState(name, paramInfo.m_Name);
    }
    public void ClearTextureStateColor(string name, EShaderColorParameter parameter)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        ClearTextureState(name, paramInfo.m_Name);
    }
    public void ClearTextureStateVector(string name, EShaderVectorParameter parameter)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        ClearTextureState(name, paramInfo.m_Name);
    }
    public void ClearTextureStateInt(string name, EShaderIntParameter parameter)
    {
        var paramInfo = UEShaderParamUtil.GetShaderParameterInfo(parameter);
        ClearTextureState(name, paramInfo.m_Name);
    }

    public void SetTextureState(string name, string paramName, float value)
    {
        var state = m_makeupState.GetState(name);
        float originalValue = float.NaN;
        if (state != null && state.m_ParameterList.ContainsKey(paramName))
        {
            originalValue = (float)state.m_ParameterList[paramName].m_Value;

        }
        if (originalValue != value)
        {
            m_makeupState.SetState(name, paramName, value);
            SetStateDirty(state.m_MakeupName, paramName);
        }
    }

    public void SetTextureState(string name, string paramName, Color value)
    {
        var state = m_makeupState.GetState(name);
        Color originalValue = new Color(float.NaN, float.NaN, float.NaN);
        if (state != null && state.m_ParameterList.ContainsKey(paramName))
        {
            originalValue = (Color)state.m_ParameterList[paramName].m_Value;

        }
        if (originalValue != value)
        {
            m_makeupState.SetState(name, paramName, value);
            SetStateDirty(state.m_MakeupName, paramName);
        }
    }

    public void SetTextureState(string name, string paramName, Vector4 value)
    {
        var state = m_makeupState.GetState(name);
        Vector4 originalValue = new Vector4(float.NaN, float.NaN);
        if (state != null && state.m_ParameterList.ContainsKey(paramName))
        {
            originalValue = (Vector4)state.m_ParameterList[paramName].m_Value;

        }
        if (originalValue != value)
        {
            m_makeupState.SetState(name, paramName, value);
            SetStateDirty(state.m_MakeupName, paramName);
        }
    }

    public void SetTextureState(string name, string paramName, int value)
    {
        var state = m_makeupState.GetState(name);
        int originalValue = int.MaxValue;
        if (state != null && state.m_ParameterList.ContainsKey(paramName))
        {
            originalValue = (int)state.m_ParameterList[paramName].m_Value;

        }
        if (originalValue != value)
        {
            m_makeupState.SetState(name, paramName, value);
            SetStateDirty(state.m_MakeupName, paramName);
        }
    }

    public void ClearTextureState(string name, string paramName)
    {
        var state = m_makeupState.GetState(name);
        if (state != null)
        {
            SetStateDirty(state.m_MakeupName, paramName);
            m_makeupState.RemoveState(name, paramName);
        }
    }

    [System.Obsolete("Use ClearTextureState instead")]
    public void ClearTextureStateFloat(string name, string paramName)
    {
        GetMaterialData(name);
        m_makeupState.RemoveFloatState(name, paramName);
    }
    [System.Obsolete("Use ClearTextureState instead")]
    public void ClearTextureStateColor(string name, string paramName)
    {
        GetMaterialData(name);
        m_makeupState.RemoveColorState(name, paramName);
    }
    [System.Obsolete("Use ClearTextureState instead")]
    public void ClearTextureStateVector(string name, string paramName)
    {
        GetMaterialData(name);
        m_makeupState.RemoveVectorState(name, paramName);
    }
    [System.Obsolete("Use ClearTextureState instead")]
    public void ClearTextureStateInt(string name, string paramName)
    {
        GetMaterialData(name);
        m_makeupState.RemoveIntState(name, paramName);
    }

    private void SetStateDirty(string makeupName, string paramName)
    {
        if (!m_dirtyStateDict.ContainsKey(makeupName))
        {
            m_dirtyStateDict.Add(makeupName, new List<string>());
        }
        if (!m_dirtyStateDict[makeupName].Contains(paramName))
        {
            m_dirtyStateDict[makeupName].Add(paramName);
        }
    }

    public void SetStateClear(string makeupName, string paramName)
    {
        if (m_dirtyStateDict.ContainsKey(makeupName))
        {
            if (m_dirtyStateDict[makeupName].Contains(paramName))
            {
                m_dirtyStateDict[makeupName].Remove(paramName);
            }
        }
    }

    public void ApplyTexture()
    {
        foreach (var dirtyState in m_dirtyStateDict)
        {
            if (dirtyState.Value.Count > 0)
            {
                ApplyTexture(dirtyState.Key);
            }
        }
        m_dirtyStateDict.Clear();
    }

    private void ApplyTexture(string name)
    {
        var material = GetMaterialData(name);
        if (material == null)
        {
            return;
        }
        if (material.m_Mode == UECharacterData.MaterialMode.Blend)
        {
            UpdateTexture(material);
        }
        else if (material.m_Mode == UECharacterData.MaterialMode.Normal)
        {
            UpdateMaterialParameter(material);
        }
    }

    private void UpdateTexture(UECharacterData.MaterialData material)
    {
        var SMRs = GetSMRsByPartName(material.m_BodyPartName);

        foreach (var smr in SMRs)
        {
            if (material.m_MaterialIndex >= smr.materials.Length) { continue; }

            // TODO: by mao song liang
            if (smr.name.EndsWith("_lod2"))
                continue;

            Material dstMaterial = smr.materials[material.m_MaterialIndex];

            Texture sourceTexture = m_textureBackupSystem.GetTexture(smr.name, material.m_MaterialIndex, material.m_ReplaceTextureName);
            RenderTexture destinationTexture = new RenderTexture(sourceTexture.width, sourceTexture.height, 0, RenderTextureFormat.ARGB32);

            var renderList = new UECharacterData.BlendBlitList(
                m_materialDataList.Where(m => m.Hash == material.Hash),
                m_makeupState);

            renderList.Update(m_originalState, smr, this);

            renderList.Render(sourceTexture, ref destinationTexture);

            renderList.PostUpdate(dstMaterial, m_originalState, smr, this);

            RenderTexture previousRT = (RenderTexture)m_currentTexture.GetTexture(smr.name, material.m_MaterialIndex, material.m_ReplaceTextureName);
            if (previousRT)
            {
                previousRT.Release();
                GameObject.Destroy(previousRT);
            }

            if (destinationTexture)
            {
                m_currentTexture.SetTexture(smr.name, material.m_MaterialIndex, material.m_ReplaceTextureName, destinationTexture);
                dstMaterial.SetTexture(material.m_ReplaceTextureName, destinationTexture);
            }
            else if (material.m_ReplaceTextureName.Length > 0)
            {
                m_currentTexture.SetTexture(smr.name, material.m_MaterialIndex, material.m_ReplaceTextureName, null);
                SetStateClear(material.m_TypeName, null);
                dstMaterial.SetTexture(material.m_ReplaceTextureName, sourceTexture);
            }
        }
    }

    private void UpdateMaterialParameter(UECharacterData.MaterialData material)
    {
        var SMRs = GetSMRsByPartName(material.m_BodyPartName);
        foreach (var smr in SMRs)
        {
            if (material.m_MaterialIndex >= smr.materials.Length)
            {
                continue;
            }
            var state = m_makeupState.GetState(material.m_TypeName);
            string originalStateName = material.m_TypeName + smr.name;
            var originalState = m_originalState.GetState(originalStateName);
            Material dstMaterial = smr.materials[material.m_MaterialIndex];

            Texture originalTexture = null;
            if (material.m_ReplaceTextureName.Length > 0)
            {
                originalTexture = m_textureBackupSystem.GetTexture(material.m_BodyPartName, material.m_MaterialIndex, material.m_ReplaceTextureName);

            }
            if (state == null)
            {
                if (originalState == null)
                {
                    if (originalTexture != null)
                    {
                        SetStateClear(material.m_TypeName, null);
                        dstMaterial.SetTexture(material.m_ReplaceTextureName, originalTexture);
                    }
                    return;
                }
                else
                {
                    state = new MakeupData();
                }
            }
            if (originalState == null)
            {
                m_originalState.SetState(originalStateName, -1);
                originalState = m_originalState.GetState(originalStateName);
            }

            if (state.m_TextureIndex >= 0)
            {
                if (material.m_SpriteAtlas != null && state.m_TextureIndex < material.m_SpriteAtlas.spriteCount)
                {
                    Sprite[] sprites = new Sprite[material.m_SpriteAtlas.spriteCount];
                    material.m_SpriteAtlas.GetSprites(sprites);

                    dstMaterial.SetTexture(material.m_ReplaceTextureName, sprites[state.m_TextureIndex].texture);
                    foreach (var sprite in sprites)
                    {
                        GameObject.Destroy(sprite);
                    }
                }
                else if (state.m_TextureIndex < material.m_TextureData.Length)
                {
                    SetStateClear(state.m_MakeupName, null);
                    dstMaterial.SetTexture(material.m_ReplaceTextureName, material.m_TextureData[state.m_TextureIndex]);
                }
            }
            else if (originalTexture != null)
            {
                SetStateClear(state.m_MakeupName, null);
                dstMaterial.SetTexture(material.m_ReplaceTextureName, originalTexture);
            }

            UpdateMaterialParameter(dstMaterial, state, originalState);
            if (originalState.IsEmpty())
            {
                m_originalState.Remove(originalStateName);
            }
        }
    }

    private void SetMaterialParameterValue(Material dstMaterial, string paramName, MaterialParameterType type, object value)
    {
        switch (type)
        {
            case MaterialParameterType.Float:
                dstMaterial.SetFloat(paramName, (float)value);
                break;
            case MaterialParameterType.Color:
                dstMaterial.SetColor(paramName, (Color)value);
                break;
            case MaterialParameterType.Vector:
                dstMaterial.SetVector(paramName, (Vector4)value);
                break;
            case MaterialParameterType.Int:
                dstMaterial.SetInt(paramName, (int)value);
                break;
        }
    }

    private object GetMaterialParameterValue(Material material, string paramName, MaterialParameterType type)
    {
        switch (type)
        {
            case MaterialParameterType.Float:
                return material.GetFloat(paramName);
            case MaterialParameterType.Color:
                return material.GetColor(paramName);
            case MaterialParameterType.Vector:
                return material.GetVector(paramName);
            case MaterialParameterType.Int:
                return material.GetInt(paramName);
            default:
                return null;
        }
    }

    public void UpdateMaterialParameter(Material dstMaterial, MakeupData state, MakeupData originalState, bool materialBatched = false)
    {
        List<string> itemsToRemove = new List<string>();

        foreach (var pair in originalState.m_ParameterList)
        {
            var key = materialBatched ? pair.Key + "_" + state.m_MakeupName : pair.Key;
            if (state.m_ParameterList.ContainsKey(pair.Key))
            {
                continue;
            }
            if (!dstMaterial.HasProperty(key))
            {
                continue;
            }
            SetStateClear(state.m_MakeupName, pair.Key);
            SetMaterialParameterValue(dstMaterial, key, pair.Value.m_Type, pair.Value.m_Value);
            itemsToRemove.Add(pair.Key);
        }
        foreach (var key in itemsToRemove)
        {
            originalState.m_ParameterList.Remove(key);
        }
        itemsToRemove.Clear();

        foreach (var pair in state.m_ParameterList)
        {
            var key = materialBatched ? pair.Key + "_" + state.m_MakeupName : pair.Key;
            if (!dstMaterial.HasProperty(key))
            {
                continue;
            }
            if (!originalState.m_ParameterList.ContainsKey(pair.Key))
            {
                var originalValue = GetMaterialParameterValue(dstMaterial, key, pair.Value.m_Type);
                originalState.m_ParameterList.Add(pair.Key, new MaterialParameter
                {
                    m_Type = pair.Value.m_Type,
                    m_Value = originalValue
                });
            }
            SetStateClear(state.m_MakeupName, pair.Key);
            SetMaterialParameterValue(dstMaterial, key, pair.Value.m_Type, pair.Value.m_Value);
        }
    }

    private UECharacterData.MaterialData GetMaterialData(string name)
    {
        foreach (var material in m_materialDataList)
        {
            if (material.m_TypeName == name)
            {
                return material;
            }
        }
        Debug.Assert(false, name + " is not in makeup data list");
        return null;
    }

    private static Texture GetTextureData(UECharacterData.MaterialData material, int textureIndex)
    {
        if (material.m_SpriteAtlas != null)
        {
            Debug.Assert(textureIndex < material.m_SpriteAtlas.spriteCount, "Texture index out of SpriteAtlas range");

            Sprite[] sprites = new Sprite[material.m_SpriteAtlas.spriteCount];
            material.m_SpriteAtlas.GetSprites(sprites);
            foreach (var sprite in sprites)
            {
                GameObject.Destroy(sprite);
            }
            return sprites[textureIndex].texture;
        }
        else
        {
            Debug.Assert(textureIndex < material.m_TextureData.Length, "Texture index out of range");
            return material.m_TextureData[textureIndex];
        }
    }

    private static int GetTextureCount(UECharacterData.MaterialData material)
    {
        if (material.m_SpriteAtlas != null)
        {
            return material.m_SpriteAtlas.spriteCount;
        }
        else
        {
            return material.m_TextureData.Length;
        }
    }

    public List<UECharacterCustomData.MakeupData> GetMakeupDataList()
    {
        List<UECharacterCustomData.MakeupData> outputDataList = new List<UECharacterCustomData.MakeupData>();
        var dataList = m_makeupState.GetMakeupDataList();
        foreach (var mPair in dataList)
        {
            var makeupData = mPair.Value;
            UECharacterCustomData.MakeupData outputData = new UECharacterCustomData.MakeupData()
            {
                m_MakeupName = makeupData.m_MakeupName,
                m_TextureIndex = makeupData.m_TextureIndex,
                m_ColorParameterList = new List<UECharacterCustomData.ColorParameter>(),
                m_FloatParameterList = new List<UECharacterCustomData.FloatParameter>(),
                m_VectorParameterList = new List<UECharacterCustomData.VectorParameter>(),
                m_IntParameterList = new List<UECharacterCustomData.IntParameter>()
            };

            foreach (var pair in makeupData.m_ParameterList)
            {
                switch (pair.Value.m_Type)
                {
                    case MaterialParameterType.Float:
                        UECharacterCustomData.FloatParameter floatParam = new UECharacterCustomData.FloatParameter()
                        {
                            m_Name = pair.Key,
                            m_Value = (float)pair.Value.m_Value
                        };
                        outputData.m_FloatParameterList.Add(floatParam);
                        break;
                    case MaterialParameterType.Color:
                        UECharacterCustomData.ColorParameter colorParam = new UECharacterCustomData.ColorParameter()
                        {
                            m_Name = pair.Key,
                            m_Value = (Color)pair.Value.m_Value
                        };
                        outputData.m_ColorParameterList.Add(colorParam);
                        break;
                    case MaterialParameterType.Vector:
                        UECharacterCustomData.VectorParameter vectorParam = new UECharacterCustomData.VectorParameter()
                        {
                            m_Name = pair.Key,
                            m_Value = (Vector4)pair.Value.m_Value
                        };
                        outputData.m_VectorParameterList.Add(vectorParam);
                        break;
                    case MaterialParameterType.Int:
                        UECharacterCustomData.IntParameter intParam = new UECharacterCustomData.IntParameter()
                        {
                            m_Name = pair.Key,
                            m_Value = (int)pair.Value.m_Value
                        };
                        outputData.m_IntParameterList.Add(intParam);
                        break;
                }
            }
            outputDataList.Add(outputData);
        }
        return outputDataList;
    }

    public void SetMakeupData(List<UECharacterCustomData.MakeupData> makeupDataList)
    {
        foreach (var makeupData in makeupDataList)
        {
            var material = GetMaterialData(makeupData.m_MakeupName);
            SetTextureState(makeupData.m_MakeupName, makeupData.m_TextureIndex);
            foreach (var param in makeupData.m_ColorParameterList)
            {
                SetTextureState(makeupData.m_MakeupName, param.m_Name, param.m_Value);
            }
            foreach (var param in makeupData.m_FloatParameterList)
            {
                SetTextureState(makeupData.m_MakeupName, param.m_Name, param.m_Value);
            }
            foreach (var param in makeupData.m_VectorParameterList)
            {
                SetTextureState(makeupData.m_MakeupName, param.m_Name, param.m_Value);
            }
            foreach (var param in makeupData.m_IntParameterList)
            {
                SetTextureState(makeupData.m_MakeupName, param.m_Name, param.m_Value);
            }
        }
        ApplyTexture();
    }

    private void CopyUsedTextures()
    {
        foreach (var material in m_materialDataList)
        {

            if (material.m_Mode != UECharacterData.MaterialMode.Normal)
            {
                continue;
            }
            var state = m_makeupState.GetState(material.m_TypeName);

            if (state == null || state.m_TextureIndex < 0)
            {
                continue;
            }

            var SMRs = GetSMRsByPartName(material.m_BodyPartName);
            Texture2D newTexture = null;

            if (material.m_SpriteAtlas != null && state.m_TextureIndex < material.m_SpriteAtlas.spriteCount)
            {

                Sprite[] sprites = new Sprite[material.m_SpriteAtlas.spriteCount];
                material.m_SpriteAtlas.GetSprites(sprites);
                Texture2D texture = sprites[state.m_TextureIndex].texture;
                bool useMipmap = false;
                if (texture.mipmapCount > 1)
                {
                    useMipmap = true;
                }
                newTexture = new Texture2D(texture.width, texture.height, texture.format, useMipmap);
                Graphics.CopyTexture(texture, newTexture);
                foreach (var sprite in sprites)
                {
                    GameObject.Destroy(sprite);
                }

            }
            else if (state.m_TextureIndex < material.m_TextureData.Length)
            {
                Texture2D texture = (Texture2D)material.m_TextureData[state.m_TextureIndex];

                bool useMipmap = false;
                if (texture.mipmapCount > 1)
                {
                    useMipmap = true;
                }
                newTexture = new Texture2D(texture.width, texture.height, texture.format, useMipmap);
                Graphics.CopyTexture(texture, newTexture);
            }


            foreach (var smr in SMRs)
            {
                if (material.m_MaterialIndex < smr.materials.Length)
                {
                    Material dstMaterial = smr.materials[material.m_MaterialIndex];
                    m_currentTexture.SetTexture(smr.name, material.m_MaterialIndex, material.m_ReplaceTextureName, newTexture);
                    dstMaterial.SetTexture(material.m_ReplaceTextureName, newTexture);
                }
            }
        }
    }

    public enum MaterialParameterType
    {
        None, Float, Color, Vector, Int
    }

    public struct MaterialParameter
    {
        public MaterialParameterType m_Type;
        public object m_Value;
    }

    public class MakeupData
    {
        public string m_MakeupName;
        public int m_TextureIndex;

        public Dictionary<string, MaterialParameter> m_ParameterList;

        public MakeupData()
        {
            m_TextureIndex = -1;
            m_ParameterList = new Dictionary<string, MaterialParameter>();
        }

        public bool IsEmpty()
        {
            return m_ParameterList.Count == 0 && m_TextureIndex < 0;
        }
    }

    public struct MakeupTextureInfo
    {
        public string m_PartName;
        public int m_MaterialIndex;
        public string m_TextureName;
        public Texture m_texture;
    }

    public List<MakeupTextureInfo> GetMakeupTextureInfos()
    {
        return m_currentTexture.GetTextureList();
    }

    public List<string> GetMakeupNameList()
    {
        List<string> makeupNameList = new List<string>();
        foreach (var makeupData in m_materialDataList)
        {
            makeupNameList.Add(makeupData.m_TypeName);
        }
        return makeupNameList;
    }

    public void Reset()
    {
        if (m_textureBackupSystem != null)
        {
            m_textureBackupSystem.Clear();
        }
        if (m_makeupState != null)
        {
            m_makeupState.Reset();
        }
        if (m_originalState != null)
        {
            m_originalState.Reset();
        }
        if (m_currentTexture != null)
        {
            m_currentTexture.Release();
            m_currentTexture.Clear();
        }
        if (m_bodyPartsSMRDict != null)
        {
            m_bodyPartsSMRDict.Clear();
        }
        if (m_dirtyStateDict != null)
        {
            m_dirtyStateDict.Clear();
        }
    }

    public void ResetState()
    {
        m_makeupState.Reset();
        m_originalState.Reset();
        m_currentTexture.Release();
        m_currentTexture.Clear();
        m_dirtyStateDict.Clear();
    }

    public void InGameMode()
    {
        CopyUsedTextures();
        m_textureBackupSystem = null;
        m_makeupState = null;
        m_originalState = null;
        m_bodyPartsSMRDict = null;
        m_dirtyStateDict = null;
    }

    // Game logic requires material mode
    public int GetMaterialMode(string name)
    {
        if (m_materialDataList == null) { return -1; }

        var mats = from mat in m_materialDataList
                   where mat.m_TypeName == name
                   select mat;

        foreach (var mat in mats) { return (int)mat.m_Mode; }

        return -1;
    }
}

class UEMakeupTextureSystem
{
    Dictionary<string, Dictionary<int, Dictionary<string, Texture>>> m_textureList;

    public UEMakeupTextureSystem()
    {
        m_textureList = new Dictionary<string, Dictionary<int, Dictionary<string, Texture>>>();
    }

    public bool Contains(string partName, int materialIndex, string textureName)
    {
        if (!m_textureList.ContainsKey(partName))
        {
            return false;
        }
        var partDict = m_textureList[partName];
        if (!partDict.ContainsKey(materialIndex))
        {
            return false;
        }
        var materialDict = partDict[materialIndex];
        return materialDict.ContainsKey(textureName);
    }

    public void SetTexture(string partName, int materialIndex, string textureName, Texture texture)
    {
        if (!m_textureList.ContainsKey(partName))
        {
            m_textureList.Add(partName, new Dictionary<int, Dictionary<string, Texture>>());
        }
        var partDict = m_textureList[partName];
        if (!partDict.ContainsKey(materialIndex))
        {
            partDict.Add(materialIndex, new Dictionary<string, Texture>());
        }
        var materialDict = partDict[materialIndex];
        if (!materialDict.ContainsKey(textureName))
        {
            materialDict.Add(textureName, texture);
        }
        else
        {
            materialDict[textureName] = texture;
        }
    }

    public Texture GetTexture(string partName, int materialIndex, string textureName)
    {
        if (!Contains(partName, materialIndex, textureName))
        {
            return null;
        }
        return m_textureList[partName][materialIndex][textureName];
    }

    public void Clear()
    {
        m_textureList = new Dictionary<string, Dictionary<int, Dictionary<string, Texture>>>();
    }

    public void Release()
    {
        foreach (var i in m_textureList)
        {
            foreach (var j in m_textureList[i.Key])
            {
                foreach (var k in m_textureList[i.Key][j.Key])
                {
                    if (k.Value != null)
                    {
                        RenderTexture renderTexture = (RenderTexture)k.Value;
                        renderTexture.Release();
                    }
                }
            }
        }
    }

    public List<UEMakeupSystem.MakeupTextureInfo> GetTextureList()
    {
        List<UEMakeupSystem.MakeupTextureInfo> textureInfoList = new List<UEMakeupSystem.MakeupTextureInfo>();
        foreach (var i in m_textureList)
        {
            foreach (var j in m_textureList[i.Key])
            {
                foreach (var k in m_textureList[i.Key][j.Key])
                {
                    UEMakeupSystem.MakeupTextureInfo textureInfo = new UEMakeupSystem.MakeupTextureInfo
                    {
                        m_PartName = i.Key,
                        m_MaterialIndex = j.Key,
                        m_TextureName = k.Key,
                        m_texture = k.Value
                    };
                    textureInfoList.Add(textureInfo);
                }
            }
        }
        return textureInfoList;
    }
}

public class UECharacterMakeupState
{
    private Dictionary<string, UEMakeupSystem.MakeupData> m_makeupStates;
    public UECharacterMakeupState()
    {
        m_makeupStates = new Dictionary<string, UEMakeupSystem.MakeupData>();
    }

    public UEMakeupSystem.MakeupData GetStateOrDefault(string name)
    {
        var originalState = GetState(name);

        if (originalState == null)
        {
            SetState(name, -1);
            originalState = GetState(name);
        }

        return originalState;
    }

    public UEMakeupSystem.MakeupData GetState(string name)
    {
        if (m_makeupStates.ContainsKey(name))
        {
            return m_makeupStates[name];
        }
        return null;
    }

    public void Remove(string name)
    {
        if (m_makeupStates.ContainsKey(name))
        {
            m_makeupStates.Remove(name);
        }
    }

    public UEMakeupSystem.MakeupData SetState(string name, int index)
    {
        var state = GetState(name);
        if (state != null)
        {
            state.m_TextureIndex = index;
        }
        else
        {
            state = new UEMakeupSystem.MakeupData
            {
                m_MakeupName = name,
                m_TextureIndex = index
            };
            m_makeupStates.Add(name, state);
        }
        return state;
    }

    public UEMakeupSystem.MakeupData SetState(string name, string paramName, float value)
    {
        var state = GetState(name);
        if (state == null)
        {
            state = new UEMakeupSystem.MakeupData()
            {
                m_MakeupName = name
            };
            m_makeupStates.Add(name, state);
        }
        state.m_ParameterList[paramName] = new UEMakeupSystem.MaterialParameter
        {
            m_Type = UEMakeupSystem.MaterialParameterType.Float,
            m_Value = value
        };
        return state;
    }

    public UEMakeupSystem.MakeupData SetState(string name, string paramName, Color value)
    {
        var state = GetState(name);
        if (state == null)
        {
            state = new UEMakeupSystem.MakeupData()
            {
                m_MakeupName = name
            };
            m_makeupStates.Add(name, state);
        }
        state.m_ParameterList[paramName] = new UEMakeupSystem.MaterialParameter
        {
            m_Type = UEMakeupSystem.MaterialParameterType.Color,
            m_Value = value
        };
        return state;
    }

    public UEMakeupSystem.MakeupData SetState(string name, string paramName, Vector4 value)
    {
        var state = GetState(name);
        if (state == null)
        {
            state = new UEMakeupSystem.MakeupData()
            {
                m_MakeupName = name
            };
            m_makeupStates.Add(name, state);
        }
        state.m_ParameterList[paramName] = new UEMakeupSystem.MaterialParameter
        {
            m_Type = UEMakeupSystem.MaterialParameterType.Vector,
            m_Value = value
        };
        return state;
    }

    public UEMakeupSystem.MakeupData SetState(string name, string paramName, int value)
    {
        var state = GetState(name);
        if (state == null)
        {
            state = new UEMakeupSystem.MakeupData()
            {
                m_MakeupName = name
            };
            m_makeupStates.Add(name, state);
        }
        state.m_ParameterList[paramName] = new UEMakeupSystem.MaterialParameter
        {
            m_Type = UEMakeupSystem.MaterialParameterType.Int,
            m_Value = value
        };
        return state;
    }

    public void RemoveState(string name, string paramName)
    {
        var state = GetState(name);
        if (state != null)
        {
            if (state.m_ParameterList.ContainsKey(paramName))
            {
                state.m_ParameterList.Remove(paramName);
            }
        }
    }

    public void RemoveFloatState(string name, string paramName)
    {
        RemoveState(name, paramName);
    }

    public void RemoveColorState(string name, string paramName)
    {
        RemoveState(name, paramName);
    }

    public void RemoveVectorState(string name, string paramName)
    {
        RemoveState(name, paramName);
    }

    public void RemoveIntState(string name, string paramName)
    {
        RemoveState(name, paramName);
    }

    public Dictionary<string, UEMakeupSystem.MakeupData> GetMakeupDataList()
    {
        return m_makeupStates;
    }

    public void Reset()
    {
        m_makeupStates = new Dictionary<string, UEMakeupSystem.MakeupData>();
    }
}
