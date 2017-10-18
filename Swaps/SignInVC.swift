//
//  SignInVC.swift
//  Swaps
//
//  Created by Tevin Scott on 10/12/17.
//  Copyright © 2017 Tevin Scott. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import GoogleSignIn

/// Manages the Sign In View and the Google Sign In Authentication that occurs within the view
class SignInVC : UIViewController, GIDSignInUIDelegate, GIDSignInDelegate{
    
    // MARK: - Attributes
    let coreDataManager: CoreDataManager = CoreDataManager.init()
    
    // MARK: - Button Action
    @IBAction func googleBtnTapped(_ sender: Any) {
        GIDSignIn.sharedInstance().signIn()
    }
    
    
    // MARK: - Google Sign-In Functions

    /**
     Signs in the user to Google & Firebase
     */
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        print("Sign in called")
        if (user != nil){
            if let authentication = user.authentication {
                let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken, accessToken: authentication.accessToken)
                 print("authenticating!!!!!!!!!")
                FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) -> Void in
                    if error != nil {
                        print("Problem at signing in with google with error : \(String(describing: error))")
                    } else if error == nil {
                        self.performSegue(withIdentifier: "goToFeed", sender: self)
                        print("user signed in")
                    }
                })
            }
        }
    }
    
    /**
     Asks the delegate to open a resource specified by a URL, and provides a dictionary of launch options.
     
     - parameters:
         - application: Your singleton app object.
         - url:         The URL resource to open. This resource can be a network resource or a file. For information about
                         the Apple-registered URL schemes, see Apple URL Scheme Reference.
         - options:     A dictionary of URL handling options. For information about the possible keys in this dictionary and how to handle them,
                         see UIApplicationOpenURLOptionsKey. By default, the value of this parameter is an empty dictionary.
     */
    @available(iOS 9.0, *)
    func application(_ application: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any])
        -> Bool {
            return GIDSignIn.sharedInstance().handle(url,
                                                     sourceApplication:options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
                                                     annotation: [:])
    }
    
    /**
     signed out the user from Firebase & Google
     */
    private func signOut(){
        try! FIRAuth.auth()!.signOut()
        GIDSignIn.sharedInstance().signOut()
    }
    
    // MARK: - View controller life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        signOut()
        coreDataManager.deleteAll()
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        GIDSignIn.sharedInstance().delegate = self
        FIRAuth.auth()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        GIDSignIn.sharedInstance().uiDelegate = self
    }
}
