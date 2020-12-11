//
//  SwiftUIView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/08.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct RootView: View {
    @EnvironmentObject var env: Store
    
    var body: some View {
        Group {
            if (self.env.callMode) {
                VideoView().transition(.opacity)
            } else {
                FirstView()
                    .environmentObject(self.env)
                    .transition(.opacity)
            }
        }
    }
}

struct RootView_Previews: PreviewProvider {
    static var previews: some View {
        RootView()
            .environmentObject(Store())
    }
}
