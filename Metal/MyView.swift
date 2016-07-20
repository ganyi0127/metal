//
//  MyView.swift
//  TestGraphics
//
//  Created by YiGan on 7/20/16.
//  Copyright © 2016 YiGan. All rights reserved.
//

import UIKit
import Metal
import QuartzCore
class MyView: UIView {
    
    var device:MTLDevice! = nil
    
    var metalLayer:CAMetalLayer! = nil
    
    var vertexBuffer:MTLBuffer! = nil
    
    var pipelineState:MTLRenderPipelineState?
    
    var commandQueue:MTLCommandQueue! = nil
    
    //
    var timer:CADisplayLink! = nil
    
    //缓冲区
    let vertexData:[Float] = [
        0, 1, 0,
        -1, -1, 0,
        1, -1, 0
    ]
    
    
    override func didMoveToSuperview() {
        
        config()
        createContents()
    }
    
    private func config(){
        
        //MARK:1
        device = MTLCreateSystemDefaultDevice()
        
        //MARK:2
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .BGRA8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: frame.size.width / 2, height: frame.size.height / 2))
        layer.addSublayer(metalLayer)
        
        //MARK:3
        let dataSize = vertexData.count * sizeofValue(vertexData[0])
        vertexBuffer = device.newBufferWithBytes(vertexData, length: dataSize, options: .CPUCacheModeDefaultCache)
        
        //4...5 in Shader.metal
        //MARK:6
        let defaultLibrary = device.newDefaultLibrary()
        let fragmentProgram = defaultLibrary?.newFunctionWithName("basic_fragment")
        let vertexProgram = defaultLibrary?.newFunctionWithName("basic_vertex")
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = .BGRA8Unorm
        
        do{
            pipelineState = try device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        }catch let error{
            print("error:\(error)\n")
        }
        
        //MARK:7
        commandQueue = device.newCommandQueue()
        
        //MARK:finally
        timer = CADisplayLink(target: self, selector: #selector(MyView.loop))
        timer.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: NSDefaultRunLoopMode)
    }
    
    private func createContents(){
        
    }
    
    func loop(){
        render()
    }
    
    func render(){
        
        let drawable = metalLayer.nextDrawable()
        
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = drawable?.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .Clear
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor(red: 180 / 255, green: 120 / 255, blue: 23 / 255, alpha: 1)
        
        let commandBuffer = commandQueue.commandBuffer()
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.setRenderPipelineState(pipelineState!)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(MTLPrimitiveType.Line, vertexStart: 0, vertexCount: 2, instanceCount: 1)
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable!)
        commandBuffer.commit()
    }
}