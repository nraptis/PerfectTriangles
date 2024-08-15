/*
 * PerfectTriangulation Framework - MIT Open License
 *
 * Permission is hereby granted, free of charge, to any person or organization using this framework for the purposes of:
 * 1.) Medical research
 * 2.) AI research
 * 3.) Education
 * 4.) Drug research
 *
 * The above use cases are granted as non-exclusive, non-transferable permissions for research and educational purposes only.
 * This framework is publicly distributed and free to access for review and use under the above categories. However, the
 * source code is closed and not available for modification or redistribution.
 *
 * For commercial applications, including but not limited to software development, product integration, and other
 * for-profit uses, a separate commercial license must be obtained. The commercial license is available for a fee of $175,000.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE
 * WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS
 * OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES, OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT,
 * OR OTHERWISE, ARISING FROM, OUT OF, OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

import UIKit

import RaptisTriangultion

class DemoView: UIView {
    
    private static let paddingRight = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? 64.0 : 24.0)
    private static let paddingLeft = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? 64.0 : 24.0)
    private static let paddingTop = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? 64.0 : 24.0)
    private static let paddingBottom = CGFloat(UIDevice.current.userInterfaceIdiom == .pad ? 64.0 : 24.0)

    var controlPoints = [ControlPoint]()
    
    var dragTouch: UITouch?
    var dragControlPoint = ControlPoint()
    var dragStartControlPoint = CGPoint.zero
    var dragStartTouchPoint = CGPoint.zero
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    
    func reset(width: CGFloat, height: CGFloat) {
        
        controlPoints.removeAll()
        
        let left = Self.paddingLeft
        let right = width - Self.paddingRight
        let top = Self.paddingTop
        let bottom = height - Self.paddingBottom
        
        let centerX = left + (right - left) * 0.5
        let centerY = top + (bottom - top) * 0.5
        
        let radius = (right - left) * 0.5
        
        let numberOfPoints = 12
        
        for circleIndex in 0..<numberOfPoints {
            let angle = (CGFloat(circleIndex) / CGFloat(numberOfPoints)) * CGFloat.pi * 2.0
            let controlPoint = ControlPoint()
            controlPoint.x = centerX + sin(angle) * radius
            controlPoint.y = centerY - cos(angle) * radius
            controlPoints.append(controlPoint)
        }
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        for touch in touches {
            
            if dragTouch !== nil { break }
            
            let location = touch.location(in: self)
            var bestDistance = CGFloat(50.0 * 50.0)
            for controlPoint in controlPoints {
                let diffX = controlPoint.x - location.x
                let diffY = controlPoint.y - location.y
                let distanceSquared = diffX * diffX + diffY * diffY
                if distanceSquared < bestDistance {
                    dragTouch = touch
                    dragControlPoint = controlPoint
                    bestDistance = distanceSquared
                    dragStartControlPoint = CGPoint(x: controlPoint.x, y: controlPoint.y)
                    dragStartTouchPoint = location
                }
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch in touches where touch === dragTouch {
            let location = touch.location(in: self)
            let deltaX = location.x - dragStartControlPoint.x
            let deltaY = location.y - dragStartControlPoint.y
            dragControlPoint.x = dragStartControlPoint.x + deltaX
            dragControlPoint.y = dragStartControlPoint.y + deltaY
            
            setNeedsDisplay()
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragTouch = nil
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        dragTouch = nil
    }
    
    override func draw(_ rect: CGRect) {

        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.clear(bounds)
        
        
        var points = [CGPoint]()
        var idealDistance = CGFloat(14.0)
        var index1 = controlPoints.count - 1
        var index2 = 0
        index1 = controlPoints.count - 1
        index2 = 0
        while index2 < controlPoints.count {
            
            let x1 = controlPoints[index1].x
            let y1 = controlPoints[index1].y
            
            let x2 = controlPoints[index2].x
            let y2 = controlPoints[index2].y
            
            var diffX = (x2 - x1)
            var diffY = (y2 - y1)
            
            let distanceSquared = diffX * diffX + diffY * diffY
            if distanceSquared > 1.0 {
                let distance = sqrt(distanceSquared)
                diffX /= distance
                diffY /= distance
                let steps = Int(distance / idealDistance) + 1
                if steps > 0 {
                    for step in 0..<steps {
                        let percent = CGFloat(step) / CGFloat(steps)
                        let x = x1 + (x2 - x1) * percent
                        let y = y1 + (y2 - y1) * percent
                        points.append(CGPoint(x: x, y: y))
                    }
                    
                }
                
            }
            
            index1 = index2
            index2 += 1
        }
        
        let triangles = RaptisTriangultion.PerfectTriangulator.shared.triangulate(points: points)
        
        for triangle in triangles {
            
            let p1 = CGPoint(x: triangle.x1, y: triangle.y1)
            let p2 = CGPoint(x: triangle.x2, y: triangle.y2)
            let p3 = CGPoint(x: triangle.x3, y: triangle.y3)
            
            context.saveGState()
            context.setFillColor(UIColor(red: CGFloat.random(in: 0.75...1.0),
                                         green: CGFloat.random(in: 0.75...1.0),
                                         blue: CGFloat.random(in: 0.75...1.0),
                                         alpha: 0.5).cgColor)
            context.move(to: p1)
            context.addLine(to: p2)
            context.addLine(to: p3)
            context.closePath()

            context.fillPath()
            
            context.restoreGState()
        }
        
        
        index1 = controlPoints.count - 1
        index2 = 0
        while index2 < controlPoints.count {
            
            let cp1 = CGPoint(x: controlPoints[index1].x, y: controlPoints[index1].y)
            let cp2 = CGPoint(x: controlPoints[index2].x, y: controlPoints[index2].y)

            context.saveGState()
            context.setLineWidth(4.0)
            context.setStrokeColor(UIColor.gray.cgColor)
            context.move(to: cp1)
            context.addLine(to: cp2)
            context.strokePath()
            context.restoreGState()
            
            context.saveGState()
            context.setLineWidth(2.0)
            context.setStrokeColor(UIColor.white.cgColor)
            context.move(to: cp1)
            context.addLine(to: cp2)
            context.strokePath()
            context.restoreGState()
            
            index1 = index2
            index2 += 1
        }
        
        let rectsOuter = controlPoints.map { CGRect(x: $0.x - 6.0, y: $0.y - 6.0, width: 13.0, height: 13.0) }
        let rectsInner = controlPoints.map { CGRect(x: $0.x - 4.0, y: $0.y - 4.0, width: 9.0, height: 9.0) }

        context.saveGState()
        context.setFillColor(UIColor.gray.cgColor)
        context.fill(rectsOuter)
        context.restoreGState()
        
        context.saveGState()
        context.setFillColor(UIColor.green.cgColor)
        context.fill(rectsInner)
        context.restoreGState()
    }

    
    
}
