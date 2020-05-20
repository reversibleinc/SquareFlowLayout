//
//  SquareFlowLayout.swift
//
//  Created by Taras Chernyshenko on 11/11/18.
//  Copyright © 2018 Taras Chernyshenko. All rights reserved.
//

import UIKit

public protocol SquareFlowLayoutDelegate: class {
    func shouldExpandItem(at indexPath: IndexPath) -> Bool
}

public class SquareFlowLayout: UICollectionViewFlowLayout {
    public enum ExpandedPosition {
        case start
        case middle
        case end
        case none

        /// Calculate the expanded position of a layout chunk.
        /// eg. [true, false, false] -> .start,  [false, false, false] -> .none
        /// - Parameter layoutChunk: An array with boolean values, which represent if the cell should be expanded.
        public static func of(layoutChunk: [Bool]) -> ExpandedPosition {
            if layoutChunk.count > 0 && layoutChunk[0] {
                return .start
            } else if layoutChunk.count > 1 && layoutChunk[1] {
                return .middle
            } else if layoutChunk.count > 2 && layoutChunk[2] {
                return .end
            }
            return .none
        }
    }

    private var cache: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var contentHeight: CGFloat = 0
    @IBInspectable public var interSpacing: CGFloat = 1
    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else {
            return 0
        }
        let insets = collectionView.contentInset
        return collectionView.bounds.width - (insets.left + insets.right)
    }

    private var contentInsets: UIEdgeInsets {
        return collectionView?.contentInset ?? UIEdgeInsets.zero
    }

    public weak var flowDelegate: SquareFlowLayoutDelegate?

    public override var collectionViewContentSize: CGSize {
        return CGSize(width: contentWidth, height: contentHeight)
    }

    public override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        var layoutAttributesArray = [UICollectionViewLayoutAttributes]()
        if cache.isEmpty {
            prepare()
        }
        for (_, layoutAttributes) in cache {
            if rect.intersects(layoutAttributes.frame) {
                layoutAttributesArray.append(layoutAttributes)
            }
        }
        return layoutAttributesArray
    }

    public override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return cache[indexPath]
    }

    public override func prepare() {
        guard let collectionView = self.collectionView, collectionView.numberOfSections > 0 else {
            return
        }

        cache.removeAll()

        let numberOfColumns = 3
        contentHeight = 0
        let itemWidth = (contentWidth - CGFloat(numberOfColumns - 1) * interSpacing) / CGFloat(numberOfColumns)
        let itemHeight = itemWidth

        let expandedWidth = itemWidth * 2 + interSpacing
        let expandedHeight = expandedWidth

        var xOffset: CGFloat = 0
        var yOffset: CGFloat = 0

        var index = 0
        var layoutValues: [Bool] = []
        for item in 0 ..< collectionView.numberOfItems(inSection: 0) {
            layoutValues.append(flowDelegate?.shouldExpandItem(at: IndexPath(row: item, section: 0)) == true)
        }
        let chunkSize = 3
        let layouts = stride(from: 0, to: layoutValues.count, by: chunkSize).map {
            Array(layoutValues[$0 ..< Swift.min($0 + chunkSize, layoutValues.count)])
        }

        func add(rect: CGRect, at idx: Int, in layout: [Bool]) {
            if idx < layout.count {
                let indexPath = IndexPath(row: index, section: 0)
                let targetLayoutAttributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                targetLayoutAttributes.frame = rect
                contentHeight = max(rect.maxY, contentHeight)
                cache[indexPath] = targetLayoutAttributes
                index = index + 1
            }
        }

        for layout in layouts {
            let expandedPosition = ExpandedPosition.of(layoutChunk: layout)
            switch expandedPosition {
            case .start:
                add(rect: CGRect(x: 0, y: yOffset, width: expandedWidth, height: expandedHeight), at: 0, in: layout)
                add(rect: CGRect(x: expandedWidth + interSpacing, y: yOffset, width: itemWidth, height: itemHeight), at: 1, in: layout)
                add(rect: CGRect(x: expandedWidth + interSpacing, y: yOffset + itemHeight + interSpacing, width: itemWidth, height: itemHeight), at: 2, in: layout)
            case .middle:
                add(rect: CGRect(x: 0, y: yOffset, width: itemWidth, height: itemHeight), at: 0, in: layout)
                add(rect: CGRect(x: itemWidth + interSpacing, y: yOffset, width: expandedWidth, height: expandedHeight), at: 1, in: layout)
                add(rect: CGRect(x: 0, y: yOffset + itemHeight + interSpacing, width: itemWidth, height: itemHeight), at: 2, in: layout)
            case .end:
                add(rect: CGRect(x: 0, y: yOffset, width: itemWidth, height: itemHeight), at: 0, in: layout)
                add(rect: CGRect(x: 0, y: yOffset + itemHeight + interSpacing, width: itemWidth, height: itemHeight), at: 1, in: layout)
                add(rect: CGRect(x: itemWidth + interSpacing, y: yOffset, width: expandedWidth, height: expandedHeight), at: 2, in: layout)
            case .none:
                for i in 0 ..< layout.count {
                    add(rect: CGRect(x: xOffset, y: yOffset, width: itemWidth, height: itemHeight), at: i, in: layout)
                    xOffset = xOffset + itemWidth + interSpacing
                }
            }
            xOffset = 0
            yOffset = yOffset + (expandedPosition == .none ? itemHeight : expandedHeight) + interSpacing
        }
    }
}
