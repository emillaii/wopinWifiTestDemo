//
//  ViewController.swift
//  WopinWifiTest
//
//  Created by Lai kwok tai on 5/7/2018.
//  Copyright © 2018 Lai kwok tai. All rights reserved.
//

import UIKit
import NetworkExtension
import AVFoundation
import QRCodeReader
import CocoaMQTT

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, QRCodeReaderViewControllerDelegate, CocoaMQTTDelegate {
    
    func mqtt(_ mqtt: CocoaMQTT, didConnectAck ack: CocoaMQTTConnAck) {
        print("didConnectAck")
        mqtt.subscribe(self.topic)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didStateChangeTo state: CocoaMQTTConnState) {
        print("didStateChangeTo")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishMessage message: CocoaMQTTMessage, id: UInt16) {
        print("didPublishMessage")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didPublishAck id: UInt16) {
        print("didPublishAck")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didReceiveMessage message: CocoaMQTTMessage, id: UInt16 ) {
        print("didSubscribeTopic " + message.topic + " " + message.string!)
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didSubscribeTopic topic: String) {
        print("didSubscribeTopic")
    }
    
    func mqtt(_ mqtt: CocoaMQTT, didUnsubscribeTopic topic: String) {
        print("didUnsubscribeTopic")
    }
    
    func mqttDidPing(_ mqtt: CocoaMQTT) {
        print("mqttDidPing")
    }
    
    func mqttDidReceivePong(_ mqtt: CocoaMQTT) {
        print("mqttDidReceivePong")
    }
    
    func mqttDidDisconnect(_ mqtt: CocoaMQTT, withError err: Error?) {
        print("mqttDidDisconnect")
    }
    
    //Mqtt Client
    var mqtt: CocoaMQTT?
    let defaultHost = wopinMqttServer
    let topic = wopinMqttTopic
    
    @IBOutlet weak var redColor: UITextField!
    @IBOutlet weak var greenColor: UITextField!
    @IBOutlet weak var blueColor: UITextField!
    
    func mqttSetting() {
        let clientID = "iOS"
        mqtt = CocoaMQTT(clientID: clientID, host: defaultHost, port: 8083)
        mqtt!.username = wopinMqttUsername
        mqtt!.password = wopinMqttPassword
        mqtt!.keepAlive = 60
        mqtt!.delegate = self
        mqtt?.connect()
    }
    
    @IBAction func connectMqtt(_ sender: Any) {
        mqttSetting()
    }
    
    @IBAction func sendRGBCommand(_ sender: Any) {
        let r = Int(redColor.text!)
        let g = Int(greenColor.text!)
        let b = Int(blueColor.text!)
        let code = wopinWifiLEDCommand(r: r!, g: g!, b: b!)
        mqtt?.publish(wopinMqttTopic, withString: code)
    }
    
    lazy var readerVC: QRCodeReaderViewController = {
        let builder = QRCodeReaderViewControllerBuilder {
            $0.reader = QRCodeReader(metadataObjectTypes: [.qr], captureDevicePosition: .back)
        }
        return QRCodeReaderViewController(builder: builder)
    }()
    
    var indicator = UIActivityIndicatorView()
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var ssidTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    var essids = [String]()
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return essids.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "wifiTableCell", for: indexPath)
        
        cell.textLabel?.text = essids[indexPath.row]
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        DispatchQueue.main.async {
            self.ssidTextField.text = self.essids[indexPath.row]
        }
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    var timer : Timer!
    
    @IBOutlet weak var connectedWifiLabel: UILabel!
    private let SSID = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        redColor.delegate = self
        greenColor.delegate = self
        blueColor.delegate = self
        timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(runTimedCode), userInfo: nil, repeats: true)
    }
    
    @IBAction func connectToWopin(_ sender: Any) {
        readerVC.delegate = self
        var wopinSSID = ""
        var wopinPW = ""
        
        readerVC.completionBlock = { (result: QRCodeReaderResult?) in
            print(result ?? "")
            print(result?.value ?? "")
            self.indicator.startAnimating()
            var wifiInfo = result?.value.split(separator: ";")
            let sv = UIViewController.displaySpinner(onView: self.view)
            if (wifiInfo?.count == 3)
            {
                wopinSSID = String(wifiInfo![0])
                wopinSSID.removeFirst(7)
                wopinPW = String(wifiInfo![2])
                wopinPW.removeFirst(2)
            }
            print(wopinSSID)
            print(wopinPW)
            let hotspotConfig = NEHotspotConfiguration(ssid: wopinSSID, passphrase: wopinPW, isWEP: false)
            hotspotConfig.joinOnce = true
            NEHotspotConfigurationManager.shared.apply(hotspotConfig) {[unowned self] (error) in
                
                if let error = error {
                    self.showError(error: error)
                }
                else {
                    if (getWifiSsid() == wopinSSID) {
                        self.showSuccess(msg: "")
                    }
                }
                UIViewController.removeSpinner(spinner: sv)
            }
        }
        
        // Presents the readerVC as modal form sheet
        readerVC.modalPresentationStyle = .formSheet
        present(readerVC, animated: true, completion: nil)
    }
    
    private func showError(error: Error) {
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: .alert)
        let action = UIAlertAction(title: "Darn", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    private func showSuccess(msg: String) {
        let alert = UIAlertController(title: "", message: msg + " Connected", preferredStyle: .alert)
        let action = UIAlertAction(title: "OK", style: .default, handler: nil)
        alert.addAction(action)
        present(alert, animated: true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func runTimedCode() {
        connectedWifiLabel.text = getWifiSsid()
    }
    
    @IBAction func configureWifi(_ sender: Any) {
        
        if (ssidTextField.text?.count == 0 || passwordTextField.text?.count == 0)
        {
            let alert = UIAlertController(title: "Missing ssid or password", message: "It's recommended check the inputs", preferredStyle: .alert)
            
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true)
            return
        }
        
        let ssid = ssidTextField.text
        let password = passwordTextField.text
        
        let headers = ["Content-Type" : "application/x-www-form-urlencoded",
                       "Accept-Language" : "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7",
                       "Connection" : "keep-alive",
                       "ssid" : ssid,
                       "password" : password]
        
        let postString = "" //ToDo: Cannot send the post data??? So add the info in header first...
        
        var request = URLRequest(url: URL(string: wopinWifiURL)!)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers as? [String : String]
        request.httpBody = postString.data(using: .ascii)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "")
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse ?? "")
                let httpResponseData = String(data: data!, encoding: .utf8)
                do {
                    let ra = try JSONDecoder().decode(WifiResponse.self, from: (httpResponseData?.data(using: .utf8)!)!)
                    print(ra.status)
                    print(ra.deviceId)
                    if (ra.status == "Connected")
                    {
                        self.showSuccess(msg: "Device " + ra.deviceId)
                    }
                } catch {
                    print(error)
                }
                
            }
        })
        
        dataTask.resume()
    }
    
    @IBAction func scanNearbyWifi(_ sender: Any) {
        self.essids.removeAll()
        DispatchQueue.main.async {
            self.myTableView.reloadData()
        }
        let alert = UIAlertController(title: nil, message: "Please wait...", preferredStyle: .alert)
        
        let loadingIndicator = UIActivityIndicatorView(frame: CGRect(x: 10, y: 5, width: 50, height: 50))
        loadingIndicator.hidesWhenStopped = true
        loadingIndicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyle.gray
        loadingIndicator.startAnimating();
        
        alert.view.addSubview(loadingIndicator)
        present(alert, animated: true, completion: nil)
        
        let headers = ["Content-Type" : "application/x-www-form-urlencoded",
                       "Accept-Language" : "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7",
                       "Connection" : "keep-alive",
                       "scan" : "1"]
        
        let postString = "" //ToDo: Cannot send the post data???
        
        var request = URLRequest(url: URL(string: wopinWifiURL)!)
        
        request.httpMethod = "POST"
        request.allHTTPHeaderFields = headers
        request.httpBody = postString.data(using: .ascii)
        
        let session = URLSession.shared
        let dataTask = session.dataTask(with: request, completionHandler: { (data, response, error) -> Void in
            if (error != nil) {
                print(error ?? "")
            } else {
                let httpResponse = response as? HTTPURLResponse
                print(httpResponse ?? "")
                let httpResponseData = String(data: data!, encoding: .utf8)
                var jsonString = String((httpResponseData?.dropLast())!)
                jsonString = "[" + jsonString + "]"
                
                do {
                    let ra = try JSONDecoder().decode([WifiScanResult].self, from: jsonString.data(using: .utf8)!)
                    for r in ra {
                        print(r.essid);
                        self.essids.append(r.essid)
                    }
                } catch {
                    print(error)
                }
                
                DispatchQueue.main.async {
                    self.myTableView.reloadData()
                }
            }
        })
        dismiss(animated: false, completion: nil)
        dataTask.resume()
    }

    @IBAction func scandeviceQR(_ sender: Any) {
        let cameraVc = UIImagePickerController()
        cameraVc.sourceType = UIImagePickerControllerSourceType.camera
        self.present(cameraVc, animated: true, completion: nil)
    }
    
    // MARK: - QRCodeReaderViewController Delegate Methods
    
    func reader(_ reader: QRCodeReaderViewController, didScanResult result: QRCodeReaderResult) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
    func readerDidCancel(_ reader: QRCodeReaderViewController) {
        reader.stopScanning()
        
        dismiss(animated: true, completion: nil)
    }
    
}

