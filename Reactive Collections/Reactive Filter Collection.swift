// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import RxSwift

/// A reactive collection that includes the elements of an underlying collection that satisfy a predicate.
///
/// Just like `LazyFilterCollection`, a reactive filter collection uses its base collection's indices and filters its indices on demand. Observed collection differences are filtered then passed through.
///
/// - Note: The performance characteristics of `startIndex`, `index(after:)`, and other index manipulation operations depend on how sparsely populated the filter collection is relative to its base collection. A filter collection is never random-access meaning that traversal and counting operations require traversing over every element in the base collection.
///
/// - Note: Every observed difference on the base collection triggers a filtering operation on the observed changes that might have quadratic time complexity if the base collection isn't random-access. It's therefore recommended to use a random-access base collection for any significant number of elements.
public final class ReactiveFilterCollection<Base : ReactiveCollection> {
	
	/// Creates a reactive filter collection over given base collection and with given predicate function.
	fileprivate init(base: Base, predicate: @escaping Predicate) {
		self.base = base
		self.predicate = predicate
	}
	
	/// The base collection on which the predicate function is evaluated.
	fileprivate let base: Base
	
	/// The predicate function.
	fileprivate let predicate: Predicate
	
	/// A predicate function.
	public typealias Predicate = (Base.Element) -> Bool
	
	/// The collection's observers.
	fileprivate let observers = ObserverBag<E>()
	
	/// The dispose bag for the collection.
	private let disposeBag = DisposeBag()
	
	deinit {
		observers.emit(.completed)
	}
	
}

extension ReactiveFilterCollection : Collection {
	
	public typealias Index = Base.Index
	public typealias Element = Base.Element
	
	public var startIndex: Base.Index {
		guard let element = base.first else { return endIndex }
		return predicate(element) ? base.startIndex : index(after: base.startIndex)
	}
	
	public var endIndex: Base.Index {
		return base.endIndex
	}
	
	public subscript (index: Index) -> Element {
		return base[index]
	}
	
	public func index(after index: Index) -> Index {
		return base.indices[index...].dropFirst().first(where: { predicate(base[$0]) }) ?? endIndex
	}
	
}

extension ReactiveFilterCollection : BidirectionalCollection where Base : BidirectionalCollection {
	public func index(before index: Index) -> Index {
		return base.indices[..<index].reversed().first(where: { predicate(base[$0]) }) !! "Index out of bounds"
	}
}

extension ReactiveFilterCollection : ObservableType {
	
	public typealias E = CollectionDifference<Element>
	
	public func subscribe<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.E == E {
		return observers.subscribe(observer)
	}
	
}

extension ReactiveFilterCollection : ObserverType {
	
	public func on(_ event: Event<E>) {
		switch event {
			case .next(let difference):	observe(difference)
			case .error:				fatalError("Unexpectedly observed error")
			case .completed:			fatalError("Prematurely observed completion")
		}
	}
	
	private func observe(_ difference: CollectionDifference<Element>) {
		
		guard !observers.isEmpty else { return }
		typealias Change = CollectionDifference<Element>.Change
		
		// FIXME: Time complexity is O(changes.count * base.count) if base is not random-access. Changes are ordered and filtering preserves ordering so we could improve performance by keeping offsets while iterating over changes.
		
		// Time complexity analysis: n = base.count, m = changes.count, RA = random-access collection
		
		func map(_ changes: [Change], kind change: (Int, Element, Int?) -> Change) -> [Change] {						// RA O(m * n), otherwise O(m * n²)
			return changes.compactMap { baseChange -> Change? in
				
				let element = baseChange.element
				guard predicate(element) else { return nil }
				let index = base.index(base.startIndex, offsetBy: baseChange.offset)									// RA O(1), otherwise O(n)
				let newOffset = distance(from: self.startIndex, to: index)												// O(n)
				
				let newOffsetOfComplementaryChange: Int?
				if let baseOffsetOfComplementaryChange = baseChange.offsetOfComplementaryChange {
					let complementaryIndex = base.index(base.startIndex, offsetBy: baseOffsetOfComplementaryChange)		// RA O(1), otherwise O(n)
					if predicate(base[complementaryIndex]) {
						newOffsetOfComplementaryChange = distance(from: self.startIndex, to: index)						// O(n)
					} else {
						newOffsetOfComplementaryChange = nil
					}
				} else {
					newOffsetOfComplementaryChange = nil
				}
				
				return change(newOffset, element, newOffsetOfComplementaryChange)
				
			}
		}
		
		observers.emit(.init(
			insertions:	map(difference.insertions, kind: Change.insert),
			removals:	map(difference.removals, kind: Change.remove)
		))
		
	}
	
}

extension ReactiveCollection {
	public func filter(_ predicate: @escaping (Element) -> Bool) -> ReactiveFilterCollection<Self> {
		return .init(base: self, predicate: predicate)
	}
}
