using System.IO;
using System.Linq;
using UnityEngine;


public class UEBlendShapeToJson
{
    [System.Serializable]
    public class UEBlendShapes
    {
        [System.Serializable]
        public class BlendShape
        {
            public string BlendShapeName;
            public int BlendShapeFrameCount;
            public BlendShapeFrame[] BlendShapeFrames;
        }

        [System.Serializable]
        public class BlendShapeFrame
        {
            public float BlendShapeFrameWeight;
            public int VertexCount;
            public Vector3[] deltaVertices;
            public Vector3[] deltaNormals;
            public Vector3[] deltaTangents;
        }

        public int BlendShapeCount;
        public BlendShape[] BlendShapes;
    }

    public static void ClearBlendShapes(SkinnedMeshRenderer smr)
    {
        var mesh = smr.sharedMesh;

        mesh.ClearBlendShapes();
    }

    public static void SaveBlendShapes(SkinnedMeshRenderer smr)
    {
        var mesh = smr.sharedMesh;

        var myBlendShapes = new UEBlendShapes();
        myBlendShapes.BlendShapeCount = mesh.blendShapeCount;

        var blendShapeCount = myBlendShapes.BlendShapeCount;
        myBlendShapes.BlendShapes = new UEBlendShapes.BlendShape[blendShapeCount];
        for (int i = 0; i < myBlendShapes.BlendShapes.Length; i++)
        {
            myBlendShapes.BlendShapes[i] = new UEBlendShapes.BlendShape();
        }

        foreach (var shapeIndex in Enumerable.Range(0, blendShapeCount))
        {
            var blendShape = myBlendShapes.BlendShapes[shapeIndex];
            blendShape.BlendShapeName = mesh.GetBlendShapeName(shapeIndex);
            blendShape.BlendShapeFrameCount = mesh.GetBlendShapeFrameCount(shapeIndex);
            blendShape.BlendShapeFrames = new UEBlendShapes.BlendShapeFrame[mesh.GetBlendShapeFrameCount(shapeIndex)];

            for (int i = 0; i < blendShape.BlendShapeFrames.Length; i++)
            {
                blendShape.BlendShapeFrames[i] = new UEBlendShapes.BlendShapeFrame();
            }

            foreach (var frameIndex in Enumerable.Range(0, blendShape.BlendShapeFrameCount))
            {
                var blendShapeFrame = blendShape.BlendShapeFrames[frameIndex];

                blendShapeFrame.BlendShapeFrameWeight = mesh.GetBlendShapeFrameWeight(shapeIndex, frameIndex);
                blendShapeFrame.VertexCount = mesh.vertexCount;

                blendShapeFrame.deltaVertices = new Vector3[blendShapeFrame.VertexCount];
                blendShapeFrame.deltaNormals = new Vector3[blendShapeFrame.VertexCount];
                blendShapeFrame.deltaTangents = new Vector3[blendShapeFrame.VertexCount];

                mesh.GetBlendShapeFrameVertices(shapeIndex, frameIndex,
                    blendShapeFrame.deltaVertices,
                    blendShapeFrame.deltaNormals,
                    blendShapeFrame.deltaTangents);
            }
        }

        string jsonStr = JsonUtility.ToJson(myBlendShapes);

        using (StreamWriter file = new StreamWriter(Path.Combine(Application.persistentDataPath, "OriginalBS.json")))
        {
            file.Write(jsonStr);
        }
    }

    public static void LoadBlendShapes(SkinnedMeshRenderer smr)
    {
        var mesh = smr.sharedMesh;

        UEBlendShapes myBlendShapes;

        using (StreamReader file = new StreamReader(Path.Combine(Application.persistentDataPath, "OriginalBS.json")))
        {
            // TODO: streaming
            string jsonStr = file.ReadToEnd();
            myBlendShapes = JsonUtility.FromJson<UEBlendShapes>(jsonStr);
        }

        foreach (var blendShape in myBlendShapes.BlendShapes)
        {
            foreach (var frame in blendShape.BlendShapeFrames)
            {
                mesh.AddBlendShapeFrame(blendShape.BlendShapeName,
                    frame.BlendShapeFrameWeight,
                    frame.deltaVertices,
                    frame.deltaNormals,
                    frame.deltaTangents);
            }
        }
    }
}
