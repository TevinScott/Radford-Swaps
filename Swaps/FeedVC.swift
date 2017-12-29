//
//  FeedVC.swift
//  Swaps
//
//  Created by Tevin Scott on 12/17/17.
//  Copyright © 2017 Tevin Scott. All rights reserved.
//

import Foundation
import UIKit
import GoogleSignIn
import Firebase
import GoogleMobileAds
import AlgoliaSearch

/// A Class that manages the Feed View and its sub views
class FeedVC : UIViewController, UICollectionViewDelegate, UICollectionViewDataSource, UISearchBarDelegate{
    
    // MARK: - Attributes
    let coredataManager = CoreDataManager()
    let firebaseDataManager = FirebaseDataManager()
    let algoliaSearchManager = AlgoliaSearchManager.init()
    //adMob variables
    var adsToLoad = [GADNativeExpressAdView]()
    let adInterval = 3
    // outlets
    @IBOutlet var searchBar: UISearchBar!
    @IBOutlet var collectionView: UICollectionView!
    //layout properties
    var collectionViewOriginalLocation: CGFloat!
    var extendedCollectionViewHeight: CGFloat!
    private let leftAndRightPadding: CGFloat = 32.0
    private let numberOfItemsPerRow: CGFloat = 2.0
    private let heightAdjustment: CGFloat = 5.0
    private let cellIdentifier = "SaleCell"
    var setOfItems: ItemCollection = ItemCollection.init(){ didSet { collectionView?.reloadData() } }
    var searchActive : Bool = false

    // MARK: - Button Actions
    /**
     Presents the newItemView to user, if they are currently signed into an account.
     */
    @IBAction func postItemBtnAction(_ sender: Any) {
        if(Auth.auth().currentUser?.uid != nil) {
            performSegue(withIdentifier: "postNewItemSegue", sender: self)
        }
    }
    
    /**
     this button action returns the user to the
     */
    @IBAction func profileBtnAction(_ sender: Any) {
        //if user is currently signed in the profile view is presented
        if (Auth.auth().currentUser?.uid != nil){
           performSegue(withIdentifier: "goToProfileSegue", sender: self)
        } else { // else the user is returned to the sign in view
            self.dismiss(animated: true, completion: {})
            self.navigationController?.popViewController(animated: true)
        }
    }
    // MARK: - Collection View function Overrides
    
    /**
     Asks the data source object for the number of sections in the collection view.
     
     - parameter:
     -collectionView:   The collection view requesting this information
     
     - returns:             The number of sections in collectionView.
     */
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    /**
     Asks the data source object for the number of items in the specified section.
     
     - parameters:
     -collectionView:   The collection view requesting this information.
     -section:          An index number identifying a section in collectionView. This index value is 0-based.
     
     - returns:             The number of sections in collectionView.
     */
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return  setOfItems.collectionCount //based on size of list
    }
    
    /**
     Asks your data source object for the cell that corresponds to the specified item in the collection view.
     This method must always return a valid view object.
     
     - parameters:
     -collectionView:   The collection view requesting this information.
     -indexPath:        The index path that specifies the location of the item.
     
     - returns:             A configured cell object. You must not return nil from this method.
     */
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath) as! SaleItemCollectionViewCell
        cell.saleItem = setOfItems.getSaleItemAtIndexPath(indexPath: indexPath)
        return cell
    }
    
    /**
     Tells the delegate that the item at the specified index path was selected.
     The collection view calls this method when the user successfully selects an item in the collection view.
     It does not call this method when you programmatically set the selection.
     
     - parameters:
     -collectionView:   The collection view requesting this information.
     -indexPath:        The index path of the cell that was selected.
     */
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath){
        if let cell = collectionView.cellForItem(at: indexPath) as? SaleItemCollectionViewCell {
            //branch here, if user owns item go to (Edit)SaleItemSegue
            if let userID = Auth.auth().currentUser?.uid {
                
                if(cell.saleItem?.userID == userID){
                    performSegue(withIdentifier: "EditSaleItemSegue", sender: cell)
                }else{
                    performSegue(withIdentifier: "ViewSaleItemSegue", sender: cell)
                }
            }else{
                //user is currently not signed in.
                performSegue(withIdentifier: "ViewSaleItemSegue", sender: cell)
            }
        } else {
            // Error indexPath is not on screen: this should never happen.
        }
    }
   

    // MARK: - Segue Override
    
    /**
     Notifies the view controller that a segue is about to be performed.
     
     - parameters:
     -segue:    The segue object containing information about the view controllers involved in the segue.
     -sender:   The object that initiated the segue. You might use this parameter to perform different actions based on which control (or other object) initiated the segue.
     */
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "ViewSaleItemSegue"{
            let selectedSaleItem = (sender as! SaleItemCollectionViewCell).saleItem!
            let textToPass = selectedSaleItem
            let saleItemVC = segue.destination as! SaleItemVC
            saleItemVC.saleItem = textToPass
        }
        if segue.identifier == "EditSaleItemSegue"{
            let selectedSaleItem = (sender as! SaleItemCollectionViewCell).saleItem!
            let textToPass = selectedSaleItem
            let saleItemVC = segue.destination as! EditItemVC
            saleItemVC.saleItem = textToPass
        }
    }

    // MARK: - View controller life cycle
   

    /** for future commit, google add
     func addNativeExpressAds(){
     let index = 2
     let size = GADAdSizeFromCGSize(CGSize(width: 150, height: 150))
     while index < setOfItems.collectionCount {
     let adView = GADNativeExpressAdView(adSize: size)
     //Stopping Point
     //https://www.youtube.com/watch?v=chNb7-k6m4M 3:00 in
     }
     }
     */
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        //search and database init
        searchBar.delegate = self
        algoliaSearchManager.getAllItems() { (escapingList) -> () in
            self.setOfItems = ItemCollection.init(inputList: escapingList)
        }
        //constrains the layout to the layout property attributes
        let width = ((collectionView.frame).width - leftAndRightPadding)/numberOfItemsPerRow
        let layout = collectionView.collectionViewLayout as! UICollectionViewFlowLayout
        layout.itemSize = CGSize(width: width, height: width+heightAdjustment)
        collectionViewOriginalLocation = self.collectionView.frame.origin.y
        //addNativeExpressAds()
    }
    // MARK: - Search bar functionality
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String){
        algoliaSearchManager.searchDatabase(searchString: searchText) {
            (escapingList) -> () in
            self.setOfItems = ItemCollection.init(inputList: escapingList)
        }
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        searchActive = true;
    }
    
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarCancelButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        searchActive = false;
    }
    
    // MARK: - Navigation Bar Hide and Show Functions
    
    /**
     A function used to hide and show the navigation bar when the user is scrolling the collectionView of this class
    */
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if(velocity.y>0) {
            //Code will work without the animation block.I am using animation block incase if you want to set any delay to it.
            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(true, animated: true)
                self.navigationController?.setToolbarHidden(true, animated: true)
                self.searchBar.frame.origin.y = 20
                self.collectionView.frame.origin.y = (self.navigationController?.navigationBar.frame.height)! + self.searchBar.frame.height
                

            }, completion: nil)
            
        } else {
            UIView.animate(withDuration: 0, delay: 0, options: UIViewAnimationOptions(), animations: {
                self.navigationController?.setNavigationBarHidden(false, animated: true)
                self.searchBar.frame.origin.y = 0
                
                self.collectionView.frame.origin.y = self.collectionViewOriginalLocation
            }, completion: nil)
        }
    }
    
    @objc func didTapView(gesture: UITapGestureRecognizer){
        view.endEditing(true)
    }

}
