//
//  VideoView.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/06.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI

struct VideoView: View {
    
    @ObservedObject var callSession: CallSessionManager = CallSessionManager.shared
    
    var body: some View {
        VStack {
            // remoteVideo
            VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                        stream: callSession.remoteStream)
            
            Spacer()
            
            Text("My PeerId : \(callSession.peerId ?? "")")
            
            if let errMsg = callSession.errMsg {
                Text("Error \(errMsg)")
            }
            
            // localVideo
            VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200),
                        stream: callSession.localStream)
                .frame(width: 200, height: 200, alignment: .bottomLeading)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
