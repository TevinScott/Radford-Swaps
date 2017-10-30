//
//  DataManager.swift
//  Radford Swaps
//
//  Created by Tevin Scott on 9/22/17.
//  Copyright © 2017 Tevin Scott. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FirebaseDatabase
import FirebaseStorage
import GoogleSignIn

/// An Interace for accessing the FireBase Database
class FirebaseDataManager {
    
    // MARK: - Attributes
    private let rootRef = Database.database().reference()
    private var saleRef: DatabaseReference!
    private var userRef: DatabaseReference!
    private var databaseHandle: DatabaseHandle!
    private var itemKeyDictionary = [String: Int]()
    private var hashIndex = 0;
    var listOfItems = [SaleItem]()
    
    // MARK: - Initializer
    init(){
        saleRef = rootRef.child("Sale Items")
        userRef = rootRef.child("UserAccounts")
    }
    
    // MARK: - Get Data
    /**
     adds new items to the class variable listOfItems and removes sales items that are no longer in the database
     
     - parameters:
     - completion: on completion the escaping value [SaleItem] is instatiated from the FireBase list of Sale Items
     
     */
    func getAllItems(completion: @escaping ([SaleItem]) -> ()){
        saleRef?.observe(DataEventType.value, with: { (snapshot:DataSnapshot) in
            if let result = snapshot.children.allObjects as? [DataSnapshot] {
                for child in result {
                    if(self.itemKeyDictionary[child.key] == nil){
                        let aSaleItem = SaleItem.init(snapshot: child)
                        
                        self.listOfItems.append(aSaleItem)
                        self.itemKeyDictionary[child.key] = self.hashIndex
                        self.hashIndex += 1
                    }
                }
                completion(self.listOfItems)
            }
        })
        saleRef?.observe(.childRemoved, with: { (snapshot) -> Void in
            let index = self.indexOfMessage(snapshot: snapshot)
            self.listOfItems.remove(at: index)
            completion(self.listOfItems)
        })
        
    }
    
    /**
     checks if the current User's account is in the Firebase database
     
     - Parameters:
         - userAccountInfo: the account for which will be checked.
         - completion:  returns true if the user already exists in firebase database
     */
    func checkUserAccount(userInfo: UserAccountInfo, completion: @escaping(Bool) ->()){
        userRef.queryOrdered(byChild: "name").queryStarting(atValue: userInfo.userID).queryEnding(atValue: userInfo.userID+"\u{f8ff}").observe(.value, with:
            { snapshot in })
    }

    /**
     Returns the index of the saleItem that has been deleted from the firebase database
     
     - Parameter snapshot: a snapshot of the data that has been removed from the firebase database
     
     - returns: the index location in listOfItems of the saleItem that has been deleted from the database
     */
    private func indexOfMessage(snapshot: DataSnapshot) -> Int {
        var index = 0
        for  saleItem in self.listOfItems {
            if (snapshot.key == saleItem.itemID) {
                return index
            }
            index += 1
        }
        return -1
    }

    /**
     uploads a SaleItem Object's values to Firebase Cloud Storage.
     Firebase Storage for the item image.
     Firebase Database for item name, price, description, category and, a URL reference to the image in Firebase Storage.
     
     - Parameter saleItem: the saleItem Object for which will be Uploaded
     */
    func uploadSaleItem(inputSaleItem: SaleItem){

        uploadItemImage(saleItem: inputSaleItem){ (completedURL) -> () in //image upload
            inputSaleItem.imageURL = completedURL
            self.uploadSaleItemToDatabase(saleItem: inputSaleItem) //saleItem upload
        }
    }
    
    // MARK: - Update & Upload Data
    /**
     updates the current user's saleitem and stores it within the firebase database
     
     - Parameters:
         - saleItem:        a reference to the saleItem that is to be updated within the database
         - imageChanged:    specifies if the saleItem image needs to also be updated in firebase storage should this value be true
     */
    func updateDatabaseSaleItem(saleItem: SaleItem, imageChanged: Bool, previousURL: String){
        if( Auth.auth().currentUser!.uid == saleItem.userID){
            saleRef.child(saleItem.itemID!).updateChildValues(["name": saleItem.name!,
                                                               "price" : saleItem.price!,
                                                               "desc" : saleItem.description!])
                if(imageChanged){
                    self.uploadItemImage(saleItem: saleItem){ (completedURL) -> () in
                        self.deleteImageInFireStorage(imageURL: saleItem.imageURL!)
                        saleItem.imageURL = completedURL
                        self.deleteImageInFireStorage(imageURL: previousURL)
                        self.saleRef.child(saleItem.itemID!).updateChildValues(["imageURL" : completedURL])
                    }
                }
        }
    }
    
    /**
     Uploads The current image stored in the given saleItem object to Firebase Storage and returns the URL reference.
     
     - Parameter saleItem: a reference to the saleItem for which the containing image will be uploaded
     - parameter completionURL: URL that references the image in firebase storage
     
     */
    private func uploadItemImage(saleItem: SaleItem, completionURL: @escaping (String) -> ()){
        let fileStorage = Storage.storage().reference().child("\(String(describing: saleItem.name!)).png")
        if let imageToUpload = UIImagePNGRepresentation(saleItem.image!) {
            fileStorage.putData(imageToUpload, metadata: nil, completion: {
                (metadata, error) in
                if(error != nil){
                    return
                }
                completionURL((metadata?.downloadURL()?.absoluteString)!)
            })
        }
        
    }
    
    /**
     this function is to ONLY assist uploadSaleItemToAll
     uploads a SaleItems Object's values ONLY to Firebase Database.
     
     - Parameter saleItem: the item for which the value of will be uploaded
 
     */
    private func uploadSaleItemToDatabase(saleItem: SaleItem){
        
        let saleItemDictionary : [String : AnyObject] = ["name" : saleItem.name as AnyObject,
                                                         "price" : saleItem.price as AnyObject,
                                                         "desc" : saleItem.description as AnyObject,
                                                         "imageURL" : saleItem.imageURL as AnyObject,
                                                         "category" : saleItem.category as AnyObject,
                                                         "userID" : saleItem.userID as AnyObject,]
        saleRef.childByAutoId().setValue(saleItemDictionary)
    }
    
    /**
     updates a current user account should the user decide to user their One time username Change
     
     - parameter userAccountInfo: a reference to the userAccountInfo that represents the modified information of a users account info
     */
    func updateUserAccountInfo(userAccountInfo: UserAccountInfo){
        let query = userRef.queryOrderedByKey().queryEqual(toValue: userAccountInfo.userID)
        query.observe(.childAdded, with: { (snapshot) in
            snapshot.ref.updateChildValues(["chosenUsername" : userAccountInfo.chosenUsername,
                                            "nameChangeUsed" : String(userAccountInfo.oneTimeNameChangeUsed)])
        })
    }
    
    /**
     Uploads a UserAccountInfo object to firebase database under the key value of UserAccounts
     
     - parameter userAccountInfo: the reference to the UserAccountInfo object that will be added to firebase
     
     */
    private func uploadUserInfo(userAccountInfo: UserAccountInfo){
        let userAccountDictionary : [String : String] = ["userID" : userAccountInfo.userID,
                                                         "chosenUsername" : userAccountInfo.chosenUsername,
                                                         "nameChangeUsed" : String(userAccountInfo.oneTimeNameChangeUsed)]
        rootRef.child("UserAccounts").childByAutoId().setValue(userAccountDictionary)
    }
    
    // MARK: - Delete Data
    /**
     removes the given Sale Item from the firebase database
     
     - Parameter saleItemID: the primary ID of the saleItem that will be removed from the FireBase Database
     
     */
    func deleteSaleItem(saleItemToDelete: SaleItem) {
        saleRef = rootRef.child("Sale Items")
        saleRef?.child(saleItemToDelete.itemID!).removeValue()
        deleteImageInFireStorage(imageURL: saleItemToDelete.imageURL!)
    }
    
    /**
     removes the image from Firebase Storage from the given imageURL
     
     - Parameter imageURL: URL of the image that will be deleted from Firebase Storage
     
     */
    private func deleteImageInFireStorage (imageURL: String) {
        let imageRef = Storage.storage().reference(forURL: imageURL)
        imageRef.delete{(error)in}
    }
    
}