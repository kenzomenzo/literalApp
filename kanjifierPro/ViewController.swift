//
//  ViewController.swift
//  kanjifierPro
//
//  NOTE: The project's final app name is Literal.
//
//  Created by Kent Vainio on 2/17/18.
//  Copyright © 2018 Kent Vainio. All rights reserved.
//

import UIKit

extension String {
    var firstUppercased: String {
        guard let first = first else { return "" }
        return String(first).uppercased() + dropFirst()
    }
}

class ViewController: UIViewController, UIImagePickerControllerDelegate,
UINavigationControllerDelegate, UITextFieldDelegate, UIPickerViewDelegate, UIPickerViewDataSource  {

    @IBOutlet weak var photoImageView: UIImageView!
    @IBOutlet weak var resultsField: UITextView!
    @IBOutlet weak var imageSourceControl: UISegmentedControl!
    @IBOutlet weak var txt_pickUpData: UITextField!
    
    var languages: [String: String] = ["Japanese": "ja", "German":"de", "Chinese": "zh-TW", "French" : "fr", "Spanish":"es"]
    var service = ComputerVisionService()
    var usingCamera = true
    var wordTranslationDictionary = [String: String]()
    var finishedTranslating = false
    var isNoMatch = false
    let noMatchText = "Matching words could not be found!"
    var pickerData = ["Japanese", "German", "Chinese", "French", "Spanish"]
    var myPickerView = UIPickerView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        txt_pickUpData.delegate = self
        
        resultsField.isEditable = false
        resultsField.textColor = UIColor.white
        resultsField.backgroundColor = UIColor(red: 176/255, green: 184/255, blue: 173/255, alpha: 1.0)
        self.view.backgroundColor = UIColor(red: 176/255, green: 184/255, blue: 173/255, alpha: 1.0)
        imageSourceControl.tintColor = UIColor(red: 149/255, green: 236/255, blue: 126/255, alpha: 1.0)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func switchedSource(_ sender: UISegmentedControl) {
        let index = imageSourceControl.selectedSegmentIndex
        if (index == 0) {
            usingCamera = true
        }
        else if (index == 1) {
            usingCamera = false
        }
    }
    
    func translateText(wordNum: Int, myText: String) {
        let translator = ROGoogleTranslate(with: "AIzaSyDymbsjp4qqdqDRpH65-mArbP2VkWZZMvE")
        let params = ROGoogleTranslateParams(source: "en", target: languages[txt_pickUpData.text!]!, text: myText)
        translator.translate(params: params) { (result) in
            self.wordTranslationDictionary[myText] = result
            if (self.wordTranslationDictionary.count == wordNum) {
                self.finishedTranslating = true
            }
        }
    }
    
    @IBAction func selectImage(_ sender: UITapGestureRecognizer) {
        let imagePickerController = UIImagePickerController()
        if (usingCamera) {
            imagePickerController.sourceType = .camera
        }
        else {
            imagePickerController.sourceType = .photoLibrary
        }
        imagePickerController.delegate = self
        present(imagePickerController, animated: true, completion: nil)
        resultsField.text = "Please wait..."
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        guard let selectedImage = info[UIImagePickerControllerOriginalImage] as? UIImage else {
            fatalError("Expected an image, but was provided \(info)")
        }
        
        photoImageView.image = selectedImage
        dismiss(animated: true, completion: nil)
        
        let imageData = UIImageJPEGRepresentation(selectedImage, 0.8)!
        service.predict(image: imageData, completion: { (result: [[String: Any]]?, error: Error?) in
                if let error = error {
                    self.resultsField.text = error.localizedDescription
                } else if let result = result {
                    if result.count == 0 {
                        self.isNoMatch = true
                        self.finishedTranslating = true
                    }
                    else {
                        for index in 0..<result.count {
                            let firstEntry = result[index]["name"] as? String
                            self.translateText(wordNum: result.count, myText: firstEntry!)
                        }
                    }
                }
        })
        
        while(!finishedTranslating) {}
        finishedTranslating = false
        if (isNoMatch) {
            self.resultsField.text = noMatchText
            isNoMatch = false
        }
        else {
            self.resultsField.text = ""
            var wordCount = 1
            let finalWordCount = wordTranslationDictionary.count
            for (eng, translated) in wordTranslationDictionary {
                self.resultsField.text = self.resultsField.text! + eng + " - " + translated
                if (wordCount < finalWordCount) {
                    self.resultsField.text = self.resultsField.text! + "\n"
                }
                wordCount = wordCount + 1
            }
        }
        let newDict = [String: String]()
        wordTranslationDictionary = newDict
    }
    
    func pickUp(_ textField : UITextField){
        // UIPickerView
        self.myPickerView = UIPickerView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        self.myPickerView.delegate = self
        self.myPickerView.dataSource = self
        self.myPickerView.backgroundColor = UIColor.white
        textField.inputView = self.myPickerView
        
        // ToolBar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(ViewController.doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(ViewController.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
        
    }
    //MARK:- PickerView Delegate & DataSource
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return pickerData[row]
    }
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.txt_pickUpData.text = pickerData[row]
    }
    //MARK:- TextField Delegate
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.pickUp(txt_pickUpData)
    }
    
    //MARK:- Button
    @objc func doneClick() {
        txt_pickUpData.resignFirstResponder()
    }
    @objc func cancelClick() {
        txt_pickUpData.resignFirstResponder()
    }
}

