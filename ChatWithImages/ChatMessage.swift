
import UIKit

@objcMembers
class ChatMessage: NSObject {
    var objectId: String?
    var ownerId: String?
    var userName: String?
    var messageText: String?
    var pictureUrl: String?
    var picture: UIImage?
}
