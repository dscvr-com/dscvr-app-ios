//
//  EditProfileViewController.swift
//  Optonaut
//
//  Created by Johannes Schickling on 6/17/15.
//  Copyright © 2015 Optonaut. All rights reserved.
//

import UIKit
import ReactiveSwift
import Result
import Mixpanel
import Async
import AVFoundation
import ObjectMapper
import SpriteKit

class SaveViewController: UIViewController, RedNavbar {
    
    fileprivate let viewModel: SaveViewModel

    fileprivate let readyNotification = NotificationSignal<Void>()
    
    required init(recorderCleanup: SignalProducer<UIImage, NoError>) {
        
        let (placeholderSignal, placeholderSink) = Signal<UIImage, NoError>.pipe()
        
        viewModel = SaveViewModel(placeholderSignal: placeholderSignal, readyNotification: readyNotification)
        
        super.init(nibName: nil, bundle: nil)
        
        recorderCleanup
            .start(on: QueueScheduler(qos: .background, name: "RecorderQueue", targeting: nil))
            .on(event: { event in
                placeholderSink.action(event)
            })
            .map { SKTexture(image: $0) }
            .observeOnMain()
            .on(
                completed: { [weak self] in
                    print("stitching finished")
                    self?.viewModel.stitcherFinished.value = true
                    SwiftSpinner.hide()
                    self?.tabController!.cameraButton.isHidden = false
                    self?.onTapCameraButton()
                },
                value: { [weak self] image in
                }
            )
            .start()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    deinit {
        logRetain()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        readyNotification.notify(())
        
        title = "RENDERING 360 IMAGE"
        
        var cancelButton = UIImage(named: "camera_back_button")
        
        cancelButton = cancelButton?.withRenderingMode(UIImageRenderingMode.alwaysOriginal)
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: cancelButton, style: UIBarButtonItemStyle.plain, target: self, action: #selector(self.cancel))
        
        view.backgroundColor = .white


        viewModel.isReadyForSubmit.producer.startWithValues { [weak self] isReady in
            self?.tabController!.cameraButton.loading = !isReady
        }
        
        viewModel.isReadyForStitching.producer
            .filter(isTrue)
            .startWithValues { [weak self] _ in
                if let strongSelf = self {
                    PipelineService.stitch(strongSelf.viewModel.optograph.ID)
                }
            }
    }

    func readyToSubmit(){
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
    func postLaterAction(){
        if viewModel.isReadyForSubmit.value {
            submit(false)
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        updateNavbarAppear()
        
        navigationController?.setNavigationBarHidden(false, animated: false)
        UIApplication.shared.setStatusBarHidden(true, with: .none)
        
        navigationController?.navigationBar.titleTextAttributes = [
            NSFontAttributeName: UIFont.fontDisplay(14, withType: .Regular),
            NSForegroundColorAttributeName: UIColor(hex:0xFF5E00),
        ]
        
        tabController!.delegate = self
        tabController!.cameraButton.progressLocked = true
        
        Mixpanel.sharedInstance()?.timeEvent("View.CreateOptograph")
        tabController!.cameraButton.isHidden = true
        SwiftSpinner.show("Stitching in progress")
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        tabController!.cameraButton.progressLocked = false

        navigationController?.interactivePopGestureRecognizer?.isEnabled = true
        UIApplication.shared.setStatusBarHidden(false, with: .none)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        Mixpanel.sharedInstance()?.track("View.CreateOptograph")
    }

    dynamic fileprivate func cancel() {
        let confirmAlert = UIAlertController(title: "Discard Moment?", message: "If you go back now, the recording will be discarded.", preferredStyle: .alert)
        confirmAlert.addAction(UIAlertAction(title: "Discard", style: .destructive, handler: { _ in
            PipelineService.stopStitching()
            LoadingIndicatorView.show("Discarding..")
            self.viewModel.isReadyForSubmit.producer.skipRepeats().startWithValues { val in
                if val{
                    LoadingIndicatorView.hide()
                    self.viewModel.deleteOpto()
                    self.navigationController!.popViewController(animated: true)
                }
            }
        }))
        confirmAlert.addAction(UIAlertAction(title: "Keep", style: .cancel, handler: nil))
        navigationController!.present(confirmAlert, animated: true, completion: nil)
    }
    
    func dismissKeyboard() {
        view.endEditing(true)
    }
    
    
    fileprivate func submit(_ shouldBePublished: Bool) {
        viewModel.submit(shouldBePublished, directionPhi: Double(0), directionTheta: Double(0))
            .observeOnMain()
            .on(
                started: { [weak self] in
                    self?.tabController!.cameraButton.loading = true
                },
                completed: { [weak self] in
                    Mixpanel.sharedInstance()?.track("Action.CreateOptograph.Post")
                    self?.navigationController!.popViewController(animated: true)
                }
            )
            .start()
    }
}

// MARK: - TabControllerDelegate
extension SaveViewController: TabControllerDelegate {
    
    func onTapCameraButton() {
        if viewModel.isReadyForSubmit.value {
            submit(true)
        }
    }
}
