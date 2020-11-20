//
//  Color.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/20.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

extension Color {
    static let lightMain = Color(red: 248 / 256, green: 225 / 256, blue: 232 / 256)
    
    static let main = Color(red: 205 / 256, green: 71 / 256, blue: 118 / 256)
}

struct Color_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            Color.lightMain.frame(width: 100, height: 100, alignment: .center)
            Color.main.frame(width: 100, height: 100, alignment: .center)
        }
    }
}
