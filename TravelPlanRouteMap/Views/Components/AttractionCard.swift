import SwiftUI

/// 景点卡片组件
struct AttractionCard: View {
    let attraction: Attraction
    let index: Int
    var onDelete: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: Spacing.md) {
            // 序号标记
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [AppColors.primary, AppColors.secondary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)
                
                Text("\(index)")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: Spacing.xs) {
                Text(attraction.name)
                    .font(.body.weight(.semibold))
                    .foregroundColor(AppColors.text)
                
                if let address = attraction.address {
                    Text(address)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let onDelete = onDelete {
                Button(action: {
                    HapticFeedback.light()
                    onDelete()
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundColor(.secondary)
                        .font(.title3)
                }
            } else {
                Image(systemName: "chevron.right")
                    .foregroundColor(.secondary)
            }
        }
        .padding(Spacing.md)
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
}

#Preview {
    VStack(spacing: 16) {
        AttractionCard(
            attraction: Attraction(
                name: "故宫博物院",
                coordinate: Coordinate(latitude: 39.9163, longitude: 116.3972),
                address: "北京市东城区景山前街4号"
            ),
            index: 1
        )
        
        AttractionCard(
            attraction: Attraction(
                name: "天安门广场",
                coordinate: Coordinate(latitude: 39.9087, longitude: 116.3975),
                address: "北京市东城区"
            ),
            index: 2,
            onDelete: {}
        )
    }
    .padding()
    .background(AppColors.background)
}
