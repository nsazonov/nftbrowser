import Foundation
import UIKit

class TableViewCell: UITableViewCell {
    
    @IBOutlet var titleLabel: UILabel!
        
    @IBOutlet var picView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        picView.contentMode = .scaleAspectFill
    }
        
    override func layoutSubviews() {
        
    }
        
}
