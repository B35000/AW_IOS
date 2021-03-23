//
//  SecurityTestViewController.swift
//  airwork
//
//  Created by Bry Onyoni on 18/02/2021.
//

import UIKit
import Foundation
import CertificateSigningRequest
import CryptoSwift
import Firebase
import SwiftyRSA

class SecurityTestViewController: UIViewController {
    let tagPrivate = "com.csr.private.rsa256"
    let tagPublic = "com.csr.public.rsa256"
    let db = Firestore.firestore()
    let exportImportManager = CryptoExportImportManager()

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        
        let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
        let sizeOfKey = keyAlgorithm.availableKeySizes.last!

        //this generates a public key private key pair for us
        let (potentialPrivateKey, potentialPublicKey) =
            self.generateKeysAndStoreInKeychain(keyAlgorithm, keySize: sizeOfKey,
                                                tagPrivate: tagPrivate, tagPublic: tagPublic)
        
        let tag = "com.color.airwork.key".data(using: .utf8)!
        let attributes: [String: Any] = [
             kSecAttrKeyType as String: keyAlgorithm.secKeyAttrType,
             kSecAttrKeySizeInBits as String: 2048,
             kSecPrivateKeyAttrs as String:[kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: tag]
        ]
        
        var error_m: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error_m) else {
            print("error generating private key")
            return
        }
        
        let publicKey = SecKeyCopyPublicKey(privateKey)
        if publicKey != nil {
            print("creating public key from private key successful")
        }
        
        if potentialPublicKey != nil {
            print("Generated public key!")
        }
        
        
        
        //this converts the keys to a string
        let pub_key_as_string = convertKeyToString(publicKey!)
        let prv_key_as_string = convertKeyToString(privateKey)
        
        if pub_key_as_string != nil {
            print("pub key converted to string!")
        }
        
        
        //this converts the string keys back to keys
        let converted_back_pri_key = convertPriStringToKey(prv_key_as_string!, keyAlgorithm)
        let converted_back_pub_key = convertPubStringToKey(pub_key_as_string!, keyAlgorithm)
        
        if converted_back_pub_key != nil {
            print("Converted pub key back to sec")
        }
        
        
        //test assymetric encryption
        let plainText = "my test data!"
        let pub = converted_back_pub_key
        let pri = converted_back_pri_key
        
        let data = Data.init(base64Encoded: plainText.base64Encoded()!)! as CFData
        let algorithm: SecKeyAlgorithm = .rsaEncryptionOAEPSHA256
        
        guard SecKeyIsAlgorithmSupported(pub!, .encrypt, algorithm) else {
            print("public secret key doesnt support algorithm passed")
            return
        }
        
        guard (plainText.count < (SecKeyGetBlockSize(pub!)-130)) else {
            print("plaintext too large, size: \(plainText.count) ; max size: \(SecKeyGetBlockSize(pub!)-130)")
            return
        }
        
        var error: Unmanaged<CFError>?
        guard let cipherText = SecKeyCreateEncryptedData(pub!, algorithm, data, &error) as CFData? else {
            print("error creating the cipherText")
            return
        }
        
        let encrypted_string = (cipherText as Data).base64EncodedString()
        print("encoded data: \(encrypted_string)")
                
        
        
        //test decryption of assymetric encryption data
        let data_dec = Data.init(base64Encoded: encrypted_string)! as CFData
        guard SecKeyIsAlgorithmSupported(pri!, .decrypt, algorithm) else {
            print("private secret key doesnt support algorithm passed")
            return
        }
        
        var error2: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(pri!, algorithm,  (data_dec), &error2) as Data? else {
            print("error decrypting data: \(error2.debugDescription)")
            return
        }
        
        let decrypted_text = clearText.base64EncodedString().base64Decoded()
        
        print("decrypted text : \(decrypted_text!)")
        
        
        
        
        
        //test signature work
        var error3: Unmanaged<CFError>?
        let sign_algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
        let data2 = Data.init(base64Encoded: "mysignature".base64Encoded()!)! as CFData
        guard let signature = SecKeyCreateSignature(pri!, sign_algorithm, data2, &error3) as CFData? else {
            print("error making signature")
            return
        }
        
        var error4: Unmanaged<CFError>?
        guard SecKeyVerifySignature(pub!, sign_algorithm, data2, signature, &error4) else{
            print("error verifying signature: \(error4.debugDescription)")
            return
        }
        
        
        
        //testing if stashing key in keychain works for us
        let key = pri
        let stash_tag = "com.color.airwork.private_key"
        let addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: stash_tag,
                                       kSecValueRef as String: key]
        
        let status = SecItemAdd(addquery as CFDictionary, nil)
        guard status == errSecSuccess else {
            print("failed to stash secret key")
            return
        }
        
        
        //testing if we can get the stashed key from keychain
        let getquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: stash_tag,
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                       kSecReturnRef as String: true]
        
        var item: CFTypeRef?
        let fetch_status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard fetch_status == errSecSuccess else {
            print("failed to fetch status")
            return
        }
        let fetched_key = item as! SecKey
        
        
        if(convertKeyToString(key!) == convertKeyToString(fetched_key)){
            print("stashed key matches original!")
        }else{
            print("stashed key doesnt match original")
        }
        
        
        
        print("Test the thing ---------------------------------------")
//        begin_the_thing()
        trial2()
        
        return
        
        var error5: Unmanaged<CFError>?
        guard let pub_key_data = SecKeyCopyExternalRepresentation(pub!, &error5) as Data? else {
            print("failed to convert pub key into data")
            return
        }
        var exportable_pub_key = exportImportManager.exportRSAPublicKeyToPEM(pub_key_data, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
        
        print("exportable key gotten: \(exportable_pub_key)")
        
        do {
            let decoded_pem_key = try PublicKey(pemEncoded: exportable_pub_key)
            print("pub_key_data: \(pub_key_data.base64EncodedString())")
            print("decoded_pem_key: \(decoded_pem_key.originalData?.base64EncodedString())")
            
        
            
        } catch let error {
            //Log Error
            print("that didnt work lol")
            return
        }
        
        
        
        
    }
    
    func trial2(){
        let myPublicKeyString = RSAKeyManager.shared.getMyPublicKeyString()
        let pri = RSAKeyManager.shared.getMyPrivateKey()?.reference
        let pub = RSAKeyManager.shared.getMyPublicKey()?.reference
        
        do {
            var error3: Unmanaged<CFError>?
            let sign_algorithm: SecKeyAlgorithm = .rsaSignatureDigestPKCS1v15SHA256
            let sign: SecKeyAlgorithm = .rsaSignatureRaw
            let data2 = Data.init(base64Encoded: "gucci123".base64Encoded()!)! as CFData
            guard let signature = SecKeyCreateSignature(pri!, sign_algorithm, data2, &error3) as Data? else {
                print("error making signature: \(error3.debugDescription)")
                return
            }
            
            let signature_string = (signature).base64EncodedString()
            
            db.collection("test_stuff").document("ios_pub_key").setData([
                "key" : myPublicKeyString,
                "sig" : signature_string
            ]){ err in
                print("set public key in db")
            }
            
            
            var error4: UnsafeMutablePointer<Unmanaged<CFError>?>?
            let data3 = Data.init(base64Encoded: signature_string)! as CFData
            if (SecKeyVerifySignature(pub!, sign_algorithm, data2, data3, error4)){
                print("signature is valid")
            }else{
                print("signature is invalid")
            }
            
            
        } catch let error {
            print("someting went wrong \(error.localizedDescription)")
        }
        
        
        
        
        
        db.collection("test_stuff").document("to_ios_data").getDocument { (document, error) in
            if let document = document, document.exists {
                print("loaded data sent to decrypt from android")
                //lets try decrypting the data from android
                let uploader_pub_key_str = document.data()!["uploader_pub_key"] as! String
                let encrypted_string = document.data()!["enc_data_key"] as! String
                
                do {
                    let encryptedMessageString: String
                    let myPrivateKey = RSAKeyManager.shared.getMyPrivateKey()
                    let encrypted = try EncryptedMessage(base64Encoded: encrypted_string)
                    let clear = try encrypted.decrypted(with: myPrivateKey!, padding: .PKCS1)
                    let string = try clear.string(encoding: .utf8)
                    
                    print("decrypted string: \(string)")
                } catch let error {
                    print("someting went wrong \(error.localizedDescription)")
                    //Log error
                }
                
                
            } else {
                print("Document does not exist")
            }
        }
        
        
        db.collection("test_stuff").document("android_pub_key").getDocument { (document, error) in
            if let document = document, document.exists {
                print("loaded the android pub key")
                let and_pub_key = document.data()!["key"] as! String
                
                do {
                    let message: String = "Hi, Gucci"
                    let otherPublicKey = try PublicKey(pemEncoded: and_pub_key)
                    
                    let clear = try ClearMessage(string: message, using: .utf8)
                    let encryptedMessage = try clear.encrypted(with: otherPublicKey, padding: .PKCS1)
                    let encryptedMessageString = encryptedMessage.base64String
                    
                    
                    self.db.collection("test_stuff").document("to_android_data").setData([
                        "enc_data_key" : encryptedMessageString,
                        "signature" : "signature_string",
                        "uploader_pub_key" : "exportable_pub_key",
                    ]){err in
                        print("sent android data to decrypt!")
                    }
                    
                } catch let error {
                    //Log error
                }
            }
        }
        
    }
    
    
    func begin_the_thing(){
        //get my keys incase there are none
        fetchMyKeys()
        
        //get an android pub key if there is one
        db.collection("test_stuff").document("android_pub_key").getDocument { (document, error) in
            if let document = document, document.exists {
                print("loaded the android pub key")
                //lets try sending the android some encrypted data
//                self.sendAndroidEncryptedData(android_pub_key: document.data()!["key"] as! String)
                
                do {
                    let decoded_pem_key = try PublicKey(pemEncoded: document.data()!["key"] as! String)
                    print("decoded_pem_key: \(decoded_pem_key.originalData?.base64EncodedString())")
                    
                    let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
                    var error: Unmanaged<CFError>?
                    let options: [String: Any] = [kSecAttrKeyType as String: keyAlgorithm.secKeyAttrType,
                                                  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                                  kSecAttrKeySizeInBits as String : 2048]
                    
                    guard let key = SecKeyCreateWithData(decoded_pem_key.originalData as! CFData, options as CFDictionary, &error)
                    else {
                        fatalError("Failed to create key from decoded_pem_key original data \(error.debugDescription)")
                        return
                    }
                    
                    self.sendAndroidEncryptedData(android_pub_key: self.convertKeyToString(key)!)
                    
                } catch let error {
                    //Log Error
                    print("that didnt work lol")
                    return
                }
                
            } else {
                print("Document does not exist")
            }
        }
        
        
        //get any encrypted data sent from android
        db.collection("test_stuff").document("to_ios_data").getDocument { (document, error) in
            if let document = document, document.exists {
                print("loaded data sent to decrypt from android")
                //lets try decrypting the data from android
                
                do {
                    let decoded_pem_key = try PublicKey(pemEncoded: document.data()!["uploader_pub_key"] as! String)
                    print("decoded_pem_key: \(decoded_pem_key.originalData?.base64EncodedString())")
                    
                    let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
                    var error: Unmanaged<CFError>?
                    let options: [String: Any] = [kSecAttrKeyType as String: keyAlgorithm.secKeyAttrType,
                                                  kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                                  kSecAttrKeySizeInBits as String : 2048]
                    
                    guard let key = SecKeyCreateWithData(decoded_pem_key.originalData as! CFData, options as CFDictionary, &error)
                    else {
                        fatalError("Failed to create key from decoded_pem_key original data \(error.debugDescription)")
                        return
                    }
                    
                    self.decryptDataSentFromAndroid(encrypted_string: document.data()!["enc_data_key"] as! String,
                                                    android_pub_key: self.convertKeyToString(key)!,
                                               signature_string: document.data()!["signature"] as! String)
                    
                } catch let error {
                    //Log Error
                    print("that didnt work lol")
                    return
                }
                
                
                
            } else {
                print("Document does not exist")
            }
        }
  
    }
    
    func generateMyKeys() -> (SecKey?, SecKey?){
        let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
        print("generating keys since there are none!------------")
        
        let tag = "com.color.airwork.test.keys2".data(using: .utf8)!
        let attributes: [String: Any] = [
            kSecAttrKeyType as String: keyAlgorithm.secKeyAttrType,
            kSecAttrKeySizeInBits as String: 2048,
            kSecAttrCanSign as String: true,
            kSecPrivateKeyAttrs as String:[kSecAttrIsPermanent as String: true, kSecAttrApplicationTag as String: tag]
        ]
        
        var error_m: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error_m) else {
            print("error generating private key")
            return (nil,nil)
        }
        
        let publicKey = SecKeyCopyPublicKey(privateKey)
        
        stashMyKeys(pri_key: privateKey, pub_key: publicKey!)
        
        return (privateKey, publicKey)
    }
    
    func stashMyKeys(pri_key: SecKey, pub_key: SecKey){
        let pri_stash_tag = "com.color.airwork.test.private_key2"
        let pri_addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: pri_stash_tag,
                                       kSecValueRef as String: pri_key]
        
        let pri_status = SecItemAdd(pri_addquery as CFDictionary, nil)
        guard pri_status == errSecSuccess else {
            print("failed to stash secret key")
            return
        }
        
        let pub_stash_tag = "com.color.airwork.test.public_key2"
        let pub_addquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: pub_stash_tag,
                                       kSecValueRef as String: pub_key]
        
        let pub_status = SecItemAdd(pub_addquery as CFDictionary, nil)
        guard pub_status == errSecSuccess else {
            print("failed to stash secret key")
            return
        }
        
        
        //record my public key in the db
//        let my_key_as_string = convertKeyToString(pub_key)
        var error5: Unmanaged<CFError>?
        guard let pub_key_data = SecKeyCopyExternalRepresentation(pub_key, &error5) as Data? else {
            print("failed to convert pub key into data")
            return
        }
        var exportable_pub_key = exportImportManager.exportRSAPublicKeyToPEM(pub_key_data, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
        
        db.collection("test_stuff").document("ios_pub_key").setData([
            "key" : exportable_pub_key,
        ]){err in
            print("set public key in db")
        }
        
    }
    
    func fetchMyKeys() -> (SecKey?, SecKey?){
        let stash_pri_tag = "com.color.airwork.test.private_key2"
        let getpriquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: stash_pri_tag,
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                       kSecReturnRef as String: true]
        
        var pri_item: CFTypeRef?
        let pri_fetch_status = SecItemCopyMatching(getpriquery as CFDictionary, &pri_item)
        guard pri_fetch_status == errSecSuccess else {
            print("failed to fetch status")
            return generateMyKeys()
        }
        let fetched_pri_key = pri_item as! SecKey
        
        //next the public key
        let pub_stash_tag = "com.color.airwork.test.public_key2"
        let pub_getquery: [String: Any] = [kSecClass as String: kSecClassKey,
                                       kSecAttrApplicationTag as String: pub_stash_tag,
                                       kSecAttrKeyType as String: kSecAttrKeyTypeRSA,
                                       kSecReturnRef as String: true]
        
        var pub_item: CFTypeRef?
        let pub_fetch_status = SecItemCopyMatching(pub_getquery as CFDictionary, &pub_item)
        guard pub_fetch_status == errSecSuccess else {
            print("failed to fetch status")
            return generateMyKeys()
        }
        let fetched_pub_key = pub_item as! SecKey
        
        return (fetched_pri_key, fetched_pub_key)
    }
    
    
    func sendAndroidEncryptedData(android_pub_key: String){
        let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
        let plainText = "my test data!"
        
        let (pri,pub) = fetchMyKeys()
        let android_pub = convertPubStringToKey(android_pub_key, keyAlgorithm)
        
        let data = Data.init(base64Encoded: plainText.base64Encoded()!)! as CFData
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1
        
        guard SecKeyIsAlgorithmSupported(android_pub!, .encrypt, algorithm) else {
            print("public secret key doesnt support algorithm passed")
            return
        }
        
        guard (plainText.count < (SecKeyGetBlockSize(android_pub!)-130)) else {
            print("plaintext too large, size: \(plainText.count) ; max size: \(SecKeyGetBlockSize(android_pub!)-130)")
            return
        }
        
        var error: Unmanaged<CFError>?
        guard let cipherText = SecKeyCreateEncryptedData(android_pub!, algorithm, data, &error) as CFData? else {
            print("error creating the cipherText")
            return
        }
        
        let encrypted_string = (cipherText as Data).base64EncodedString()
        
        var error3: Unmanaged<CFError>?
        let sign_algorithm: SecKeyAlgorithm = .rsaSignatureMessagePKCS1v15SHA512
        let data2 = Data.init(base64Encoded: "gucci123".base64Encoded()!)! as CFData
        guard let signature = SecKeyCreateSignature(pri!, sign_algorithm, data2, &error3) as CFData? else {
            print("error making signature: \(error3.debugDescription)")
            return
        }
        
        let signature_string = (signature as Data).base64EncodedString()
        var error5: Unmanaged<CFError>?
        guard let pub_key_data = SecKeyCopyExternalRepresentation(pub!, &error5) as Data? else {
            print("failed to convert pub key into data")
            return
        }
        var exportable_pub_key = exportImportManager.exportRSAPublicKeyToPEM(pub_key_data, keyType: kSecAttrKeyTypeRSA as String, keySize: 2048)
//        let my_pub_key = convertKeyToString(pub!)
        
        
        //push the encrypted data to the db
        db.collection("test_stuff").document("to_android_data").setData([
            "enc_data_key" : encrypted_string,
            "signature" : signature_string,
            "uploader_pub_key" : exportable_pub_key,
        ]){err in
            print("sent android data to decrypt!")
        }
        
    }
    
    
    func decryptDataSentFromAndroid(encrypted_string: String, android_pub_key: String, signature_string: String){
        let (pub,pri) = fetchMyKeys()
        
        let keyAlgorithm = KeyAlgorithm.rsa(signatureType: .sha256)
        let algorithm: SecKeyAlgorithm = .rsaEncryptionPKCS1
        let android_pub = convertPubStringToKey(android_pub_key, keyAlgorithm)
        
        let data2 = Data.init(base64Encoded: "gucci123".base64Encoded()!)! as CFData
        let signature = Data.init(base64Encoded: signature_string.base64Encoded()!)! as CFData
        let sign_algorithm: SecKeyAlgorithm = .rsaSignatureRaw
        
        //test if the signature is ok
//        var error4: Unmanaged<CFError>?
//        guard SecKeyVerifySignature(pub!, sign_algorithm, data2, signature, &error4) else{
//            print("error verifying signature: \(error4.debugDescription)")
//            return
//        }
        
        
        //if the signature is ok, go ahead with the decryption
        do {
            let encrypted = try EncryptedMessage(base64Encoded: encrypted_string)
            print("obtained encrypted")
            let clear = try encrypted.decrypted(with: PrivateKey(reference: pri!), padding: .PKCS1)
            print("obtained clear")

            let data = clear.data
            let string = try clear.string(encoding: .utf8)
            print("string: \(string)")

        } catch let error {

            print("decrypting failed \(error.localizedDescription)")
        }
        
        
        
        
        let data_dec = Data.init(base64Encoded: encrypted_string)! as CFData
        guard SecKeyIsAlgorithmSupported(pri!, .decrypt, algorithm) else {
            print("private secret key doesnt support algorithm passed")
            return
        }
        
        var error2: Unmanaged<CFError>?
        guard let clearText = SecKeyCreateDecryptedData(pri!, algorithm,  (data_dec), &error2) as Data? else {
            print("error decrypting data: \(error2.debugDescription)")
            return
        }
        
        let decrypted_text = clearText.base64EncodedString().base64Decoded()
        print("decrypted text : \(decrypted_text!)")
    }
    
    
    
    
    
    
    
    func convertKeyToString(_ key: SecKey) -> String? {
        var error: Unmanaged<CFError>?

        guard let data = SecKeyCopyExternalRepresentation(key, &error) as Data? else {
            return nil
        }

        return data.base64EncodedString()
    }
    
    func convertPubStringToKey(_ key_string: String, _ algorithm: KeyAlgorithm) -> SecKey? {
        var error: Unmanaged<CFError>?
        
        guard let data = Data.init(base64Encoded: key_string)
        else{
            fatalError("Failed to convert key string, the string was not really base64")
            return nil
        }
        
        let options: [String: Any] = [kSecAttrKeyType as String: algorithm.secKeyAttrType,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                                      kSecAttrKeySizeInBits as String : 2048]
        
        guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error)
        else {
            fatalError("Failed to convert key data to string")
            return nil
        }
        
        return key
    }
    
    func convertPriStringToKey(_ key_string: String, _ algorithm: KeyAlgorithm) -> SecKey? {
        var error: Unmanaged<CFError>?
        
        guard let data = Data.init(base64Encoded: key_string)
        else{
            fatalError("Failed to convert key string, the string was not really base64")
            return nil
        }
        
        let options: [String: Any] = [kSecAttrKeyType as String: algorithm.secKeyAttrType,
                                      kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
                                      kSecAttrKeySizeInBits as String : 2048]
        
        guard let key = SecKeyCreateWithData(data as CFData, options as CFDictionary, &error)
        else {
            fatalError("Failed to convert key data to string")
            return nil
        }
        
        return key
        
    }
    
    
    
    func generateKeysAndStoreInKeychain(_ algorithm: KeyAlgorithm, keySize: Int,
                                           tagPrivate: String, tagPublic: String) -> (SecKey?, SecKey?) {
       let publicKeyParameters: [String: Any] = [
           String(kSecAttrIsPermanent): true,
           String(kSecAttrAccessible): kSecAttrAccessibleAfterFirstUnlock,
           String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!
       ]

       var privateKeyParameters: [String: Any] = [
           String(kSecAttrIsPermanent): true,
           String(kSecAttrAccessible): kSecAttrAccessibleAfterFirstUnlock,
           String(kSecAttrApplicationTag): tagPrivate.data(using: .utf8)!
       ]

       #if !targetEnvironment(simulator)
           //This only works for Secure Enclave consistign of 256 bit key,
           //note, the signatureType is irrelavent for this check
           if algorithm.type == KeyAlgorithm.ec(signatureType: .sha1).type {
               let access = SecAccessControlCreateWithFlags(kCFAllocatorDefault,
                                                            kSecAttrAccessibleAfterFirstUnlock,
                                                            .privateKeyUsage,
                                                            nil)!   // Ignore error
               privateKeyParameters[String(kSecAttrAccessControl)] = access
           }
       #endif

       //Define what type of keys to be generated here
       var parameters: [String: Any] = [
           String(kSecAttrKeyType): algorithm.secKeyAttrType,
           String(kSecAttrKeySizeInBits): keySize,
           String(kSecReturnRef): true,
           String(kSecPublicKeyAttrs): publicKeyParameters,
           String(kSecPrivateKeyAttrs): privateKeyParameters
       ]

       #if !targetEnvironment(simulator)
           //iOS only allows EC 256 keys to be secured in enclave.
           //This will attempt to allow any EC key in the enclave,
           //assuming iOS will do it outside of the enclave if it
           //doesn't like the key size, note: the signatureType is irrelavent for this check
           if algorithm.type == KeyAlgorithm.ec(signatureType: .sha1).type {
               parameters[String(kSecAttrTokenID)] = kSecAttrTokenIDSecureEnclave
           }
       #endif

       //Use Apple Security Framework to generate keys, save them to application keychain
       var error: Unmanaged<CFError>?
       let privateKey = SecKeyCreateRandomKey(parameters as CFDictionary, &error)
       if privateKey == nil {
           print("Error creating keys occured: \(error!.takeRetainedValue() as Error), keys weren't created")
           return (nil, nil)
       }

       //Get generated public key
       let query: [String: Any] = [
           String(kSecClass): kSecClassKey,
           String(kSecAttrKeyType): algorithm.secKeyAttrType,
           String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!,
           String(kSecReturnRef): true
       ]

       var publicKeyReturn: CFTypeRef?
       let result = SecItemCopyMatching(query as CFDictionary, &publicKeyReturn)
       if result != errSecSuccess {
           print("Error getting publicKey fron keychain occured: \(result)")
           return (privateKey, nil)
       }
       // swiftlint:disable:next force_cast
       let publicKey = publicKeyReturn as! SecKey?
       return (privateKey, publicKey)
   }
    
    
    func getPublicKeyBits(_ algorithm: KeyAlgorithm, publicKey: SecKey, tagPublic: String) -> (Data?, Int?) {

        //Set block size
        let keyBlockSize = SecKeyGetBlockSize(publicKey)
        //Ask keychain to provide the publicKey in bits
        let query: [String: Any] = [
            String(kSecClass): kSecClassKey,
            String(kSecAttrKeyType): algorithm.secKeyAttrType,
            String(kSecAttrApplicationTag): tagPublic.data(using: .utf8)!,
            String(kSecReturnData): true
        ]

        var tempPublicKeyBits: CFTypeRef?
        var _ = SecItemCopyMatching(query as CFDictionary, &tempPublicKeyBits)

        guard let keyBits = tempPublicKeyBits as? Data else {
            return (nil, nil)
        }

        return (keyBits, keyBlockSize)
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

extension String {
    func base64Encoded() -> String? {
        return data(using: .utf8)?.base64EncodedString()
    }

    func base64Decoded() -> String? {
        guard let data = Data(base64Encoded: self) else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
