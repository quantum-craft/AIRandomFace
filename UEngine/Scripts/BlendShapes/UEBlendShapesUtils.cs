using System;
using System.Collections.Generic;
using UnityEngine;

namespace UEUtils
{
    public class UEBlendShapesUtils
    {
        private static readonly UEBlendShapesUtils _instance = new UEBlendShapesUtils();
        private UEBlendShapesUtils() { }
        public static UEBlendShapesUtils Instance { get { return _instance; } }

        public SkinnedMeshRenderer m_CurrentFaceRenderer;

        public static string GetBlendShapeName(int idx, SkinnedMeshRenderer faceRenderer)
        {
            return faceRenderer.sharedMesh.GetBlendShapeName(idx);
        }

        public static IEnumerable<BlendShape> ParseBlendShapes(SkinnedMeshRenderer faceRenderer)
        {
            for (int index = 0; index < faceRenderer.sharedMesh.blendShapeCount; index++)
            {
                string shapeName = faceRenderer.sharedMesh.GetBlendShapeName(index);
                yield return ParseBlendShape(shapeName, index);
            }
        }

        // int count = name.Count(c => c == separator); // Requires LINQ.
        public static BlendShape ParseBlendShape(string name, int index)
        {
            string[] subStrings = name.Split('.');
            string[] components = subStrings[1].Split('_');

            try
            {
                if ((subStrings.Length - 1) != 1) { throw new Exception(name + " has " + (subStrings.Length - 1) + " \'" + '.' + "\'"); }
                if ((components.Length - 1) != 3) { throw new Exception(subStrings[1] + " has " + (components.Length - 1) + " \'" + '_' + "\'"); }
            }
            catch (Exception ex)
            {
                Debug.Log(ex.ToString());
            }

            return new BlendShape
            {
                ShapeIndex = index,
                Model = subStrings[0],
                Part = components[0],
                Operation = ParseOperation(components[1]),
                Axis = ParseAxis(components[2]),
                Magnitude = ParseMagnitude(components[3])
            };
        }

        public static List<BlendShape> ConstructBlendShapes(SkinnedMeshRenderer faceRenderer)
        {
            Instance.m_CurrentFaceRenderer = faceRenderer;

            var list = new List<BlendShape>();
            foreach (var shape in ParseBlendShapes(faceRenderer))
            {
                list.Add(shape);
            }

            return list;
        }

        public static Dictionary<string, AxisPair[]> ConstructBlendShapesMap(List<BlendShape> shapes)
        {
            var blendShapesMap = new Dictionary<string, AxisPair[]>();

            foreach (var shape in shapes)
            {
                if (!blendShapesMap.ContainsKey(shape.MapKey()))
                {
                    blendShapesMap.Add(shape.MapKey(), ConstructAxisPairs());
                }

                switch (shape.Magnitude)
                {
                    case Magnitude.Add:
                        if (blendShapesMap[shape.MapKey()][(int)shape.Axis].Add != -1)
                        {
                            throw new Exception("Replacing BlendShape idx: " + blendShapesMap[shape.MapKey()][(int)shape.Axis].Add +
                                    " " + GetBlendShapeName(blendShapesMap[shape.MapKey()][(int)shape.Axis].Add, Instance.m_CurrentFaceRenderer) +
                                    " with idx: " + shape.ShapeIndex + " " + GetBlendShapeName(shape.ShapeIndex, Instance.m_CurrentFaceRenderer) +
                                    " . Please check the names of these BlendShapes.");
                        }
                        blendShapesMap[shape.MapKey()][(int)shape.Axis].Add = shape.ShapeIndex;
                        break;
                    case Magnitude.Sub:
                        if (blendShapesMap[shape.MapKey()][(int)shape.Axis].Sub != -1)
                        {
                            throw new Exception("Replacing BlendShape idx: " + blendShapesMap[shape.MapKey()][(int)shape.Axis].Sub +
                                    " " + GetBlendShapeName(blendShapesMap[shape.MapKey()][(int)shape.Axis].Sub, Instance.m_CurrentFaceRenderer) +
                                    " with idx: " + shape.ShapeIndex + " " + GetBlendShapeName(shape.ShapeIndex, Instance.m_CurrentFaceRenderer) +
                                    " . Please check the names of these BlendShapes.");
                        }
                        blendShapesMap[shape.MapKey()][(int)shape.Axis].Sub = shape.ShapeIndex;
                        break;
                    default:
                        throw new Exception("Magnitude: " + shape.Magnitude.ToString() + " is neither add nor sub.");
                }
            }

            return blendShapesMap;
        }

        public static AxisPair[] ConstructAxisPairs()
        {
            var axisPairs = new AxisPair[(int)Axis.ENUM_MAX];

            for (int i = 0; i < (int)Axis.ENUM_MAX; i++)
            {
                axisPairs[i] = new AxisPair { };
            }

            return axisPairs;
        }

        public static void ValidateBlendShapeMap(SkinnedMeshRenderer faceRenderer, Dictionary<string, AxisPair[]> map)
        {
            int totalRegisteredShapeCount = 0;
            foreach (var pairs in map)
            {
                var key = pairs.Key;
                var value = pairs.Value;

                for (int i = 0; i < value.Length; i++)
                {
                    if (value[i].Add != -1) { totalRegisteredShapeCount++; }
                    if (value[i].Sub != -1) { totalRegisteredShapeCount++; }
                }
            }

            if (totalRegisteredShapeCount != faceRenderer.sharedMesh.blendShapeCount)
            {
                throw new Exception("UI Registered BlendShapes count: " + totalRegisteredShapeCount +
                                    " does not equal to total count: " + faceRenderer.sharedMesh.blendShapeCount);
            }
        }

        public static float GetBlendShapeAxisValue(SkinnedMeshRenderer faceRenderer, int addIndex, int subIndex)
        {
            float addValue = addIndex >= 0 ? faceRenderer.GetBlendShapeWeight(addIndex) : 0.0f;
            float subValue = subIndex >= 0 ? faceRenderer.GetBlendShapeWeight(subIndex) : 0.0f;

            if (addValue > 0 && subValue > 0)
            {
                Debug.LogError("Blendshape index: " + addIndex + " and " + subIndex + "value conflict");
            }

            return addValue > 0.0f ? addValue : -subValue;
        }

        public static void SetBlendShapeAxisValue(SkinnedMeshRenderer faceRenderer, float value, int addIndex, int subIndex)
        {
            if (value > 0.0f)
            {
                if (addIndex >= 0) { faceRenderer.SetBlendShapeWeight(addIndex, Mathf.Clamp(value, 0.0f, 100.0f)); }
                if (subIndex >= 0) { faceRenderer.SetBlendShapeWeight(subIndex, 0.0f); }
            }
            else
            {
                if (addIndex >= 0) { faceRenderer.SetBlendShapeWeight(addIndex, 0.0f); }
                if (subIndex >= 0) { faceRenderer.SetBlendShapeWeight(subIndex, Mathf.Clamp(-value, 0.0f, 100.0f)); }
            }
        }

        public class BlendShape
        {
            public int ShapeIndex = -1;
            public Model Model = "None";
            public Part Part = "None";
            public Operation Operation = Operation.ENUM_NONE;
            public Axis Axis = Axis.ENUM_NONE;
            public Magnitude Magnitude = Magnitude.ENUM_NONE;

            public string MapKey()
            {
                return ToMapKey(Part, Operation);
            }

            public static string ToMapKey(Part part, Operation operation)
            {
                return part + ' ' + operation.ToString();
            }

            public static Part KeyToPart(string key)
            {
                string[] subStrings = key.Split(' ');
                return subStrings[0];
            }

            public static Operation KeyToOperation(string key)
            {
                string[] subStrings = key.Split(' ');
                return ParseOperation(subStrings[1]);
            }
        }

        public struct Model
        {
            private string value;

            private Model(string value)
            {
                this.value = value;
            }

            public static implicit operator Model(string value)
            {
                return new Model(value);
            }

            public static implicit operator string(Model model)
            {
                return model.value;
            }
        }

        public struct Part
        {
            private string value;

            private Part(string value)
            {
                this.value = value;
            }

            public static implicit operator Part(string value)
            {
                return new Part(value);
            }

            public static implicit operator string(Part part)
            {
                return part.value;
            }
        }

        public enum Operation { ENUM_NONE = -1, Position, Scale, Rotation, ENUM_MAX };
        public static Operation ParseOperation(string component)
        {
            switch (component.ToLower())
            {
                case "position":
                case "p":
                case "po":
                    return Operation.Position;
                case "scale":
                case "s":
                case "sc":
                    return Operation.Scale;
                case "rotation":
                case "r":
                case "ro":
                    return Operation.Rotation;
                default:
                    throw new Exception("Operation: " + component + " is strange!");
            }
        }

        public enum Axis { ENUM_NONE = -1, X, Y, Z, Total, ENUM_MAX };
        public static Axis ParseAxis(string component)
        {
            switch (component.ToLower())
            {
                case "x":
                    return Axis.X;
                case "y":
                    return Axis.Y;
                case "z":
                    return Axis.Z;
                case "total":
                case "t":
                    return Axis.Total;
                default:
                    throw new Exception("Axis: " + component + " is strange!");
            }
        }

        public enum Magnitude { ENUM_NONE = -1, Add, Sub, ENUM_MAX };
        public static Magnitude ParseMagnitude(string component)
        {
            switch (component.ToLower())
            {
                case "add":
                case "a":
                    return Magnitude.Add;
                case "sub":
                case "s":
                    return Magnitude.Sub;
                default:
                    throw new Exception("Magnitude: " + component + " is neither add nor sub.");
            }
        }

        public class AxisPair
        {
            public int Add = -1;
            public int Sub = -1;
        }
    }
}
