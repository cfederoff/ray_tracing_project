import Foundation

class Sphere {
    var center: vector_float3;
    var radius: Float
    var color: vector_float3;
    var reflectance: Float
    var material: Float
    var other: Float
    
    init(center: vector_float3, radius: Float, color: vector_float3, reflectance: Float,  other: Float, material: Float) {
        self.center = center
        self.radius = radius
        self.color = color
        self.reflectance = reflectance
        self.other = other
        self.material = material
    }
}
