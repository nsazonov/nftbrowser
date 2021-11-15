import Foundation
import UIKit

class TableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
            
    @IBOutlet var picView: UIImageView!
    
    var nftImage: UIImage? {
        get {
            return picView.image
        }
        set {
            picView.image = newValue
        }
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        picView.contentMode = .scaleAspectFill
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        nftImage = nil
    }
        
}
