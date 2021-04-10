//
//  PaymentInitiatorViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 19/03/2021.
//

import UIKit
import CoreData
import Firebase
import Cosmos

class PaymentInitiatorViewController: UIViewController {
    @IBOutlet weak var phoneNumberLabel: UILabel!
    @IBOutlet weak var amountLabel: UILabel!
    @IBOutlet weak var currencyLabel: UILabel!
    @IBOutlet weak var initiateButton: UIButton!
    @IBOutlet weak var makingRequestContainer: UIView!
    @IBOutlet weak var makingRequestLabel: UILabel!
    @IBOutlet weak var payTitleLabel: UILabel!
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    var constants = Constants.init()
    let db = Firestore.firestore()
    let till_no = "4042515"
    var appKey = ""
    var appSecret = ""
    var passK = ""

    var payment_total = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        var my_id = Auth.auth().currentUser!.uid
        var my_acc = self.getApplicantAccount(user_id: my_id)
        
        phoneNumberLabel.text = "\(my_acc!.phone!.country_number_code!)\(my_acc!.phone!.digit_number)"
        amountLabel.text = "\(payment_total)"
        currencyLabel.text = "\(my_acc!.phone!.country_currency!)"
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    
    
    @IBAction func whenInitiateTapped(_ sender: Any) {
        initiateButton.isHidden = true
        makingRequestContainer.isHidden = false
        startMpesaPayments()
    }
    
    @IBAction func cancelPendingTransactionTapped(_ sender: Any) {
        canConfirmPayemtnts = false
        initiateButton.isHidden = false
        makingRequestContainer.isHidden = true
    }
    

    
    func startMpesaPayments(){
        showLoadingScreen()
        payment_total = 10
        self.makingRequestLabel.text = "Making a payment request!"
        var my_id = Auth.auth().currentUser!.uid
        var my_acc = self.getApplicantAccount(user_id: my_id)
        var my_num = ("\(my_acc!.phone!.country_number_code!)\(my_acc!.phone!.digit_number)").replacingOccurrences(of: "+", with: "")
        
        
        
        let dateFormatterGet = DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyyMMddHHmmss"
        
        var amount = "\(payment_total)"
//        var partyA = "254798075721"
        var partyA = my_num

        
        let date = Date()
        print(dateFormatterPrint.string(from: date))
        
        
        guard let filePath = Bundle.main.path(forResource: "maps-Info", ofType: "plist") else {
            fatalError("Couldn't find file 'maps-Info.plist'.")
        }
        let plist = NSDictionary(contentsOfFile: filePath)
        
        self.appKey = plist?.object(forKey: "appKey") as! String
        self.appSecret = plist?.object(forKey: "appSecret") as! String
        self.passK = plist?.object(forKey: "PASS_KEY") as! String

        
        var appKeySecret = "\(appKey):\(appSecret)"
        var shortCode = till_no
        var passKey = passK
        var timeStamp: String = dateFormatterPrint.string(from: date)
        var passWordEncoded = shortCode + passKey + timeStamp
        
        
        var bytesPas: [UInt8] = Array(passWordEncoded.data(using: .isoLatin1)!)
        var bytes: [UInt8] = Array(appKeySecret.data(using: .isoLatin1)!)
        
        var encoded = bytes.toBase64()!
        var passEncoded = bytesPas.toBase64()!
        
        
        
        var url: String = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        var request : URLRequest = URLRequest(url: (URL(string: url) as URL?)!)
        let config = URLSessionConfiguration.default
        request.httpMethod = "GET"
        
        request.addValue("Basic \(encoded)", forHTTPHeaderField: "authorization")
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")

        
        print("request as string: \(request)")
        print("Timestamp: --- \(timeStamp)")
        print("passWordEncoded: --- \(passWordEncoded)")
        print("Passencoded: --- \(passEncoded)")
        print("Encoded: --- \(encoded)")

        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

//                    let results = jsonResult["results"] as! NSArray
                    let access_token = jsonResult["access_token"] as? String
//                    let result_title = (results[0] as! NSDictionary)["formatted_address"] as! String
                    
                    print("access token \(access_token)")
                    print("data: \(jsonResult)")
                    
                    if(access_token != nil){
                        self.STKPushSimulation(self.till_no, "CustomerPayBillOnline", amount, partyA,
                                               partyA, self.till_no, "https://ilovepancake.github.io/PigDice",
                                                "https://adcafe.github.io/CBK/", "JobPayment", "jsjsj", access_token!)
                    }
                    
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }

            

        })
        
    }
    
    func STKPushSimulation(_ businessShortCode: String,
                           _ transactionType: String,
                           _ amount: String,
                           _ phoneNumber: String,
                           _ partyA: String,
                           _ partyB: String,
                           _ callBackURL: String,
                           _ queueTimeOutURL: String,
                           _ accountReference: String,
                           _ transactionDesc: String,
                           _ bearer: String){
        let dateFormatterGet = DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyyMMddHHmmss"
        let date = Date()
        
        var appKeySecret = "\(appKey):\(appSecret)"
        var shortCode = till_no
        var passKey = passK
        var timeStamp: String = dateFormatterPrint.string(from: date)
        var passWordEncoded = shortCode + passKey + timeStamp
        
        
        var bytesPas: [UInt8] = Array(passWordEncoded.data(using: .isoLatin1)!)
        var bytes: [UInt8] = Array(appKeySecret.data(using: .isoLatin1)!)
        
        var encoded = bytes.toBase64()!
        var password = bytesPas.toBase64()!
        
        
        var jsonArray: [String: Any] = [
            "BusinessShortCode": businessShortCode,
            "Password": password,
            "Timestamp": timeStamp,
            "TransactionType": transactionType,
            "Amount": amount,
            "PhoneNumber": phoneNumber,
            "PartyA": partyA,
            "PartyB": partyB,
            "CallBackURL": callBackURL,
            "AccountReference": accountReference,
            "QueueTimeOutURL": queueTimeOutURL,
            "TransactionDesc": transactionDesc
         ]
        
        print(jsonArray)
        
        let JSON = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        let json_string_array = String(data: JSON!, encoding: String.Encoding.utf8)!
        let trimmed_json_array = json_string_array.replacingOccurrences(of: "\\", with: "")
        print(trimmed_json_array)
        
        
        var url: String = "https://api.safaricom.co.ke/mpesa/stkpush/v1/processrequest"
        var request : URLRequest = URLRequest(url: (URL(string: url) as URL?)!)
        request.httpMethod = "POST"
        request.httpBody = JSON!
        
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(bearer)", forHTTPHeaderField: "authorization")
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")
        
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

//                    let results = jsonResult["results"] as! NSArray
                    let CheckoutRequestID = jsonResult["CheckoutRequestID"] as? String
//                    let result_title = (results[0] as! NSDictionary)["formatted_address"] as! String
                    
                    print("CheckoutRequestID: -- \(CheckoutRequestID)")
                    print("data: \(jsonResult)")
                    
                    if CheckoutRequestID != nil {
                        
                        self.startPaymentListeningForMpesaPayment(businessShortCode,password,timeStamp,CheckoutRequestID!)
                        
                        DispatchQueue.main.async {
                            self.makingRequestLabel.text = "Waiting for payment confirmation..."
                            self.hideLoadingScreen()
                        }
                    }

                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }

            

        })
        
    }
    
    var canConfirmPayemtnts = true
    func startPaymentListeningForMpesaPayment(_ businessShortCode: String,_ password: String,_ timestamp: String,
                                              _ checkoutRequestID: String){
        if (canConfirmPayemtnts) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.checkIfMpesaPaymentHasBeenCompleted( businessShortCode, password, timestamp, checkoutRequestID)
            }
        }
    }
    
    func checkIfMpesaPaymentHasBeenCompleted(_ businessShortCode: String,_ password: String,_ timestamp: String,_ checkoutRequestID: String){
        let dateFormatterGet = DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyyMMddHHmmss"
        let date = Date()

        
        var appKeySecret = "\(appKey):\(appSecret)"
        var shortCode = till_no
        var passKey = passK
        var timeStamp: String = dateFormatterPrint.string(from: date)
        var passWordEncoded = shortCode + passKey + timeStamp
        
        
        var bytesPas: [UInt8] = Array(passWordEncoded.data(using: .isoLatin1)!)
        var bytes: [UInt8] = Array(appKeySecret.data(using: .isoLatin1)!)
        
        var encoded = bytes.toBase64()!
        var passEncoded = bytesPas.toBase64()!
        
        
        
        var url: String = "https://api.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials"
        var request : URLRequest = URLRequest(url: (URL(string: url) as URL?)!)
        let config = URLSessionConfiguration.default
        request.httpMethod = "GET"
        
        request.addValue("Basic \(encoded)", forHTTPHeaderField: "authorization")
        request.addValue("no-cache", forHTTPHeaderField: "cache-control")

        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

//                    let results = jsonResult["results"] as! NSArray
                    let access_token = jsonResult["access_token"] as? String
//                    let result_title = (results[0] as! NSDictionary)["formatted_address"] as! String
                    
                    print("access token \(access_token)")
                    print("data: \(jsonResult)")
                    
                    if(access_token != nil){
                        self.STKPushTransactionStatus(businessShortCode,password,timestamp,checkoutRequestID, access_token!)
                    }
                    
                   
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }

            

        })
    }
    
    
    func STKPushTransactionStatus(_ businessShortCode: String,_ password: String,_ timestamp: String,_ checkoutRequestID: String,_ accessToken: String){
        let dateFormatterGet = DateFormatter()
        let dateFormatterPrint = DateFormatter()
        dateFormatterPrint.dateFormat = "yyyyMMddHHmmss"
        let date = Date()
        
        var appKeySecret = "\(appKey):\(appSecret)"
        var shortCode = till_no
        var passKey = passK
        var timeStamp: String = dateFormatterPrint.string(from: date)
        var passWordEncoded = shortCode + passKey + timeStamp
        
        
        var bytesPas: [UInt8] = Array(passWordEncoded.data(using: .isoLatin1)!)
        var bytes: [UInt8] = Array(appKeySecret.data(using: .isoLatin1)!)
        
        var encoded = bytes.toBase64()!
        var password = bytesPas.toBase64()!
        
        var jsonArray: [String: Any] = [
            "BusinessShortCode": businessShortCode,
            "Password": password,
            "Timestamp": timeStamp,
            "CheckoutRequestID": checkoutRequestID,
         ]
        
        print(jsonArray)
        
        let JSON = try? JSONSerialization.data(withJSONObject: jsonArray, options: [])
        
        
        var url: String = "https://api.safaricom.co.ke/mpesa/stkpushquery/v1/query"
        var request : URLRequest = URLRequest(url: (URL(string: url) as URL?)!)
        request.httpMethod = "POST"
        request.httpBody = JSON!
        
        request.addValue("application/json", forHTTPHeaderField: "content-type")
        request.addValue("Bearer \(accessToken)", forHTTPHeaderField: "authorization")
        
        NSURLConnection.sendAsynchronousRequest(request as URLRequest, queue: OperationQueue(), completionHandler:{ (response:URLResponse!, data: Data!, error: Error!) -> Void in
            var error: AutoreleasingUnsafeMutablePointer<NSError?>? = nil
            do{
                let jsonResult: NSDictionary! = try JSONSerialization.jsonObject(with: data, options:JSONSerialization.ReadingOptions.mutableContainers) as? NSDictionary

                if (jsonResult != nil) {
                    // process jsonResult

                    let ResponseCode = jsonResult["ResponseCode"] as? String
                    let ResponseDescription = jsonResult["ResponseDescription"] as? String
                    let MerchantRequestID = jsonResult["MerchantRequestID"] as? String
                    let CheckoutRequestID = jsonResult["CheckoutRequestID"] as? String
                    let ResultCode = jsonResult["ResultCode"] as? String
                    let ResultDesc = jsonResult["ResultDesc"] as? String
                    
                    print("data: \(jsonResult)")
                    print("response code: \(ResponseCode)")
                    
                    if (ResponseCode != nil && MerchantRequestID != nil ) {
                        if (ResponseCode! == "0" && ResultCode! == "0") {
                            print("payment has been accepted!")
                            DispatchQueue.main.async {
                                self.payTitleLabel.text = "Payment complete!"
                                self.makingRequestContainer.isHidden = true
                                
                                var response = PaymentResponse()
                                response.ResponseCode = ResponseCode!
                                response.ResponseDescription = ResponseDescription!
                                response.MerchantRequestID = MerchantRequestID!
                                response.CheckoutRequestID = CheckoutRequestID!
                                response.ResultCode = ResultCode!
                                response.ResultDesc = ResultDesc!
                                
                                self.record_transaction_and_finish(response, checkoutRequestID)
                            }
                        }else if (ResponseCode! == "0" && ResultCode! == "1") {
                            
                        }else{
                            print("Payments have failed for some reason..")
                            self.startPaymentListeningForMpesaPayment(businessShortCode,password,timestamp, checkoutRequestID)
                        }
                    }else{
                        print("Payments response has no response code and MerchantRequestID")
                        self.startPaymentListeningForMpesaPayment(businessShortCode,password,timestamp, checkoutRequestID)
                    }
                    
                    
                } else {
                   // couldn't load JSON, look at error
                }
            }catch {
            
            }

            

        })
        
    }
    
    
    func record_transaction_and_finish(_ response: PaymentResponse,_ transaction_id: String){
        showLoadingScreen()
        var receipt = PaymentReceipt()
        receipt.receipt_time = Int((Date().timeIntervalSince1970 * 1000.0).rounded())
        receipt.transaction_id = transaction_id
        receipt.paymentResponse = response
        
        var method = PaymentMethod()
        method.name = "Mpesa"
        method.min_amount = 10
        method.min_amount_currency = "KES"
        receipt.method = method
                
        let payment_objs = self.getJobPaymentsIfExists()
        var paid_jobs: [String] = [String]()
        
        for item in payment_objs {
            let payment_receipt = self.getPaymentReceipt(item.payment_receipt!)
            
            for job in payment_receipt.paid_jobs {
                paid_jobs.append(job.job_id)
            }
        }
        
        var my_received_ratings_jobs: [String] = [String]()
        var my_id = Auth.auth().currentUser!.uid
        let my_ratings = self.getAccountRatings(my_id)
        print("my ratings size: \(my_ratings)")
        
        for item in my_ratings {
            if(!paid_jobs.contains(item.job_id!)){
                my_received_ratings_jobs.append(item.job_id!)
            }
        }
        
        for item in my_received_ratings_jobs {
            receipt.paid_jobs.append(self.jobAsInCodable(item))
        }
        
        var payment_receipt_json = ""
        let encoder = JSONEncoder()
        
        do {
            let json_string = try encoder.encode(receipt)
            payment_receipt_json = String(data: json_string, encoding: .utf8)!
        }catch {
           print("error encoding job")
        }
        
        var data: [ String : Any] = [
            "transaction_id" : transaction_id,
            "receipt_time" : receipt.receipt_time,
            "payment_receipt" : payment_receipt_json
        ]
        
        db.collection(constants.airworkers_ref)
            .document(my_id)
            .collection(constants.job_payments)
            .document(transaction_id)
            .setData(data){ err in
                if let err = err {
                    print("Error writing document: \(err)")
                } else {
                    print("Document successfully written!")
                    self.hideLoadingScreen()
                    self.dismiss(animated: true, completion: nil)
                }
                
            }
        
    }
    
    func getPaymentReceipt(_ payment_receipt_json: String) -> PaymentReceipt{
        let decoder = JSONDecoder()
        
        do{
            let jsonData = payment_receipt_json.data(using: .utf8)!
            let job_images =  try decoder.decode(PaymentReceipt.self, from: jsonData)
            
            return job_images
        }catch{
            print("error loading job images")
        }
        
        return PaymentReceipt()
    }
    
    func jobAsInCodable(_ job_id: String) -> encodable_job{
        let job = self.getJobIfExists(job_id: job_id)
        
        var enc_job = encodable_job()
        enc_job.job_title = job!.job_title!
        enc_job.job_details = job!.job_details!
        enc_job.job_worker_count = Int(job!.job_worker_count)
        
        
        for tag in job!.tags!{
            var item = (tag as! JobTag)
            var jobtags = jobtag()
            jobtags.tag_title = item.title!
            jobtags.no_of_days = Int(item.no_of_days)
            jobtags.tag_class = "custom"
            jobtags.work_duration = item.work_duration ?? ""
            enc_job.selected_tags.append(jobtags)
        }
        
        enc_job.work_duration = job!.work_duration!
        
        var start_date = myDate()
        start_date.day = Int(job!.start_day)
        start_date.month = Int(job!.start_month)
        start_date.month_of_year = job!.start_month_of_year!
        start_date.year = Int(job!.start_year)
        start_date.day_of_week = job!.start_day_of_week!
        
        enc_job.start_date = start_date
        
        var end_date = myDate()
        end_date.day = Int(job!.end_day)
        end_date.month = Int(job!.end_month)
        end_date.month_of_year = job!.end_month_of_year!
        end_date.year = Int(job!.end_year)
        end_date.day_of_week = job!.end_day_of_week!
        
        enc_job.end_date = end_date
        
        var time = Time()
        time.am_pm = job!.am_pm!
        time.hour = Int(job!.time_hour)
        time.minute = Int(job!.time_minute)
        
        enc_job.time = time
        enc_job.is_asap = job!.is_asap
        
        var location = myLocation()
        location.latitude = job!.location_lat
        location.longitude = job!.location_long
        location.description = job!.location_desc!
        
        enc_job.location_set = location
        
        var pay = Pay()
        pay.amount = Int(job!.pay_amount)
        pay.currency = job!.pay_currency!
        
        enc_job.pay = pay
        enc_job.country_name = job!.country_name!
        enc_job.country_name_code = job!.country_name_code!
        enc_job.language = job!.language!
        enc_job.upload_time = Int(job!.upload_time)
        enc_job.job_id = job!.job_id!
        
        var uploader = Uploader()
        uploader.name = job!.uploader_name!
        uploader.id = job!.uploader_id!
        uploader.email = job!.uploader_email!
        
        var my_id = Auth.auth().currentUser!.uid
        var me = self.getApplicantAccount(user_id: my_id)
        uploader.number = Int(me!.phone!.digit_number)
        uploader.country_code = job!.uploader_phone_number_code!
        enc_job.uploader = uploader
        
        return enc_job
    }
    
    
    struct PaymentReceipt: Codable{
        var receipt_time = 0
        var transaction_id = ""
        var paymentResponse = PaymentResponse()
        var method = PaymentMethod()
        var paid_jobs: [encodable_job] = [encodable_job]()
    }
    
    struct PaymentResponse: Codable{
        var ResponseDescription = ""
        var ResponseCode = ""
        var MerchantRequestID = ""
        
        var CheckoutRequestID = ""
        var ResultCode = ""
        var ResultDesc = ""
        var timeOfDay: String = ""
        var datee: String = ""
        var payingPhoneNumber: String = ""
        var pushrefInAdminConsole: String = ""
        var uploaderId: String = ""
    }
    
    struct PaymentMethod: Codable{
        var name = ""
        var min_amount = 0
        var min_amount_currency = ""
    }
    
    struct encodable_job: Codable{
        var job_title = ""
        var job_details = ""
        var job_worker_count = 0
        var selected_tags: [jobtag] = []
        var work_duration: String = ""
        var start_date: myDate = myDate()
        var end_date: myDate = myDate()
        var time: Time = Time()

        var is_asap = false
        var location_set = myLocation()
        var pay = Pay()
        var country_name = ""
        var country_name_code = ""
        var language = ""
        var upload_time = 0
        var job_id = ""
        var uploader = Uploader()
    }
    
    struct jobtag: Codable{
        var no_of_days = 0
        var tag_class = ""
        var tag_title = ""
        var work_duration = ""
    }
    
    struct jobtaglist: Codable{
        var tags = [jobtag]()
    }
    
    struct myDate: Codable{
        var day = 0
        var month = 0
        var year = 0
        var day_of_week = ""
        var month_of_year = ""
    }
    
    struct Time: Codable{
        var hour = 0
        var minute = 0
        var am_pm = ""
    }
    
    struct myLocation: Codable{
        var latitude = 0.0
        var longitude = 0.0
        var description = ""
    }
    
    struct Pay: Codable{
        var amount = 0
        var currency = ""
    }
    
    struct Uploader: Codable{
        var id = ""
        var email = ""
        var name = ""
        var number = 0
        var country_code = ""
    }
    
    struct selected_workers: Codable{
        var worker_list = [String]()
    }
    
    
    var child = SpinnerViewController()
    var isShowingSpinner = false
    func showLoadingScreen() {
       if !isShowingSpinner {
           child = SpinnerViewController()
           // add the spinner view controller
           addChild(child)
           child.view.frame = view.frame
           view.addSubview(child.view)
           child.didMove(toParent: self)
           isShowingSpinner = true
       }
    }
       
    func hideLoadingScreen(){
       if isShowingSpinner {
           child.willMove(toParent: nil)
           child.view.removeFromSuperview()
           child.removeFromParent()
           isShowingSpinner = false
       }
    }
    
    
    func getApplicantAccount(user_id: String) -> Account? {
        do{
            let request = Account.fetchRequest() as NSFetchRequest<Account>
            
            let predic = NSPredicate(format: "uid == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getJobIfExists(job_id: String) -> Job? {
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    
    func getAccountRating(_ rating_id: String) -> Rating? {
        do{
            let request = Rating.fetchRequest() as NSFetchRequest<Rating>
            
            let predic = NSPredicate(format: "rating_id == %@", rating_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getAccountRatings(_ user_id: String) -> [Rating] {
        do{
            let request = Rating.fetchRequest() as NSFetchRequest<Rating>
            
            let predic = NSPredicate(format: "rated_user_id == %@", user_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return filterRatings(ratings: items)
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func filterRatings(ratings: [Rating]) -> [Rating] {
        var filtered_items = [Rating]()
        
        for item in ratings {
            let job_id = item.job_id
            let job = self.getJobIfExists(job_id: job_id!)
            let rater_id = item.rating_id!.replacingOccurrences(of: job_id!, with: "")
            
            var req_id_format = "\(job!.uploader_id!)\(job!.job_id!)"
//            var req_id_format = "\(job!.job_id!)"
            if self.amIAirworker(){
                if rater_id != ""{
                    req_id_format = "\(rater_id)\(job!.job_id!)"
                }
            }
            if item.rating_id! == req_id_format{
                filtered_items.append(item)
            }
        }
        
        return filtered_items
    }
    
    func gett(_ dateFormat: String,_ date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    
    func amIAirworker() -> Bool{
        let app_data = self.getAppDataIfExists()
        if app_data!.is_airworker {
            return true
        }
        
        return false
    }
    
    func getAppDataIfExists() -> AppData? {
        do{
            let request = AppData.fetchRequest() as NSFetchRequest<AppData>
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items[0]
            }
            
        }catch {
            
        }
        
        return nil
    }
    
    func getNewJobsIfExists() -> [Job]{
        do{
            let request = Job.fetchRequest() as NSFetchRequest<Job>
            let sortDesc = NSSortDescriptor(key: "upload_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return[]
    }
    
    func getAppliedJobsIfExists() -> [AppliedJob] {
        do{
            let request = AppliedJob.fetchRequest() as NSFetchRequest<AppliedJob>
            let sortDesc = NSSortDescriptor(key: "application_time", ascending: false)
            request.sortDescriptors = [sortDesc]
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    
    func getJobPaymentsIfExists() -> [JobPayment] {
        do{
            let request = JobPayment.fetchRequest() as NSFetchRequest<JobPayment>
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    func getJobApplicantsIfExists(job_id: String) -> [JobApplicant]{
        do{
            let request = JobApplicant.fetchRequest() as NSFetchRequest<JobApplicant>
            
            let predic = NSPredicate(format: "job_id == %@", job_id)
            request.predicate = predic
            
            let items = try context.fetch(request)
            
            if(!items.isEmpty){
                return items
            }
            
        }catch {
            
        }
        
        return []
    }
    
    
}
