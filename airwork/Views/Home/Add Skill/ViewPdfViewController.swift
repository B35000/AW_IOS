//
//  ViewPdfViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 26/03/2021.
//

import UIKit
import PDFKit
import Firebase
import CoreData

class ViewPdfViewController: UIViewController {
    @IBOutlet weak var pdfContainer: UIView!
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    let db = Firestore.firestore()
    let constants = Constants.init()
    var pdfView = PDFView()
    var skill_id = ""
    var picked_doc: Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        setDocOnView()
    }
    
    func setDocOnView(){
        let uid = Auth.auth().currentUser!.uid
        
         do {
            pdfView = PDFView()

            pdfView.translatesAutoresizingMaskIntoConstraints = false
            view.addSubview(pdfView)

            pdfView.leadingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.leadingAnchor).isActive = true
            pdfView.trailingAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.trailingAnchor).isActive = true
            pdfView.topAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.topAnchor).isActive = true
            pdfView.bottomAnchor.constraint(equalTo: pdfContainer.safeAreaLayoutGuide.bottomAnchor).isActive = true
            
            let d = PDFDocument(data: picked_doc!)
            pdfView.document = d
                        
         } catch {
             print("\(error.localizedDescription)")
         }
        
        
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
