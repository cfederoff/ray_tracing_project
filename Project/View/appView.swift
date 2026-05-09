import SwiftUI

struct appView: View {
    
    @EnvironmentObject var gamescene: GameScene
    
    var body: some View {
        VStack{
            ContentView()
                .frame(width: 800, height: 550)            
        }
    }
}

struct appView_Previews: PreviewProvider {
    static var previews: some View {
        appView().environmentObject(GameScene())
    }
}
