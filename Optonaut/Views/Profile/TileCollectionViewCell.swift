//
//  TileCollectionViewCell.swift
//  Optonaut
//
//  Created by Johannes Schickling on 24/01/2016.
//  Copyright © 2016 Optonaut. All rights reserved.
//

import Foundation
import SpriteKit
import ReactiveCocoa
import SceneKit

class TileCollectionViewCell: UICollectionViewCell {
    
//    private let renderDelegate: CubeRenderDelegate
//    private let scnView: SCNView
    private let iconView = UILabel()
    private let loadingView = UIActivityIndicatorView()
    
    private let viewModel = TileCollectionViewModel()
    
    private let glView: OpenGLView
    
    override init(frame: CGRect) {
        
        glView = OpenGLView(frame: CGRect(origin: CGPointZero, size: frame.size))
        
//        if #available(iOS 9.0, *) {
//            scnView = SCNView(frame: CGRect(origin: CGPointZero, size: frame.size), options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
//        } else {
//            scnView = SCNView(frame: frame)
//        }
//        scnView = SCNView(frame: CGRect(origin: CGPointZero, size: frame.size), options: [SCNPreferredRenderingAPIKey: SCNRenderingAPI.OpenGLES2.rawValue])
        
//        renderDelegate = CubeRenderDelegate(rotationMatrixSource: CoreMotionRotationSource.Instance, width: scnView.frame.width, height: scnView.frame.height, fov: Double(HorizontalFieldOfView))
        
        super.init(frame: frame)
        
        contentView.addSubview(glView)
        
//        scnView.playing = UIDevice.currentDevice().deviceType != .Simulator
//        scnView.playing = false
//        
//        scnView.scene = renderDelegate.scene
//        scnView.delegate = renderDelegate
//        scnView.backgroundColor = .clearColor()
//        contentView.addSubview(scnView)
        
        iconView.frame = CGRect(x: frame.width - 32, y: 14, width: 18, height: 18)
        iconView.textColor = .whiteColor()
        iconView.font = UIFont.iconOfSize(18)
        iconView.rac_text <~ viewModel.isPrivate.producer
            .combineLatestWith(viewModel.uploadStatus.producer)
            .combineLatestWith(viewModel.isStitched.producer).map { ($0.0, $0.1, $1) }
            .map { isPrivate, uploadStatus, isStitched in
                if isStitched {
                    return ""
                } else if isPrivate {
                    return String.iconWithName(.Safe)
                } else if uploadStatus == .Offline {
                    return String.iconWithName(.ArrowDown)
                } else {
                    return ""
                }
            }
        contentView.addSubview(iconView)
        
        loadingView.frame = CGRect(origin: CGPointZero, size: frame.size)
        loadingView.backgroundColor = UIColor.blackColor().alpha(0.7)
        loadingView.hidesWhenStopped = true
        loadingView.rac_animating <~ viewModel.isStitched.producer.map(negate)
        contentView.addSubview(loadingView)
        
        contentView.backgroundColor = UIColor(0xcacaca)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
    }
    
    func setImage(texture: SKTexture, forIndex index: CubeImageCache.Index) {
//        renderDelegate.setTexture(texture, forIndex: index)
//        scnView.prepareObject(renderDelegate.planes[index]!, shouldAbortBlock: nil)
//        Async.main { [weak self] in
////            self?.loadingStatus.value = isPreview ? .Preview : .Loaded
//            self?.loadingStatus.value = .Loaded
//        }
    }
    
    func bind(optographID: UUID) {
        viewModel.bind(optographID)
    }
    
}