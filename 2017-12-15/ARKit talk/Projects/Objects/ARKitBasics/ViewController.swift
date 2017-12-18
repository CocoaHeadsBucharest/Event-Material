/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Main view controller for the AR experience.
*/

import UIKit
import SceneKit
import ARKit

class ViewController: UIViewController, ARSCNViewDelegate, ARSessionDelegate {
	// MARK: - IBOutlets

	@IBOutlet weak var sceneView: ARSCNView!
	var lampScene = SCNScene()
	var lamp: SCNNode!
	
	// MARK: - View Life Cycle
	
	override func viewDidLoad() {
		super.viewDidLoad()

		sceneView.scene = lampScene

		let node =  SCNReferenceNode(url: Bundle.main.url(forResource: "Models.scnassets/lamp/lamp.scn", withExtension: nil)!)!
		node.load()
		lampScene.rootNode.addChildNode(node)
		node.isHidden = true
		lamp = node
		
		let tgr = UITapGestureRecognizer(target: self, action: #selector(didTap(_:)))
		view.addGestureRecognizer(tgr)

		let pgr = UIPanGestureRecognizer(target: self, action: #selector(didPan(_:)))
		view.addGestureRecognizer(pgr)
	}
	
    /// - Tag: StartARSession
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        /*
         Start the view's AR session with a configuration that uses the rear camera,
         device position and orientation tracking, and plane detection.
        */
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = .horizontal
		sceneView.debugOptions = ARSCNDebugOptions.showFeaturePoints
        sceneView.session.run(configuration)

        // Set a delegate to track the number of plane anchors for providing UI feedback.
        sceneView.session.delegate = self
        
        /*
         Prevent the screen from being dimmed after a while as users will likely
         have long periods of interaction without touching the screen or buttons.
        */
        UIApplication.shared.isIdleTimerDisabled = true
		
        
    }
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		
		// Pause the view's AR session.
		sceneView.session.pause()
	}
	
	// MARK: - ARSCNViewDelegate
    
    /// - Tag: PlaceARContent
	func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }

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
		plane.firstMaterial?.diffuse.contents = #imageLiteral(resourceName: "tiles")
        
        /*
         Add the plane visualization to the ARKit-managed node so that it tracks
         changes in the plane anchor as plane estimation continues.
        */
        node.addChildNode(planeNode)
	}

    /// - Tag: UpdateARContent
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

	// MARK: - Gesture Recognizers

	@IBAction func didTap(_ recognizer: UITapGestureRecognizer) {
		let location = recognizer.location(in: sceneView)

		// When tapped on a plane, reposition the content
		let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
		if !arHitTestResult.isEmpty {
			let hit = arHitTestResult.first!
			lamp.simdTransform = hit.worldTransform

			if lamp.isHidden {
				lamp.isHidden = false
			}
		}
	}

	@IBAction func didPan(_ recognizer: UIPanGestureRecognizer) {
		let location = recognizer.location(in: sceneView)

		// Drag the object on an infinite plane
		let arHitTestResult = sceneView.hitTest(location, types: .existingPlane)
		if !arHitTestResult.isEmpty {
			let hit = arHitTestResult.first!
			lamp.simdTransform = hit.worldTransform
		}
	}
}
