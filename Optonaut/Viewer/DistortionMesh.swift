//
//  DistortionMesh.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation
import SceneKit

class DistortionMesh {
    static let BytesPerFloat = sizeof(CFloat)
    static let BytesPerShort = sizeof(CShort)
    static let ComponentsPerVertex = 4
    static let Rows = 40
    static let Cols = 40
    
    static func clamp(val: Float, minVal: Float, maxVal: Float) -> Float
    {
        return max(minVal, min(maxVal, val))
    }
    
    private let vertexBuffer: SCNGeometrySource
    private let texCoordBuffer: SCNGeometrySource
    private let indexBuffer: SCNGeometryElement
    
    private var vertexData = [CFloat](count: DistortionMesh.Cols * DistortionMesh.Rows * DistortionMesh.ComponentsPerVertex, repeatedValue: 0)
    private var indexData = [CShort](count: (DistortionMesh.Rows - 1) * DistortionMesh.Cols * 2 + (DistortionMesh.Rows - 2), repeatedValue: 0)
    let geometry: SCNGeometry
    
    init(distortion: Distortion,
        screenWidth: Float, screenHeight: Float,
        xEyeOffsetScreen: Float, yEyeOffsetScreen: Float,
        textureWidth: Float, textureHeight: Float,
        xEyeOffsetTexture: Float, yEyeOffsetTexture: Float,
        viewportXTexture: Float, viewportYTexture: Float,
        viewportWidthTexture: Float, viewportHeightTexture: Float,
        flip180: Bool, vignetteEnabled: Bool) {
            
            var vertexOffset: Int = 0
            
            for row in 0..<DistortionMesh.Rows {
                for col in 0..<DistortionMesh.Cols {
                    
                    
                    var uTexture = Float(col) / Float(DistortionMesh.Cols - 1) * (viewportWidthTexture / textureWidth) + viewportXTexture / textureWidth
                    
                    var vTexture = Float(row) / Float(DistortionMesh.Rows - 1) * (viewportHeightTexture / textureHeight) + viewportYTexture / textureHeight
                    
                    let xTexture = uTexture * textureWidth - xEyeOffsetTexture
                    let yTexture = vTexture * textureHeight - yEyeOffsetTexture
                    let rTexture = Float(sqrt(xTexture * xTexture + yTexture * yTexture))
                    
                    let textureToScreen = rTexture > Float(0.0) ? distortion.distortInverse(rTexture) / rTexture : Float(1.0);
                    
                    let xScreen = xTexture * textureToScreen;
                    let yScreen = yTexture * textureToScreen;
                    
                    let uScreen = (xScreen + xEyeOffsetScreen) / screenWidth;
                    let vScreen = (yScreen + yEyeOffsetScreen) / screenHeight;
                    
                    if flip180 {
                        uTexture = Float(1.0) - uTexture
                        vTexture = Float(1.0) - vTexture
                    }
                    
                    vertexData[vertexOffset + 0] = (2.0 * uScreen - 1.0);
                    vertexData[vertexOffset + 1] = (2.0 * vScreen - 1.0);
                    vertexData[vertexOffset + 2] = uTexture;
                    vertexData[vertexOffset + 3] = vTexture;
                    
                    vertexOffset = (vertexOffset + DistortionMesh.ComponentsPerVertex);
                }
            }
            var indexOffset = 0
            vertexOffset = 0
            
            for row in 0..<(DistortionMesh.Rows - 1) {
                if row > 0 {
                    indexData[indexOffset] = indexData[indexOffset - 1]
                    indexOffset = indexOffset + 1
                }
                for col in 0..<DistortionMesh.Cols {
                    if col > 0 {
                        if row % 2 == 0 {
                            vertexOffset = vertexOffset + 1
                        } else {
                            vertexOffset = vertexOffset - 1
                        }
                    }
                    
                    indexOffset = indexOffset + 1
                    indexData[indexOffset] = CShort(vertexOffset)
                    indexOffset = indexOffset + 1
                    indexData[indexOffset] = CShort(vertexOffset + DistortionMesh.Cols)
                }
                vertexOffset = vertexOffset + DistortionMesh.Cols
            }
   
            vertexBuffer = SCNGeometrySource(data: NSData(bytes: vertexData, length: vertexData.count * DistortionMesh.BytesPerFloat),
                semantic: SCNGeometrySourceSemanticVertex,
                vectorCount: vertexData.count,
                floatComponents: true,
                componentsPerVector: 2,
                bytesPerComponent: DistortionMesh.BytesPerFloat,
                dataOffset: 0,
                dataStride: DistortionMesh.ComponentsPerVertex * DistortionMesh.BytesPerFloat)
            
            texCoordBuffer = SCNGeometrySource(data: NSData(bytes: vertexData, length: vertexData.count * DistortionMesh.BytesPerFloat),
                semantic: SCNGeometrySourceSemanticTexcoord,
                vectorCount: vertexData.count,
                floatComponents: true,
                componentsPerVector: 2,
                bytesPerComponent: DistortionMesh.BytesPerFloat,
                dataOffset: 2,
                dataStride: DistortionMesh.ComponentsPerVertex * DistortionMesh.BytesPerFloat)
            
            
            indexBuffer = SCNGeometryElement(data: NSData(bytes: indexData, length: indexData.count * DistortionMesh.BytesPerShort), primitiveType: .TriangleStrip, primitiveCount: indexData.count, bytesPerIndex: DistortionMesh.BytesPerShort)
            
            geometry = SCNGeometry(sources: [vertexBuffer, texCoordBuffer], elements: [indexBuffer])
    }
}
