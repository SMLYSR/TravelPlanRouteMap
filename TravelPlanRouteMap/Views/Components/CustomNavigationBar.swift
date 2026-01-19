import SwiftUI

/// 自定义导航栏组件
struct CustomNavigationBar: View {
    let title: String
    var showBackButton: Bool = true
    var onBack: (() -> Void)? = nil
    var trailingContent: AnyView? = nil
    
    var body: some View {
        HStack {
            if showBackButton {
                Button(action: {
                    HapticFeedback.light()
                    onBack?()
                }) {
                    Image(systemName: "chevron.left")
                        .font(.title3.weight(.semibold))
                        .foregroundColor(AppColors.primary)
                        .frame(width: 44, height: 44)
                }
            } else {
                Spacer()
                    .frame(width: 44)
            }
            
            Spacer()
            
            Text(title)
                .font(.headline)
                .foregroundColor(AppColors.text)
            
            Spacer()
            
            if let trailing = trailingContent {
                trailing
                    .frame(width: 44, height: 44)
            } else {
                Spacer()
                    .frame(width: 44)
            }
        }
        .padding(.horizontal, Spacing.md)
        .padding(.vertical, Spacing.sm)
        .background(Color.white.opacity(0.95))
    }
}

#Preview {
    VStack {
        CustomNavigationBar(
            title: "选择目的地",
            showBackButton: true,
            onBack: {}
        )
        
        CustomNavigationBar(
            title: "首页",
            showBackButton: false
        )
        
        Spacer()
    }
    .background(AppColors.background)
}
