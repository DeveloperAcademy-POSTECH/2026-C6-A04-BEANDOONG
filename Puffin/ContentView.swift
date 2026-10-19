//
//  ContentView.swift
//  beandoong
//
//  Created by 최서진 on 10/9/26.
//

import SwiftUI

struct ContentView: View {
    var body: some View {
        VStack {
            Image("Puffin_logo")
                .resizable()
                .scaledToFit()
                .frame(width: 200)
        }
    }
}

#Preview {
    ContentView()
}
