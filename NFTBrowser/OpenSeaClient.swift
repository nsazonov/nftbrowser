import Foundation
import os

enum OpenSeaError: Error, CustomStringConvertible {
    case networkError(Error)
    case responseError
    var description: String {
        switch self {
        case .networkError(let error):
            return "Network error \(error.localizedDescription)"
        case .responseError:
            return "Response error"            
        }
    }
}

struct NextToken: CustomStringConvertible {
    let offset: Int
    
    // can't be created outside of this scope
    fileprivate init(offset: Int) {
        self.offset = offset
    }
    var description: String { return "Offset \(offset)"}
    
    func offset(by newOffset: Int) -> NextToken {
        return NextToken(offset: self.offset + newOffset)
    }
}

enum OpenSeaResult {
    case assets([Asset], NextToken)
    case empty
}

class OpenSeaClient {
    let resultsLimit = 20
    let assetsUrl = "https://api.opensea.io/api/v1/assets?order_direction=desc"
    let defaultLimit = 30
    typealias CompletionHandler = ((Result<OpenSeaResult, OpenSeaError>) -> Void)
                
    func fetchAssets(_ completion: @escaping CompletionHandler) {
        runDataTask(nextToken: nil, completion)
    }
    
    func fetchMore(_ nextToken: NextToken, completion: @escaping CompletionHandler) {
        runDataTask(nextToken: nextToken, completion)
    }
    
    private func runDataTask(nextToken currentNextToken: NextToken?, _ completion: @escaping CompletionHandler) {
        var components = URLComponents(string: assetsUrl)!
        var queryItems = [URLQueryItem(name: "limit", value: String(defaultLimit))]
        if let currentNextToken = currentNextToken {
            queryItems += [URLQueryItem(name: "offset", value: String(currentNextToken.offset))]
        }
        components.queryItems = queryItems
        URLSession.shared.dataTask(with: components.url!) { data, _, networkError in
            if let networkError = networkError {
                DispatchQueue.main.async {
                    os_log("Network error %s.", log: Log.client, type: .error, networkError.localizedDescription)
                    completion(.failure(.networkError(networkError)))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    os_log("Network error", log: Log.client, type: .error)
                    completion(.failure(.responseError))
                }
                return
            }
            do {
                let response = try JSONDecoder().decode(OpenSeaResponse.self, from: data)
                DispatchQueue.main.async {
                    if let assets = response.assets, !assets.isEmpty {
                        let nextToken = currentNextToken?.offset(by: assets.count) ?? NextToken(offset: assets.count)
                        os_log("Received %d items on initial fetch. Next token %s",
                               log: Log.client,
                               type: .default,
                               assets.count,
                               nextToken.description)
                        completion(.success(.assets(assets, nextToken)))
                    } else {
                        os_log("No assets recevied.", log: Log.client, type: .default)
                        completion(.success(.empty))
                    }
                }
            } catch {
                os_log("Data error %s.", log: Log.client, type: .error, error.localizedDescription)
                DispatchQueue.main.async {
                    completion(.failure(.responseError))
                }
            }
        }.resume()        
    }
}
