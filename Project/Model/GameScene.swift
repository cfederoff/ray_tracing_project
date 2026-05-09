import Foundation

class GameScene: ObservableObject {
    
    @Published var camera: Camera
    @Published var spheres: [Sphere]
    
    init() {
        camera = Camera(position: [0.0, 1.0, 1.0])
        
        spheres = []
        
        for _ in 1...50 {
            
            let tempSphere = Sphere (
                center: [
                    Float.random(in: -5.0...5.0),
                    Float.random(in: 0.0...2.0),
                    Float.random(in: -10.0...0.0)
                ],
                radius: Float.random(in: 0.1...0.5),
                color: [
                    Float.random(in: 0.0...1.0),
                    Float.random(in: 0.0...1.0),
                    Float.random(in: 0.0...1.0)
                ],
                reflectance: Float.random(in: 0.0...1.0),
                other: Float.random(in: 0.0...1.0),
                material: Float.random(in: 1...3)
            )
            spheres.append(tempSphere)

        }
        
        let tempSphere1 = Sphere(center: [0,-100.5,-1], radius: 100.0, color: [0.8,0.8,0.8], reflectance: 1.0, other:5.0, material: 1)
        spheres.append(tempSphere1)
        let tempSphere2 = Sphere(center: [0.0,0.0, -1.2], radius: 0.5, color: [0.1, 0.2, 0.5], reflectance: 1.0, other: 0.2, material: 1)
        spheres.append(tempSphere2)

        let tempSphere5 = Sphere(center: [1.0,0.0, -1.0], radius: 0.5, color: [0.8, 0.6, 0.2], reflectance: 1.0, other:1.00/1.5, material: 2)
        spheres.append(tempSphere5)
    }
}

