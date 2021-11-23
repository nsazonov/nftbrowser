import UIKit
import os

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    private static let cellIdentifier = "cellIdentifier"
    
    private let client = OceanSeaClient()
    
    private let imageDownloader = ImageDownloader()
    
    private var assets: [Asset] = []
    
    private var nextToken: NextToken?
    
    private let tableView: UITableView = {
        let tableView = UITableView(frame: .zero)
        tableView.autoresizingMask = [.flexibleTopMargin,
                                      .flexibleLeftMargin,
                                      .flexibleBottomMargin,
                                      .flexibleRightMargin,
                                      .flexibleWidth,
                                      .flexibleHeight]
        tableView.rowHeight = UITableView.automaticDimension
        tableView.separatorStyle = .none
        tableView.estimatedRowHeight = 80
        tableView.register(UINib(nibName: "TableViewCell", bundle: nil), forCellReuseIdentifier: ViewController.cellIdentifier)
        return tableView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "NFT Browser"
        tableView.delegate = self
        tableView.dataSource = self
        tableView.frame = view.bounds
        view.addSubview(tableView)
        os_log("Initial data fetch.", log: Log.table, type: .default)
        client.fetchAssets {[weak self] result in
            switch result {
            case .success(let result):
                switch result {
                case .empty:
                    os_log("No data on initial fetch.", log: Log.table, type: .default)
                case .assets(let assets, let nextToken):
                    self?.assets = assets
                    self?.nextToken = nextToken
                    os_log("Received %d items on initial fetch. Next token %s", log: Log.table, type: .default, assets.count, nextToken.description)
                }
            case .failure(let error):
                os_log("Client error %s", log: Log.table, type: .error, error.description)
            }
            self?.tableView.reloadData()
        }
    }
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return assets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return tableView.dequeueReusableCell(withIdentifier: ViewController.cellIdentifier, for: indexPath)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        guard let tableCell = cell as? TableViewCell else {
            fatalError("Unknonw cell type")
        }
        tableCell.titleLabel.text = assets[indexPath.row].name
        if indexPath.row == assets.count - 1, let nextToken = nextToken {
            self.nextToken = nil
            os_log("Fetch more items. Next token", log: Log.table, type: .debug, nextToken.description)
            client.fetchMore(nextToken) {[weak self] result in
                switch result {
                case .success(let result):
                    switch result {
                    case .assets(let assets, let nextToken):
                        self?.assets += assets
                        self?.nextToken = nextToken
                    case .empty:
                        self?.nextToken = nil
                    }
                case .failure:
                    // in case of network error we want to make another attempt to load data
                    self?.nextToken = nextToken
                }
                os_log("Reload table.", log: Log.table, type: .default)
                self?.tableView.reloadData()
            }
        }
        guard let urlString = assets[indexPath.row].thumbnailUrl, let url = URL(string: urlString) else {
            tableCell.nftImage = nil
            return
        }
        tableCell.tag = indexPath.row
        imageDownloader.fetchImage(url: url) { result in
            if tableCell.tag != indexPath.row {
                return
            }
            switch result {
            case .failure:
                tableCell.nftImage = nil
            case .success(let image):
                tableCell.nftImage = image
            }
        }
    }

}
