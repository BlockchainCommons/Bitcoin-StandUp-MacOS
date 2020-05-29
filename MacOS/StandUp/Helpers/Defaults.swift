//
//  Defaults.swift
//  StandUp
//
//  Created by Peter on 23/11/19.
//  Copyright © 2019 Blockchain Commons, LLC
//

import Foundation

class Defaults {
    
    private func getBitcoinConf(completion: @escaping ((conf: [String], error: Bool)) -> Void) {
        print("getbitcoinconf")
        
        let runBuildTask = RunBuildTask()
        runBuildTask.args = []
        runBuildTask.env = ["DATADIR":dataDir()]
        runBuildTask.showLog = false
        runBuildTask.exitStrings = ["Done"]
        runBuildTask.runScript(script: .getRPCCredentials) {
            
            if !runBuildTask.errorBool {
                
                let conf = runBuildTask.stringToReturn.components(separatedBy: "\n")
                completion((conf, false))
                
            } else {
                
                completion(([""], true))
                setSimpleAlert(message: "Error", info: runBuildTask.errorDescription, buttonLabel: "OK")
                
            }
            
        }
        
    }
    
    let ud = UserDefaults.standard
    
    func setDefaults(completion: @escaping () -> Void) {
        
        if ud.object(forKey: "dataDir") == nil {
            
            ud.set("/Users/\(NSUserName())/Library/Application Support/Bitcoin", forKey: "dataDir")
            
        }
        
        func setLocals() {
            
            print("setlocals")
            
            if ud.object(forKey: "pruned") == nil {
                
                ud.set(1, forKey: "pruned")
                
            }
            
            if ud.object(forKey: "txindex") == nil {
                
                ud.set(0, forKey: "txindex")
                
            }
            
            if ud.object(forKey: "walletdisabled") == nil {
                
                ud.set(0, forKey: "walletdisabled")
                
            }
            
            completion()
            
        }
        
        getBitcoinConf { (conf, error) in
            
            var proxyOn = false
            var listenOn = false
            var bindOn = false
            
            if !error {
                
                if conf.count > 0 {
                    
                    for setting in conf {
                        
                        if setting.contains("=") {
                            
                            let arr = setting.components(separatedBy: "=")
                            let k = arr[0]
                            let existingValue = arr[1]
                            
                            switch k {
                                
                            case "proxy":
                            
                                if existingValue == "127.0.0.1:9050" {
                                    
                                    proxyOn = true
                                    
                                }
                                
                            case "listen":
                                
                                if Int(existingValue) == 1 {
                                    
                                    listenOn = true
                                    
                                }
                                
                            case "bindaddress":
                                
                                if existingValue == "127.0.0.1" {
                                    
                                    bindOn = true
                                    
                                }
                                
                            case "testnet":
                                                                
                                if Int(existingValue) == 1 {
                                
                                    //self.ud.set(0, forKey: "mainnet")
                                    // MARK: TODO - throw an error as specifying a network in the conf file is incompatible with Standup
                                
                                }
                                
                            case "prune":
                                
                                self.ud.set(Int(existingValue), forKey: "prune")
                                
                                if Int(existingValue) == 1 {
                                
                                    self.ud.set(0, forKey: "txindex")
                                
                                }
                                
                            case "disablewallet":
                                
                                self.ud.set(Int(existingValue), forKey: "disablewallet")
                                
                            case "txindex":
                                
                                self.ud.set(Int(existingValue), forKey: "txindex")
                                
                                if Int(existingValue) == 1 {
                                
                                    self.ud.set(0, forKey: "prune")
                                
                                }
                                
                            default:
                                
                                break
                                
                            }
                            
                        }
                        
                    }
                    
                    if bindOn && proxyOn && listenOn {
                        
                        self.ud.set(1, forKey: "isPrivate")
                        
                    } else {
                        
                        self.ud.set(0, forKey: "isPrivate")
                        
                    }
                    
                    setLocals()
                    
                }
                
            } else {
                
                setLocals()
                print("error getting conf")
                
            }
            
        }
        
        if ud.object(forKey: "nodeLabel") == nil {
            
            ud.set("StandUp Node", forKey: "nodeLabel")
            
        }
        
    }
    
    func dataDir() -> String {
        
        return ud.object(forKey:"dataDir") as? String ?? "/Users/\(NSUserName())/Application Support/Bitcoin"
        
    }
    
    func isPrivate() -> Int {
        
        return ud.object(forKey: "isPrivate") as? Int ?? 0
        
    }
    
    func prune() -> Int {
        
        return ud.object(forKey:"prune") as? Int ?? 0
        
    }
    
    func txindex() -> Int {
        
        return ud.object(forKey: "txindex") as? Int ?? 0
        
    }
    
    func walletdisabled() -> Int {
        
        return ud.object(forKey: "disablewallet") as? Int ?? 0
        
    }
    
    func setDataDir(value: String) {
        
        ud.set(value, forKey: "dataDir")
        
    }
    
    func existingVersion() -> String {
        return ud.object(forKey: "version") as? String ?? "0.20.0rc1"
    }
    
    func existingBinary() -> String {
        return ud.object(forKey: "macosBinary") as? String ?? "bitcoin-\(existingVersion())-osx64.tar.gz"
    }
    
    func existingPrefix() -> String {
        return ud.object(forKey: "binaryPrefix") as? String ?? "bitcoin-\(existingVersion())"
    }

}

