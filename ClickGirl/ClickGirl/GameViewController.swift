import UIKit
import SpriteKit

class GameViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        guard let skView = view as? SKView else { return }
        // すでにシーンが表示されていたら再セットアップしない
        guard skView.scene == nil else { return }

        skView.ignoresSiblingOrder = true
        skView.showsFPS = false
        skView.showsNodeCount = false

        let size = skView.bounds.size
        let scene = GameScene(size: size)
        scene.scaleMode = .resizeFill
        scene.backgroundColor = UIColor(red: 0.03, green: 0.03, blue: 0.1, alpha: 1.0)
        skView.presentScene(scene)
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }

    override var prefersStatusBarHidden: Bool {
        return true
    }
}
