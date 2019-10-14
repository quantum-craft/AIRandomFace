using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using UnityEngine;
// using UGameEngine;

public class UECharacterLoader : MonoBehaviour
{
    private UEBlendShapesControl m_blendShapesController;
    public UEBlendShapesControl BlendShapesController
    {
        get { return m_blendShapesController; }
        private set { }
    }

    private UEMakeupSystem m_makeupSystem;
    public UEMakeupSystem MakeupSystem
    {
        get { return m_makeupSystem; }
        private set { }
    }

    [Tooltip("Character data asset bundle path in Application.streamingAssetsPath\\")]
    public string m_CharacterDataBundlePath;
    [Tooltip("Character data name in asset bundle")]
    public string m_CharacterDataName;

    private AssetBundle m_characterDataBundle;
    public UECharacterData m_characterData;
    // private UECharacterData m_characterData;

    // private RefSet m_characterDataRefSet;

    private bool m_initialized = false;
    private bool m_inGameMode = false;


    private void Start()
    {
        // m_characterDataBundle = AssetBundle.LoadFromFile(Path.Combine(Application.streamingAssetsPath, m_CharacterDataBundlePath));
        // m_characterData = m_characterDataBundle.LoadAsset<UECharacterData>(m_CharacterDataName);

        Debug.Log(gameObject.GetInstanceID() + ": Start");

//        m_characterDataRefSet = new RefSet();
//        var asset = AssetDepot.LoadAsset("CharacterData", m_characterDataRefSet);

//#if RES_DEBUG
//        Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Load Asset bundle (RES_DEBUG defined)");
//#else
//        Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Load Asset bundle");
//#endif

//        m_characterData = asset as UECharacterData;

        if (m_characterData == null)
        {
            Debug.LogWarning(gameObject.name + " failed to load character data");
        }
    }

    public void InitializeEditModeCharacter()
    {
        Debug.Log(gameObject.GetInstanceID() + ": Edit mode initialize");

        //if (m_initialized)
        //{
        //    Debug.LogError(gameObject.name + " CharacterLoader already initialized!");
        //    return;
        //}

        InitializeCharacter();

        m_initialized = true;
        Debug.Log(gameObject.GetInstanceID() + ": Edit mode initialize success");

    }

    private void InitializeCharacter()
    {
        m_blendShapesController = new UEBlendShapesControl();
        m_makeupSystem = new UEMakeupSystem();

        var SMRs = gameObject.GetComponentsInChildren<SkinnedMeshRenderer>();
        foreach (var smr in SMRs)
        {
            if (smr.sharedMesh && smr.sharedMesh.blendShapeCount > 0)
            {
                m_blendShapesController.AddBlendShapes(smr);
            }
        }
        m_makeupSystem.SetCharacter(gameObject, m_characterData);
    }

    public void InitializeInGameCharacter(UECharacterCustomData customData)
    {
        Debug.Log(gameObject.GetInstanceID() + ": In game mode initialize");

        if (m_initialized)
        {
            Debug.LogError("CharacterLoader already initialized");
            return;
        }
        InitializeCharacter();
        SetCustomizedData(customData);

        m_blendShapesController.InGameMode();
        m_blendShapesController = null;
        m_makeupSystem.InGameMode();

        // m_characterData = null;
        // m_characterDataBundle.Unload(true);
        // m_characterDataBundle = null;

//        if (m_characterDataRefSet != null)
//        {
//            m_characterDataRefSet.ReleaseRef();

//#if RES_DEBUG
//            Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Unload Asset bundle (RES_DEBUG defined)");
//#else
//            Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Unload Asset bundle");
//#endif

//            m_characterDataRefSet = null;
//        }

        if (m_characterData != null)
        {
            m_characterData = null;
        }

        m_inGameMode = true;
        m_initialized = true;

        Debug.Log(gameObject.GetInstanceID() + ": In game mode initialize success");
    }

    public void SetCustomizedData(UECharacterCustomData customData)
    {
        if (m_inGameMode)
        {
            Debug.LogError("Can't set customized data in \" In Game Mode\"");
            return;
        }
        if (!m_initialized)
        {
            InitializeCharacter();
            m_initialized = true;
        }
        else
        {
            m_makeupSystem.ResetState();
            m_blendShapesController.ResetAllValue();
        }

        BlendShapesController.SetBlendShapesDataByList(customData.m_BlendShapeDataList);
        m_makeupSystem.SetMakeupData(customData.m_MakeupDataList);
    }

    public UECharacterCustomData GetCustomizedData()
    {
        if (m_inGameMode)
        {
            Debug.LogError("Can't get customized data in \" In Game Mode\"");
            return null;
        }
        UECharacterCustomData customData = new UECharacterCustomData();
        customData.m_BlendShapeDataList = m_blendShapesController.GetBlendShapesDataList();
        customData.m_MakeupDataList = m_makeupSystem.GetMakeupDataList();
        return customData;
    }

    private void FixedUpdate()
    {
        if (!m_inGameMode && m_initialized)
        {
            m_makeupSystem.ApplyTexture();
        }
    }

    private void OnDestroy()
    {
        Debug.Log(gameObject.GetInstanceID() + ": Destory");

        if (m_makeupSystem != null) { m_makeupSystem.Reset(); }
        else { Debug.LogWarning(gameObject.name + " hasn't initialized m_makeupSystem"); }

        //if (m_characterDataBundle)
        //{
        //    m_characterDataBundle.Unload(true);
        //    m_characterDataBundle = null;
        //}

//        if (m_characterDataRefSet != null)
//        {
//            m_characterDataRefSet.ReleaseRef();

//#if RES_DEBUG
//            Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Unload Asset bundle (RES_DEBUG defined)");
//#else
//            Debug.Log("UECharacterLoader " + gameObject.GetInstanceID() + " Unload Asset bundle");
//#endif

//            m_characterDataRefSet = null;
//        }

        if (m_characterData != null)
        {
            m_characterData = null;
        }
    }
}
