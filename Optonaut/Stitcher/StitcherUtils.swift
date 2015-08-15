//
//  StitcherUtils.swift
//  Optonaut
//

import Foundation
import GLKit
import CoreMotion

func CMRotationToGLKMatrix4(r: CMRotationMatrix) -> GLKMatrix4{
    return GLKMatrix4Make(Float(r.m11), Float(r.m12), Float(r.m13), 0,
        Float(r.m21), Float(r.m22), Float(r.m23), 0,
        Float(r.m31), Float(r.m32), Float(r.m33), 0,
        0,     0,     0,     1)
}

