// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import RxSwift

/// A reactive view into a subsequence of elements in another reactive collection.
///
/// A reactive slice behaves like a `Slice` except that
/// * it propagates observed changes within the slice's bounds to the slice's observers;
/// * it's created over a range of offsets instead of indices; and
/// * it cannot mutate the underlying collection, even if the latter is range-replaceable or mutable.
///
/// Using a `ReactiveSlice` instance with a mutable collection requires that the base collection’s `subscript(_: Index)` setter does not invalidate indices. If mutations need to invalidate indices, don’t use `ReactiveSlice`. Instead, define a subsequence type that takes these index invalidation requirements into account.
///
/// A reactive slice emits differences that only concern elements within the slice's bounds.
public final class ReactiveSlice<Base : ReactiveCollection> {
	
	/// Creates a view into the given collection that allows access to elements within the specified range of offsets (relative to `base.startIndex`).
	///
	/// - Precondition: `startOffset` ≥ 0 and `maximumCount` ≥ 0.
	///
	/// - Complexity: O(1) if `base` is a random-access collection; O(*n*) where *n* is the length of `base` otherwise.
	///
	/// - Parameter base:			The underlying collection.
	/// - Parameter startOffset:	The offset, relative to `base.startIndex`, of the first element in `self`.
	/// - Parameter maximumCount:	The maximum number of elements in the slice.
	public init(base: Base, startOffset: Int, maximumCount: Int) {
		
		precondition(startOffset >= 0)
		precondition(maximumCount >= 0)
		
		self.base = base
		self.startOffset = startOffset
		self.maximumCount = maximumCount
		self.startIndex = base.index(base.startIndex, offsetBy: startOffset, limitedBy: base.endIndex) ?? base.startIndex
		self.endIndex = base.index(self.startIndex, offsetBy: maximumCount, limitedBy: base.endIndex) ?? base.endIndex
		
	}
	
	/// Creates a view into the given collection that allows access to elements within the specified range.
	///
	/// - Precondition: Every index in `bounds` is a valid index in `base`.
	/// - Postcondition: `self.maximumCount` = `base.distance(from: bounds.lowerBound, to: bounds.upperBound)`.
	///
	/// - Complexity: O(1) if `base` is a random-access collection; O(*n*) where *n* is the length of `base` otherwise.
	///
	/// - Parameter base:	The underlying collection.
	/// - Parameter bounds:	The initial bounds of the slice into `base`.
	public init(base: Base, bounds: Range<Index>) {
		self.base = base
		self.startIndex = bounds.lowerBound
		self.endIndex = bounds.upperBound
		self.startOffset = base.distance(from: base.startIndex, to: self.startIndex)
		self.maximumCount = base.distance(from: self.startIndex, to: self.endIndex)
	}
	
	/// Creates a view into the given collection that allows access to elements within the specified range of offsets (relative to `base.startIndex`).
	///
	/// - Precondition: `startOffset` ≥ 0 and `maximumCount` ≥ 0.
	///
	/// - Complexity: O(1).
	///
	/// - Parameter base:			The underlying collection.
	/// - Parameter startOffset:	The offset, relative to `base.startIndex`, of the first element in `self`.
	/// - Parameter maximumCount:	The maximum number of elements in the slice.
	/// - Parameter bounds:			The initial bounds of the slice into `base`.
	fileprivate init(base: Base, startOffset: Int, maximumCount: Int, bounds: Range<Index>) {
		self.base = base
		self.startOffset = startOffset
		self.maximumCount = maximumCount
		self.startIndex = bounds.lowerBound
		self.endIndex = bounds.upperBound
	}
	
	/// The underlying collection.
	public let base: Base
	
	/// The offset, relative to `base.startIndex`, of the first element in `self`.
	///
	/// The slice is empty if `base.count` ≤ `startOffset`.
	///
	/// - Invariant: `startOffset` ≥ 0.
	public let startOffset: Int
	
	/// The maximum number of elements in the slice.
	///
	/// - Invariant: 0 ≤ `count` ≤ `maximumCount`.
	public let maximumCount: Int
	
	// See `Collection`.
	public private(set) var startIndex: Index
	
	// See `Collection`.
	public private(set) var endIndex: Index
	
	/// The slice's observers.
	fileprivate let observers = ObserverBag<E>()
	
	/// The dispose bag.
	private let disposeBag = DisposeBag()
	
	deinit {
		observers.emit(.completed)
	}
	
}

extension ReactiveSlice : Collection {
	
	public typealias Index = Base.Index
	public typealias Element = Base.Element
	public typealias SubSequence = ReactiveSlice
	
	public subscript (index: Index) -> Element {
		return base[index]
	}
	
	public subscript (range: Range<Index>) -> ReactiveSlice {
		let newStartOffset = range.lowerBound == startIndex ? startOffset : base.distance(from: base.startIndex, to: range.lowerBound)
		let newMaximumCount = range.upperBound == endIndex ? maximumCount : base.distance(from: self.startIndex, to: range.upperBound)
		return .init(base: base, startOffset: newStartOffset, maximumCount: newMaximumCount, bounds: range)
	}
	
	public func index(after index: Index) -> Index {
		return base.index(after: index)
	}
	
	public var count: Int {
		return base.count
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

extension ReactiveSlice : BidirectionalCollection where Base : BidirectionalCollection {
	public func index(before index: Index) -> Index {
		return base.index(before: index)
	}
}

extension ReactiveSlice : RandomAccessCollection where Base : RandomAccessCollection {}

extension ReactiveSlice : ObservableType {
	
	public typealias E = CollectionDifference<Element>
	
	public func subscribe<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.E == E {
		return observers.subscribe(observer)
	}
	
}

extension ReactiveSlice : ReactiveCollection {}

extension ReactiveSlice : ObserverType {
	
	public func on(_ event: Event<E>) {
		switch event {
			case .next(let difference):	observe(difference)
			case .error:				fatalError("Unexpectedly observed error")
			case .completed:			fatalError("Prematurely observed completion")
		}
	}
	
	private func observe(_ difference: CollectionDifference<Element>) {
		TODO.unimplemented
	}
	
}

extension ReactiveCollection where Self.SubSequence == ReactiveSlice<Self> {
	
	public subscript (range: Range<Index>) -> SubSequence {
		return .init(base: self, bounds: range)
	}
	
}
