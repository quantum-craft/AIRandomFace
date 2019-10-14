using System.IO;
using System.Linq;
using UnityEngine;
using System.Collections.Generic;
using System;
using System.Text;

public class UEBlendShapeSerializer
{
    // private const float thredshold = 1e-10f;
    private const float thredshold = 0.0f;

    public static byte[] GetCompressedBlendshapesData(Mesh mesh)
    {
        Debug.Log("UEBlendshape: Get Compressed data");
        List<byte> resultBytes = new List<byte>();
        int blendShapeCount = mesh.blendShapeCount;
        resultBytes.AddRange(BitConverter.GetBytes(blendShapeCount));
        Vector3[] deltaVertices = new Vector3[mesh.vertexCount];
        Vector3[] deltaNormals = new Vector3[mesh.vertexCount];
        Vector3[] deltaTangents = new Vector3[mesh.vertexCount];

        int[] segmentStartList = null;
        int[] segmentSizeList = null;
        int segmentCapacity = 0;

        for (int blendShapeIndex = 0; blendShapeIndex < blendShapeCount; blendShapeIndex++)
        {
            var blendShapeName = mesh.GetBlendShapeName(blendShapeIndex);
            byte[] bytes = System.Text.Encoding.ASCII.GetBytes(blendShapeName);

            resultBytes.AddRange(bytes);
            resultBytes.Add(0);
            int blendShapeFrameCount = mesh.GetBlendShapeFrameCount(blendShapeIndex);
            resultBytes.AddRange(BitConverter.GetBytes(blendShapeFrameCount));

            for (int frameIndex = 0; frameIndex < blendShapeFrameCount; frameIndex++)
            {
                float blendShapeFrameWeight = mesh.GetBlendShapeFrameWeight(blendShapeIndex, frameIndex);
                resultBytes.AddRange(BitConverter.GetBytes(blendShapeFrameWeight));

                mesh.GetBlendShapeFrameVertices(blendShapeIndex, frameIndex, deltaVertices, deltaNormals, deltaTangents);

                int segmentCount = getSegmentCount(deltaVertices);
                if (segmentCapacity < segmentCount)
                {
                    segmentStartList = new int[segmentCount];
                    segmentSizeList = new int[segmentCount];
                    segmentCapacity = segmentCount;
                }
                parseBlendShapeData(deltaVertices, segmentStartList, segmentSizeList);
                vectorListToBytes(deltaVertices, segmentStartList, segmentSizeList, segmentCount, resultBytes);

                segmentCount = getSegmentCount(deltaNormals);
                if (segmentCapacity < segmentCount)
                {
                    segmentStartList = new int[segmentCount];
                    segmentSizeList = new int[segmentCount];
                    segmentCapacity = segmentCount;
                }
                parseBlendShapeData(deltaNormals, segmentStartList, segmentSizeList);
                vectorListToBytes(deltaNormals, segmentStartList, segmentSizeList, segmentCount, resultBytes);

                segmentCount = getSegmentCount(deltaTangents);
                if (segmentCapacity < segmentCount)
                {
                    segmentStartList = new int[segmentCount];
                    segmentSizeList = new int[segmentCount];
                    segmentCapacity = segmentCount;
                }
                parseBlendShapeData(deltaTangents, segmentStartList, segmentSizeList);
                vectorListToBytes(deltaTangents, segmentStartList, segmentSizeList, segmentCount, resultBytes);
            }
        }
        return resultBytes.ToArray();
    }

    private static int getSegmentCount(Vector3[] vectorList)
    {
        int segmentCount = 0;
        bool isInSegment = false;
        int vertexCount = vectorList.Count();
        for (int vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
        {
            if (vectorList[vertexIndex].sqrMagnitude > thredshold)
            {
                if (!isInSegment)
                {
                    isInSegment = true;
                    segmentCount++;
                }
            }
            else
            {
                isInSegment = false;
            }
        }
        return segmentCount;
    }

    private static void parseBlendShapeData(Vector3[] vectorList, int[] segmentStartList, int[] segmentSizeList)
    {
        bool isInSegment = false;
        int segmentSize = 0;
        int vertexCount = vectorList.Count();
        int segmentIndex = 0;
        for (int vertexIndex = 0; vertexIndex < vertexCount; vertexIndex++)
        {
            if (vectorList[vertexIndex].sqrMagnitude > thredshold)
            {
                if (!isInSegment)
                {
                    isInSegment = true;
                    segmentStartList[segmentIndex] = vertexIndex;
                    segmentSize++;
                }
                else
                {
                    segmentSize++;
                }
            }
            else
            {
                if (isInSegment)
                {
                    isInSegment = false;
                    segmentSizeList[segmentIndex] = segmentSize;
                    segmentIndex++;
                    segmentSize = 0;
                }
            }
        }
        if (isInSegment)
        {
            segmentSizeList[segmentIndex] = segmentSize;
        }
    }

    private static void vectorListToBytes(Vector3[] vectorList, int[] segmentStartList, int[] segmentSizeList, int segmentCount, List<byte> outBytes)
    {
        outBytes.AddRange(BitConverter.GetBytes(segmentCount));
        for (int segmentIndex = 0; segmentIndex < segmentCount; segmentIndex++)
        {
            outBytes.AddRange(BitConverter.GetBytes(segmentStartList[segmentIndex]));
            outBytes.AddRange(BitConverter.GetBytes(segmentSizeList[segmentIndex]));
            for (int index = 0; index < segmentSizeList[segmentIndex]; index++)
            {
                outBytes.AddRange(BitConverter.GetBytes(vectorList[segmentStartList[segmentIndex] + index].x));
                outBytes.AddRange(BitConverter.GetBytes(vectorList[segmentStartList[segmentIndex] + index].y));
                outBytes.AddRange(BitConverter.GetBytes(vectorList[segmentStartList[segmentIndex] + index].z));
            }
        }
    }

    private static int bytesToVectorList(byte[] bytes, Vector3[] vectorList, int pointer)
    {
        int segmentCount = BitConverter.ToInt32(bytes, pointer);
        pointer += 4;

        for (int segmentIndex = 0; segmentIndex < segmentCount; segmentIndex++)
        {
            int segmentStart = BitConverter.ToInt32(bytes, pointer);
            pointer += 4;

            int segmentSize = BitConverter.ToInt32(bytes, pointer);
            pointer += 4;

            for (int index = 0; index < segmentSize; index++)
            {
                vectorList[segmentStart + index].x = BitConverter.ToSingle(bytes, pointer);
                pointer += 4;
                vectorList[segmentStart + index].y = BitConverter.ToSingle(bytes, pointer);
                pointer += 4;
                vectorList[segmentStart + index].z = BitConverter.ToSingle(bytes, pointer);
                pointer += 4;
            }
        }
        return pointer;
    }

    public static void SetBlendshapesData(Mesh mesh, byte[] compressedData)
    {
        Debug.Log("UEBlendshape: Set Compressed data");

        int pointer = 0;
        int vertexCount = mesh.vertexCount;

        int blendShapeCount = BitConverter.ToInt32(compressedData, pointer);
        pointer += 4;

        for (int blendShapeIndex = 0; blendShapeIndex < blendShapeCount; blendShapeIndex++)
        {
            int endPointer = pointer;
            for (; compressedData[endPointer] != 0; endPointer++) ;

            string blendShapeName = Encoding.ASCII.GetString(compressedData, pointer, endPointer - pointer);
            pointer = endPointer + 1;

            int blendShapeFrameCount = BitConverter.ToInt32(compressedData, pointer);
            pointer += 4;

            for (int frameIndex = 0; frameIndex < blendShapeFrameCount; frameIndex++)
            {
                Vector3[] deltaVertices = new Vector3[vertexCount];
                Vector3[] deltaNormals = new Vector3[vertexCount];
                Vector3[] deltaTangents = new Vector3[vertexCount];

                float blendShapeFrameWeight = BitConverter.ToSingle(compressedData, pointer);
                pointer += 4;

                pointer = bytesToVectorList(compressedData, deltaVertices, pointer);
                pointer = bytesToVectorList(compressedData, deltaNormals, pointer);
                pointer = bytesToVectorList(compressedData, deltaTangents, pointer);

                mesh.AddBlendShapeFrame(blendShapeName, blendShapeFrameWeight, deltaVertices, deltaNormals, deltaTangents);
            }
        }
    }
}
