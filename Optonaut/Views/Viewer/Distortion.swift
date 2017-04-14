//
//  Distortion.swift
//  Optonaut
//
//  Created by Emi on 25/10/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import Foundation

class Distortion {
    let coefficients : [Float]
    
    init() {
        coefficients = [0.441, 0.156]
    }
    
    init(coefficients : [Float]) {
        self.coefficients = coefficients
    }
    
    func distortionFactor(_ radius : Float) -> Float {
        var result = Float(1.0)
        var factor = Float(1.0)
        let squared = radius * radius
        for coeff in coefficients {
            factor = factor * squared
            result = result + coeff * factor
        }
        
        return result
    }
    
    func distort(_ radius : Float) -> Float {
        return radius * distortionFactor(radius)
    }
    
    func distortInverse(_ radius : Float) -> Float {
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
    
    static func solveLeastSquares(_ matA: [[Double]], vecY: [Double]) -> [Double] {
        let numSamples = matA.count
        let numCoefficients = matA[0].count
        
        assert(numCoefficients == 2) //Only 2 coeffs supported atm due to inversion.
    
        var matATA = [[Double]](repeating: [Double](repeating: 0, count: numCoefficients), count: numCoefficients)
        
        for k in 0..<numCoefficients {
            for j in 0..<numCoefficients {
                var sum = Double(0.0)
                for  i in 0..<numSamples {
                    sum += matA[i][j] * matA[i][k]
                }
                matATA[j][k] = sum;
            }
        }
        
        var matInvATA = [[Double]](repeating: [Double](repeating: 0, count: numCoefficients), count: numCoefficients)
        
        let det: Double = matATA[0][0] * matATA[1][1] - matATA[0][1] * matATA[1][0]
        
        matInvATA[0][0] = (matATA[1][1] / det)
        matInvATA[1][1] = (matATA[0][0] / det)
        matInvATA[0][1] = (-matATA[1][0] / det)
        matInvATA[1][0] = (-matATA[0][1] / det)
    
        var vecATY = [Double](repeating: 0, count: numCoefficients)
        for j in 0..<numCoefficients {
            var sum = Double(0.0)
            for i in 0..<numSamples {
                sum += matA[i][j] * vecY[i]
            }
            vecATY[j] = sum
        }
        var vecX = [Double](repeating: 0, count: numCoefficients)
        for j in 0..<numCoefficients {
            var sum = Double(0.0)
            for i in 0..<numCoefficients {
                sum += matInvATA[i][j] * vecATY[i]
            }
            vecX[j] = sum
        }
        return vecX;
    }
    
    func getApproximateInverseDistortion(_ maxRadius: Float) -> Distortion {
        let numSamples = 10
        let numCoefficients = 2
        
        var matA = [[Double]](repeating: [Double](repeating: 0, count: numCoefficients), count: numSamples)
        var vecY = [Double](repeating: 0, count: numSamples)
        
        for i in 0..<numSamples {
            let r = Double(maxRadius) * Double(i + 1) / Double(numSamples);
            let rp = Double(distort(Float(r)))
            var v = rp;
            for j in 0..<numCoefficients {
                v *= rp * rp
                matA[i][j] = v
            }
            vecY[i] = (r - rp)
        }
        let vecK = Distortion.solveLeastSquares(matA, vecY: vecY);
    
        var newCoefficients = [Float](repeating: 0, count: vecK.count)
        for i in 0..<vecK.count {
            newCoefficients[i] = Float(vecK[i])
        }

        return Distortion(coefficients: newCoefficients);
    }
}
