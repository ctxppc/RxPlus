// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import RxSwift

/// A collection wrapping another collection and emitting collection change events whenever the underlying collection changes.
///
/// An observable collection emits a change for every element that is inserted, moved, or removed. This means that the complexity of all mutating operations is at least linearly proportional to the number of affected elements.
///
/// All events are emitted *after* the collection has been mutated.
///
/// - Warning: In the case that the underlying collection has reference semantics, it must not be mutated directly. An observable collection only emits events for changes performed via the observable collection. In particular, an observable collection does not observe changes performed directly on an underlying observable collection.
public final class ObservableCollection<Base : BidirectionalCollection> {
	
	/// Creates a collection managing given collection.
	public init(_ base: Base) {
		self.base = base
	}
	
	/// The underlying collection.
	private var base: Base
	
	/// Replaces the underlying collection by a new collection.
	public func replace(by newBase: Base) {
		if observers.isEmpty {
			base = newBase
		} else {
			
			let changes = base.enumerated().map {
				CollectionDifference.Change.remove(offset: $0.offset, element: $0.element, associatedWith: nil)
			} + newBase.enumerated().map {
				CollectionDifference.Change.insert(offset: $0.offset, element: $0.element, associatedWith: nil)
			}
			
			base = newBase
			
			emit(changes)
			
		}
	}
	
	/// The observable collection's observers.
	fileprivate var observers = ObserverBag<E>()
	
	deinit {
		observers.emit(.completed)
	}
	
}

extension ObservableCollection where Base : ReactiveCollection {
	
	@available(*, unavailable, message: "An observable collection cannot observe changes on an underlying reactive collection.")
	public convenience init(_ base: Base) {
		fatalError("An observable collection cannot observe changes on an underlying reactive collection.")
	}
	
}

extension ObservableCollection : Collection {
	
	public typealias Index = Base.Index
	public typealias Element = Base.Element
	public typealias SubSequence = Base.SubSequence
	
	public func index(after index: Index) -> Index {
		return base.index(after: index)
	}
	
	public subscript (index: Index) -> Element {
		return base[index]
	}
	
	public subscript (range: Range<Index>) -> SubSequence {
		return base[range]
	}
	
	public var startIndex: Index {
		return base.startIndex
	}
	
	public var endIndex: Index {
		return base.endIndex
	}
	
	public var isEmpty: Bool {
		return base.isEmpty
	}
	
	public func index(_ index: Index, offsetBy distance: Int) -> Index {
		return base.index(index, offsetBy: distance)
	}
	
	public func index(_ index: Index, offsetBy distance: Int, limitedBy limit: Index) -> Index? {
		return base.index(index, offsetBy: distance, limitedBy: limit)
	}
	
	public func formIndex(_ index: inout Index, offsetBy distance: Int) {
		base.formIndex(&index, offsetBy: distance)
	}
	
	public func formIndex(_ index: inout Index, offsetBy distance: Int, limitedBy limit: Index) -> Bool {
		return base.formIndex(&index, offsetBy: distance, limitedBy: limit)
	}
	
	public func distance(from start: Index, to end: Index) -> Int {
		return base.distance(from: start, to: end)
	}
	
}

extension ObservableCollection : BidirectionalCollection where Base : BidirectionalCollection {
	
	public func index(before index: Index) -> Index {
		return base.index(before: index)
	}
	
	public var indices: Base.Indices {
		return base.indices
	}
	
}

extension ObservableCollection : RandomAccessCollection where Base : RandomAccessCollection {}

extension ObservableCollection : MutableCollection where Base : MutableCollection & RandomAccessCollection {
	
	public subscript (index: Index) -> Element {
		
		get {
			return base[index]
		}
		
		set {
			
			let offset = base.distance(from: base.startIndex, to: index)
			let previousElement = base[index]
			base[index] = newValue
			
			guard !observers.isEmpty else { return }
			emit([
				.insert(offset: offset, element: newValue, associatedWith: offset),
				.remove(offset: offset, element: previousElement, associatedWith: offset),
			])
			
		}
	}
	
	public subscript (range: Range<Index>) -> SubSequence {
		
		get {
			return base[range]
		}
		
		set {
			if observers.isEmpty {
				base[range] = newValue
			} else {
				
				guard !range.isEmpty else { return }
				
				let lowerBoundOffset = base.distance(from: base.startIndex, to: range.lowerBound)
				let upperBoundOffset = base.distance(from: base.startIndex, to: range.upperBound)
				let offsets = lowerBoundOffset..<upperBoundOffset
				
				let removals = Swift.zip(base[range], offsets).map {
					CollectionDifference.Change.remove(offset: $0.1, element: $0.0, associatedWith: $0.1)
				}
				
				base[range] = newValue
				
				let insertions = Swift.zip(base[range], offsets).map {
					CollectionDifference.Change.insert(offset: $0.1, element: $0.0, associatedWith: $0.1)
				}
				
				emit(insertions + removals)
				
			}
		}
		
	}
	
	public func swapAt(_ firstIndex: Index, _ otherIndex: Index) {
		
		guard firstIndex != otherIndex else { return }
		base.swapAt(firstIndex, otherIndex)
		
		guard !observers.isEmpty else { return }
		let offsetOfFirstIndex = base.distance(from: base.startIndex, to: firstIndex)
		let offsetOfOtherIndex = base.distance(from: base.startIndex, to: otherIndex)
		emit([
			
			// The element at `firstIndex` moved to `otherIndex`.
			.remove(offset: offsetOfFirstIndex, element: base[otherIndex], associatedWith: offsetOfOtherIndex),
			.insert(offset: offsetOfOtherIndex, element: base[otherIndex], associatedWith: offsetOfFirstIndex),
			
			// The element at `otherIndex` moved to `firstIndex`.
			.remove(offset: offsetOfOtherIndex, element: base[firstIndex], associatedWith: offsetOfFirstIndex),
			.insert(offset: offsetOfFirstIndex, element: base[firstIndex], associatedWith: offsetOfOtherIndex)
			
		])
		
	}
	
}

extension ObservableCollection : RangeReplaceableCollection where Base : RangeReplaceableCollection & RandomAccessCollection {
	
	public convenience init() {
		self.init(.init())
	}
	
	public func replaceSubrange<NewElements : Collection, Range : RangeExpression>(_ subrange: Range, with newElements: NewElements) where NewElements.Element == Element, Range.Bound == Index {
		if observers.isEmpty {
			base.replaceSubrange(subrange, with: newElements)
		} else {
			
			let offsetOfFirstReplaced = base.distance(from: base.startIndex, to: subrange.relative(to: base).lowerBound)
			let removals = Swift.zip(base[subrange], offsetOfFirstReplaced...).map {
				CollectionDifference.Change.remove(offset: $0.1, element: $0.0, associatedWith: nil)
			}
			
			let previousCount = base.count
			base.replaceSubrange(subrange, with: newElements)
			let newCount = base.count
			
			let insertionCount = newCount - previousCount + removals.count
			let indexOfFirstReplaced = base.index(base.startIndex, offsetBy: offsetOfFirstReplaced)
			let indexAfterLastReplaced = base.index(indexOfFirstReplaced, offsetBy: insertionCount)
			
			let insertions = Swift.zip(base[indexOfFirstReplaced..<indexAfterLastReplaced], offsetOfFirstReplaced...).map {
				CollectionDifference.Change.insert(offset: $0.1, element: $0.0, associatedWith: nil)
			}
			
			emit(insertions + removals)
			
		}
	}
	
	public func reserveCapacity(_ newCapacity: Int) {
		base.reserveCapacity(newCapacity)
	}
	
}

extension ObservableCollection : ObservableType {
	
	public typealias E = CollectionDifference<Element>
	
	public func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
		return observers.subscribe(observer)
	}
	
	/// Emits an interdependent collection of changes to observers.
	fileprivate func emit<C : Swift.Collection>(_ changes: C) where C.Element == CollectionDifference<Base.Element>.Change {
		let difference = CollectionDifference(changes) !! "Invalid difference"
		observers.emit(difference)
	}
	
}

extension ObservableCollection : ReactiveCollection {}
