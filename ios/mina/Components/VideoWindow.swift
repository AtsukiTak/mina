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
    var video: SKWVideo?

    init(frame: CGRect) {
        self.frame = frame
        super.init()
    }
    
    func attachMediaStream(stream: SKWMediaStream) {
        stream.addVideoRenderer(self.video!, track: 0)
    }
}

extension VideoWindow: UIViewRepresentable {
    func makeUIView(context: Context) -> SKWVideo {
        self.video = SKWVideo(frame: self.frame)
        return self.video!
    }
    
    func updateUIView(_ uiView: SKWVideo, context: Context) {
    }
}

struct VideoWindow_Previews: PreviewProvider {
    static var previews: some View {
        VideoWindow(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            .frame(width: 200.0, height: 200.0, alignment: .center)
    }
}
