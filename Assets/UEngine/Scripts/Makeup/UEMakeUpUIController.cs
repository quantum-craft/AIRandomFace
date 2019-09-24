using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.UI;

//[ExecuteInEditMode]
public class UEMakeUpUIController : MonoBehaviour{
   

    public Dropdown m_irisID;
    public Slider m_irisScale_slider;
    public Slider m_irisAlpha_slider;
    public Slider m_irisR_slider;
    public Slider m_irisG_slider;
    public Slider m_irisB_slider;

    public Dropdown m_pupilID;
    public Slider m_pupilScale_slider;
    public Slider m_pupilAlpha_slider;
    public Slider m_pupilR_slider;
    public Slider m_pupilG_slider;
    public Slider m_pupilB_slider;

    public Slider m_MoveUpDown_slider;
    public Slider m_MoveLeftRight_slider;

    public Slider m_catchlightsPow_slider;
    public Slider m_catchlightsAlpha_slider;
    public Slider m_catchlightsR_slider;
    public Slider m_catchlightsG_slider;
    public Slider m_catchlightsB_slider;

    public Slider m_eyelashLenght_slider;
    public Slider m_eyelashCurvature_slider;
    public Slider m_eyelashR_slider;
    public Slider m_eyelashG_slider;
    public Slider m_eyelashB_slider;

    public Dropdown m_EyeBrowID;
    public Slider m_EyeBrowAlpha_slider;
    public Slider m_EyeBrowR_slider;
    public Slider m_EyeBrowG_slider;
    public Slider m_EyeBrowB_slider;

    public Dropdown m_EyeShadowID;
    public Slider m_EyeshadowAlpha_slider;
    public Slider m_EyeshadowArea_slider;
    public Slider m_EyeshadowReflect_slider;
    public Slider m_EyeshadowShine_slider;
    public Slider m_EyeshadowR_slider;
    public Slider m_EyeshadowG_slider;
    public Slider m_EyeshadowB_slider;

    public Dropdown m_EyeLineID;
    public Slider m_EyeLineR_slider;
    public Slider m_EyeLineG_slider;
    public Slider m_EyeLineB_slider;

    public Dropdown m_LipNormalID;

    public Dropdown m_LipID;
    public Slider m_LipAlpha_slider;
    public Slider m_LipArea_slider;
    public Slider m_LipReflect_slider;
    public Slider m_LipR_slider;
    public Slider m_LipG_slider;
    public Slider m_LipB_slider;

    public Dropdown m_BlusherID;
    public Slider m_BlusherAlpha_slider;
    public Slider m_BlusherArea_slider;
    public Slider m_BlusherR_slider;
    public Slider m_BlusherG_slider;
    public Slider m_BlusherB_slider;

    public Slider m_RaisedLinesPow_slider;
    public Slider m_FishtailLinesPow_slider;
    public Slider m_NasolabialFoldsPow_slider;

    public Dropdown m_MustacheID;
    public Slider m_MustacheAlpha_slider;
    public Slider m_MustacheR_slider;
    public Slider m_MustacheG_slider;
    public Slider m_MustacheB_slider;

    public Slider m_SkinColorR_slider;
    public Slider m_SkinColorG_slider;
    public Slider m_SkinColorB_slider;

    public GameObject m_char;
    public Slider m_R_slider;

    public GameObject on;
    public GameObject off;

    [HideInInspector]
    public Renderer faceRenderer;

    public void SetupFaceRenderer(SkinnedMeshRenderer smr)
    {
        faceRenderer = smr;
        UEMakeupUtils.ConstructUEMakeupUtils(faceRenderer);
    }

    //private void OnGUI()
    //{
    //    if (GUI.Button(new Rect(Screen.width * 0.78f, Screen.height * 0.78f, Screen.width * 0.1f, Screen.height * 0.08f), "显示头发"))
    //    {
    //        on.SetActive(false);
    //        off.SetActive(true);
    //    }
    //    if (GUI.Button(new Rect(Screen.width * 0.88f, Screen.height * 0.78f, Screen.width * 0.1f, Screen.height * 0.08f), "关闭头发"))
    //    {
    //        on.SetActive(true);
    //        off.SetActive(false);
    //    }
    //}


    private void Update()
    {
        if (faceRenderer == null) return;
        var m_irisTestID = m_irisID.value;
        var m_irisScale = m_irisScale_slider.value;
        var m_irisAlpha = m_irisAlpha_slider.value;
        var m_irisColor = new Color(m_irisR_slider.value, m_irisG_slider.value, m_irisB_slider.value,1);
        var m_pupilTestID = m_pupilID.value;
        var m_pupilScale = m_pupilScale_slider.value;
        var m_pupilAlpha = m_pupilAlpha_slider.value;
        var m_pupilColor = new Color(m_pupilR_slider.value, m_pupilG_slider.value, m_pupilB_slider.value, 1);
        var m_catchlightsPow = m_catchlightsPow_slider.value;
        var m_catchlightsAlpha = m_catchlightsAlpha_slider.value;
        var m_catchlightsColor = new Color(m_catchlightsR_slider.value, m_catchlightsG_slider.value, m_catchlightsB_slider.value, 1);
        var m_MoveUpDown = m_MoveUpDown_slider.value;
        var m_MoveLeftRight = m_MoveLeftRight_slider.value;
        SetEyeBallValue(m_irisTestID+1, m_irisAlpha, m_irisScale, m_irisColor, m_pupilTestID+1, m_pupilAlpha, m_pupilScale, m_pupilColor, m_catchlightsPow, m_catchlightsAlpha, m_catchlightsColor, m_MoveUpDown, m_MoveLeftRight);

        var m_eyelashLenght = m_eyelashLenght_slider.value;
        var m_eyelashCurvature = m_eyelashCurvature_slider.value;
        var m_eyelashcol = new Color(m_eyelashR_slider.value, m_eyelashG_slider.value, m_eyelashB_slider.value, 1);
        SetEyeLashValue(m_eyelashCurvature, m_eyelashLenght, m_eyelashcol);

        var m_EyeBrowTestID = m_EyeBrowID.value;
        var m_EyeBrowAlpha = m_EyeBrowAlpha_slider.value;
        var m_EyeBrowColor = new Color(m_EyeBrowR_slider.value, m_EyeBrowG_slider.value, m_EyeBrowB_slider.value, 1);
        SetEyeBrowValue(m_EyeBrowTestID+1, m_EyeBrowAlpha, m_EyeBrowColor);

        var m_EyeShadowTestID = m_EyeShadowID.value;
        var m_EyeshadowAlpha = m_EyeshadowAlpha_slider.value;
        var m_EyeshadowArea = m_EyeshadowArea_slider.value;
        var m_EyeshadowReflect = m_EyeshadowReflect_slider.value;
        var m_EyeshadowShine = m_EyeshadowShine_slider.value;
        var m_EyeshadowColor = new Color(m_EyeshadowR_slider.value, m_EyeshadowG_slider.value, m_EyeshadowB_slider.value, 1);
        SetEyeShadowValue(m_EyeShadowTestID , m_EyeshadowAlpha, m_EyeshadowArea, m_EyeshadowReflect, m_EyeshadowShine, m_EyeshadowColor);

        var m_EyeLineTestID = m_EyeLineID.value;
        var m_EyeLineColor = new Color(m_EyeLineR_slider.value, m_EyeLineG_slider.value, m_EyeLineB_slider.value, 1);
        SetEyeLineValue(m_EyeLineTestID, m_EyeLineColor);

        var m_LipNormalTestID = m_LipNormalID.value;
        SetLipNormalValue(m_LipNormalTestID);

        var m_BlusherTestID = m_BlusherID.value;
        var m_BlusherAlpha = m_BlusherAlpha_slider.value;
        var m_BlusherArea = m_BlusherArea_slider.value;
        var m_BlusherColor = new Color(m_BlusherR_slider.value, m_BlusherG_slider.value, m_BlusherB_slider.value, 1);
        SetBlusherValue(m_BlusherTestID, m_BlusherAlpha, m_BlusherArea, m_BlusherColor);

        var m_LipTestID = m_LipID.value;
        var m_LipAlpha = m_LipAlpha_slider.value;
        var m_LipArea = m_LipArea_slider.value;
        var m_LipReflect = m_LipReflect_slider.value;
        var m_LipColor = new Color(m_LipR_slider.value, m_LipG_slider.value, m_LipB_slider.value, 1);
        SetLipValue(m_LipTestID, m_LipAlpha, m_LipArea, m_LipReflect, m_LipColor);

        var m_raisedlinesPow = m_RaisedLinesPow_slider.value;
        var m_fishtaillinesPow = m_FishtailLinesPow_slider.value;
        var m_nasolabialfoldsPow = m_NasolabialFoldsPow_slider.value;
        SetWrinkleValue(m_raisedlinesPow, m_fishtaillinesPow, m_nasolabialfoldsPow);

        var m_MustacheTestID = m_MustacheID.value;
        var m_MustacheAlpha = m_MustacheAlpha_slider.value;
        var m_MustacheColor = new Color(m_MustacheR_slider.value, m_MustacheG_slider.value, m_MustacheB_slider.value, 1);
        SetMustacheValue(m_MustacheTestID, m_MustacheAlpha, m_MustacheColor);

        var m_SkinColor = new Color(m_SkinColorR_slider.value, m_SkinColorG_slider.value, m_SkinColorB_slider.value, 1);
        SetSkinValue(m_SkinColor);            
    }
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
    //----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------

    //EYELASH----------------------------------------------------
    public void SetEyeLashValue(/*int EyelashID,*/ float EyeLashCurvature, float EyeLashLenght, Color EyeLashCol)
    {
        UEMakeupUtils.Instance.SetEyeLashValue(EyeLashCurvature, EyeLashLenght, EyeLashCol);
        //eyelish_mat.SetFloat("_raisedlinespow", RaisedLinesPow);
        //eyelish_mat.SetFloat("_curvature", EyeLashCurvature);
        //eyelish_mat.SetFloat("_lenght", EyeLashLenght);
        //eyelish_mat.SetColor("_eyeLashcol", EyeLashCol);
    }

    //EYEBALL----------------------------------------------------
    public void SetEyeBallValue(int IrisID, float IrisAlpha, float IrisScale, Color IrisColor, int PupilID, float PupilAlpha, float PupilScale, Color PupilColor, float CatchLightsPow, float CatchLightsAlpha, Color CatchLightsColor, float MoveUpDown, float MoveLeftRight)
    {
        UEMakeupUtils.Instance.SetEyeBallValue(IrisID, IrisAlpha, IrisScale, IrisColor, PupilID, PupilAlpha, PupilScale, PupilColor, CatchLightsPow, CatchLightsAlpha, CatchLightsColor, MoveUpDown, MoveLeftRight);
        //eyeball_mat.SetInt("_iris", IrisID);
        //eyeball_mat.SetFloat("_irisalpha", IrisAlpha);
        //eyeball_mat.SetFloat("_irisscale", IrisScale);
        //eyeball_mat.SetColor("_iriscol", IrisColor);

        //eyeball_mat.SetInt("_pupil", PupilID);
        //eyeball_mat.SetFloat("_pupilalpha", PupilAlpha);
        //eyeball_mat.SetFloat("_pupilscale", PupilScale);
        //eyeball_mat.SetColor("_pupilcol", PupilColor);

        //eyeball_mat.SetFloat("_Spec", CatchLightsPow);
        //eyeball_mat.SetFloat("_reflectalpha", CatchLightsAlpha);
        //eyeball_mat.SetColor("_speccol", CatchLightsColor);

        //eyeball_mat.SetFloat("_moveupdown", MoveUpDown);
        //eyeball_mat.SetFloat("_moveleftright", MoveLeftRight);
    }

    //FACE----------------------------------------------------
    public void SetBlusherValue(int BlusherID, float BlusherAlpha, float BlusherArea, Color BlusherColor)
    {
        UEMakeupUtils.Instance.SetBlusherValue(BlusherID, BlusherAlpha, BlusherArea, BlusherColor);
        //face_mat.SetInt("_blusher", BlusherID);
        //face_mat.SetFloat("_blusheralpha", BlusherAlpha);
        //face_mat.SetFloat("_blusherarea", BlusherArea);
        //face_mat.SetColor("_blusherCol", BlusherColor);
    }

    public void SetEyeBrowValue(int EyeBrowID, float EyeBrowAlpha, Color EyeBrowColor)
    {
        UEMakeupUtils.Instance.SetEyeBrowValue(EyeBrowID, EyeBrowAlpha, EyeBrowColor);
        //face_mat.SetInt("_eyebrow", EyeBrowID);
        //face_mat.SetFloat("_eyebrowalpha", EyeBrowAlpha);
        //face_mat.SetColor("_eyebrowCol", EyeBrowColor);
    }

    public void SetEyeShadowValue(int EyeShadowID,float EyeshadowAlpha,float EyeshadowArea,float EyeshadowReflect,float EyeshadowShine,Color EyeshadowColor)
    {
        UEMakeupUtils.Instance.SetEyeShadowValue(EyeShadowID, EyeshadowAlpha, EyeshadowArea, EyeshadowReflect, EyeshadowShine, EyeshadowColor);
        //face_mat.SetInt("_eyeshadow", EyeShadowID);
        //face_mat.SetFloat("_eyeshadowalpha", EyeshadowAlpha);
        //face_mat.SetFloat("_eyeshadowarea", EyeshadowArea);
        //face_mat.SetFloat("_eyeshadowroughness", EyeshadowReflect);
        //face_mat.SetFloat("_eyeshadowshine", EyeshadowShine);
        //face_mat.SetColor("_eyeshadowCol", EyeshadowColor);
    }

    public void SetEyeLineValue(int EyeLineID, Color EyeLineColor)
    {
        UEMakeupUtils.Instance.SetEyeLineValue(EyeLineID, EyeLineColor);
        //face_mat.SetInt("_eyeline", EyeLineID);
        //face_mat.SetColor("_eyelineCol", EyeLineColor);
    }

    public void SetLipNormalValue(int LipNormalID)
    {
        UEMakeupUtils.Instance.SetLipNormalValue(LipNormalID);
        //face_mat.SetInt("_lipnormal", LipNormalID);
    }

    public void SetLipValue(int LipID,float LipAlpha,float LipArea,float LipReflect,Color LipColor)
    {
        UEMakeupUtils.Instance.SetLipValue(LipID, LipAlpha, LipArea, LipReflect, LipColor);
        //face_mat.SetInt("_lip", LipID);
        //face_mat.SetFloat("_lipalpha", LipAlpha);
        //face_mat.SetFloat("_liparea", LipArea);
        //face_mat.SetFloat("_liproughness", LipReflect);
        //face_mat.SetColor("_lipCol", LipColor);
    }

    public void SetWrinkleValue(float RaisedLinesPow, float FishtailLinesPow, float NasolabialFoldsPow)
    {
        UEMakeupUtils.Instance.SetWrinkleValue(RaisedLinesPow, FishtailLinesPow, NasolabialFoldsPow);
        //face_mat.SetFloat("_raisedlinespow", RaisedLinesPow);
        //face_mat.SetFloat("_fishtaillinespow", FishtailLinesPow);
        //face_mat.SetFloat("_nasolabialfoldspow", NasolabialFoldsPow);
    }

    public void SetMustacheValue(int MustacheID, float MustacheAlpha, Color MustacheColor)
    {
        UEMakeupUtils.Instance.SetMustacheValue(MustacheID, MustacheAlpha, MustacheColor);
        //face_mat.SetInt("_mustache", MustacheID);
        //face_mat.SetFloat("_mustachealpha", MustacheAlpha);
        //face_mat.SetColor("_mustacheCol", MustacheColor);
    }

    //SKIN----------------------------------------------------
    public void SetSkinValue(Color SkinColor)
    {
        UEMakeupUtils.Instance.SetSkinValue(SkinColor);
        //face_mat.SetColor("_skinCol", SkinColor);
    }

    public void GetMakeupData(ref UECharacterCustomData.MakeupData makeupData)
    {
        UEMakeupUtils.Instance.GetMakeupData(ref makeupData);
    }

    public void SetMakeupData(ref UECharacterCustomData.MakeupData makeupData)
    {
        //TODO:update UI controller settings here
        //m_irisID.value = makeupData.m_Eyeball.IrisID - 1;
        //m_irisScale_slider.value = makeupData.m_Eyeball.IrisScale;
        //m_irisAlpha_slider.value = makeupData.m_Eyeball.IrisAlpha;
        //m_irisR_slider.value = makeupData.m_Eyeball.IrisColor.r;
        //m_irisG_slider.value = makeupData.m_Eyeball.IrisColor.g;
        //m_irisB_slider.value = makeupData.m_Eyeball.IrisColor.b;

        //m_pupilID.value = makeupData.m_Eyeball.PupilID -1;
        //m_pupilScale_slider.value = makeupData.m_Eyeball.PupilScale;
        //m_pupilAlpha_slider.value = makeupData.m_Eyeball.PupilAlpha;
        //m_pupilR_slider.value = makeupData.m_Eyeball.PupilColor.r;
        //m_pupilG_slider.value = makeupData.m_Eyeball.PupilColor.g;
        //m_pupilB_slider.value = makeupData.m_Eyeball.PupilColor.b;

        //m_catchlightsPow_slider.value = makeupData.m_Eyeball.CatchLightsPow;
        //m_catchlightsAlpha_slider.value = makeupData.m_Eyeball.CatchLightsAlpha;
        //m_catchlightsR_slider.value = makeupData.m_Eyeball.CatchLightsColor.r;
        //m_catchlightsG_slider.value = makeupData.m_Eyeball.CatchLightsColor.g;
        //m_catchlightsB_slider.value = makeupData.m_Eyeball.CatchLightsColor.b;

        //m_MoveUpDown_slider.value = makeupData.m_Eyeball.MoveUpDown;
        //m_MoveLeftRight_slider.value = makeupData.m_Eyeball.MoveLeftRight;
        ////TODO:update UI controller settings here
        //m_BlusherID.value = makeupData.m_Face.BlusherID;
        //m_BlusherAlpha_slider.value = makeupData.m_Face.BlusherAlpha;
        //m_BlusherArea_slider.value = makeupData.m_Face.BlusherArea;
        //m_BlusherR_slider.value = makeupData.m_Face.BlusherColor.r;
        //m_BlusherG_slider.value = makeupData.m_Face.BlusherColor.g;
        //m_BlusherB_slider.value = makeupData.m_Face.BlusherColor.b;

        //m_EyeBrowID.value = makeupData.m_Face.EyeBrowID-1;
        //m_EyeBrowAlpha_slider.value = makeupData.m_Face.EyeBrowAlpha;
        //m_EyeBrowR_slider.value = makeupData.m_Face.EyeBrowColor.r;
        //m_EyeBrowG_slider.value = makeupData.m_Face.EyeBrowColor.g;
        //m_EyeBrowB_slider.value = makeupData.m_Face.EyeBrowColor.b;

        //m_EyeShadowID.value = makeupData.m_Face.EyeShadowID;
        //m_EyeshadowAlpha_slider.value = makeupData.m_Face.EyeshadowAlpha;
        //m_EyeshadowArea_slider.value = makeupData.m_Face.EyeshadowArea;
        //m_EyeshadowReflect_slider.value = makeupData.m_Face.EyeshadowReflect;
        //m_EyeshadowShine_slider.value = makeupData.m_Face.EyeshadowShine;
        //m_EyeshadowR_slider.value = makeupData.m_Face.EyeshadowColor.r;
        //m_EyeshadowG_slider.value = makeupData.m_Face.EyeshadowColor.g;
        //m_EyeshadowB_slider.value = makeupData.m_Face.EyeshadowColor.b;

        //m_EyeLineID.value = makeupData.m_Face.EyeLineID;
        //m_EyeLineR_slider.value = makeupData.m_Face.EyeLineColor.r;
        //m_EyeLineG_slider.value = makeupData.m_Face.EyeLineColor.g;
        //m_EyeLineB_slider.value = makeupData.m_Face.EyeLineColor.b;

        //m_LipNormalID.value = makeupData.m_Face.LipNormalID;

        //m_LipID.value = makeupData.m_Face.LipID;
        //m_LipAlpha_slider.value = makeupData.m_Face.LipAlpha;
        //m_LipArea_slider.value = makeupData.m_Face.LipArea;
        //m_LipReflect_slider.value = makeupData.m_Face.LipReflect;
        //m_LipR_slider.value = makeupData.m_Face.LipColor.r;
        //m_LipG_slider.value = makeupData.m_Face.LipColor.g;
        //m_LipB_slider.value = makeupData.m_Face.LipColor.b;

        //m_RaisedLinesPow_slider.value = makeupData.m_Face.RaisedLinesPow;
        //m_FishtailLinesPow_slider.value = makeupData.m_Face.FishtailLinesPow;
        //m_NasolabialFoldsPow_slider.value = makeupData.m_Face.NasolabialFoldsPow;

        //m_SkinColorR_slider.value = makeupData.m_Face.SkinColor.r;
        //m_SkinColorG_slider.value = makeupData.m_Face.SkinColor.g;
        //m_SkinColorB_slider.value = makeupData.m_Face.SkinColor.b;
    }
}
