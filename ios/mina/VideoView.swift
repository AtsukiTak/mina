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
    
    var localVideoWindow: VideoWindow {
        VideoWindow(
            frame: CGRect(x: 0, y: 0, width: 200, height: 200),
            stream: callManager.localStream
        )
    }
    
    var remoteVideoWindow: VideoWindow {
        VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
    }
    
    var body: some View {
        VStack {
            // remoteVideo
            self.remoteVideoWindow
            Spacer()
            Text("My PeerId : \(callManager.peerId ?? "")")
            // localVideo
            self.localVideoWindow
                .frame(width: 200, height: 200, alignment: .bottomLeading)
        }
    }
}

struct VideoView_Previews: PreviewProvider {
    static var previews: some View {
        VideoView()
    }
}
