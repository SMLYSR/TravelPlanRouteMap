import SwiftUI

/// 自定义输入框组件
struct CustomTextField: View {
    @Binding var text: String
    let placeholder: String
    let icon: String
    var onSubmit: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.sm) {
            Image(systemName: icon)
                .foregroundColor(AppColors.primary)
                .frame(width: 24, height: 24)
            
            TextField(placeholder, text: $text)
                .font(.body)
                .onSubmit {
                    onSubmit?()
                }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(AppColors.border, lineWidth: 1)
        )
    }
}

#Preview {
    VStack(spacing: 20) {
        CustomTextField(
            text: .constant(""),
            placeholder: "请输入目的地",
            icon: "mappin.circle.fill"
        )
        
        CustomTextField(
            text: .constant("北京"),
            placeholder: "请输入景点名称",
            icon: "star.fill"
        )
    }
    .padding()
    .background(AppColors.background)
}
