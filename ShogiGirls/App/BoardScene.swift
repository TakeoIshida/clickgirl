import SpriteKit
import UIKit

final class BoardScene: SKScene {
    var boardPosition = ShogiPosition.initial()
    var player: Side = .black
    var selected: Int?
    var destinations: Set<Int> = []
    var lastMove: ShogiMove?
    var hintMove: ShogiMove?
    var onSquare: ((Int) -> Void)?
    private var cell: CGFloat { (size.width - 24) / 9 }
    override func didMove(to view: SKView) { backgroundColor = .clear; drawBoard() }
    override func didChangeSize(_ oldSize: CGSize) { drawBoard() }
    func point(_ index: Int) -> CGPoint {
        let i = player == .black ? index : 80 - index
        return CGPoint(x:12 + (CGFloat(i % 9) + 0.5) * cell, y:size.height - 12 - (CGFloat(i / 9) + 0.5) * cell)
    }
    func drawBoard() {
        removeAllChildren()
        guard cell > 0 else { return }
        let base = SKShapeNode(rect:CGRect(x:5,y:5,width:size.width-10,height:size.height-10),cornerRadius:10)
        base.fillColor = UIColor(hex:0xD9B47A); base.strokeColor = UIColor(hex:0xA88450); base.lineWidth = 1.5; addChild(base)
        for i in 0..<81 {
            let center = point(i)
            let square = SKShapeNode(rectOf:CGSize(width:cell,height:cell))
            square.position = center; square.strokeColor = UIColor(hex:0xAD8757); square.lineWidth = 0.6
            square.fillColor = selected == i ? UIColor(hex:0xBAD1A4) : (lastMove?.to == i || lastMove?.from == i) ? UIColor(hex:0xE5C998) : UIColor(hex:0xEED5AC)
            addChild(square)
            if let p = boardPosition.board[i] {
                let node = SKNode(); node.position = center; if p.side != player { node.zRotation = .pi }
                let w = cell * 0.79, h = cell * 0.9
                let path = CGMutablePath(); path.move(to:CGPoint(x:-w/2,y:-h/2)); path.addLine(to:CGPoint(x:w/2,y:-h/2)); path.addLine(to:CGPoint(x:w*0.39,y:h*0.32)); path.addLine(to:CGPoint(x:0,y:h/2)); path.addLine(to:CGPoint(x:-w*0.39,y:h*0.32)); path.closeSubpath()
                let tile = SKShapeNode(path:path); tile.fillColor = UIColor(hex:0xFFF1CF); tile.strokeColor = UIColor(hex:0xB8905D); tile.lineWidth = 0.9; node.addChild(tile)
                let text = SKLabelNode(fontNamed:"HiraMinProN-W6"); text.text = p.text; text.fontSize = cell * 0.63; text.fontColor = p.promoted ? UIColor(hex:0xA94343) : UIColor(hex:0x33281D); text.verticalAlignmentMode = .center; text.position.y = -cell*0.025; node.addChild(text)
                addChild(node)
                if p.kind == .king && boardPosition.inCheck(p.side) {
                    let check = SKShapeNode(rectOf:CGSize(width:cell-3,height:cell-3),cornerRadius:3); check.position = center; check.strokeColor = UIColor(hex:0xC75959); check.lineWidth = 2.5; addChild(check)
                }
            }
            if destinations.contains(i) {
                let dot = SKShapeNode(circleOfRadius:cell*0.105); dot.position = center; dot.fillColor = UIColor(hex:0x527D68); dot.strokeColor = .white; dot.lineWidth = 1; dot.zPosition = 3; addChild(dot)
            }
            if hintMove?.to == i || hintMove?.from == i {
                let ring = SKShapeNode(rectOf:CGSize(width:cell-4,height:cell-4),cornerRadius:4); ring.position = center; ring.strokeColor = UIColor(hex:0x487EAF); ring.lineWidth = 3; ring.zPosition = 4; addChild(ring)
            }
        }
        for c in 0..<9 {
            let label = SKLabelNode(fontNamed:"HiraginoSans-W3"); label.text = "\(player == .black ? 9-c : c+1)"; label.fontSize = 8; label.fontColor = UIColor(hex:0x765D41); label.position = CGPoint(x:12+(CGFloat(c)+0.5)*cell,y:size.height-10); addChild(label)
        }
    }
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let p = touches.first?.location(in:self) else { return }
        let x = Int(floor((p.x-12)/cell)), y = Int(floor((size.height-12-p.y)/cell))
        guard (0..<9).contains(x), (0..<9).contains(y) else { return }
        onSquare?(player == .black ? y*9+x : 80-y*9-x)
    }
}

final class AccessibleBoardView: UIView {
    private let renderer = SKView()
    private var squareButtons: [UIButton] = []
    var allowsTransparency: Bool { get { renderer.allowsTransparency } set { renderer.allowsTransparency = newValue } }
    var ignoresSiblingOrder: Bool { get { renderer.ignoresSiblingOrder } set { renderer.ignoresSiblingOrder = newValue } }
    override init(frame: CGRect) {
        super.init(frame:frame); renderer.backgroundColor = .clear
        renderer.accessibilityElementsHidden = true; renderer.isUserInteractionEnabled = false
        addSubview(renderer)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) is not supported") }
    override func layoutSubviews() {
        super.layoutSubviews(); renderer.frame = bounds
        if let scene = renderer.scene as? BoardScene { updateAccessibility(scene:scene) }
    }
    func presentScene(_ scene: SKScene) { renderer.presentScene(scene) }
    func updateAccessibility(scene: BoardScene) {
        guard bounds.width > 24 else { return }
        isAccessibilityElement = false
        if squareButtons.isEmpty {
            squareButtons = (0..<81).map { _ in
                let b = UIButton(type:.custom); b.backgroundColor = .clear; addSubview(b); return b
            }
        }
        for visible in 0..<81 {
            let i = scene.player == .black ? visible : 80-visible
            let element = squareButtons[visible]
            let piece = scene.boardPosition.board[i]
            element.accessibilityLabel = "\(9-i%9)筋\(i/9+1)段、\(piece.map { "\($0.side == scene.player ? "自分" : "相手")の\($0.text)" } ?? "空きマス")"
            element.accessibilityIdentifier = "square_\(i)"; element.accessibilityTraits = .button
            let cell = (bounds.width-24)/9
            element.frame = CGRect(x:12+CGFloat(visible%9)*cell,y:12+CGFloat(visible/9)*cell,width:cell,height:cell)
            element.removeAction(identifiedBy:UIAction.Identifier("square"),for:.touchUpInside)
            element.addAction(UIAction(identifier:UIAction.Identifier("square")) { [weak scene] _ in scene?.onSquare?(i) },for:.touchUpInside)
        }
        accessibilityElements = squareButtons
    }
}
