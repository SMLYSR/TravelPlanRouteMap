import SwiftUI

/// 可滑动删除的卡片组件
struct SwipeableCard<Content: View>: View {
    let content: Content
    let onDelete: () -> Void
    let onTap: (() -> Void)?
    
    @State private var offset: CGFloat = 0
    @State private var isSwiping = false
    
    private let deleteButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = 60
    
    init(onDelete: @escaping () -> Void, onTap: (() -> Void)? = nil, @ViewBuilder content: () -> Content) {
        self.onDelete = onDelete
        self.onTap = onTap
        self.content = content()
    }
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // 删除按钮背景层（固定在右侧）
            deleteButton
            
            // 卡片内容层（可滑动）
            content
                .contentShape(Rectangle()) // 确保整个区域可以接收手势
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { gesture in
                            isSwiping = true
                            // 只允许向左滑动
                            if gesture.translation.width < 0 {
                                offset = max(gesture.translation.width, -deleteButtonWidth)
                            } else if offset < 0 {
                                // 如果已经打开，允许向右滑动关闭
                                offset = min(0, offset + gesture.translation.width)
                            }
                        }
                        .onEnded { gesture in
                            withAnimation(.easeOut(duration: 0.25)) {
                                if offset < -swipeThreshold {
                                    // 滑动超过阈值，显示删除按钮
                                    offset = -deleteButtonWidth
                                } else {
                                    // 未超过阈值，回弹
                                    offset = 0
                                }
                            }
                            
                            // 延迟重置 isSwiping，避免触发点击
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                isSwiping = false
                            }
                        }
                )
                .onTapGesture {
                    // 如果正在滑动，不触发点击
                    if !isSwiping {
                        if offset < 0 {
                            // 如果删除按钮已展开，点击关闭
                            withAnimation(.easeOut(duration: 0.25)) {
                                offset = 0
                            }
                        } else {
                            // 否则触发点击回调
                            onTap?()
                        }
                    }
                }
        }
        .clipped() // 裁剪超出边界的内容
    }
    
    private var deleteButton: some View {
        HStack {
            Spacer()
            Button(action: {
                print("🗑️ 删除按钮被点击")
                HapticFeedback.light()
                // 直接执行删除
                onDelete()
            }) {
                VStack(spacing: 4) {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 16, weight: .semibold))
                    Text("删除")
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundColor(.white)
                .frame(width: deleteButtonWidth)
                .frame(maxHeight: .infinity)
                .background(Color.red)
                .cornerRadius(12, corners: [.topRight, .bottomRight]) // 只有右侧圆角
            }
            .buttonStyle(PlainButtonStyle())
            .frame(width: deleteButtonWidth)
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        SwipeableCard(
            onDelete: {
                print("删除")
            },
            onTap: {
                print("点击")
            }
        ) {
            VStack(alignment: .leading, spacing: 8) {
                Text("成都旅行计划")
                    .font(.headline)
                Text("2024-01-15")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color.white)
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        }
        .padding(.horizontal, 16)
    }
    .background(Color.gray.opacity(0.1))
}
