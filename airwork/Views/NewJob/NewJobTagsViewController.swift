//
//  NewJobTagsViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 03/01/2021.
//

import UIKit
import CoreData

class NewJobTagsViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout{
    @IBOutlet weak var newTagField: UITextField!
    @IBOutlet weak var allTagsCollection: UICollectionView!
    @IBOutlet weak var continueButton: UIButton!
    @IBOutlet weak var errorLabel: UILabel!
    
    var selectedTags: [String] = []
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext

    var tags_to_show: [String] = []
    var typedItem = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        let i = navigationController?.viewControllers.firstIndex(of: self)
        let titleVC = (navigationController?.viewControllers[i!-2]) as! NewJobTitleViewController
        
        let pickedTitle = titleVC.titleText
        print("picked title: \(pickedTitle)")
        
        tags_to_show = getTheTagsToShow()
        if pickedTitle.contains(" "){
            print("picked title: contains spacing : \(pickedTitle)")
            let titleWords = pickedTitle.split{$0 == " "}.map(String.init)
            for item in titleWords {
                if tags_to_show.contains(item.lowercased()){
                    selectedTags.append(item.lowercased())
                }
            }
        }else{
            print("picked title is one word: \(pickedTitle)")
            if tags_to_show.contains(pickedTitle.lowercased()){
                selectedTags.append(pickedTitle.lowercased())
            }
        }
        
        if !selectedTags.isEmpty {
            tags_to_show = getTheTagsToShow()
        }
        
        allTagsCollection.delegate = self
        allTagsCollection.dataSource = self
        
    }
    

    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    

    @IBAction func whenCreateTagClicked(_ sender: Any) {
        if typedItem == "" {
            showError("Type something!")
        }else if selectedTags.contains((typedItem.lowercased())){
            showError("Already added!")
        }else{
            selectedTags.append(typedItem)
            newTagField.text = ""
            typedItem = ""
            tags_to_show = getTheTagsToShow()
            allTagsCollection.reloadData()
        }
    }
    
    @IBAction func whenCancelTapped(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    
    @IBAction func whenNewTagTyped(_ sender: UITextField) {
        hideErrorLabel()
        
        if !sender.hasText{
            showError("Type something!")
        }else{
            typedItem = sender.text!

            tags_to_show = getTheTagsToShow()
            allTagsCollection.reloadData()
        }
    }
    
    func showError(_ error: String){
        errorLabel.isHidden = false
        errorLabel.text = error
    }
    
    func hideErrorLabel(){
        errorLabel.isHidden = true
    }
    
    func showNextIfOk(){
        if !selectedTags.isEmpty {
            continueButton.isHidden = false
        }else {
            continueButton.isHidden = true
        }
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tags_to_show.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let reuseIdentifier = "JobTagCell"
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! JobTagCollectionViewCell
        
        let tag = tags_to_show[indexPath.row]
        
        cell.title.text = tag
        if selectedTags.contains(tag){
            cell.tagBack.backgroundColor = UIColor.darkGray
        }else {
            let c = UIColor(named: "TagBackColor")
            cell.tagBack.backgroundColor = c
        }
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat
    {
        
        return 1;
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
         // handle tap events
         print("You selected cell \(indexPath.item)!")
        
        var selected_t = tags_to_show[indexPath.row]
        if !selectedTags.contains(selected_t){
            selectedTags.append(selected_t)
        }else{
            selectedTags.remove(at: indexPath.row)
        }
        newTagField.text = ""
        typedItem = ""
        
        tags_to_show = getTheTagsToShow()
        allTagsCollection.reloadData()
     }
    
    
    func getTheTagsToShow() -> [String] {
        var other_suggestions: [String] = []
        
        other_suggestions.append(contentsOf: selectedTags)
        
        if typedItem != "" {
            let all_g_tags = getGlobalTagsIfExists()
            for tag in all_g_tags {
                if tag.title!.starts(with: typedItem.lowercased()){
                    other_suggestions.append(tag.title!)
                }
            }
        }
        else
        if !selectedTags.isEmpty{
            for tag in selectedTags {
                let tag_associates = getGlobalTagIfExists(tag_title: tag)
//                print("associates for \(tag) are \(tag_associates[0].tag_associates)")
                if !tag_associates.isEmpty {
                    for associateTag in tag_associates{
//                        print("attemting to decode \(associateTag.title) : \(associateTag.tag_associates)")
                        var json = associateTag.tag_associates
                        let decoder = JSONDecoder()
                        let jsonData = json!.data(using: .utf8)!
                        
                        do{
                            let tags: [json_tag] =  try decoder.decode(json_tag_array.self, from: jsonData).tags
                            for item in tags{
//                                print("decoded item: \(item.tag_title)")
                                if !other_suggestions.contains(item.tag_title){
                                    other_suggestions.append(item.tag_title)
                                }
                            }
                        }catch {
                            
                        }
                    }
                }
            }
        } else {
            let all_g_tags = getGlobalTagsIfExists()
            for tag in all_g_tags {
                if !other_suggestions.contains(tag.title!){
                    other_suggestions.append(tag.title!)
                }
            }
        }
        
        showNextIfOk()
        
        return other_suggestions
    }
    
    func getGlobalTagsIfExists() -> [GlobalTag]{
        do{
            let request = GlobalTag.fetchRequest() as NSFetchRequest<GlobalTag>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
        }catch {
            
        }
        
        return []
    }
    
    func getGlobalTagIfExists(tag_title: String) -> [JobTag]{
        do{
            let request = JobTag.fetchRequest() as NSFetchRequest<JobTag>
            let predic = NSPredicate(format: "title == %@ && global == \(NSNumber(value: true))", tag_title)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    
    struct json_tag_array: Codable{
        var tags: [json_tag] = []
    }
    
    struct json_tag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
}
