/// ZeroDark.cloud
///
/// Homepage      : https://www.zerodark.cloud
/// GitHub        : https://github.com/4th-ATechnologies/ZeroDark.cloud
/// Documentation : https://zerodarkcloud.readthedocs.io/en/latest
/// API Reference : https://apis.zerodark.cloud
///
/// Sample App: ZeroDarkTodo

import UIKit
import ZeroDarkCloud

/// All `List` objects get stored in the database using this collection.
/// (The database being used by this sample app is a collection/key/value store.)
///
let kCollection_Lists = "Lists"

/// The `List` class is a container for Tasks (i.e. a container for Todo items).
/// Every List has a title, such as "Groceries" or "Weekend Chores".
///
/// You'll notice there's nothing special about the List class.
/// We don't have to extend some base class. It's just a plain old Swift object.
///
class List: NSCopying, Codable {

	enum CodingKeys: String, CodingKey {
		case uuid = "uuid"
		case localUserID = "localUserID"
		case title = "title"
	}
	
	/// We store `List` objects in the database.
	///
	/// The database being used by this sample app is YapDatabase, which is a collection/key/value store.
	/// All List objects go into the same collection: kCollection_Lists.
	/// And each List has a uuid, which we use as the database key.
	///
	/// We commonly refer to the List.uuid value as the ListID.
	///
	/// You can fetch this object from the database via:
	/// ```
	/// var list: List? = nil
	/// databaseConnection.read() {(transaction) in
	///   list = transaction.object(forKey: listID, inCollection: kCollection_Lists) as? List
	/// }
	/// ```
	let uuid: String
	
	/// Since our sample app supports multiple logged in users, we also store a reference to the localUserID.
	/// (LocalUserID == ZDCLocalUser.uuid)
	///
	/// This can be thought of as a reference to the "parent" of this object.
	///
	let localUserID: String
	
	/// Every list has a title.
	/// The title is what the user types in when they create the List.
	///
	var title: String

	
	init(uuid: String,
	     localUserID: String,
	     title: String)
	{
		self.uuid = uuid
		self.localUserID = localUserID
		self.title = title
	}
	
	convenience init(localUserID: String, title: String) {
		let _uuid = UUID().uuidString
		self.init(uuid: _uuid, localUserID: localUserID, title: title)
	}
	
	convenience init(copy source: List, uuid: String) {
		
		self.init(uuid: uuid, localUserID: source.localUserID, title: source.title)
	}

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// MARK: NSCopying
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
 
	func copy(with zone: NSZone? = nil) -> Any {

		let copy = List(uuid        : uuid,
		                localUserID : localUserID,
		                title       : title)
		return copy
	}
}
