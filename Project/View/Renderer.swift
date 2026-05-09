//
//  Renderer.swift
//  HelloTriangle
//
//  Created by Andrew Mengede on 27/2/2022.
//

import MetalKit

class Renderer: NSObject, MTKViewDelegate {
    
    var parent: ContentView
    var metalDevice: MTLDevice!
    var metalCommandQueue: MTLCommandQueue!
    var pipeline: MTLComputePipelineState!
    var gamescene: GameScene
    
    init(_ parent: ContentView, gamescene: GameScene) {
        
        self.gamescene = gamescene
        
        self.parent = parent
        if let metalDevice = MTLCreateSystemDefaultDevice() {
            self.metalDevice = metalDevice
        }
        self.metalCommandQueue = metalDevice.makeCommandQueue()
        
        do {
            guard let library = metalDevice.makeDefaultLibrary() else {
                fatalError()
            }
            guard let kernel = library.makeFunction(name: "ray_tracing_kernel") else {
                fatalError()
            }
            pipeline = try metalDevice.makeComputePipelineState(function: kernel)
        } catch {
          fatalError()
        }
        
        super.init()
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func makeSphereBuffer() -> MTLBuffer? {
        
        var memory: UnsafeMutableRawPointer? = nil
        
        let sphereCount: Int = gamescene.spheres.count
        
        let memory_size = sphereCount * MemoryLayout<Shader_Sphere>.stride
        let page_size = 0x1000
        let allocation_size = (memory_size + page_size - 1) & (~(page_size - 1))
        
        var spheres: [Shader_Sphere] = []
        for sphere in gamescene.spheres {
            
            spheres.append(
                Shader_Sphere(
                    center: sphere.center, radius: sphere.radius, color: sphere.color, reflectance: sphere.reflectance, material: sphere.material, other: sphere.other
                )
            )
            
        }
        
        posix_memalign(&memory, page_size, allocation_size)
        memcpy(memory, &spheres, allocation_size)
        
        let buffer = metalDevice.makeBuffer(
            bytes: memory!, length: allocation_size, options: .storageModeShared
        )

        free(memory)
        
        return buffer
        
    }
    
    func draw(in view: MTKView) {
        
        guard let drawable = view.currentDrawable else {
            return
        }
        
        let commandBuffer = metalCommandQueue.makeCommandBuffer()!
        let renderEncoder = commandBuffer.makeComputeCommandEncoder()!
        
        renderEncoder.setComputePipelineState(pipeline)
        renderEncoder.setTexture(drawable.texture, index: 0)
        
        let sphereBuffer = makeSphereBuffer()
        renderEncoder.setBuffer(sphereBuffer, offset: 0, index: 0)
        
        let sphereCount: Int = gamescene.spheres.count

        var sceneData: Shader_SceneData = Shader_SceneData()
        sceneData.sphereCount = Float(sphereCount)
        sceneData.maxBounces = 32
        sceneData.camera_pos = gamescene.camera.position
        sceneData.camera_forwards = gamescene.camera.forwards
        sceneData.camera_right = gamescene.camera.right
        sceneData.camera_up = gamescene.camera.up
        renderEncoder.setBytes(&sceneData, length: MemoryLayout<Shader_SceneData>.stride, index: 1)
        

        let workGroupWidth = pipeline.threadExecutionWidth

        let workGroupHeight = pipeline.maxTotalThreadsPerThreadgroup / workGroupWidth
        let threadsPerGroup = MTLSizeMake(workGroupWidth, workGroupHeight, 1)
        let threadsPerGrid = MTLSizeMake(Int(view.drawableSize.width),
                                         Int(view.drawableSize.height), 1)
        
        renderEncoder.dispatchThreads(threadsPerGrid, threadsPerThreadgroup: threadsPerGroup)
        
        
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
    }
    
}
