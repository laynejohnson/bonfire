//
//  ChatViewController.swift
//  Bonfire
//
//  Created by Layne Johnson on 7/28/21.
//  Copyright © 2021. All rights reserved.

import Foundation
import UIKit
import Firebase

// TODO: Implement MessageKit: https://cocoapods.org/pods/MessageKit
// TODO: Add fire to nav bar
// TODO: Add user features

/*
 
 let user = Auth.auth().currentUser
 if let user = user {
 // The user's ID, unique to the Firebase project.
 // Do NOT use this value to authenticate with your backend server,
 // if you have one. Use getTokenWithCompletion:completion: instead.
 let uid = user.uid
 let email = user.email
 let photoURL = user.photoURL
 var multiFactorString = "MultiFactor: "
 for info in user.multiFactor.enrolledFactors {
 multiFactorString += info.displayName ?? "[DispayName]"
 multiFactorString += " "
 }
 // ...
 }
 */



class ChatViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var messageTextField: UITextField!
    @IBOutlet weak var sendButton: UIButton!
    
    let db = Firestore.firestore()
    
    var messages: [Message] = [
        
        // Test messages
        //        Message(sender: Constants.testChatter1, body: "Hello, friend"),
        //        Message(sender: Constants.testChatter2, body: "Hello, dear friend")
        
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        title = Constants.appName
        navigationItem.hidesBackButton = true
        
        tableView.dataSource = self
        
        // Dismiss keyboard with tap gesture
        let tapGesture = UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing))
        view.addGestureRecognizer(tapGesture)
        
        // If gesture blocks other touches
        // tapGesture.cancelsTouchesInView = false
        
        tableView.register(UINib(nibName: Constants.cellNibName, bundle: nil), forCellReuseIdentifier: Constants.cellIdentifier)
        
        loadMessages()
    }
    
    func loadMessages() {
        
        // Listen for Firestore updates.
        db.collection(Constants.FStore.collectionName)
            .order(by: Constants.FStore.dateField)
            .addSnapshotListener { querySnapshot, error in
            
            self.messages = []
            
            if let e = error {
                print("There was a problem retrieving data from Firestore: \(e)")
            } else {
                if let snapshotDocuments = querySnapshot?.documents {
                    for doc in snapshotDocuments {
                        let data = doc.data()
                        if let sender = data[Constants.FStore.senderField] as? String, let messageBody = data[Constants.FStore.bodyField] as? String {
                            let newMessage = Message(sender: sender, body: messageBody)
                            self.messages.append(newMessage)
                            
                            // Fetch main thread:
                            // Process happens in a closure (process happens in background); main thread must be fetched (process happening in foreground
                            DispatchQueue.main.async {
                                self.tableView.reloadData()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @IBAction func logOutPressed(_ sender: UIBarButtonItem) {
        
        let firebaseAuth = Auth.auth()
        
        do {
            try firebaseAuth.signOut()
            navigationController?.popToRootViewController(animated: true)
            
        } catch let signOutError as NSError {
            print("Error signing out: %@", signOutError)
        }
    }
    
    
    @IBAction func sendPressed(_ sender: Any) {
        
        if let messageBody = messageTextField.text, let messageSender = Auth.auth().currentUser?.email {
            
            db.collection(Constants.FStore.collectionName).addDocument(data: [
                Constants.FStore.senderField: messageSender,
                Constants.FStore.bodyField: messageBody,
                Constants.FStore.dateField: Date().timeIntervalSince1970
            ]) { (error) in
                if let e = error {
                    print("There was a problem saving data to Firestore: \(e)")
                } else {
                    print("Data saved successfully")
                }
            }
        }
    }
} // End ChatViewController

extension ChatViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Constants.cellIdentifier, for: indexPath) as! MessageCell
        
        cell.bubbleLabel.textColor = UIColor.black
        cell.bubbleLabel.text = messages[indexPath.row].body
        
        return cell
    }
    
    
}
