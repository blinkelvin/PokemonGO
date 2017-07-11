//
//  ViewController.swift
//  PokemonGO
//
//  Created by Kelvin Medeiros on 10/07/17.
//  Copyright © 2017 Kelvin Medeiros. All rights reserved.
//

import UIKit
import Alamofire
import Kingfisher
import MapKit

class ViewController: UIViewController, MKMapViewDelegate, CLLocationManagerDelegate {
    
    @IBOutlet weak var mapa: MKMapView!
    
    var gerLocalization = CLLocationManager()
    
    var count = 0
    var pokeindex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapa.delegate = self
        gerLocalization.delegate = self
        gerLocalization.requestWhenInUseAuthorization()
        gerLocalization.startUpdatingLocation()
        
        //Exibir pokemons
        Timer.scheduledTimer(withTimeInterval: 5, repeats: true) { (timer) in
            
            if let coords = self.gerLocalization.location?.coordinate{
                let anotacao = MKPointAnnotation()
                
                anotacao.coordinate = coords
                anotacao.coordinate.latitude += (Double(arc4random_uniform(400)) - 200) / 100000.0
                anotacao.coordinate.longitude += (Double(arc4random_uniform(400)) - 200) / 100000.0
                
                self.mapa.addAnnotation(anotacao)
            }
        }
    }
    
    func request(_ completionBlock: @escaping (String, NSError?) -> ()){
        
        Alamofire.request("http://pokeapi.co/api/v2/pokemon-form/" + String(pokeindex) + "/").responseJSON { response in
            if let json = response.result.value as? [String:AnyObject] {
                completionBlock((json["sprites"]!["front_default"] as? String)!, nil)
                self.pokeindex += 1
            }else{
                completionBlock("", NSError.init(domain: "domain", code: (response.response?.statusCode)!, userInfo: nil) as NSError?)
            }
        }
    }
    
    @IBAction func btnCentralize(_ sender: Any) {        
        self.centralize()
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        let anotacaoView = MKAnnotationView(annotation: annotation, reuseIdentifier: nil)
        anotacaoView.contentMode = .scaleAspectFit
        
        if annotation is MKUserLocation{
            anotacaoView.image = #imageLiteral(resourceName: "player")
        }else{
            self.request({ (result, error) in
                if error == nil{
                    ImageDownloader.default.downloadImage(with: URL(string: result)!, options: [], progressBlock: nil) {
                        (image, error, url, data) in
                        anotacaoView.image = image
                    }
                }
            })
        }
        
        anotacaoView.frame.size.height = 40
        anotacaoView.frame.size.width = 40
        
        return anotacaoView
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        if count < 3{
            self.centralize()
            self.count += 1
        }else{
            self.gerLocalization.stopUpdatingLocation()
        }
    }
    
    func centralize(){
        if let coords = self.gerLocalization.location?.coordinate{
            let regiao = MKCoordinateRegionMakeWithDistance(coords, 200, 200)
            self.mapa.setRegion(regiao, animated: true)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status != .authorizedWhenInUse && status != .notDetermined{
            let alertController = UIAlertController(title: "Permissão de localização", message: "Para que você possa caçar pokemons, precisamos da sua localização!", preferredStyle: .alert)
            
            let acaoConf = UIAlertAction(title: "Abrir Configurações", style: .default, handler: { (alertaConfig) in
                
                if let config = NSURL(string: UIApplicationOpenSettingsURLString){
                    UIApplication.shared.open(config as URL)
                }
            })
            
            let acaoCancel = UIAlertAction(title: "Cancelar", style: .default, handler: nil)
            
            alertController.addAction(acaoConf)
            alertController.addAction(acaoCancel)
            
            present(alertController, animated: true, completion: nil)
        }
    }
    
}

