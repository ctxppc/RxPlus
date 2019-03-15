// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import RxSwift

/// A reactive collection
public final class ReactiveFlattenCollection<Collections> where Collections : ReactiveCollection, Collections.Element : Collection {
	
	/// Creates a reactive collection concatenating given collections.
	public init(concatenating collections: Collections) {
		self.collections = collections
	}
	
	/// The collections whose elements are concenated to form the elements of `self`.
	public let collections: Collections
	
}

extension ReactiveFlattenCollection : Collection {
	
	public typealias Element = Collections.Element.Element
	
	public enum Index : Comparable {
		
		/// An index pointing to an element.
		///
		/// - Parameter sourceIndex: The index of the source. It must be a valid index to an element in the `sources` property.
		/// - Parameter innerIndex: The index to an element _within_ the source at `sourceIndex`. It must be a valid index to an element in the source.
		case element(sourceIndex: Collections.Index, innerIndex: AnyIndex)
		
		/// The index pointing after the last element.
		case end
		
		public static func < (precedingIndex: Index, followingIndex: Index) -> Bool {
			switch (precedingIndex, followingIndex) {
				
				case let (.element(sourceIndex: s1, innerIndex: i1), .element(sourceIndex: s2, innerIndex: i2)):
				return (s1, i1) < (s2, i2)
				
				case (.element, .end):	return true
				case (.end, _):			return false
				
			}
		}
		
	}
	
	public var startIndex: Index {
		guard let sourceIndex = collections.indices.first, let innerIndex = collections[sourceIndex].indices.first else { return .end }
		return .element(sourceIndex: sourceIndex, innerIndex: .init(innerIndex))
	}
	
	public var endIndex: Index {
		return .end
	}
	
	public subscript (index: Index) -> Element {
		guard case .element(sourceIndex: let sourceIndex, innerIndex: let innerIndex) = index else { fatalError("Index out of bounds") }
		return collections[sourceIndex][innerIndex]
	}
	
	public func index(after index: Index) -> Index {
		
		guard case .element(sourceIndex: let sourceIndex, innerIndex: let innerIndex) = index else { fatalError("Index out of bounds") }
		
		let source = collections[sourceIndex]
		let nextInnerIndex = source.index(after: innerIndex)
		if nextInnerIndex < source.endIndex {
			return .element(sourceIndex: sourceIndex, innerIndex: nextInnerIndex)
		}
		
		let nextSourceIndex = collections.index(after: sourceIndex)
		guard nextSourceIndex < collections.endIndex else { return .end }
		for sourceIndex in collections.indices[nextSourceIndex...] {
			if let innerIndex = sources[sourceIndex].indices.first {
				return .element(sourceIndex: sourceIndex, innerIndex: innerIndex)
			}
		}
		
		return .end
		
	}
	
}
