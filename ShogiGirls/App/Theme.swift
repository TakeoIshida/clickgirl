import UIKit

extension UIColor {
    convenience init(hex: UInt32) { self.init(red:CGFloat((hex >> 16)&255)/255,green:CGFloat((hex >> 8)&255)/255,blue:CGFloat(hex&255)/255,alpha:1) }
}
enum Theme {
    static let paper = UIColor(hex:0xF7F3EB), ink = UIColor(hex:0x303B37), muted = UIColor(hex:0x7B8277), green = UIColor(hex:0x496957), gold = UIColor(hex:0xBA965B)
    static func label(_ text: String, size: CGFloat = 15, color: UIColor = ink, weight: UIFont.Weight = .regular) -> UILabel {
        let v = UILabel(); v.text = text; v.font = .systemFont(ofSize:size,weight:weight); v.textColor = color; v.numberOfLines = 0; return v
    }
    static func stack(_ views: [UIView] = [], axis: NSLayoutConstraint.Axis = .vertical, spacing: CGFloat = 12) -> UIStackView {
        let v = UIStackView(arrangedSubviews:views); v.axis = axis; v.spacing = spacing; return v
    }
    static func button(_ title: String, id: String? = nil, primary: Bool = false, action: @escaping () -> Void) -> UIButton {
        let b = UIButton(type:.system)
        var config = UIButton.Configuration.filled(); config.title = title; config.baseBackgroundColor = primary ? green : UIColor(hex:0xEAE9DF); config.baseForegroundColor = primary ? .white : ink
        config.cornerStyle = .medium; config.contentInsets = NSDirectionalEdgeInsets(top:12,leading:13,bottom:12,trailing:13)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { a in var b=a; b.font = UIFont.systemFont(ofSize:14,weight:.semibold); return b }
        b.configuration = config; b.accessibilityIdentifier = id; b.addAction(UIAction { _ in action() },for:.touchUpInside)
        b.heightAnchor.constraint(greaterThanOrEqualToConstant:44).isActive = true
        return b
    }
    static func portrait(_ character: CharacterProfile, imageName: String? = nil, cropFace: Bool = true) -> UIImageView {
        var image = UIImage(named:imageName ?? character.imageName) ?? UIImage(named:character.imageName)
        // Face-focused display crop only; full original remains available in the gallery.
        if cropFace, let cg = image?.cgImage, cg.height > cg.width * 14 / 10,
           let top = cg.cropping(to:CGRect(x:0,y:0,width:cg.width,height:cg.width)) { image = UIImage(cgImage:top) }
        let v = UIImageView(image:image); v.contentMode = .scaleAspectFill; v.clipsToBounds = true; v.backgroundColor = UIColor(hex:character.colorHex).withAlphaComponent(0.25); v.layer.cornerRadius = 18; v.accessibilityLabel = "\(character.name)のイラスト"; return v
    }
    static func card(_ content: UIView, padding: CGFloat = 16) -> UIView {
        let v = UIView(); v.backgroundColor = .white; v.layer.cornerRadius = 20; v.layer.borderColor = UIColor(hex:0xE7E5DA).cgColor; v.layer.borderWidth = 1
        v.addSubview(content); content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([content.topAnchor.constraint(equalTo:v.topAnchor,constant:padding),content.bottomAnchor.constraint(equalTo:v.bottomAnchor,constant:-padding),content.leadingAnchor.constraint(equalTo:v.leadingAnchor,constant:padding),content.trailingAnchor.constraint(equalTo:v.trailingAnchor,constant:-padding)])
        return v
    }
}
