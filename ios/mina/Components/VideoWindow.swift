//
//  VideoWindow.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/10/06.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import SwiftUI
import SkyWay

final class VideoWindow: NSObject {
    
    let frame: CGRect
    var stream: SKWMediaStream?
    var isStreamAttached: Bool = false

    init(frame: CGRect, stream: SKWMediaStream? = nil) {
        NSLog("init VideoWindow")
        self.frame = frame
        self.stream = stream
        super.init()
    }
}

extension VideoWindow: UIViewRepresentable {
    func makeUIView(context: Context) -> SKWVideo {
        SKWVideo(frame: self.frame)
    }
    
    func updateUIView(_ uiView: SKWVideo, context: Context) {
        if let stream = self.stream {
            if self.isStreamAttached == false {
                stream.addVideoRenderer(uiView, track: 0)
                self.isStreamAttached = true
            }
        }
        
        NSLog("updated VideoWindow. stream is %@", self.isStreamAttached ? "attached" : "not attached")
    }
}

struct VideoWindow_Previews: PreviewProvider {
    static var previews: some View {
        VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            .frame(width: 200.0, height: 200.0, alignment: .center)
    }
}
