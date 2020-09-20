//
//  ViewController.swift
//  FloraLookup
//
//  Created by AmeerMuhammed on 9/9/20.
//  Copyright © 2020 AmeerMuhammed. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage


class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate{
    @IBOutlet weak var cameraImageView: UIImageView!
    @IBOutlet weak var descLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        cameraImageView.layer.cornerRadius = 10
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = true
        navigationItem.title="Sunflower"
        requestData(flowerName: "sun flower")
    }
    
    let imagePicker = UIImagePickerController()
    let wikipediaURl = "https://en.wikipedia.org/w/api.php"
    
    @IBAction func cameraPressed(_ sender: UIBarButtonItem) {
        present(imagePicker, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let ciImage = CIImage(image: userImage)
                else { fatalError("Cannot convert to CIImage") }
            detect(ciimage: ciImage)
        }
        imagePicker.dismiss(animated: true, completion: nil)
    }
    
    func detect(ciimage: CIImage)
    {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model)
            else { fatalError("Cannot import model") }
        let request = VNCoreMLRequest(model: model) { (request, error) in
            let classification = request.results?.first as? VNClassificationObservation
            if let flowerName = classification?.identifier {
                self.navigationItem.title = flowerName.capitalized
                self.requestData(flowerName: flowerName)
            }
        }
        
        let handler = VNImageRequestHandler(ciImage: ciimage)
        
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }
    
    func requestData(flowerName: String) {
        let parameters : [String:String] = [
            "format" : "json",
            "action" : "query",
            "prop" : "extracts|pageimages",
            "exintro" : "",
            "explaintext" : "",
            "titles" : flowerName,
            "indexpageids" : "",
            "redirects" : "1",
            "pithumbsize" : "500"
        ]
        
        Alamofire.request(wikipediaURl, method: .get, parameters: parameters).responseJSON { (response) in
            if response.result.isSuccess {
                let flowerJSON : JSON = JSON(response.result.value!)
                let pageid = flowerJSON["query"]["pageids"][0].stringValue
                let flowerDesc = flowerJSON["query"]["pages"][pageid]["extract"].stringValue
                let flowerImageURL = flowerJSON["query"]["pages"][pageid]["thumbnail"]["source"].stringValue
                
                self.cameraImageView.sd_setImage(with: URL(string: flowerImageURL))
                
                self.descLabel.text = flowerDesc
            }
        }
    }
}

