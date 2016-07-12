//
//  LoginViewController.swift
//  PomeloDemo
//
//  Created by little2s on 16/7/12.
//  Copyright © 2016年 little2s. All rights reserved.
//

import UIKit
import NTYPomeloKit

class LoginViewController: UITableViewController {

    @IBOutlet weak var accountField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    
    var pomelo: NTYPomelo!
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return indexPath.section == 0 ? nil : indexPath
    }
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        if indexPath.section == 1 && indexPath.row == 0 {
            login()
        }
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
    }
    
    func login() {
        
        guard let account = accountField.text, password = passwordField.text where !account.isEmpty && !password.isEmpty else {
            return
        }
        
        let resource = ChatAdapterAPI.loginResourceWithAccount(account, password: password, type: "tel")
        
        requestChatAdapterResource(resource, modifyRequest: nil) { [weak self] result in
            
            switch result {
            case .Success(let info):
                
                self?.connectToServer(info.server, userId: info.userInfo.userId, token: info.token)
                
            case .Failure(_):
                break
            }
            
        }
        
    }
    
    typealias Server = ChatAdapterAPI.Server
    
    func connectToServer(server: Server, userId: String, token: String) {
        
        func enterEntry() {
            
            let params: JSONObject = [
                "uid": userId,
                "access_token": token
            ]
            
            pomelo.requestWithRoute("connector.entryHandler.enter", andParams: params) { data in
                
                print("entry enter callback, data=\(data)")
                
            }
            
        }
        
        pomelo = NTYPomelo(delegate: self)
        
        pomelo.connectToHost(server.host, onPort: server.port) { data in
            
            print("connect pomelo callback, data=\(data)")
            
            enterEntry()
            
        }
        
    }
    
}

extension LoginViewController: NTYPomeloDelegate {
    
    func PomeloDidConnect(pomelo: NTYPomelo!) {
        print("pomelo did connect")
    }
    
    func PomeloDidDisconnect(pomelo: NTYPomelo!, withError error: NSError!) {
        print("pomelo did disconnect")
        
    }
    
}