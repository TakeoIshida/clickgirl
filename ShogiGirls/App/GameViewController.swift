import UIKit
import SpriteKit
import AudioToolbox

@MainActor final class GameViewController: UIViewController {
    private var store = SaveStore()
    private let ads = Ads()
    private var page = "home"
    private var content: UIStackView!
    private var scroll: UIScrollView!
    private var energyLabel: UILabel?
    private var timer: Timer?
    private var match: Match?
    private var selectedSquare: Int?
    private var selectedDrop: PieceKind?
    private var hintMove: ShogiMove?
    private var legal: [ShogiMove] = []
    private var boardView: AccessibleBoardView?
    private var boardScene: BoardScene?
    private var thinking = false
    private var thinkingForHint = false
    private var jobID = UUID()
    private var cancellation = SearchCancellation()
    private var suspended = false
    private var dialog = ""
    private var portraitMood = "base"
    private var newRewards: [GalleryReward] = []
    private var didStart = false
    private var uiTesting = false
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var preferredStatusBarStyle: UIStatusBarStyle { .darkContent }
    override func viewDidLoad() {
        super.viewDidLoad(); view.backgroundColor = Theme.paper
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            uiTesting = true; ads.testing = true
            let d = UserDefaults(suiteName:"ShogiGirlsUITesting")!
            if !ProcessInfo.processInfo.arguments.contains("--keep-save") { d.removePersistentDomain(forName:"ShogiGirlsUITesting") }
            store = SaveStore(defaults:d)
            if ProcessInfo.processInfo.arguments.contains("--all-unlocked") { store.update { s in for c in Characters.all { var r = MatchRecord(); r.wins = 20; s.records[c.id] = r } } }
            ads.forceUnavailable = ProcessInfo.processInfo.arguments.contains("--ad-unavailable")
        }
        #endif
        NotificationCenter.default.addObserver(self,selector:#selector(background),name:UIApplication.willResignActiveNotification,object:nil)
        NotificationCenter.default.addObserver(self,selector:#selector(foreground),name:UIApplication.didBecomeActiveNotification,object:nil)
        timer = Timer.scheduledTimer(withTimeInterval:1,repeats:true) { [weak self] _ in Task { @MainActor in self?.updateEnergy() } }
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        guard !didStart else { return }; didStart = true
        showHome(); ads.start(from:self)
        if let message = store.recoveryMessage { alert("データの復元",message) }
    }
    override func viewDidLayoutSubviews() { super.viewDidLayoutSubviews(); if let b = boardView, let s = boardScene { b.updateAccessibility(scene:s) } }
    deinit { timer?.invalidate(); NotificationCenter.default.removeObserver(self) }
    private func setup(_ name: String) {
        page = name; view.subviews.forEach { $0.removeFromSuperview() }; boardView = nil; boardScene = nil; energyLabel = nil
        scroll = UIScrollView(); scroll.alwaysBounceVertical = true; scroll.showsVerticalScrollIndicator = false
        scroll.translatesAutoresizingMaskIntoConstraints = false; view.addSubview(scroll)
        content = Theme.stack(spacing:16); content.translatesAutoresizingMaskIntoConstraints = false; scroll.addSubview(content)
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo:view.safeAreaLayoutGuide.topAnchor),scroll.bottomAnchor.constraint(equalTo:view.safeAreaLayoutGuide.bottomAnchor),scroll.leadingAnchor.constraint(equalTo:view.leadingAnchor),scroll.trailingAnchor.constraint(equalTo:view.trailingAnchor),
            content.topAnchor.constraint(equalTo:scroll.contentLayoutGuide.topAnchor,constant:16),content.bottomAnchor.constraint(equalTo:scroll.contentLayoutGuide.bottomAnchor,constant:-24),content.centerXAnchor.constraint(equalTo:scroll.frameLayoutGuide.centerXAnchor),content.widthAnchor.constraint(equalToConstant:min(680,view.bounds.width-36))
        ])
    }
    private func heading(_ title: String, subtitle: String, back: (() -> Void)? = nil) {
        if let back { let row = Theme.stack([Theme.button("‹ 戻る",id:"back",action:back),UIView()],axis:.horizontal); content.addArrangedSubview(row) }
        content.addArrangedSubview(Theme.label(title,size:30,weight:.semibold))
        content.addArrangedSubview(Theme.label(subtitle,size:13,color:Theme.muted))
    }
    private func alert(_ title: String, _ text: String, actions: [(String, () -> Void)] = []) {
        let a = UIAlertController(title:title,message:text,preferredStyle:.alert)
        for (name,action) in actions { a.addAction(UIAlertAction(title:name,style:.default) { _ in action() }) }
        a.addAction(UIAlertAction(title:actions.isEmpty ? "閉じる" : "キャンセル",style:.cancel))
        if let existing = presentedViewController {
            existing.dismiss(animated:true) { [weak self] in self?.present(a,animated:true) }
        } else { present(a,animated:true) }
    }
    private func cancelSearch() { cancellation.cancel(); jobID = UUID(); thinking = false; thinkingForHint = false }
    @objc private func background() { suspended = true; cancelSearch(); if let m = match { store.saveMatch(m) } }
    @objc private func foreground() { suspended = false; updateEnergy(); if page == "battle" { renderBattle(); startAIIfNeeded() } }
    private func updateEnergy() { let seconds = store.recoverySeconds(); energyLabel?.text = "対局力  \(store.energy()) / 100\(seconds > 0 ? "  ·  +1まで \(seconds/60):\(String(format:"%02d",seconds%60))" : "  ·  満タン")" }
    private func showHome() {
        cancelSearch(); match = nil; setup("home")
        let eyebrow = Theme.label("SHOGI GIRLS  /  十人十色の一手",size:11,color:Theme.gold,weight:.semibold)
        content.addArrangedSubview(eyebrow)
        heading("将棋ガールズ",subtitle:"また会いたくなる、一局を。")
        let featured = Characters.find(store.state.lastCharacter)
        let portrait = Theme.portrait(featured); portrait.contentMode = .scaleAspectFit; portrait.heightAnchor.constraint(equalToConstant:160).isActive = true
        let intro = Theme.stack([Theme.label("今日も、あなたと。",size:21,weight:.semibold),Theme.label("指して、勝って、\n彼女の新しい表情に出会おう。",size:13,color:Theme.muted),Theme.label("\(featured.name)  /  \(featured.subtitle)",size:12,color:Theme.green)],spacing:12)
        let hero = Theme.stack([intro,portrait],axis:.horizontal,spacing:10); hero.distribution = .fillEqually
        content.addArrangedSubview(Theme.card(hero))
        energyLabel = Theme.label("",size:13,color:Theme.green,weight:.semibold); updateEnergy()
        content.addArrangedSubview(Theme.stack([energyLabel!,Theme.button("動画で +20",id:"energyReward") { [weak self] in self?.energyReward() }],axis:.horizontal))
        if let active = store.state.activeMatch {
            content.addArrangedSubview(Theme.button(active.result == nil ? "\(Characters.find(active.characterID).name)との対局を再開" : "前の対局結果を見る",id:"resume",primary:true) { [weak self] in self?.openMatch(active) })
        }
        content.addArrangedSubview(Theme.label("対戦相手",size:21,weight:.semibold))
        for row in 0..<5 {
            let cards = (0..<2).map { column -> UIView in
                let c = Characters.all[row*2+column], unlocked = store.unlocked(c.id), record = store.record(c.id)
                let image = Theme.portrait(c); image.heightAnchor.constraint(equalToConstant:view.bounds.width > 600 ? 240 : 135).isActive = true
                if !unlocked { image.alpha = 0.3 }
                let stack = Theme.stack([image,Theme.label("\(String(format:"%02d",c.ai.level))  \(c.name)",size:19,weight:.semibold),Theme.label("\(c.difficulty) · \(c.subtitle)",size:11,color:Theme.muted),Theme.label("\(record.wins)勝  \(record.losses)敗  \(record.draws)分",size:12,color:Theme.green)],spacing:7)
                stack.addArrangedSubview(Theme.button(unlocked ? "対局する" : "未解放",id:"character_\(c.id)",primary:unlocked) { [weak self] in
                    guard let self else { return }
                    if unlocked { self.showSetup(c) } else { self.alert("\(c.name)への挑戦", "\(Characters.all[c.ai.level-2].name)に1勝すると解放されるよ。") }
                })
                return Theme.card(stack,padding:10)
            }
            let rowStack = Theme.stack(cards,axis:.horizontal,spacing:12); rowStack.distribution = .fillEqually; content.addArrangedSubview(rowStack)
        }
        let nav = Theme.stack([Theme.button("コレクション",id:"gallery") { [weak self] in self?.showGallery() },Theme.button("設定・遊び方",id:"settings") { [weak self] in self?.showSettings() }],axis:.horizontal); nav.distribution = .fillEqually; content.addArrangedSubview(nav)
        content.addArrangedSubview(Theme.label("オフライン対局対応 · 進行状況は自動保存",size:11,color:Theme.muted))
    }
    private func showSetup(_ c: CharacterProfile) {
        setup("setup"); heading("\(c.name)と対局",subtitle:"\(c.age)歳  /  \(c.subtitle)",back:{ [weak self] in self?.showHome() })
        let image = Theme.portrait(c); image.heightAnchor.constraint(equalToConstant:220).isActive = true; content.addArrangedSubview(image)
        content.addArrangedSubview(Theme.card(Theme.label("「\(c.greeting)」",size:17)))
        content.addArrangedSubview(Theme.label("あなたの持ち駒側",size:15,weight:.semibold))
        let side = UISegmentedControl(items:["先手側（下手）","後手側"]); side.selectedSegmentIndex = store.state.settings.player.rawValue; side.accessibilityIdentifier = "side"
        content.addArrangedSubview(side)
        content.addArrangedSubview(Theme.label("ハンディキャップ",size:15,weight:.semibold))
        let handicap = UIButton(type:.system); handicap.accessibilityIdentifier = "handicap"; handicap.showsMenuAsPrimaryAction = true
        var selectedHandicap = store.state.settings.handicap
        func refreshHandicap() {
            var cfg = UIButton.Configuration.bordered(); cfg.title = "\(selectedHandicap.title)  ▾"; cfg.contentInsets = .init(top:14,leading:16,bottom:14,trailing:16); handicap.configuration = cfg
            handicap.menu = UIMenu(children:Handicap.allCases.map { h in UIAction(title:h.title,state:h == selectedHandicap ? .on : .off) { _ in selectedHandicap = h; refreshHandicap() } })
        }
        refreshHandicap(); content.addArrangedSubview(handicap)
        content.addArrangedSubview(Theme.label("駒落ちは相手の駒を減らし、相手から指し始めるよ。\nどの条件でも、勝つと画像と次の相手が解放される。\n時間制限なし。対局はいつでも中断・再開できるよ。",size:13,color:Theme.muted))
        content.addArrangedSubview(Theme.button("対局を始める  −20",id:"startMatch",primary:true) { [weak self] in
            guard let self else { return }
            if let active = self.store.state.activeMatch { self.alert("進行中の対局があるよ", "先に再開して決着をつけよう。",actions:[("再開する",{ self.openMatch(active) })]); return }
            let player = Side(rawValue:side.selectedSegmentIndex) ?? .black
            self.store.update { $0.settings.player = player; $0.settings.handicap = selectedHandicap }
            var m = Match(characterID:c.id,player:player,handicap:selectedHandicap)
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--mate-fixture") {
                var p = ShogiPosition(); p.board[76] = Piece(.king,.black); p.board[4] = Piece(.king,.white); p.board[3] = Piece(.lance,.white); p.board[5] = Piece(.lance,.white); p.board[12] = Piece(.pawn,.white); p.board[14] = Piece(.pawn,.white); p.board[22] = Piece(.pawn,.black); p.board[21] = Piece(.gold,.black)
                m = Match(characterID:c.id,player:.black,handicap:.even,initial:p)
            }
            let free = true
            #else
            let free = false
            #endif
            guard self.store.begin(m,free:free) else { self.alert("対局力が足りないよ", "3分で1回復するよ。動画を見ると20回復できる。",actions:[("動画で20回復",{ self.energyReward() })]); return }
            self.openMatch(m)
        })
        #if DEBUG
        content.addArrangedSubview(Theme.label("開発版：対局力を消費せず遊べます",size:11,color:Theme.muted))
        #endif
    }
    private func openMatch(_ m: Match) {
        cancelSearch(); match = m; selectedSquare = nil; selectedDrop = nil; hintMove = nil; portraitMood = "base"; dialog = Characters.find(m.characterID).greeting
        if m.result != nil { finishMatch() } else { renderBattle(); startAIIfNeeded() }
    }
    private func renderBattle() {
        guard let m = match else { return }
        let previousOffset = page == "battle" ? scroll?.contentOffset : nil
        setup("battle"); content.spacing = 8
        let c = Characters.find(m.characterID)
        let top = Theme.stack([Theme.label(c.name,size:23,weight:.semibold),Theme.label("\(m.handicap.title) · \(m.moves.count)手",size:12,color:Theme.muted),Theme.button("中断",id:"pause") { [weak self] in self?.pauseMatch() }],axis:.horizontal,spacing:8)
        content.addArrangedSubview(top)
        let image = Theme.portrait(c,imageName:"\(c.id)_\(portraitMood)"); image.widthAnchor.constraint(equalToConstant:90).isActive = true; image.heightAnchor.constraint(equalToConstant:90).isActive = true
        let speech = Theme.label("「\(dialog)」",size:14); speech.accessibilityIdentifier = "dialog"
        content.addArrangedSubview(Theme.stack([image,speech],axis:.horizontal,spacing:14))
        let thinkingText = thinkingForHint ? "おすすめの手を考えているよ…" : "\(c.name)が考えているよ…"
        let status = Theme.label(thinking ? thinkingText : m.position.turn == m.player ? "あなたの番  ·  駒を選んでね" : "相手の番",size:13,color:Theme.green,weight:.semibold)
        if m.position.inCheck(m.player) { status.text = "王手！ 玉を守る手を選んでね"; status.textColor = UIColor(hex:0xAD4949) }
        status.accessibilityIdentifier = "turnStatus"; content.addArrangedSubview(status)
        content.addArrangedSubview(handRow(side:m.player.opponent))
        legal = m.position.legalMoves()
        let board = AccessibleBoardView(); board.backgroundColor = .clear; board.allowsTransparency = true; board.ignoresSiblingOrder = true
        let boardSize = min(view.bounds.width-36, min(480,max(260,(view.bounds.height-view.safeAreaInsets.top-view.safeAreaInsets.bottom)*0.49)))
        board.translatesAutoresizingMaskIntoConstraints = false; board.heightAnchor.constraint(equalToConstant:boardSize).isActive = true; board.widthAnchor.constraint(equalToConstant:boardSize).isActive = true
        let wrap = UIView(); wrap.addSubview(board); wrap.heightAnchor.constraint(equalToConstant:boardSize).isActive = true
        board.centerXAnchor.constraint(equalTo:wrap.centerXAnchor).isActive = true; board.topAnchor.constraint(equalTo:wrap.topAnchor).isActive = true
        let scene = BoardScene(size:CGSize(width:boardSize,height:boardSize)); scene.scaleMode = .resizeFill; scene.boardPosition = m.position; scene.player = m.player; scene.selected = selectedSquare; scene.lastMove = m.moves.last; scene.hintMove = hintMove
        if store.state.settings.legalGuides { scene.destinations = Set(selectedMoves().map { $0.to }) }
        scene.onSquare = { [weak self] i in self?.tapSquare(i) }; board.presentScene(scene); boardView = board; boardScene = scene
        content.addArrangedSubview(wrap); content.addArrangedSubview(handRow(side:m.player))
        let hint = Theme.button("ヒント \(store.freeHints())",id:"hint") { [weak self] in self?.requestHint() }; hint.isEnabled = !thinking && m.position.turn == m.player
        let undo = Theme.button(m.undoUsed ? "待った済" : "待った",id:"undo") { [weak self] in self?.requestUndo() }; undo.isEnabled = !thinking && m.position.turn == m.player && m.canUndo
        let resign = Theme.button("投了",id:"resign") { [weak self] in self?.confirmResign() }
        let buttons = Theme.stack([hint,undo,resign],axis:.horizontal,spacing:6); buttons.distribution = .fillEqually; content.addArrangedSubview(buttons)
        if m.position.canDeclareWin(m.player,handicap:m.handicap,player:m.player) {
            content.addArrangedSubview(Theme.button("入玉を宣言する",id:"declare",primary:true) { [weak self] in if self?.match?.declareWin() == true { self?.finishMatch() } })
        }
        let last = m.moves.last.flatMap { move in m.positions.dropLast().last.map { move.notation(in:$0) } } ?? "対局開始"
        content.addArrangedSubview(Theme.label("\(last)  ·  自動保存中",size:11,color:Theme.muted))
        if let previousOffset {
            view.layoutIfNeeded()
            let maximumY = max(0,scroll.contentSize.height-scroll.bounds.height)
            scroll.setContentOffset(CGPoint(x:0,y:min(maximumY,max(0,previousOffset.y))),animated:false)
        }
    }
    private func handRow(side: Side) -> UIView {
        guard let m = match else { return UIView() }
        let row = Theme.stack(axis:.horizontal,spacing:3); row.distribution = .fillEqually
        for kind in PieceKind.handKinds {
            let count = m.position.hands[side.rawValue][kind.rawValue]
            let button = UIButton(type:.system); button.setTitle("\(kind.text)\(count)",for:.normal); button.titleLabel?.font = .systemFont(ofSize:14,weight:.medium)
            button.setTitleColor(count > 0 ? Theme.ink : Theme.muted.withAlphaComponent(0.45),for:.normal)
            button.backgroundColor = side == m.player && selectedDrop == kind ? UIColor(hex:0xBDCFB5) : UIColor(hex:0xEDE7D9); button.layer.cornerRadius = 7
            button.heightAnchor.constraint(equalToConstant:38).isActive = true; button.accessibilityIdentifier = "hand_\(side.rawValue)_\(kind.rawValue)"
            button.accessibilityLabel = "\(side == m.player ? "自分" : "相手")の持ち駒、\(kind.text)\(count)枚"
            button.isEnabled = side == m.player && count > 0 && m.position.turn == m.player && !thinking
            button.addAction(UIAction { [weak self] _ in self?.selectedDrop = kind; self?.selectedSquare = nil; self?.hintMove = nil; self?.refreshSelection() },for:.touchUpInside); row.addArrangedSubview(button)
        }
        return row
    }
    private func selectedMoves() -> [ShogiMove] { legal.filter { selectedDrop != nil ? $0.drop == selectedDrop : selectedSquare != nil && $0.from == selectedSquare } }
    private func refreshSelection() { renderBattle() }
    private func tapSquare(_ i: Int) {
        guard let m = match, !thinking, !suspended, m.result == nil, m.position.turn == m.player else { return }
        if m.position.board[i]?.side == m.player { selectedSquare = i; selectedDrop = nil; hintMove = nil; refreshSelection(); return }
        let choices = selectedMoves().filter { $0.to == i }
        if choices.count == 2 {
            alert("成りますか？","成ると駒の動きが変わるよ。",actions:choices.sorted { $0.promote && !$1.promote }.map { move in (move.promote ? "成る" : "成らない", { [weak self] in self?.play(move) }) })
        } else if let move = choices.first { play(move) }
    }
    private func play(_ move: ShogiMove) {
        guard let before = match?.position, match?.play(move) == true, let m = match else { return }
        selectedSquare = nil; selectedDrop = nil; hintMove = nil
        if store.state.settings.haptics { UIImpactFeedbackGenerator(style:.light).impactOccurred() }
        if store.state.settings.sound { AudioServicesPlaySystemSound(1104) }
        let c = Characters.find(m.characterID)
        if m.position.inCheck(m.player.opponent) { dialog = c.line(for:"check"); portraitMood = "worry" }
        else if move.promote { dialog = c.line(for:"promote") }
        else if before.board[move.to] != nil { portraitMood = before.turn == m.player ? "worry" : "happy"; if before.turn != m.player { dialog = c.line(for:"capture") } }
        store.saveMatch(m)
        if m.result != nil { finishMatch() } else { renderBattle(); startAIIfNeeded() }
    }
    private func startAIIfNeeded() {
        guard let m = match, page == "battle", !thinking, !suspended, m.result == nil, m.position.turn != m.player else { return }
        if match?.declareWin() == true { finishMatch(); return }
        thinkingForHint = false; thinking = true; renderBattle()
        cancellation = SearchCancellation(); let token = cancellation; let id = UUID(); jobID = id
        let profile = Characters.find(m.characterID).ai
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let result = ShogiAI(profile:profile).search(m.position,cancellation:token)
            DispatchQueue.main.async {
                guard let self, self.jobID == id, !token.cancelled, self.page == "battle" else { return }
                self.thinking = false; self.thinkingForHint = false
                let c = Characters.find(m.characterID); self.dialog = c.line(for:result.score > 250 ? "lead" : result.score < -250 ? "behind" : "normal")
                self.portraitMood = result.score > 250 ? "happy" : result.score < -250 ? "worry" : "base"
                if let move = result.move { self.play(move) }
                else { let result = self.match?.adjudicate(); self.match?.result = result; self.finishMatch() }
            }
        }
    }
    private func pauseMatch() { cancelSearch(); if let m = match { store.saveMatch(m) }; showHome() }
    private func confirmResign() {
        alert("投了する？","この対局は負けとして記録されるよ。",actions:[("投了する",{ [weak self] in guard let self, let m = self.match else { return }; self.cancelSearch(); self.match?.resign(m.player); self.finishMatch() })])
    }
    private func requestHint() {
        if store.freeHints() > 0 { runHint(free:true) }
        else { alert("ヒントを追加", "動画を最後まで見ると、この局面のおすすめの一手が見られるよ。", actions:[("動画を見る",{ [weak self] in guard let self else { return }; self.ads.reward(from:self) { [weak self] ok in if ok { self?.runHint(free:false) } else { self?.adUnavailable() } } })]) }
    }
    private func runHint(free: Bool) {
        guard let m = match, !thinking, m.position.turn == m.player, m.result == nil else { return }
        thinkingForHint = true; thinking = true; renderBattle(); cancellation = SearchCancellation(); let token = cancellation; let id = UUID(); jobID = id
        DispatchQueue.global(qos:.userInitiated).async { [weak self] in
            let r = ShogiAI(profile:.init(level:10,style:.balanced)).search(m.position,timeLimit:1,cancellation:token)
            DispatchQueue.main.async {
                guard let self, self.jobID == id, !token.cancelled else { return }; self.thinking = false; self.thinkingForHint = false
                if let move = r.move { if free { _ = self.store.useFreeHint() }; self.hintMove = move; self.dialog = "おすすめは \(move.notation(in:m.position))。青い枠を見てね。" }
                self.renderBattle()
            }
        }
    }
    private func requestUndo() {
        alert("一手戻す？", "動画を最後まで見ると、直前の自分の手まで戻せるよ。1対局につき1回。",actions:[("動画を見る",{ [weak self] in
            guard let self else { return }; self.ads.reward(from:self) { [weak self] ok in
                guard let self else { return }; if ok, self.match?.undo() == true, let m = self.match { self.store.saveMatch(m); self.selectedSquare = nil; self.selectedDrop = nil; self.hintMove = nil; self.dialog = "もう一度、ゆっくり考えてみてね。"; self.renderBattle() } else if !ok { self.adUnavailable() }
            }
        })])
    }
    private func energyReward() {
        guard store.energy() < 100 else { alert("対局力は満タンだよ","そのまま対局を始めよう。"); return }
        ads.reward(from:self) { [weak self] ok in if ok { self?.store.rewardEnergy(); self?.updateEnergy() } else { self?.adUnavailable() } }
    }
    private func adUnavailable() { alert("動画を読み込めなかったよ", "通信状態を確認して、少し時間をおいて試してね。報酬や利用回数は変更していないよ。") }
    private func finishMatch() {
        guard let m = match, let result = m.result else { return }; cancelSearch(); newRewards = store.finish(m); setup("result")
        let c = Characters.find(m.characterID), won = result.winner == m.player
        heading(result.winner == nil ? "引き分け" : won ? "あなたの勝ち！" : "また、挑戦しよう",subtitle:"\(c.name)との一局  /  \(result.reason.title)")
        let image = Theme.portrait(c,imageName:"\(c.id)_\(result.winner == nil ? "base" : won ? "worry" : "happy")"); image.heightAnchor.constraint(equalToConstant:250).isActive = true; content.addArrangedSubview(image)
        content.addArrangedSubview(Theme.card(Theme.label("「\(c.line(for:result.winner == nil ? "draw" : won ? "lose" : "win"))」",size:18)))
        let record = store.record(c.id)
        content.addArrangedSubview(Theme.label("\(record.wins)勝  ·  \(record.losses)敗  ·  \(record.draws)分  /  勝率\(record.winRate)%",size:17,weight:.semibold))
        for reward in newRewards {
            let unlock = Theme.card(Theme.stack([Theme.label("NEW MEMORY",size:11,color:Theme.gold,weight:.bold),Theme.label("\(reward.title)を解放！",size:20,weight:.semibold)])); unlock.accessibilityIdentifier = "rewardUnlocked"; content.addArrangedSubview(unlock)
            unlock.alpha = 0; UIView.animate(withDuration:0.5,delay:0.15,options:[]) { unlock.alpha = 1 }
        }
        if won && record.wins == 1 && c.ai.level < 10 { content.addArrangedSubview(Theme.label("次の相手・\(Characters.all[c.ai.level].name)に挑戦できるようになったよ。",size:15,color:Theme.green)) }
        content.addArrangedSubview(Theme.button("もう一局",id:"retry",primary:true) { [weak self] in self?.store.dismissResult(); self?.match = nil; self?.showSetup(c) })
        content.addArrangedSubview(Theme.button("コレクションを見る",id:"resultGallery") { [weak self] in self?.store.dismissResult(); self?.match = nil; self?.showGallery(character:c) })
        content.addArrangedSubview(Theme.button("ホームへ",id:"resultHome") { [weak self] in self?.store.dismissResult(); self?.showHome() })
        ads.resultShown(id:m.id,from:self)
    }
    private func showGallery(character: CharacterProfile? = nil) {
        setup("gallery"); heading("コレクション",subtitle:"勝つたびに増える、ふたりの思い出。",back:{ [weak self] in self?.showHome() })
        if let c = character {
            let r = store.record(c.id); content.addArrangedSubview(Theme.label("\(c.name)  ·  \(r.wins)勝  /  解放 \(GalleryReward.all(for:c.id).filter { store.unlocked($0) }.count)/5",size:20,weight:.semibold))
            for reward in GalleryReward.all(for:c.id) {
                let unlocked = store.unlocked(reward), available = UIImage(named:reward.id) != nil
                let image = Theme.portrait(c,imageName:available ? reward.id : c.imageName); image.heightAnchor.constraint(equalToConstant:220).isActive = true
                if !unlocked { image.image = image.image?.withRenderingMode(.alwaysTemplate); image.tintColor = UIColor(hex:0x313B35); image.alpha = 0.35 }
                let title = Theme.label(reward.title,size:18,weight:.semibold)
                let caption = Theme.label(unlocked ? "\(reward.requiredWins)勝の記念\(available ? "" : " · イラスト準備中")" : "あと\(max(0,reward.requiredWins-r.wins))勝で解放",size:13,color:Theme.muted)
                let parts = Theme.stack([image,title,caption])
                if unlocked { parts.addArrangedSubview(Theme.button("大きく見る",id:"reward_\(reward.index)") { [weak self] in self?.showArtwork(c,reward) }) }
                content.addArrangedSubview(Theme.card(parts))
            }
        } else {
            let total = Characters.all.reduce(0) { $0 + GalleryReward.all(for:$1.id).filter { store.unlocked($0) }.count }
            content.addArrangedSubview(Theme.label("\(total) / 50  MEMORIES",size:14,color:Theme.gold,weight:.semibold))
            for c in Characters.all { content.addArrangedSubview(Theme.button("\(c.name)  ·  \(store.record(c.id).wins)勝",id:"gallery_\(c.id)") { [weak self] in self?.showGallery(character:c) }) }
        }
    }
    private func showArtwork(_ c: CharacterProfile, _ reward: GalleryReward) {
        guard store.unlocked(reward) else { return }
        setup("artwork"); heading(reward.title,subtitle:"\(c.name) / \(reward.requiredWins)勝の思い出",back:{ [weak self] in self?.showGallery(character:c) })
        let image = Theme.portrait(c,imageName:UIImage(named:reward.id) != nil ? reward.id : c.imageName,cropFace:false); image.contentMode = .scaleAspectFit; image.heightAnchor.constraint(equalToConstant:view.bounds.height*0.68).isActive = true; content.addArrangedSubview(image)
        if UIImage(named:reward.id) == nil { content.addArrangedSubview(Theme.label("イラスト準備中：現在は基本衣装を表示しています",size:12,color:Theme.muted)) }
    }
    private func showSettings() {
        setup("settings"); heading("設定・遊び方",subtitle:"自分のペースで、気持ちよく。",back:{ [weak self] in self?.showHome() })
        for (title,key) in [("駒音",0),("移動できるマスを表示",1),("触覚フィードバック",2)] {
            let toggle = UISwitch(); toggle.isOn = key == 0 ? store.state.settings.sound : key == 1 ? store.state.settings.legalGuides : store.state.settings.haptics
            toggle.addAction(UIAction { [weak self,weak toggle] _ in self?.store.update { s in let on = toggle?.isOn ?? false; if key == 0 { s.settings.sound = on } else if key == 1 { s.settings.legalGuides = on } else { s.settings.haptics = on } } },for:.valueChanged)
            content.addArrangedSubview(Theme.card(Theme.stack([Theme.label(title),toggle],axis:.horizontal)))
        }
        content.addArrangedSubview(Theme.button("プライバシーポリシー",id:"privacyPolicy") {
            guard let url = URL(string:"https://takeoishida.github.io/clickgirl-site/shogi-girls/") else { return }
            UIApplication.shared.open(url)
        })
        if ads.privacyRequired { content.addArrangedSubview(Theme.button("広告のプライバシー設定") { [weak self] in guard let self else { return }; self.ads.privacy(from:self) { self.showSettings() } }) }
        content.addArrangedSubview(Theme.card(Theme.label("駒をタップして、行き先をタップ。持ち駒も同じ操作で打てるよ。敵陣に入ると『成る』を選べる駒がある。\n\n王手は必ず防ごう。逃げ道がなくなったら詰みで決着。二歩や王手放置などの反則手は選べないよ。\n\nヒントは1日3回無料。その後は動画で追加できる。『待った』は動画を見て1対局1回まで。\n\n1・3・5・10・20勝で画像を解放。駒落ちの勝利も数えるので、自分に合った強さで楽しんでね。\n\n千日手は引き分け。連続王手の千日手は王手側の負け。入玉宣言は玉が敵陣・王手なし・敵陣の駒10枚以上・先手28点／後手27点以上で使用可能（大駒5点、小駒1点、敵陣と持ち駒を計算）。駒落ちは相手に落とした駒の点数を加算。500手で引き分け。\n\n対局力は最大100、1対局20消費。3分で1回復。中断した対局の再開では消費しないよ。",size:14)))
        content.addArrangedSubview(Theme.label("プライバシー\n戦績・対局・設定はこの端末内に保存します。ゲーム機能はアカウント登録不要です。広告を利用する場合、広告配信事業者のSDKが通信します。アプリ削除で端末内データは失われます。",size:12,color:Theme.muted))
        content.addArrangedSubview(Theme.label("将棋ガールズ 1.0  ·  AIの段級位を保証するものではありません",size:11,color:Theme.muted))
    }
}
