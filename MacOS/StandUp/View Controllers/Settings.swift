//
//  Settings.swift
//  StandUp
//
//  Created by Peter on 08/10/19.
//  Copyright © 2019 Blockchain Commons, LLC
//

import Cocoa

class Settings: NSViewController {
    
    var filesList: [URL] = []
    var showInvisibles = false
    var selectedFolder:URL!
    var selectedItem:URL!
    let ud = UserDefaults.standard
    var seeLog = Bool()
    var standingDown = Bool()
    var args = [String]()
    var refreshing = Bool()
    
    @IBOutlet var directoryLabel: NSTextField!
    @IBOutlet var textInput: NSTextField!
    @IBOutlet var nodeLabelField: NSTextField!
    @IBOutlet var walletDisabled: NSButton!
    @IBOutlet var pruneOutlet: NSButton!
    @IBOutlet var txIndexOutlet: NSButton!
    @IBOutlet var goPrivateOutlet: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let d = Defaults()
        d.setDefaults() { [unowned vc = self] in
            vc.getSettings()
        }
    }
    
    // MARK: User Actions
    @IBAction func seeTorLog(_ sender: Any) {
        runScript(script: .showTorLog, env: ["":""], args: []) { _ in }
    }
    
    @IBAction func seeBtcLog(_ sender: Any) {
        let d = Defaults()
        let path = d.dataDir()
        let env = ["DATADIR":path]
        runScript(script: .showBitcoinLog, env: env, args: []) { _ in }
    }
        
    @IBAction func refreshHS(_ sender: Any) {
        
        actionAlert(message: "Refresh Hidden Service?", info: "This will remove your current Tor hidden service and start a new one, you will need to scan a new QuickConnect QR code to access your node remotely, all existing remote connections will fail.") { (response) in
            
            if response {
                
                DispatchQueue.main.async { [unowned vc = self] in
                    vc.refreshing = true
                    vc.performSegue(withIdentifier: "seeLog", sender: self)
                }
                
            }
            
        }
        
    }
    
    
    @IBAction func goPrivate(_ sender: Any) {
        
        let value = goPrivateOutlet.state
        
        if value == .on {
            
            actionAlert(message: "Go private?", info: "This sets your proxy to the local host and tors control port, binds localhost address, and sets listen to true in your bitcoin.conf, in plain english this means your node will only accept connections over the Tor network, this can make initial block download very slow, it is recommended to go private once your node is fully synced.") { [unowned vc = self] (response) in
                
                if response {
                    
                    vc.privateOn()
                    
                } else {
                    
                    vc.revert(outlet: vc.goPrivateOutlet)
                    
                }

            }
            
        } else {
            
            actionAlert(message: "Disable?", info: "This will enable your node to connect to other nodes over the clearnet, not just over tor, it is recommended to disable this setting when your node is doing the initial block download.") { [unowned vc = self] (response) in
                
                if response {
                    
                    vc.privateOff()
                    
                } else {
                    
                    vc.revert(outlet: vc.goPrivateOutlet)
                    
                }
                
            }
                        
        }
        
    }
    
    func privateOn() {
        
        var proxyExists = false
        var debugExists = false
        var bindExists = false
        var listenExists = false
        
        getBitcoinConf { (conf, error) in
            
            if !error {
                
                var stringConf = conf.joined(separator: "\n")
            
                for c in conf {
                    
                    if c.contains("=") {
                    
                        let arr = c.components(separatedBy: "=")
                        let k = arr[0]
                        let existingValue = arr[1]
                        
                        switch k {
                            
                        case "#debug":
                            
                            debugExists = true
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "debug=tor")
                            
                        case "#proxy":
                            
                            proxyExists = true
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "proxy=127.0.0.1:9050")
                            
                        case "#listen":
                            
                            listenExists = true
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "listen=1")
                            
                        case "#bindaddress":
                            
                            bindExists = true
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "bindaddress=127.0.0.1")
                            
                        default:
                            
                            break
                            
                        }
                        
                    }
                    
                }
                
                if !debugExists {
                    
                    stringConf = "debug=tor\n" + stringConf
                }
                
                if !proxyExists {
                    
                    stringConf = "proxy=127.0.0.1:9050\n" + stringConf
                    
                }
                
                if !listenExists {
                    
                    stringConf = "listen=1\n" + stringConf
                    
                }
                
                if !bindExists {
                    
                    stringConf = "bindaddress=127.0.0.1\n" + stringConf
                    
                }
                
                self.setBitcoinConf(conf: stringConf, activeOutlet: self.goPrivateOutlet, newValue: 3, key: "")
                
            } else {
                
                setSimpleAlert(message: "Error", info: "We had a problem getting your bitcoin.conf, please try again", buttonLabel: "OK")
                
            }
            
        }
        
    }
    
    func privateOff() {
        
        getBitcoinConf { (conf, error) in
            
            if !error {
                
                var stringConf = conf.joined(separator: "\n")
            
                for c in conf {
                    
                    if c.contains("=") {
                    
                        let arr = c.components(separatedBy: "=")
                        let k = arr[0]
                        let existingValue = arr[1]
                        
                        switch k {
                            
                        case "debug", "#debug":
                            
                            if existingValue == "tor" {
                                
                                stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "#debug=\(existingValue)")
                                
                            }
                            
                        case "proxy", "#proxy":
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "#proxy=\(existingValue)")
                            
                        case "listen", "#listen":
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "#listen=\(existingValue)")
                            
                        case "bindaddress", "#bindaddress":
                            
                            stringConf = stringConf.replacingOccurrences(of: "\(k + "=" + existingValue)", with: "#bindaddress=\(existingValue)")
                            
                        default:
                            break
                            
                        }
                        
                    }
                    
                }
                
                self.setBitcoinConf(conf: stringConf, activeOutlet: self.goPrivateOutlet, newValue: 3, key: "")
                
            } else {
                
                setSimpleAlert(message: "Error", info: "We had a problem getting your bitcoin.conf, please try again", buttonLabel: "OK")
                
            }
            
        }
        
    }
    
    
    @IBAction func seeStandUpLog(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            self.seeLog = true
            self.standingDown = false
            self.performSegue(withIdentifier: "seeLog", sender: self)
            
        }
        
    }
    
    @IBAction func backAction(_ sender: Any) {
        
        goBackAndRefresh()
        
    }
    
    @IBAction func removeStandUp(_ sender: Any) {
        
        DispatchQueue.main.async {
            
            actionAlert(message: "Danger!", info: "This will remove the StandUp directory including all its contents!\n\nThis will remove tor config, tor hidden services and uninstall tor.\n\nAre you aure you want to do this?") { (response) in
                
                if response {
                    
                    self.seeLog = false
                    self.standingDown = true
                    self.performSegue(withIdentifier: "seeLog", sender: self)
                    
                } else {
                    
                    print("tapped no")
                    
                }
                
            }
            
        }
        
    }
    
    @IBAction func removeBitcoinCore(_ sender: Any) {
        DispatchQueue.main.async { [unowned vc = self] in
            actionAlert(message: "Danger!", info: "This will remove the Bitcoin directory! All Bitcoin Core data including your wallets will be deleted!\n\nAre you sure you want to continue?") { response in
                if response {
                    let d = Defaults()
                    let env = ["DATADIR":d.dataDir()]
                    vc.runScript(script: .removeBitcoin, env: env, args: []) { success in
                        if success {
                            setSimpleAlert(message: "Bitcoin directory and its contents were deleted", info: "", buttonLabel: "OK")
                        } else {
                           setSimpleAlert(message: "Error", info: "There was an issue deleting the directory", buttonLabel: "OK")
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func saveNodeLabel(_ sender: Any) {
        
        if nodeLabelField.stringValue != "" {
            ud.set(nodeLabelField.stringValue, forKey: "nodeLabel")
            setSimpleAlert(message: "Success", info: "Node label updated to: \(nodeLabelField.stringValue)", buttonLabel: "OK")
        }
        
    }
    
    @IBAction func didSetWalletDisabled(_ sender: Any) {
        
        let value = walletDisabled.state.rawValue
        getBitcoinConf { (conf, error) in
            
            if !error {
                
                self.parseBitcoinConf(conf: conf, keyToUpdate: .disablewallet, outlet: self.walletDisabled, newValue: value)
                
            }
            
        }
        
    }
    
    @IBAction func didSetPrune(_ sender: Any) {
        
        let value = pruneOutlet.state.rawValue
        getBitcoinConf { (conf, error) in
            
            if !error {
                
                self.parseBitcoinConf(conf: conf, keyToUpdate: .prune, outlet: self.pruneOutlet, newValue: value)
                
            }
            
        }
    }
    
    @IBAction func didSetTxIndex(_ sender: Any) {
        
        let value = txIndexOutlet.state.rawValue
        getBitcoinConf { (conf, error) in
            
            if !error {
                
                self.parseBitcoinConf(conf: conf, keyToUpdate: .txindex, outlet: self.txIndexOutlet, newValue: value)
                
            }
            
        }
        
    }
    
    @IBAction func chooseDirectory(_ sender: Any) {
        
        guard let window = view.window else { return }
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.beginSheetModal(for: window) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                self.selectedFolder = panel.urls[0]
                DispatchQueue.main.async {
                    self.directoryLabel.stringValue = self.selectedFolder?.path ?? Defaults().dataDir()
                    self.ud.set(self.directoryLabel.stringValue, forKey: "dataDir")
                    self.getSettings()
                }
            }
        }
        
    }
    
    @IBAction func addPubkey(_ sender: Any) {
        
        if textInput.stringValue != "" {
            
            let descriptor = textInput.stringValue.replacingOccurrences(of: " ", with: "")
            
            if descriptor.hasPrefix("descriptor:x25519:") {
                
                DispatchQueue.main.async {
                    
                    actionAlert(message: "Add Tor V3 authentication key?", info: descriptor) { (response) in
                        
                        if response {
                            
                            self.authenticate()
                            
                        } else {
                            
                            print("tapped no")
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                setSimpleAlert(message: "Error", info: "Incorrect format, the correct format is:\n\ndescriptor:x25519:<public key here>", buttonLabel: "OK")
                
            }
            
        }
        
    }
    
    // MARK: Action Logic
    
    func setLog(content: String) {
        
        let lg = Log()
        lg.writeToLog(content: content)
        
    }
    
    func setBitcoinConf(conf: String, activeOutlet: NSButton, newValue: Int, key: String) {
        let d = Defaults()
        let env = ["CONF":conf,"DATADIR":d.dataDir()]
        runScript(script: .updateBTCConf, env: env, args: args) { [unowned vc = self] success in
            if success {
                if newValue < 2 {
                    vc.ud.set(newValue, forKey: key)
                }
                setSimpleAlert(message: "Success", info: "bitcoin.conf updated", buttonLabel: "OK")
            } else {
                setSimpleAlert(message: "Error Updating bitcoin.conf", info: "", buttonLabel: "OK")
            }
        }
    }
    
    func revert(outlet: NSButton) {
        
        DispatchQueue.main.async {
            outlet.setNextState()
        }
        
    }
    
    func parseBitcoinConf(conf: [String], keyToUpdate: BTCCONF, outlet: NSButton, newValue: Int) {
        print("parseBitcoinConf")
        print("conf = \(conf)")
        print("keytoupdate = \(keyToUpdate)")
        print("outlet = \(outlet)")
        print("newValue = \(newValue)")
        
        var isUpdatingCorrectNetwork = false
        var isSectioned = false
        var sectionToUpdate = ""
        var section = ""
        var network = ""
        let mainnet = ud.object(forKey: "mainnet") as! Int
        let testnet = ud.object(forKey: "testnet") as! Int
        
        if mainnet == 1 {
            network = "mainnet"
        }
        if testnet == 1 {
            network = "testnet"
        }
        
        func alertSettingNotForCurrentNetwork() {
            
            setSimpleAlert(message: "Error", info: "You are attempting to update a setting that is network specific. You must select the correct network first then update the setting.", buttonLabel: "OK")
            
        }
        
        func updateSectionConfArray(conf: [String], oldValue: Int, newValue: Int, key: String, sectionToUpdate: String, network: String) {
            
            // manipulate the conf array then call setBitcoinConf()
            var isInOurSection = false
            var currentSection = ""
            
            for (index, c) in conf.enumerated() {
                
                // find the section first
                if c.contains(sectionToUpdate) {
                    
                    isInOurSection = true
                    print("c = \(c)")
                    currentSection = c
                    
                }
                
                if c.contains("=") && isInOurSection {
                    
                    print("these are the settings in our section")
                    let arr = c.components(separatedBy: "=")
                    let k = arr[0]
                    let existingValue = arr[1]
                    print("k = \(k)")
                    print("existingValue = \(existingValue)")
                    
                    if k == key {
                        
                        print("in section \(currentSection)")
                        print("this is the setting to update: \(k)=\(existingValue) to \(k)=\(newValue)")
                        var updatedConf = conf
                        updatedConf[index] = "\(k)=\(newValue)"
                        let stringConf = updatedConf.joined(separator: "\n")
                        print("stringConf = \(stringConf)")
                        setBitcoinConf(conf: stringConf, activeOutlet: outlet, newValue: newValue, key: key)
                    }
                    
                }
                
                if c.contains("[") && !c.contains(sectionToUpdate) {
                    
                    isInOurSection = false
                    
                }
                
            }
            
        }
        
        for setting in conf {
            
            if setting.contains("=") {
                print("contains =")
                
                let arr = setting.components(separatedBy: "=")
                let key = arr[0]
                let value = arr[1]
                print("key = \(key)")
                print("value = \(value)")
                print("keytoupdate = \(keyToUpdate.rawValue)")
                
                func confirmForNetworkSpecificChange() {
                    
                    actionAlert(message: "Update bitcoin.conf?", info: "You are attemtping to update \(key)=\(value) to \(key)=\(newValue) in the \(section) section of your bitcoin.conf.\n\nIn order for the changes to take effect you will need to restart Bitcoin Core.\n\nAre you sure you want to proceed?") { (response) in
                        
                        if response {
                            
                            print("do it")
                            
                            if let i = Int(value) {
                                
                                updateSectionConfArray(conf: conf, oldValue: i, newValue: newValue, key: key, sectionToUpdate: sectionToUpdate, network: network)
                                
                            } else {
                                
                                setSimpleAlert(message: "Error", info: "We had an error updating your bitcoin.conf file", buttonLabel: "OK")
                                
                            }
                            
                        } else {
                            
                            print("user said no")
                            self.revert(outlet: outlet)
                            
                        }
                        
                    }
                    
                }
                
                if keyToUpdate.rawValue == key {
                    
                    print("global setting")
                    print("this is the existing setting that we want to change")
                    print("key = \(key)")
                    print("existing value = \(value)")
                    print("new value = \(newValue)")
                    //prompt user that this is a global setting in the bitcoin.conf not network specific
                    
                    if isSectioned {
                        
                        //we are in a section
                        print("our key is in a section: \(section)")
                        print("key = \(key)")
                        print("value = \(value)")
                        
                        if network == "mainnet" {
                            
                            sectionToUpdate = "[main]"
                            
                        } else if network == "testnet" {
                            
                            sectionToUpdate = "[test]"
                            
                        } else if network == "regtest" {
                            
                            sectionToUpdate = "[regtest]"
                            
                        }
                        
                        print("sectionToUpdate = \(sectionToUpdate)")
                        
                        switch section {
                            
                        case "[main]", "[test]", "[regtest]":
                            
                            if sectionToUpdate == section {
                                
                                isUpdatingCorrectNetwork = true
                                confirmForNetworkSpecificChange()
                                
                            }
                            
                        default:
                            
                            break
                            
                        }
                        
                    } else {
                        
                        print("our key is global")
                        isUpdatingCorrectNetwork = true
                        
                        actionAlert(message: "Update bitcoin.conf?", info: "You are attemtping to update \(key)=\(value) to \(key)=\(newValue).\n\nThis is a global setting and will apply to all networks.\n\nIn order for the changes to take effect you will need to restart Bitcoin Core.\n\nAre you sure you want to proceed?") { (response) in
                            
                            if response {
                                
                                print("user said do it")
                                
                                if let i = Int(value) {
                                    
                                    self.updateGlobalConfArray(conf: conf, oldValue: i, newValue: newValue, key: key, outlet: outlet)
                                    
                                } else {
                                    
                                    setSimpleAlert(message: "Error", info: "We had an error updating your bitcoin.conf file", buttonLabel: "OK")
                                    
                                }
                                
                            } else {
                                
                                print("user said no")
                                self.revert(outlet: outlet)
                                
                            }
                            
                        }
                        
                    }
                    
                }
                
            } else {
                
                // these vaues are the sections, can specify network specific settings here
                print("this should be a network section: \(setting)")
                section = setting
                isSectioned = true
                
            }
            
        }
        
        if !isUpdatingCorrectNetwork && section != "" {
            
            alertSettingNotForCurrentNetwork()
            revert(outlet: outlet)
            
        }
        
    }
    
    func updateGlobalConfArray(conf: [String], oldValue: Int, newValue: Int, key: String, outlet: NSButton) {
        print("updateGlobalConfArray")
        
        // assuming there will only ever be one global instance of any given setting in bitcoin.conf outside of sections
        
        for c in conf {
            
            if c.contains("=") {
                
                let arr = c.components(separatedBy: "=")
                let k = arr[0]
                let existingValue = arr[1]
                print("k = \(k)")
                print("key = \(key)")
                
                if k.contains(key) {
                    
                    print("same")
                    
                    if let ev = Int(existingValue) {
                        
                        if oldValue == ev {
                            
                            var stringConf = conf.joined(separator: "\n")
                            stringConf = stringConf.replacingOccurrences(of: "\(key + "=" + existingValue)", with: "\(key + "=")\(newValue)")
                            setBitcoinConf(conf: stringConf, activeOutlet: outlet, newValue: newValue, key: key)
                            
                        }
                        
                    }
                    
                }
                
            }
            
        }
        
    }
    
    func authenticate() {
        
        let filename = randomString(length: 10)
        let pubkey = self.textInput.stringValue
        runScript(script: .authenticate, env: ["":""], args: [pubkey,filename]) { success in
            if success {
                DispatchQueue.main.async { [unowned vc = self] in
                    setSimpleAlert(message: "Successfully added auth key", info: "Important! Tor is now restarting, authentication will not come into effect until this completes.\n\nYou may get an \"Internet not connected error\" when reconnecting to your node, just keep tapping the refresh button until the app connects, it is normal to have a connectivity issue immediately after restarting Tor.", buttonLabel: "OK")
                    vc.textInput.stringValue = ""
                    vc.textInput.resignFirstResponder()
                }
            } else {
                setSimpleAlert(message: "Error", info: "error authenticating", buttonLabel: "OK")
            }
        }
    }
    
    func getBitcoinConf(completion: @escaping ((conf: [String], error: Bool)) -> Void) {
        guard let path = Bundle.main.path(forResource: SCRIPT.getRPCCredentials.rawValue, ofType: "command") else {
            return
        }
        let stdOut = Pipe()
        let task = Process()
        task.launchPath = path
        task.environment = ["DATADIR":Defaults().dataDir()]
        task.standardOutput = stdOut
        task.launch()
        task.waitUntilExit()
        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            let conf = output.components(separatedBy: "\n")
            completion((conf, false))
        } else {
            completion(([""], true))
        }
    }
        
    // MARK: Update User Interface
    
    func goBackAndRefresh() {
        DispatchQueue.main.async { [unowned vc = self] in
            if let presenter = vc.presentingViewController as? ViewController {
                presenter.isBitcoinOn()
            }
            vc.dismiss(vc)
        }
    }
    
    func setState(int: Int, outlet: NSButton) {
        print("int = \(int) outlet = \(outlet)")
        if int == 1 {
            DispatchQueue.main.async {
                outlet.state = .on
            }
                        
        } else if int == 0 {
            DispatchQueue.main.async {
                outlet.state = .off
            }
        }
    }
    
    func getSettings() {
        print("getSettings")
                
        let d = Defaults()
        setState(int: d.prune(), outlet: pruneOutlet)
        setState(int: d.txindex(), outlet: txIndexOutlet)
        setState(int: d.walletdisabled(), outlet: walletDisabled)
        setState(int: d.isPrivate(), outlet: goPrivateOutlet)
        
        if ud.object(forKey: "dataDir") != nil {
                        
            DispatchQueue.main.async {
                self.directoryLabel.stringValue = d.dataDir()
            }
            
        }
        
        if ud.object(forKey: "nodeLabel") != nil {
            
            DispatchQueue.main.async {
                self.nodeLabelField.stringValue = self.ud.object(forKey: "nodeLabel") as! String
            }
            
        }
        
    }
    
    func getSetting(key: BTCCONF, button: NSButton, def: Int) {
        print("getsetting")
        
        if ud.object(forKey: key.rawValue) == nil {
            ud.set(def, forKey: key.rawValue)
        } else {
            let raw = ud.integer(forKey: key.rawValue)
            if raw == 0 {
                DispatchQueue.main.async {
                    button.state = .off
                }
            } else {
                DispatchQueue.main.async {
                    button.state = .on
                }
            }
        }
        
    }
    
    func setOutlet(outlet: NSButton, keyOn: BTCCONF) {
        print("setoutlet")
        let b = outlet.state.rawValue
        let key = keyOn.rawValue
        ud.set(b, forKey: key)
        print("set key: \(key) to \(b)")
        if b == 0 {
            ud.set(1, forKey: key)
            print("set key: \(key) to 1")
        }
    }
    
    private func runScript(script: SCRIPT, env: [String:String], args: [String], completion: @escaping ((Bool)) -> Void) {
        #if DEBUG
        print("script: \(script.rawValue)")
        #endif
        let resource = script.rawValue
        guard let path = Bundle.main.path(forResource: resource, ofType: "command") else {
            return
        }
        let stdOut = Pipe()
        let task = Process()
        task.launchPath = path
        task.environment = env
        task.arguments = args
        task.standardOutput = stdOut
        task.launch()
        task.waitUntilExit()
        let data = stdOut.fileHandleForReading.readDataToEndOfFile()
        var result = ""
        if let output = String(data: data, encoding: .utf8) {
            #if DEBUG
            print("result: \(output)")
            #endif
            result += output
            completion(true)
        } else {
            completion(false)
        }
    }
    
    // MARK: Miscellaneous
    
    func infoAbout(url: URL) -> String {
      return "No information available for \(url.path)"
    }
    
    func contentsOf(folder: URL) -> [URL] {
      return []
    }
    
    override func prepare(for segue: NSStoryboardSegue, sender: Any?) {
        
        switch segue.identifier {
            
        case "seeLog":
            
            if let vc = segue.destinationController as? Installer {
                
                vc.refreshing = refreshing
                vc.seeLog = seeLog
                vc.standingDown = standingDown
                
            }
            
        default:
            
            break
            
        }
        
    }
    
}
