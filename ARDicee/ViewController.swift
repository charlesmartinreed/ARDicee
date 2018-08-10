//
//  ViewController.swift
//  ARDicee
//
//  Created by Charles Martin Reed on 8/10/18.
//  Copyright © 2018 Charles Martin Reed. All rights reserved.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate {
    
    var diceArray = [SCNNode]()

    @IBOutlet var sceneView: ARSCNView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //visualize our plane detection
        //self.sceneView.debugOptions = [ARSCNDebugOptions.showFeaturePoints]
        
        // Set the view's delegate
        sceneView.delegate = self
        
        //units are meters
        //creating a scene with a rounded cube
        //let cube = SCNBox(width: 0.1, height: 0.1, length: 0.1, chamferRadius: 0.01)
        
//        let sphere = SCNSphere(radius: 0.2)
//
//        //styling our sphere with a ultra-high res moon texture
//        let material = SCNMaterial()
//
//        //moon texture taken from solarsystemscope.com
//        material.diffuse.contents = UIImage(named: "art.scnassets/8k_moon.jpg")
//
//        sphere.materials = [material]
//
//        //creating a node to position our object at a point in 3D space
//        //has X, Y and Z axis
//        let node = SCNNode()
//        node.position = SCNVector3(x: 0, y: 0.1, z: -0.5) //- moves object further from user
//        node.geometry = sphere
//
//        //the rootNode can carry an array of items, though we're just using one now
//        sceneView.scene.rootNode.addChildNode(node)
//
        //adding lighting to our scene
        sceneView.autoenablesDefaultLighting = true
        
   
//        }
        
       
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Create a session configuration and check what compatibility is avaiable
        if ARWorldTrackingConfiguration.isSupported {
            let configuration = ARWorldTrackingConfiguration()
            
            //detecting the horizontal plane
            configuration.planeDetection = .horizontal
            
            print("Full session AR is supported")
            sceneView.session.run(configuration)

        } else {
            let configuration = AROrientationTrackingConfiguration()
            print("Full session AR not supported. Reduced compatbility session is in use.")
            sceneView.session.run(configuration)
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: detecting touch events on our scene object
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        //get the touches and use them to place the object in the 3d space
        //if there's a first touch, asisgn it to an object in the sceneView
        if let touch = touches.first {
            let touchLocation = touch.location(in: sceneView)
            
            //convert 2 touch location into a 3d point on our created plane
            let results = sceneView.hitTest(touchLocation, types: .existingPlaneUsingExtent)
           
            if let hitResult = results.first {
                addDice(atLocation: hitResult)
            }
        }
    }
    
    //MARK: - DICE RENDERING METHODS
    func addDice(atLocation location: ARHitTestResult) {
        //Create a new scene for our dice
        let diceScene = SCNScene(named: "art.scnassets/diceCollada.scn")!
        
        //create dice node, recursive to add additional child nodes down the tree
        if let diceNode = diceScene.rootNode.childNode(withName: "Dice", recursively: true) {
            
            //using the world transform results from the hitTest to position our dice
            //column 3 contains information on the position on the touch
            //diceNode.boundingSphere.radius is used to place the dice ON TOP of the grid instead of flush
            diceNode.position = SCNVector3(
                x: location.worldTransform.columns.3.x,
                y: location.worldTransform.columns.3.y + diceNode.boundingSphere.radius,
                z: location.worldTransform.columns.3.z
            )
            
            //add the diceNode to the array
            diceArray.append(diceNode)
            
            sceneView.scene.rootNode.addChildNode(diceNode)
            
            roll(dice: diceNode)
        }
    }
    
    func roll(dice: SCNNode) {
        //using random numbers to roll the dice in the scene
        //turn it 90 degrees to show a different face
        let randomX = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        let randomZ = Float(arc4random_uniform(4) + 1) * (Float.pi/2)
        
        dice.runAction(
            SCNAction.rotateBy(x: CGFloat(randomX * 5),
                               y: 0,
                               z: CGFloat(randomZ * 5),
                               duration: 0.5)
        )
    }

    func rollAll() {
        if !diceArray.isEmpty {
            for dice in diceArray {
                roll(dice: dice)
            }
        }
    }
    
    
    //MARK: button and shake gesture both roll all the dice on the scene
    @IBAction func rollAgain(_ sender: UIBarButtonItem) {
        
        rollAll()
    }
    
    override func motionEnded(_ motion: UIEventSubtype, with event: UIEvent?) {
        rollAll()
    }
    
    //MARK: Function to remove all dice
    @IBAction func removeallDice(_ sender: UIBarButtonItem) {
        
        if !diceArray.isEmpty {
            for dice in diceArray {
                dice.removeFromParentNode()
            }
        }
    }
    
    
    //MARK: - ARSCNViewDelegateMethods
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        //detected a horizontal surface, that surface has a width and height
        //ANAnchor is like a tile on the floor, you can use these real-world coordinates to place our object

        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        let planeNode = createPlane(withPlaneAnchor: planeAnchor)
        
        //using the node parameter for this method
        node.addChildNode(planeNode)

    }
    
    //MARK: - Plane Rendering Methods
    
    func createPlane(withPlaneAnchor planeAnchor: ARPlaneAnchor) -> SCNNode {
        // convert dimensions of our anchor into a sceneplane
        let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
        
        let planeNode = SCNNode()
        
        //flat horizontal plane, no y-axis available yet
        planeNode.position = SCNVector3(x: planeAnchor.center.x, y: 0, z: planeAnchor.center.z)
        
        //convert vertical plane into a horizontal plane - rotate by 90 degrees, clockwise, around the x-axis
        planeNode.transform = SCNMatrix4MakeRotation(-Float.pi/2, 1, 0, 0)
        
        //give the planeNode a texture for visualization
        let gridMaterial = SCNMaterial()
        
        gridMaterial.diffuse.contents = UIImage(named: "art.scnassets/grid.png")
        
        plane.materials = [gridMaterial]
        
        planeNode.geometry = plane
        
        return planeNode
    }
}

