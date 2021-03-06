
import UIKit

class PictureCell: UITableViewCell {

    @IBOutlet var nameLabel: UILabel!
    @IBOutlet var pictureView: UIImageView!
    @IBOutlet var activityIndicator: UIActivityIndicatorView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        activityIndicator.isHidden = true
    }
}
