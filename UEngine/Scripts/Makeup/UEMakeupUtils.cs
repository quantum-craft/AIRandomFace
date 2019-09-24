using System.Collections;
using System.Collections.Generic;
using UnityEngine;

public class UEMakeupUtils{
    private static readonly UEMakeupUtils _instance = new UEMakeupUtils();
    private UEMakeupUtils() { }
    public static UEMakeupUtils Instance { get { return _instance; } }

    private static Material s_faceMaterial;
    private static Material s_eyeballMaterial;
    private static Material s_eyelashMaterial;

    public static UEMakeupUtils ConstructUEMakeupUtils(Renderer renderer)
    {
        var materials = renderer.materials;
        foreach (var mat in materials)
        {
            if (mat.name.StartsWith("Face"))
                s_faceMaterial = mat;
            else if (mat.name.StartsWith("Eyeball"))
                s_eyeballMaterial = mat;
        }
        return _instance;
    }
    public void SetEyeLashValue(/*int EyelashID,*/ float EyeLashCurvature, float EyeLashLenght, Color EyeLashCol)
    {
        //eyelish_mat.SetFloat("_raisedlinespow", RaisedLinesPow);
        if (s_eyelashMaterial)
        {
            s_eyelashMaterial.SetFloat("_curvature", EyeLashCurvature);
            s_eyelashMaterial.SetFloat("_lenght", EyeLashLenght);
            s_eyelashMaterial.SetColor("_eyeLashcol", EyeLashCol);
        }        
    }

    public void GetEyeLashValue(/*int EyelashID,*/ ref float EyeLashCurvature, ref float EyeLashLenght, ref Color EyeLashCol)
    {
        //eyelish_mat.SetFloat("_raisedlinespow", RaisedLinesPow);
        if (s_eyelashMaterial)
        {
            EyeLashCurvature = s_eyelashMaterial.GetFloat("_curvature");            
        }
    }

    //EYEBALL----------------------------------------------------
    public void SetEyeBallValue(int IrisID, float IrisAlpha, float IrisScale, Color IrisColor, int PupilID, float PupilAlpha, float PupilScale, Color PupilColor, float CatchLightsPow, float CatchLightsAlpha, Color CatchLightsColor, float MoveUpDown, float MoveLeftRight)
    {
        s_eyeballMaterial.SetInt("_iris", IrisID);
        s_eyeballMaterial.SetFloat("_irisalpha", IrisAlpha);
        s_eyeballMaterial.SetFloat("_irisscale", IrisScale);
        s_eyeballMaterial.SetColor("_iriscol", IrisColor);

        s_eyeballMaterial.SetInt("_pupil", PupilID);
        s_eyeballMaterial.SetFloat("_pupilalpha", PupilAlpha);
        s_eyeballMaterial.SetFloat("_pupilscale", PupilScale);
        s_eyeballMaterial.SetColor("_pupilcol", PupilColor);

        s_eyeballMaterial.SetFloat("_Spec", CatchLightsPow);
        s_eyeballMaterial.SetFloat("_reflectalpha", CatchLightsAlpha);
        s_eyeballMaterial.SetColor("_speccol", CatchLightsColor);

        s_eyeballMaterial.SetFloat("_moveupdown", MoveUpDown);
        s_eyeballMaterial.SetFloat("_moveleftright", MoveLeftRight);
    }


    //FACE----------------------------------------------------
    public void SetBlusherValue(int BlusherID, float BlusherAlpha, float BlusherArea, Color BlusherColor)
    {
        s_faceMaterial.SetInt("_blusher", BlusherID);
        s_faceMaterial.SetFloat("_blusheralpha", BlusherAlpha);
        s_faceMaterial.SetFloat("_blusherarea", BlusherArea);
        s_faceMaterial.SetColor("_blusherCol", BlusherColor);
    }

    public void SetEyeBrowValue(int EyeBrowID, float EyeBrowAlpha, Color EyeBrowColor)
    {
        s_faceMaterial.SetInt("_eyebrow", EyeBrowID);
        s_faceMaterial.SetFloat("_eyebrowalpha", EyeBrowAlpha);
        s_faceMaterial.SetColor("_eyebrowCol", EyeBrowColor);
    }

    public void SetEyeShadowValue(int EyeShadowID, float EyeshadowAlpha, float EyeshadowArea, float EyeshadowReflect, float EyeshadowShine, Color EyeshadowColor)
    {
        s_faceMaterial.SetInt("_eyeshadow", EyeShadowID);
        s_faceMaterial.SetFloat("_eyeshadowalpha", EyeshadowAlpha);
        s_faceMaterial.SetFloat("_eyeshadowarea", EyeshadowArea);
        s_faceMaterial.SetFloat("_eyeshadowroughness", EyeshadowReflect);
        s_faceMaterial.SetFloat("_eyeshadowshine", EyeshadowShine);
        s_faceMaterial.SetColor("_eyeshadowCol", EyeshadowColor);
    }

    public void SetEyeLineValue(int EyeLineID, Color EyeLineColor)
    {
        s_faceMaterial.SetInt("_eyeline", EyeLineID);
        s_faceMaterial.SetColor("_eyelineCol", EyeLineColor);
    }

    public void SetLipNormalValue(int LipNormalID)
    {
        s_faceMaterial.SetInt("_lipnormal", LipNormalID);
    }

    public void SetLipValue(int LipID, float LipAlpha, float LipArea, float LipReflect, Color LipColor)
    {
        s_faceMaterial.SetInt("_lip", LipID);
        s_faceMaterial.SetFloat("_lipalpha", LipAlpha);
        s_faceMaterial.SetFloat("_liparea", LipArea);
        s_faceMaterial.SetFloat("_liproughness", LipReflect);
        s_faceMaterial.SetColor("_lipCol", LipColor);
    }

    public void SetWrinkleValue(float RaisedLinesPow, float FishtailLinesPow, float NasolabialFoldsPow)
    {
        s_faceMaterial.SetFloat("_raisedlinespow", RaisedLinesPow);
        s_faceMaterial.SetFloat("_fishtaillinespow", FishtailLinesPow);
        s_faceMaterial.SetFloat("_nasolabialfoldspow", NasolabialFoldsPow);
    }

    public void SetMustacheValue(int MustacheID, float MustacheAlpha, Color MustacheColor)
    {
        s_faceMaterial.SetInt("_mustache", MustacheID);
        s_faceMaterial.SetFloat("_mustachealpha", MustacheAlpha);
        s_faceMaterial.SetColor("_mustacheCol", MustacheColor);
    }

    //SKIN----------------------------------------------------
    public void SetSkinValue(Color SkinColor)
    {
        s_faceMaterial.SetColor("_skinCol", SkinColor);        
    }

    
    public void GetMakeupData(ref UECharacterCustomData.MakeupData makeupData)
    {
        //makeupData.m_Eyeball.m_MakeupName = s_eyeballMaterial.name;
        //makeupData.m_Eyeball.IrisID = s_eyeballMaterial.GetInt("_iris");
        //makeupData.m_Eyeball.IrisAlpha = s_eyeballMaterial.GetFloat("_irisalpha");
        //makeupData.m_Eyeball.IrisScale = s_eyeballMaterial.GetFloat("_irisscale");
        //makeupData.m_Eyeball.IrisColor = s_eyeballMaterial.GetColor("_iriscol");

        //makeupData.m_Eyeball.PupilID = s_eyeballMaterial.GetInt("_pupil");
        //makeupData.m_Eyeball.PupilAlpha = s_eyeballMaterial.GetFloat("_pupilalpha");
        //makeupData.m_Eyeball.PupilScale = s_eyeballMaterial.GetFloat("_pupilscale");
        //makeupData.m_Eyeball.PupilColor = s_eyeballMaterial.GetColor("_pupilcol");

        //makeupData.m_Eyeball.CatchLightsPow = s_eyeballMaterial.GetFloat("_Spec");
        //makeupData.m_Eyeball.CatchLightsAlpha = s_eyeballMaterial.GetFloat("_reflectalpha");
        //makeupData.m_Eyeball.CatchLightsColor = s_eyeballMaterial.GetColor("_speccol");

        //makeupData.m_Eyeball.MoveUpDown = s_eyeballMaterial.GetFloat("_moveupdown");
        //makeupData.m_Eyeball.MoveLeftRight = s_eyeballMaterial.GetFloat("_moveleftright");

        ////TODO:add more settings here
        //makeupData.m_Face.m_MakeupName = s_faceMaterial.name;
        //makeupData.m_Face.BlusherID = s_faceMaterial.GetInt("_blusher");
        //makeupData.m_Face.BlusherAlpha = s_faceMaterial.GetFloat("_blusheralpha");
        //makeupData.m_Face.BlusherArea = s_faceMaterial.GetFloat("_blusherarea");
        //makeupData.m_Face.BlusherColor = s_faceMaterial.GetColor("_blusherCol");

        //makeupData.m_Face.EyeBrowID = s_faceMaterial.GetInt("_eyebrow");
        //makeupData.m_Face.EyeBrowAlpha = s_faceMaterial.GetFloat("_eyebrowalpha");
        //makeupData.m_Face.EyeBrowColor = s_faceMaterial.GetColor("_eyebrowCol");

        //makeupData.m_Face.EyeShadowID = s_faceMaterial.GetInt("_eyeshadow");
        //makeupData.m_Face.EyeshadowAlpha = s_faceMaterial.GetFloat("_eyeshadowalpha");
        //makeupData.m_Face.EyeshadowArea = s_faceMaterial.GetFloat("_eyeshadowarea");
        //makeupData.m_Face.EyeshadowReflect = s_faceMaterial.GetFloat("_eyeshadowroughness");
        //makeupData.m_Face.EyeshadowShine = s_faceMaterial.GetFloat("_eyeshadowshine");
        //makeupData.m_Face.EyeshadowColor = s_faceMaterial.GetColor("_eyeshadowCol");

        //makeupData.m_Face.EyeLineID = s_faceMaterial.GetInt("_eyeline");
        //makeupData.m_Face.EyeLineColor = s_faceMaterial.GetColor("_eyelineCol");

        //makeupData.m_Face.LipNormalID = s_faceMaterial.GetInt("_lipnormal");

        //makeupData.m_Face.LipID = s_faceMaterial.GetInt("_lip");
        //makeupData.m_Face.LipAlpha = s_faceMaterial.GetFloat("_lipalpha");
        //makeupData.m_Face.LipArea = s_faceMaterial.GetFloat("_liparea");
        //makeupData.m_Face.LipReflect = s_faceMaterial.GetFloat("_liproughness");
        //makeupData.m_Face.LipColor = s_faceMaterial.GetColor("_lipCol");

        //makeupData.m_Face.RaisedLinesPow = s_faceMaterial.GetFloat("_raisedlinespow");
        //makeupData.m_Face.FishtailLinesPow = s_faceMaterial.GetFloat("_fishtaillinespow");
        //makeupData.m_Face.NasolabialFoldsPow = s_faceMaterial.GetFloat("_nasolabialfoldspow");

        //makeupData.m_Face.MustacheID = s_faceMaterial.GetInt("_mustache");
        //makeupData.m_Face.MustacheAlpha = s_faceMaterial.GetFloat("_mustachealpha");
        //makeupData.m_Face.MustacheColor = s_faceMaterial.GetColor("_mustacheCol");

        //makeupData.m_Face.SkinColor = s_faceMaterial.GetColor("_skinCol");
    }
   
}
