//
//  VideoView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/06.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct VideoView: View {
    
    @ObservedObject var callManager: CallManager = CallManager.shared
    
    var body: some View {
        VStack {
            // remoteVideo
            VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                        stream: callManager.remoteStream)
            
            Spacer()
            
            Text("My PeerId : \(callManager.peerId ?? "")")
            
            if let errMsg = callManager.errMsg {
                Text("Error \(errMsg)")
            }
            
            // localVideo
            VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                        stream: callManager.localStream)
                .frame(width: 200, height: 200, alignment: .bottomLeading)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
