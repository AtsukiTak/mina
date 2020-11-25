//
//  Card.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/11/20.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct Card<V: View>: View {
    let bgColor: Color
    let content: V
    
    init(bgColor: Color, content: () -> V) {
        self.bgColor = bgColor
        self.content = content()
    }
    
    var body: some View {
        Group {
            self.content
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 20)
        .background(self.bgColor)
        .cornerRadius(10)
        .shadow(color: Color(white: 0.8), radius: 5, x: 0, y: 2)
    }
}

struct Card_Previews: PreviewProvider {
    static var previews: some View {
        Card(bgColor: Color.lightMain) {
            VStack(alignment: .leading) {
                Text("Hoge")
                    .font(.title)
                    .padding(.bottom, 10)
                Text("fuga fuga")
            }
        }
    }
}
