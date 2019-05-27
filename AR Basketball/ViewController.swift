//
//  ViewController.swift
//  AR Basketball
//
//  Created by Михаил Медведев on 23/05/2019.
//  Copyright © 2019 Михаил Медведев. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController {
    
    @IBOutlet var sceneView: ARSCNView!
    
    var ballsCounter = 0
    var score = 0
    
    var isHoopPlaced = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
        //set the contact delegate
        sceneView.scene.physicsWorld.contactDelegate = self
        
        // Show statistics such as fps and timing information
        sceneView.showsStatistics = true
        
        //enable auto light
        sceneView.autoenablesDefaultLighting = true
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration
        let configuration = ARWorldTrackingConfiguration()
        
        //Allow vertical plane detection
        configuration.planeDetection = [.vertical]
        
        // Run the view's session
        sceneView.session.run(configuration)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
}


// MARK: - IB Actions
extension ViewController {
    
    @IBAction func screenTapped(_ sender: UITapGestureRecognizer) {
        
        if isHoopPlaced {
            createBasketball()
        } else {
            let location = sender.location(in: sceneView)
            guard let result = sceneView.hitTest(location, types: [.existingPlaneUsingExtent]).first else { return }
            
            addHopp(at: result)
            print(#function, #line ,"Found existing plane")
        }
        
    }
}

// MARK: - Placing Hoop
extension ViewController {
    
    /// Places Hoop at hit test point
    ///
    /// - Parameter result: ARHitTestResult
    func addHopp(at result: ARHitTestResult) {
        let hoopScene = SCNScene(named: "art.scnassets/Hoop.scn")
        
        guard let hoopNode = hoopScene?.rootNode.childNode(withName: "Hoop", recursively: false) else { return }
        
        hoopNode.simdTransform = result.worldTransform //перезаписывает все параметры, поэтому код ниже под этой строчкой
        hoopNode.eulerAngles.x -= .pi / 2
        hoopNode.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: hoopNode, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        ///create cheking planes for score counting
        guard let topPlane = hoopScene?.rootNode.childNode(withName: "Top plane", recursively: false) else { return }
        guard let bottomPlane = hoopScene?.rootNode.childNode(withName: "Bottom plane", recursively: false) else { return }
        
        topPlane.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: topPlane, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        bottomPlane.physicsBody = SCNPhysicsBody(type: .static, shape: SCNPhysicsShape(node: bottomPlane, options: [SCNPhysicsShape.Option.type: SCNPhysicsShape.ShapeType.concavePolyhedron]))
        
        topPlane.physicsBody!.categoryBitMask = ObjectCollisionCategory.topPlane.rawValue
        topPlane.physicsBody!.collisionBitMask = ObjectCollisionCategory.none.rawValue
        topPlane.physicsBody!.contactTestBitMask = ObjectCollisionCategory.ball.rawValue
        
        bottomPlane.physicsBody!.categoryBitMask = ObjectCollisionCategory.bottomPlane.rawValue
        bottomPlane.physicsBody!.collisionBitMask = ObjectCollisionCategory.none.rawValue
        bottomPlane.physicsBody!.contactTestBitMask = ObjectCollisionCategory.ball.rawValue
 
        //remove all nodes named "Wall"
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Wall" {
                node.removeFromParentNode()
            }
        }
        
        //Add the hoop to the scene
        sceneView.scene.rootNode.addChildNode(topPlane)
        sceneView.scene.rootNode.addChildNode(bottomPlane)
        sceneView.scene.rootNode.addChildNode(hoopNode)
        isHoopPlaced = true
    }
    
   

    /// Creaate ball for throwing
    func createBasketball() {
        //текущий кадр
        guard let frame = sceneView.session.currentFrame else { return }
        
        let ball = SCNNode(geometry: SCNSphere(radius: 0.25))
        ball.geometry?.firstMaterial?.diffuse.contents = UIImage(named: "ball")
        ball.name = "Ball"
        
        let cameraTransform = SCNMatrix4(frame.camera.transform)
        ball.transform = cameraTransform
        
        let physicsBody = SCNPhysicsBody(type: .dynamic, shape: SCNPhysicsShape(node: ball))
        ball.physicsBody = physicsBody
        physicsBody.categoryBitMask = ObjectCollisionCategory.ball.rawValue
        physicsBody.contactTestBitMask = ObjectCollisionCategory.topPlane.rawValue | ObjectCollisionCategory.bottomPlane.rawValue
       
        
        let throwPower = Float(10)
        let x = -cameraTransform.m31 * throwPower
        let y = -cameraTransform.m32 * throwPower
        let z = -cameraTransform.m33 * throwPower
        
        let throwForce = SCNVector3(x, y, z)
        ball.physicsBody?.applyForce(throwForce, asImpulse: true)
        
        
        sceneView.scene.rootNode.addChildNode(ball)
        ballsCounter += 1
    }
    
    /// Remove node with name from scene when it's fall down
    ///
    /// - Parameters:
    ///   - node: SCNNode
    ///   - fallLengh: Float
    func removeFromScene(_ node: SCNNode, fallLengh: Float) {
        if node.presentation.position.y < fallLengh {
            node.removeFromParentNode()
            if let name = node.name {
                print("\(name) removed frome scene")
            }
        }
    }
    
}

// MARK: - ARSCNViewDelegate
extension ViewController: ARSCNViewDelegate {
    
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        guard let anchor = anchor as? ARPlaneAnchor else { return }
        guard !isHoopPlaced else { return }
        
        let extent = anchor.extent
        let width = CGFloat(extent.x)
        let height = CGFloat(extent.z)
        let plane = SCNPlane(width: width, height: height)
        
        plane.firstMaterial?.diffuse.contents = UIColor.blue
        
        let planeNode = SCNNode(geometry: plane)
        planeNode.eulerAngles.x = -.pi / 2
        planeNode.name = "Wall"
        planeNode.opacity = 0.125
        
        node.addChildNode(planeNode)
        
    }
    
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
        sceneView.scene.rootNode.enumerateChildNodes { node, _ in
            if node.name == "Ball" {
                removeFromScene(node, fallLengh: -50)
            }
        }
    }
}

// MARK: - SCNPhysicsContactDelegate
extension ViewController: SCNPhysicsContactDelegate {
    
    func physicsWorld(_ world: SCNPhysicsWorld, didBegin contact: SCNPhysicsContact) {
        guard let nodeABitMask = contact.nodeA.physicsBody?.categoryBitMask else { return }
        guard let nodeBBitMask = contact.nodeB.physicsBody?.categoryBitMask else { return }
       
        print("\(contact.nodeA.name!)(category bitmask is \(nodeABitMask)) contacts with \(contact.nodeB.name!)(category bitmask is \(nodeBBitMask))")
    }
    
}
