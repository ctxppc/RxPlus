// RxPlus © 2019 Constantino Tsarouhas

import DepthKit
import RxSwift

/// A reactive collection whose elements consist of those in a base collection passed through a transform function.
///
/// Just like `LazyMapCollection`, a reactive map collection uses its base collection's indices and transforms elements on demand. Observed collection differences are simply mapped to use the transformed element. This mapping is done eagerly.
public final class ReactiveMapCollection<Base : ReactiveCollection, Element> {
	
	/// Creates a reactive map collection over given base collection and with given transform function.
	fileprivate init(base: Base, transform: @escaping Transform) {
		self.base = base
		self.transform = transform
		baseObserver = .init(observers: observers, transform: transform)
		base.subscribe(baseObserver).disposed(by: disposeBag)
	}
	
	/// The base collection on which the transform function is evaluated.
	fileprivate let base: Base
	
	/// The transform function.
	fileprivate let transform: Transform
	
	/// The observer for changes to the base collection.
	private let baseObserver: BaseObserver
	
	/// A transform function.
	public typealias Transform = (Base.Element) -> Element
	
	/// The collection's observers.
	fileprivate let observers = ObserverBag<E>()
	
	/// The dispose bag for the collection.
	private let disposeBag = DisposeBag()
	
	deinit {
		observers.emit(.completed)
	}
	
}

extension ReactiveMapCollection : Collection {
	
	public typealias Index = Base.Index
	
	public var startIndex: Index {
		return base.startIndex
	}
	
	public var endIndex: Index {
		return base.endIndex
	}
	
	public subscript (index: Index) -> Element {
		return transform(base[index])
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

extension ReactiveMapCollection : BidirectionalCollection where Base : BidirectionalCollection {
	public func index(before index: Index) -> Index {
		return base.index(before: index)
	}
}

extension ReactiveMapCollection : RandomAccessCollection where Base : RandomAccessCollection {}

extension ReactiveMapCollection : ObservableType {
	
	public typealias E = CollectionDifference<Element>
	
	public func subscribe<Observer : ObserverType>(_ observer: Observer) -> Disposable where Observer.E == E {
		return observers.subscribe(observer)
	}
	
}

extension ReactiveMapCollection : ReactiveCollection {}

extension ReactiveMapCollection {
	
	/// An observer for base collection changes.
	///
	/// Due to RxSwift's design of `ObserverType` and `ObservableType` requiring the same `E` associated type for observed and emitted events, we need a separate observer type since the base element type might be different from the transformed element type.
	fileprivate class BaseObserver : ObserverType {
		
		init(observers: ObserverBag<CollectionDifference<Element>>, transform: @escaping Transform) {
			self.observers = observers
			self.transform = transform
		}
		
		unowned let observers: ObserverBag<CollectionDifference<Element>>
		let transform: Transform
		
		typealias E = CollectionDifference<Base.Element>
		
		public func on(_ event: Event<E>) {
			switch event {
				case .next(let difference):	observe(difference)
				case .error:				fatalError("Unexpectedly observed error")
				case .completed:			fatalError("Prematurely observed completion")
			}
		}
		
		private func observe(_ difference: CollectionDifference<Base.Element>) {
			guard !observers.isEmpty else { return }
			observers.emit(.init(
				insertions: difference.insertions.map {
					.insert(
						offset:			$0.offset,
						element:		transform($0.element),
						associatedWith:	$0.offsetOfComplementaryChange
					)
				},
				removals: difference.removals.map {
					.remove(
						offset:			$0.offset,
						element:		transform($0.element),
						associatedWith:	$0.offsetOfComplementaryChange
					)
				}
			))
		}
		
	}
	
}

extension ReactiveCollection {
	public func map<T>(_ transform: @escaping (Element) -> T) -> ReactiveMapCollection<Self, T> {
		return .init(base: self, transform: transform)
	}
}
