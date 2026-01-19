import UIKit

/// 自定义景点标记视图（基于 UI/UX 指南 5.2）
/// 注意：实际使用时需要继承 MAAnnotationView
class AttractionAnnotationView: UIView {
    
    let indexLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    var index: Int = 0 {
        didSet {
            indexLabel.text = "\(index)"
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    convenience init(index: Int) {
        self.init(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        self.index = index
        indexLabel.text = "\(index)"
    }
    
    private func setupUI() {
        let size: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        // 渐变背景（天空蓝渐变）
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = size / 2
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 序号标签
        indexLabel.frame = bounds
        indexLabel.textAlignment = .center
        indexLabel.font = .systemFont(ofSize: 18, weight: .bold)
        indexLabel.textColor = .white
        addSubview(indexLabel)
        
        // 阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
        
        // 圆角
        layer.cornerRadius = size / 2
        clipsToBounds = false
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}

// MARK: - 实际 MAAnnotationView 实现
/*
import MAMapKit

class AttractionMAAnnotationView: MAAnnotationView {
    
    let indexLabel = UILabel()
    private let gradientLayer = CAGradientLayer()
    
    override init(annotation: MAAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func setupUI() {
        let size: CGFloat = 40
        frame = CGRect(x: 0, y: 0, width: size, height: size)
        
        // 渐变背景（天空蓝渐变）
        gradientLayer.frame = bounds
        gradientLayer.colors = [
            UIColor(hex: "06B6D4").cgColor,
            UIColor(hex: "0EA5E9").cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = size / 2
        layer.insertSublayer(gradientLayer, at: 0)
        
        // 序号标签
        indexLabel.frame = bounds
        indexLabel.textAlignment = .center
        indexLabel.font = .systemFont(ofSize: 18, weight: .bold)
        indexLabel.textColor = .white
        addSubview(indexLabel)
        
        // 阴影
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.2
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowRadius = 4
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    func configure(with index: Int) {
        indexLabel.text = "\(index)"
    }
}
*/
