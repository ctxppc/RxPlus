// RxPlus © 2019 Constantino Tsarouhas

import CoreData
import DepthKit

public final class FetchedCollection<Entity : NSFetchRequestResult> {
	
	public init(resultsController: NSFetchedResultsController<Entity>) {
		self.resultsController = resultsController
	}
	
	public let resultsController: NSFetchedResultsController<Entity>
	
	// See `ObservableCollection`.
	public var changeHandler: CollectionChangeHandler?
	
	// See `ObservableTreeCollection`.
	public var treeChangeHandler: TreeCollectionChangeHandler?
	
}

extension FetchedCollection : ObservableTreeCollection {
	
	public var startIndex: IndexPath {
		return []
	}
	
	public var endIndex: IndexPath {
		guard let sections = resultsController.sections else { return startIndex }
		return [sections.count]
	}
	
	public subscript (indexPath: IndexPath) -> Element {
		switch indexPath.count {
			case 0:	return .list
			case 1:	return .section(title: (resultsController.sections !! "No data available")[indexPath.section].name)
			case 2:	return .entity(resultsController.object(at: indexPath))
			case _:	preconditionFailure("Invalid index path")
		}
	}
	
	public enum Element {
		
		/// An element representing the fetched collection.
		case list
		
		/// An element representing a section.
		case section(title: String)
		
		/// An element representing a fetched entity.
		case entity(Entity)
		
	}
	
	public func index(before indexPath: IndexPath) -> IndexPath {
		guard let sections = resultsController.sections else { preconditionFailure("No data available") }
		switch indexPath.count {
			
			case 1 where indexPath[0] > 0:
			let newSection = indexPath[0] - 1
			let itemCount = sections[newSection].numberOfObjects
			return itemCount > 0 ? [newSection, itemCount - 1] : [newSection]
			
			case 2 where indexPath[1] == 0:
			return [indexPath.section]
			
			case 2 where indexPath[1] > 0:
			return [indexPath.section, indexPath.item - 1]
			
			default:
			preconditionFailure("Index path out of bounds: \(indexPath)")
			
		}
	}
	
	public func index(after indexPath: IndexPath) -> IndexPath {
		guard let sections = resultsController.sections else { preconditionFailure("No data available") }
		switch indexPath.count {
			
			case 1:
			let itemCount = sections[indexPath.section].numberOfObjects
			return itemCount > 0 ? [indexPath.section, 0] : [indexPath.section + 1]
			
			case 2:
			let itemCount = sections[indexPath.section].numberOfObjects
			let newItem = indexPath.item + 1
			return newItem < itemCount ? [indexPath.section, newItem] : [indexPath.section + 1]
			
			default:
			preconditionFailure("Index path out of bounds: \(indexPath)")
			
		}
	}
	
	public func numberOfChildren(at indexPath: IndexPath) -> Int {
		switch indexPath.count {
			case 0:	return resultsController.sections?.count ?? 0
			case 1:	return numberOfObjects(section: indexPath[0]) ?? 0
			case _:	return 0
		}
	}
	
	private func numberOfObjects(section: Int) -> Int? {
		guard let sections = resultsController.sections, sections.indices.contains(section) else { return nil }
		return sections[section].numberOfObjects
	}
	
}
