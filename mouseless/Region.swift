import Foundation
import CoreGraphics

struct Region {
    var x: CGFloat
    var y: CGFloat
    var width: CGFloat
    var height: CGFloat

    var rect: CGRect {
        return CGRect(x: x, y: y, width: width, height: height)
    }
}
