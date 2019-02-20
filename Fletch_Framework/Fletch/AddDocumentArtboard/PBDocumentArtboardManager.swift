//
//  PBDocumentArtboardManager.swift
//  Fletch
//
//  Created by Issac Penn on 2019/2/20.
//  Copyright © 2019 pbb. All rights reserved.
//

import Foundation

class PBDocumentArtboardManager: NSObject {
    
    var delegate: PBDocumentArtboardManagerDelegate!
    
    func addDocumentArtboardType(type: String, withContext context:Dictionary<AnyHashable, AnyHashable>, MSDocumentClass: AnyClass) {
        let MSDocument = NSClassFromString("MSDocument")!
        let document = context["document"] as! MSDocument
        document.showMessage("hahaha")
    }
}
