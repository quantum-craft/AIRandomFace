using System.Collections;
using System.Collections.Generic;
using System.Linq;
using UnityEngine;

[CreateAssetMenu(fileName = "CharacterData", menuName = "UEngineTools/Character Data")]
public class UECharacterData : ScriptableObject
{
    public enum MaterialMode
    {
        Blend,
        Normal
    }

    [System.Serializable]
    public struct FloatParameter
    {
        public EShaderFloatParameter m_Name;
        public float m_Value;
    }

    [System.Serializable]
    public struct ColorParameter
    {
        public EShaderColorParameter m_Name;
        public Color m_Value;
    }

    [System.Serializable]
    public struct VectorParameter
    {
        public EShaderVectorParameter m_Name;
        public Vector4 m_Value;
    }

    [System.Serializable]
    public struct IntParameter
    {
        public EShaderIntParameter m_Name;
        public int m_Value;
    }

    [System.Serializable]
    public class MaterialData
    {
        public string m_TypeName;
        public string m_BodyPartName;
        public int m_MaterialIndex;
        public string m_ReplaceTextureName;
        public MaterialMode m_Mode;
        public Material m_BlendMaterial;
        public UnityEngine.U2D.SpriteAtlas m_SpriteAtlas;
        public string[] m_StringData;
        public Texture[] m_TextureData;

        public string Hash
        {
            get { return m_BodyPartName + '|' + m_MaterialIndex + '|' + m_ReplaceTextureName; }
            private set { }
        }

        public string FileHash
        {
            get { return m_BodyPartName + '!' + m_MaterialIndex + '!' + m_ReplaceTextureName; }
            private set { }
        }

        public Material m_BatchedMaterial = null;
    }

    private struct PrepareMaterial
    {
        public MaterialData M;
        public UEMakeupSystem.MakeupData State;
        public Material BatchedMaterial;
    }

    public class BlendBlitList
    {
        public BlendBlitList(IEnumerable<MaterialData> materials, UECharacterMakeupState makeupState)
        {
            var prepareMaterials = (from m in materials
                                    where makeupState.GetState(m.m_TypeName) != null && m.m_BlendMaterial != null
                                    select new PrepareMaterial
                                    {
                                        M = m,
                                        State = makeupState.GetState(m.m_TypeName),
                                        BatchedMaterial = m.m_BatchedMaterial
                                    }).ToList();

            var hasBatched = (from pm in prepareMaterials
                              where pm.BatchedMaterial != null
                              select pm).ToArray();

            Material theBatchedMaterial = null;
            if (hasBatched.Length > 0)
            {
                theBatchedMaterial = new Material(hasBatched[0].BatchedMaterial);
                foreach (var pm in hasBatched) { theBatchedMaterial.SetInt("_ShouldRender_" + pm.M.m_TypeName, 1); }
            }

            _updateOps = (from pm in prepareMaterials
                          select new UpdateOp
                          {
                              TypeName = pm.M.m_TypeName,
                              BlendState = pm.State,
                              // UpdateMaterial = pm.M.m_BatchedMaterial != null ? theBatchedMaterial : new Material(pm.M.m_BlendMaterial),
                              UpdateMaterial = pm.M.m_BatchedMaterial != null ? theBatchedMaterial : pm.M.m_BlendMaterial,
                              UseBatchedMaterial = pm.M.m_BatchedMaterial != null,
                              BlendTexture = getBlendTexture(pm.M, pm.State.m_TextureIndex, makeupState)
                          }).ToArray();

            var renderList = (from updateOp in _updateOps
                              where updateOp.UseBatchedMaterial == false
                              select new RenderOp { RenderMaterial = updateOp.UpdateMaterial }).ToList();

            if (theBatchedMaterial != null) { renderList.Add(new RenderOp { RenderMaterial = theBatchedMaterial }); }

            _renderOps = renderList.ToArray();

            // Warnings
            foreach (var warning in materials.Where(m => m.m_BlendMaterial == null))
            {
                Debug.LogAssertion("Missing blend material in " + warning.m_TypeName);
            }
        }

        public void Update(UECharacterMakeupState originalStates, SkinnedMeshRenderer smr, UEMakeupSystem makeupSystem)
        {
            foreach (var op in _updateOps)
            {
                var originalState = originalStates.GetStateOrDefault(op.TypeName + smr.name);
                makeupSystem.UpdateMaterialParameter(op.UpdateMaterial, op.BlendState, originalState, op.UseBatchedMaterial);
                makeupSystem.SetStateClear(op.BlendState.m_MakeupName, null);

                if (op.UseBatchedMaterial)
                {
                    op.UpdateMaterial.SetTexture("_TattooTex_" + op.TypeName, op.BlendTexture);
                }
                else
                {
                    op.UpdateMaterial.SetTexture("_TattooTex", op.BlendTexture);
                }
            }
        }

        public void PostUpdate(Material dstMaterial, UECharacterMakeupState originalStates, SkinnedMeshRenderer smr, UEMakeupSystem makeupSystem)
        {
            foreach (var op in _updateOps)
            {
                var originalState = originalStates.GetStateOrDefault(op.TypeName + smr.name);
                makeupSystem.UpdateMaterialParameter(dstMaterial, op.BlendState, originalState);

                if (originalState.IsEmpty()) { originalStates.Remove(op.TypeName + smr.name); }

                Destroy(op.UpdateMaterial);
            }
        }

        public void Render(Texture source, ref RenderTexture destination)
        {
            var blitCount = 0;
            RenderTexture nextSource = null;

            foreach (var op in _renderOps)
            {
                if (nextSource == null)
                {
                    Graphics.Blit(source, destination, op.RenderMaterial);
                    nextSource = destination;
                    destination = new RenderTexture(source.width, source.height, 0, RenderTextureFormat.ARGB32);

                    blitCount++;
                }
                else
                {
                    Graphics.Blit(nextSource, destination, op.RenderMaterial);
                    RenderTexture temp = nextSource;
                    nextSource = destination;
                    destination = temp;

                    blitCount++;
                }
            }

            RenderTexture.active = null;
            destination.Release();
            GameObject.Destroy(destination);

            destination = nextSource;

            // Debug.Log("Makeup blit count: " + blitCount);
        }

        private struct UpdateOp
        {
            public string TypeName;
            public UEMakeupSystem.MakeupData BlendState;
            public Material UpdateMaterial;
            public bool UseBatchedMaterial;
            public Texture BlendTexture;
        }
        private UpdateOp[] _updateOps;

        private struct RenderOp
        {
            public Material RenderMaterial;
        }
        private RenderOp[] _renderOps;

        private Texture getBlendTexture(MaterialData m, int textureIndex, UECharacterMakeupState makeupState)
        {
            if (m.m_SpriteAtlas != null)
            {
                // TODO: make static data
                //Sprite[] sprites = new Sprite[m.m_SpriteAtlas.spriteCount];
                //m.m_SpriteAtlas.GetSprites(sprites);
                //Sprite sprite = sprites[textureIndex];

                Sprite sprite =  m.m_SpriteAtlas.GetSprite(m.m_StringData[textureIndex]);//(m.m_TextureData[textureIndex].name);
                //Sprite sprite = m.m_SpriteAtlas.GetSprite(m.m_TextureData[textureIndex].name);//(m.m_TextureData[textureIndex].name);

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_ORIG_TATTOO_TEX_SIZE).m_Name,
                    new Vector2(sprite.rect.width, sprite.rect.height));

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_ORIG_TATTOO_RECT_POS).m_Name,
                    new Vector2(sprite.textureRectOffset.x, sprite.textureRectOffset.y));

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_ATLAS_TATTOO_RECT_POS).m_Name,
                    new Vector2(sprite.textureRect.position.x, sprite.textureRect.position.y));

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_ATLAS_TATTOO_TEX_SIZE).m_Name,
                    new Vector2(sprite.texture.width, sprite.texture.height));

                // (U_MIN, U_MAX, V_MIN, V_MAX)
                Vector4 uvRegion = new Vector4(
                    sprite.textureRect.xMin / sprite.texture.width,
                    sprite.textureRect.xMax / sprite.texture.width,
                    sprite.textureRect.yMin / sprite.texture.height,
                    sprite.textureRect.yMax / sprite.texture.height);

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_TATTOO_TEX_UV_REGION).m_Name,
                    uvRegion);

                Vector2 uvCenter = new Vector2(
                    sprite.textureRect.center.x / sprite.texture.width,
                    sprite.textureRect.center.y / sprite.texture.height);

                makeupState.SetState(m.m_TypeName,
                    UEShaderParamUtil.GetShaderParameterInfo(EShaderVectorParameter.BLEND_TATTOO_TEX_UV_CENTER).m_Name,
                    uvCenter);

                var retTexture = sprite.texture;

                //foreach (var sp in sprites) { GameObject.Destroy(sp); }
                GameObject.Destroy(sprite);
                sprite = null;
                //return m.m_SpriteAtlas.GetSprite(retTexture.name);
                return retTexture;
            }
            else
            {
                // TODO: clear what we set
                return m.m_TextureData[textureIndex];
            }
        }
    }

    public MaterialData[] m_MakeupDataList;

    private void OnValidate()
    {
        HashSet<string> bodyPartNameSet = new HashSet<string>();
        foreach (var makeupData in m_MakeupDataList)
        {
            if (makeupData.m_BodyPartName.Length > 0)
            {
                bodyPartNameSet.Add(makeupData.m_BodyPartName);
            }
        }

        var bodyPartNameList = bodyPartNameSet.ToArray();
        System.Array.Sort(bodyPartNameList, delegate (string s1, string s2)
        {
            return s1.Length - s2.Length;
        });
        for (int i = 0; i < bodyPartNameList.Length; i++)
        {
            for (int j = i + 1; j < bodyPartNameList.Length; j++)
            {
                string ambiguousString = getAmbiguousSubString(bodyPartNameList[i], bodyPartNameList[j]);
                if (ambiguousString != null)
                {
                    Debug.LogError("Ambiguous body part name \"" + bodyPartNameList[i] + "\" and \"" + bodyPartNameList[j] + "\" with \"" + ambiguousString + "\"");
                }
            }
        }
    }

    private string getAmbiguousSubString(string s1, string s2)
    {
        if (s2.Contains(s1))
        {
            return s1;
        }
        for (int i = 0; i < s1.Length; i++)
        {
            for (int j = 0; j <= i; j++)
            {
                if (s1[j] != s2[s2.Length - i + j - 1])
                {
                    break;
                }
                if (j == i)
                {
                    return s1.Substring(0, i);
                }
            }
        }
        for (int i = 0; i < s1.Length; i++)
        {
            for (int j = 0; j <= i; j++)
            {
                if (s1[s1.Length - 1 - i + j] != s2[j])
                {
                    break;
                }
                if (j == i)
                {
                    return s1.Substring(s1.Length - 1 - i);
                }
            }
        }

        return null;
    }
}

[System.Serializable]
public class UECharacterCustomData
{
    [System.Serializable]
    public struct BlendShapeData
    {
        public string m_PartName;
        public float[] m_Value;
    }

    [System.Serializable]
    public struct FloatParameter
    {
        public string m_Name;
        public float m_Value;
    }

    [System.Serializable]
    public struct ColorParameter
    {
        public string m_Name;
        public Color m_Value;
    }

    [System.Serializable]
    public struct VectorParameter
    {
        public string m_Name;
        public Vector4 m_Value;
    }

    [System.Serializable]
    public struct IntParameter
    {
        public string m_Name;
        public int m_Value;
    }

    [System.Serializable]
    public class MakeupData
    {
        public string m_MakeupName;
        public int m_TextureIndex;
        public List<FloatParameter> m_FloatParameterList;
        public List<ColorParameter> m_ColorParameterList;
        public List<VectorParameter> m_VectorParameterList;
        public List<IntParameter> m_IntParameterList;

        //public MakeupEyeballData m_Eyeball;
        //public MakeupEyelashData m_Eyelash;
        //public MakeupFaceData m_Face;        
    }

    public List<BlendShapeData> m_BlendShapeDataList;
    public List<MakeupData> m_MakeupDataList;
}
