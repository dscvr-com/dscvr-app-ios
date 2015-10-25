//
//  Distortion.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class Distortion {
    private let coefficients : [Float]
    
    init() {
        coefficients = [0.441, 0.156]
    }
    
    init(coefficients : [Float]) {
        self.coefficients = coefficients
    }
    
    func distortionFactor(radius : Float) -> Float {
        var result = Float(1.0)
        var factor = Float(1.0)
        let squared = radius * radius
        for coeff in coefficients {
            factor = factor * squared
            result = result + coeff * factor
        }
        
        return result
    }
    
    func distort(radius : Float) -> Float {
        return radius * distortionFactor(radius)
    }
    
    func distortInverse(radius : Float) -> Float {
        var r0 = radius / Float(0.9);
        var r1 = radius * Float(0.9);
        var dr0 = radius - distort(r0);
        while abs(r1 - r0) > Float(0.0001) {
            let dr1 = radius - distort(r1)
            let r2 = r1 - dr1 * ((r1 - r0) / (dr1 - dr0))
            r0 = r1
            r1 = r2
            dr0 = dr1
        }
        return r1
    }
}