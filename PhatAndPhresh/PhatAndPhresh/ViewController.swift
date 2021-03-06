//
//  ViewController.swift
//  PhatAndPhresh
//
//  Created by Arthur De Araujo on 10/6/17.
//  Copyright © 2017 Arthur De Araujo. All rights reserved.
//

import UIKit
import Pulsator
import Spring
import NVActivityIndicatorView
import JTMaterialTransition
import Alamofire
import SwiftyJSON

class ViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, ViewRapVCDelegate {
    
    @IBOutlet var buttonContainerView: SpringView!
    @IBOutlet var generateButton: GenerateButton!
    @IBOutlet var activityIndicator: NVActivityIndicatorView!
    @IBOutlet var collectionView: UICollectionView!
    
    @IBOutlet var generateBWidthConstraint: NSLayoutConstraint!
    @IBOutlet var generateBHeightConstraint: NSLayoutConstraint!
    
    let repeatedPulsator = Pulsator()
    var transition: JTMaterialTransition?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        self.transition = JTMaterialTransition(animatedView: self.generateButton)
        self.collectionView.register(UINib(nibName: "SavedRapCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "savedRapID")
        collectionView.delegate = self
        collectionView.dataSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: ViewController
    
    func setupUI(){
        setupGradientBackground()
        createPulsingHalo()
        generateButton.setTitle(getRandomizedGenButtonTitle(), for: .normal)
    }
    
    func createPulsingHalo(){
        repeatedPulsator.frame = CGRect(x: buttonContainerView.frame.size.width/2, y: buttonContainerView.frame.size.height/2, width: 0, height: 0)
        buttonContainerView.layer.insertSublayer(repeatedPulsator, at: 0)
        repeatedPulsator.radius = buttonContainerView.frame.size.width
        repeatedPulsator.backgroundColor = generateButton.backgroundColor?.cgColor
        repeatedPulsator.numPulse = 2
        repeatedPulsator.start()
    }
    
    func setupGradientBackground() {
        let colorTop =  UIColor(red: 239.0/255.0, green: 239.0/255.0, blue: 239.0/255.0, alpha: 1.0).cgColor
        let colorBottom = UIColor(red: 226.0/255.0, green: 255.0/255.0, blue: 233.0/255.0, alpha: 1.0).cgColor
        
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [ colorTop, colorBottom]
        gradientLayer.locations = [ 0.0, 1.0]
        gradientLayer.frame = self.view.bounds
        
        self.view.layer.insertSublayer(gradientLayer, at: 0)
    }
    
    func createSinglePulse(){
        let pulsator = Pulsator()
        pulsator.frame = CGRect(x: buttonContainerView.frame.size.width/2, y: buttonContainerView.frame.size.height/2, width: 0, height: 0)
        buttonContainerView.layer.insertSublayer(pulsator, at: 1)
        pulsator.radius = buttonContainerView.frame.size.width+10
        pulsator.backgroundColor = generateButton.backgroundColor?.cgColor
        pulsator.repeatCount = 0
        pulsator.animationDuration = 1.5
        pulsator.autoRemove = true
        pulsator.start()
    }
    
    func segueToRapVC(rapBars:String, rhymes:[String]){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ViewRapViewController") as! ViewRapViewController
        
        controller.view.backgroundColor = generateButton.backgroundColor
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self.transition
        controller.setupUI(rapBars:rapBars, rhymes:rhymes, isSavedRap:false, savedIndex:-1)
        controller.delegate = self
        
        self.present(controller, animated: true, completion: {
            self.activityIndicator.stopAnimating()
            self.repeatedPulsator.start()
            self.generateButton.setTitle(self.getRandomizedGenButtonTitle(), for: .normal)
        })
    }
    
    func segueToSavedRapVC(rapBars:String, rhymes:[String], view:UIView, savedIndex:Int){
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let controller = storyboard.instantiateViewController(withIdentifier: "ViewRapViewController") as! ViewRapViewController
        
        controller.view.backgroundColor = generateButton.backgroundColor
        controller.modalPresentationStyle = .custom
        controller.transitioningDelegate = self.transition
        controller.setupUI(rapBars:rapBars, rhymes:rhymes, isSavedRap:true, savedIndex:savedIndex)
        controller.delegate = self
        
        self.present(controller, animated: true, completion: {
            self.generateButton.setTitle(self.getRandomizedGenButtonTitle(), for: .normal)
        })
    }
    
    func getRandomizedGenButtonTitle() -> String {
        let genButtonTextList = [ "Give me some phat bars" , "Give me some phire bars", "Give me some phresh bars" , "Drop some phire bars", "Spit some phire bars"]
        let randIndex = Int(arc4random_uniform(UInt32(Int(genButtonTextList.count))))
        return genButtonTextList[randIndex]
    }
    
    // MARK: API

    func requestRap(completion: @escaping (_ rapBars: String, _ rhymes: [String]) -> Void) {
        Alamofire.request("http://phatandphresh.azurewebsites.net/api/phresh").responseJSON { response in
            //print("Request: \(String(describing: response.request))")   // original url request
            //print("Response: \(String(describing: response.response))") // http url response
            //print("Result: \(response.result)")                         // response serialization result
            
            if let json = response.result.value {
                print("JSON: \(json)") // serialized json response
            }
            
            if let data = response.data, let utf8Text = String(data: data, encoding: .utf8) {
                let json = JSON(data: data)
                print(json)
                var rhymes:[String] = json["rhymes"].arrayValue.map { $0.stringValue}
                var verses:[String] = json["verses"].arrayValue.map { $0.stringValue}
                completion(verses[0], rhymes)
            }
        }
    }
    
    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        let defaults = UserDefaults.standard
        var savedTitlesArray = defaults.stringArray(forKey: "SavedRapTitles") ?? [String]()
        return savedTitlesArray.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "savedRapID", for: indexPath) as! SavedRapCollectionViewCell
        
        let defaults = UserDefaults.standard
        var savedTitlesArray = defaults.stringArray(forKey: "SavedRapTitles") ?? [String]()
        cell.title.text = savedTitlesArray[indexPath.row]

        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        // handle tap events
        print("You selected cell #\(indexPath.item)!")
        let defaults = UserDefaults.standard
        var savedTitlesArray = defaults.stringArray(forKey: "SavedRapTitles") ?? [String]()
        var savedRapsArray = defaults.stringArray(forKey: "SavedRapBars") ?? [String]()
        
        print("Saved Titles Array: "+savedTitlesArray[indexPath.row])
        print("Saved Raps Array: "+savedRapsArray[indexPath.row])

        self.segueToSavedRapVC(rapBars: savedRapsArray[indexPath.row], rhymes: [], view: collectionView.cellForItem(at: indexPath)!, savedIndex: indexPath.row)
    }
    
    // MARK: - ViewRapVCDelegate
    
    func dismissingVC() {
        collectionView.reloadData()
    }

    // MARK: Actions

    @IBAction func pressedDownOnGenerate(_ sender: Any) {
        generateButton.scaleX = 0.8
        generateButton.scaleY = 0.8
        generateButton.animate()
        createSinglePulse()
        self.repeatedPulsator.stop()
        generateButton.setTitle("", for: .normal)
        if !self.activityIndicator.isAnimating {
            self.activityIndicator.startAnimating()
        }
    }
    
    @IBAction func pressedGenerateButton(_ sender: Any) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        requestRap { rapBars, rhymes in
            self.segueToRapVC(rapBars: rapBars, rhymes: rhymes)
        }
    }
}

