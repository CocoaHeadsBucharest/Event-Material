//
//  ViewController.swift
//  ArMeasure
//
//  Created by Marius Constantinescu on 19/11/2017.
//

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
    
    @IBOutlet var sceneView: ARSCNView!
    @IBOutlet weak var label: UILabel!
    
    var measurementNodes: [SCNNode] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set the view's delegate
        sceneView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
        sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        // Pause the view's session
        sceneView.session.pause()
    }
    
    //MARK: Actions:
	@IBAction func didTap(gestureRecognizer: UITapGestureRecognizer) {
        //make a hit test to see where we should place it
        
        let point = gestureRecognizer.location(in: self.view)
        
        if let hit = sceneView.hitTest(point, types: [.existingPlaneUsingExtent]).first {
            let radius: CGFloat = 0.01
            let sphere = SCNSphere(radius:radius)
            sphere.firstMaterial?.diffuse.contents = UIColor.green
            let newNode = SCNNode(geometry: sphere)
            
            //if we already have 2 or more nodes, we start a new measurement
            if measurementNodes.count >= 2 {
				clearMeasurement()
            }
            
            //we add the measuring point to the scene
            measurementNodes.append(newNode)
            self.sceneView.scene.rootNode.addChildNode(newNode)
            newNode.simdTransform = hit.worldTransform
            
            //if we have two measuring nodes here, we draw a line and show the measuring result
            if measurementNodes.count == 2 {
                computeDistance()
            }
        }  
    }
	
	fileprivate func clearMeasurement() {
		for node in measurementNodes {
			node.removeFromParentNode()
		}
		measurementNodes = []
		label.text = ""
	}
	
	func computeDistance() {
		let firstPosition = measurementNodes[0].position
		let secondPosition = measurementNodes[1].position
		
		//create a Scene Kit line
		let indices: [Int32] = [0, 1]
		let source = SCNGeometrySource(vertices: [firstPosition, secondPosition])
		let element = SCNGeometryElement(indices: indices, primitiveType: .line)
		let line =  SCNGeometry(sources: [source], elements: [element])
		let lineNode = SCNNode(geometry: line)
		
		//make it green
		let planeMaterial = SCNMaterial()
		planeMaterial.diffuse.contents = UIColor.green
		line.materials = [planeMaterial]
		
		//add it to scene and our own representation
		sceneView.scene.rootNode.addChildNode(lineNode)
		measurementNodes.append(lineNode)
		
		//we create a 3D vector with the root in 0,0,0 and the length on each axes equal to the diference between the two points
		let distVector = SCNVector3(x: firstPosition.x - secondPosition.x, y: firstPosition.y - secondPosition.y, z: firstPosition.z - secondPosition.z)
		//we calculate the vector's length
		let dist = sqrtf(distVector.x * distVector.x + distVector.y * distVector.y + distVector.z * distVector.z)
		//we show the distance
		let measurementValue = String(format: "%.2f", dist)
		label.text = "Distance: \(measurementValue) m"
	}
	
    // MARK: - ARSCNViewDelegate
	
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
		
		if let planeAnchor = anchor as? ARPlaneAnchor {
			// Create a SceneKit plane to visualize the plane anchor using its position and extent.
			let plane = SCNPlane(width: CGFloat(planeAnchor.extent.x), height: CGFloat(planeAnchor.extent.z))
			let planeNode = SCNNode(geometry: plane)
			planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
			
			/*
			`SCNPlane` is vertically oriented in its local coordinate space, so
			rotate the plane to match the horizontal orientation of `ARPlaneAnchor`.
			*/
			planeNode.eulerAngles.x = -.pi / 2
			
			// Make the plane visualization semitransparent to clearly show real-world placement.
			planeNode.opacity = 0.55
			plane.firstMaterial?.diffuse.contents = UIColor.blue
			
			/*
			Add the plane visualization to the ARKit-managed node so that it tracks
			changes in the plane anchor as plane estimation continues.
			*/
			node.addChildNode(planeNode)
		}
	}
	
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update content only for plane anchors and nodes matching the setup created in `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as?  ARPlaneAnchor,
            let planeNode = node.childNodes.first,
            let plane = planeNode.geometry as? SCNPlane
            else { return }
        
        // Plane estimation may shift the center of a plane relative to its anchor's transform.
        planeNode.simdPosition = float3(planeAnchor.center.x, 0, planeAnchor.center.z)
        
        /*
         Plane estimation may extend the size of the plane, or combine previously detected
         planes into a larger one. In the latter case, `ARSCNView` automatically deletes the
         corresponding node for one plane, then calls this method to update the size of
         the remaining plane.
         */
        plane.width = CGFloat(planeAnchor.extent.x)
        plane.height = CGFloat(planeAnchor.extent.z)
    }
}
