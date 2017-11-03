//
//  ARViewController.swift
//  
//
//  Created by zixin cheng on 11/3/17.
//

import Foundation
import UIKit
import SceneKit
import ARKit

class ARViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate{
    
    @IBOutlet weak var arView: ARSCNView!
    
    override func viewDidAppear(_ animated: Bool) {
        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
         */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        arView.session.run(configuration)
        
        // Set a delegate to track the number of plane anchors for providing UI feedback.
        arView.session.delegate = self
    }
}

