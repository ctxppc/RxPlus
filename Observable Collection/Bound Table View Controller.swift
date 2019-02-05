// RxPlus © 2019 Constantino Tsarouhas

import UIKit

public class BoundTableViewController<Collection : ObservableTreeCollection> : UITableViewController {
	
	/// The collection presented by the table view controller.
	public var presentedCollection: Collection?
	
}
