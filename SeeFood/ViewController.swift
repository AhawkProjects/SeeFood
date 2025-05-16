//
//  ViewController.swift
//  SeeFood
//
//  Created by Abrar Hoque on 7/15/20.
//  Copyright © 2020 Abrar Hoque. All rights reserved.
//

import UIKit
import CoreML
import Vision

class ViewController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    // Add a property to store the fetched description
    var objectDescription: String?
    
    // Replace with your actual API key retrieval method (e.g., from Info.plist)
    let openAIAPIKey = "YOUR_OPENAI_API_KEY"
    
    // Function to fetch description from OpenAI
    func fetchDescription(for object: String, completion: @escaping (String?) -> Void) {
        let endpoint = "https://api.openai.com/v1/chat/completions"
        guard let url = URL(string: endpoint) else {
            completion(nil)
            return
        }
        let prompt = "Give a short, fun, one-sentence description of a \(object) for a mobile app."
        let parameters: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [["role": "user", "content": prompt]],
            "max_tokens": 40
        ]
        let jsonData = try? JSONSerialization.data(withJSONObject: parameters)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("Bearer \(openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let first = choices.first,
               let message = first["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content.trimmingCharacters(in: .whitespacesAndNewlines))
            } else {
                completion(nil)
            }
        }
        task.resume()
    }

    
    
    @IBOutlet weak var imageView: UIImageView!
    
    let imagePicker = UIImagePickerController()
    
    func navBar()->UINavigationBar?{
        let navBar = self.navigationController?.navigationBar
        return navBar
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        imagePicker.delegate = self
        imagePicker.sourceType = .camera
        imagePicker.allowsEditing = false
        
        
        
    }
    
    
    func setTNavBarTitleAsLabel(title: String, color: UIColor ){

        // removed some code..

        let navigationTitlelabel = UILabel(frame: CGRect(x: 0, y: 0, width: 20, height: 20))
        navigationTitlelabel.numberOfLines = 1
        navigationTitlelabel.lineBreakMode = .byTruncatingTail

        navigationTitlelabel.adjustsFontSizeToFitWidth = true
        navigationTitlelabel.minimumScaleFactor = 0.1
        navigationTitlelabel.textAlignment = .center
        navigationTitlelabel.textColor  = color
        navigationTitlelabel.text = title

        if let navBar = navBar(){
            //was navBar.topItem?.title = title

            self.navBar()?.topItem?.titleView = navigationTitlelabel
            //navBar.titleTextAttributes = [.foregroundColor : color ?? .black]
        }
    }
    
    
    
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        
        if let userPickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            imageView.image = userPickedImage
            
            guard let ciimage = CIImage(image: userPickedImage) else {
                fatalError("Could not convert to CI Image")
            }
            
            detect(image: ciimage)
            
        }
        
        imagePicker.dismiss(animated: true, completion: nil)
        
        
    }
    
    func detect(image: CIImage){
        
        
        guard let model = try? VNCoreMLModel(for: Inceptionv3().model) else {
            fatalError("Loading coreMl model failed")
        }
        
        let request = VNCoreMLRequest(model: model) { (request, error) in
            
            guard let results = request.results as? [VNClassificationObservation] else {
                fatalError("Model Failed to process image")
            }
            
            //print(results)
            if let firstResult = results.first {
    let label = firstResult.identifier
    if label.contains("hotdog") {
        self.setTNavBarTitleAsLabel(title: "My gullocks what a gargantuan GLizzy that is my good sir", color: UIColor.white)
    } else {
        self.setTNavBarTitleAsLabel(title: "Yooo that aint no glizzy, thats a \(label)", color: UIColor.white)
    }
    // Fetch description from OpenAI
    self.fetchDescription(for: label) { [weak self] description in
        guard let self = self, let description = description else { return }
        DispatchQueue.main.async {
            // You can choose how to display this. Here, we show an alert.
            let alert = UIAlertController(title: "What is a \(label)?", message: description, preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}

            
        }
        
        let handler = VNImageRequestHandler(ciImage: image)
        
        do{
            try handler.perform([request])
        } catch {
            print(error)
        }
        
    }
    
    @IBAction func cameraTapped(_ sender: UIBarButtonItem) {
        
        present(imagePicker, animated: true, completion: nil)
        
    }
    
    
    
    
    
    


}

