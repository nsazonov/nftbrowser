import Foundation
import UIKit
import os

class ImageDownloader {
            
    let inMemoryCache: InMemoryCache = {
        return InMemoryCache()
    }()
    
    let session: URLSession = {
        let config = URLSessionConfiguration.default
        config.requestCachePolicy = .returnCacheDataElseLoad
        return URLSession(configuration: config)
    }()
    
    enum ImageError: Error {
        case loadError
        case dataError
        case networkError(Error)
        case thumbnailError
    }
        
    func fetchImage(url: URL, completion: @escaping ((Result<UIImage, ImageError>)) -> Void) {
        if let cachedImage = inMemoryCache[key: url] {
            os_log("Return image from cache %s", log: Log.imageCache, type: .default, url.absoluteString)
            completion(.success(cachedImage))
            return
        }
        session.dataTask(with: url) { [weak self] data, _, error in
            if let error = error {
                DispatchQueue.main.async {
                    os_log("Network error %s", log: Log.imageCache, type: .error, error.localizedDescription)
                    completion(.failure(.networkError(error)))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    os_log("Data error fetching image %s", log: Log.imageCache, type: .error, url.absoluteString)
                    completion(.failure(.dataError))
                }
                return
            }
            guard let image = data.thumbnail else {
                DispatchQueue.main.async {
                    os_log("Failed to decompress image %s", log: Log.imageCache, type: .error, url.absoluteString)
                    completion(.failure(.thumbnailError))
                }
                return
            }
            self?.inMemoryCache[key: url] = image
            DispatchQueue.main.async {
                os_log("Loaded image %s", log: Log.imageCache, type: .default, url.absoluteString)
                completion(.success(image))
            }
        }.resume()
    }
    
}

class InMemoryCache {
    
    static let cacheSize = 5 * 1024 * 1024 * 1024 // 5 MB
    
    private let cache: NSCache<NSURL, UIImage> = {
        let cache = NSCache<NSURL, UIImage>()
        cache.totalCostLimit = InMemoryCache.cacheSize
        return cache
    }()
    
    subscript(key url: URL) -> UIImage? {
        get {
            cache.object(forKey: url.keyValue)
        }
        set {
            guard let image = newValue else {
                cache.removeObject(forKey: url.keyValue)
                return
            }
            let count = image.sizeInBytes ?? Int(image.size.width * image.size.height * 4)
            cache.setObject(image, forKey: url.keyValue, cost: count)
        }
    }
    
}

fileprivate extension UIImage {
    var sizeInBytes: Int? {
        guard let cgImage = self.cgImage else {
            return nil
        }
        return cgImage.bytesPerRow * cgImage.height
    }
}

fileprivate extension URL {
    var keyValue: NSURL {
        return NSURL(string: absoluteString)!
    }
}

extension Data {
    
    static let maxPixelSize = 300
   
    var thumbnail: UIImage? {
        let options = [
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceThumbnailMaxPixelSize: Data.maxPixelSize] as CFDictionary
        guard let source = CGImageSourceCreateWithData(self as CFData, nil) else {
            os_log("Couldn't create CFData from Data", log: Log.imageCache, type: .error)
            return nil
        }
        guard let imageReference = CGImageSourceCreateThumbnailAtIndex(source, 0, options) else {
            os_log("Couldn't create thumbnail from Data", log: Log.imageCache, type: .error)
            return nil
        }
        return UIImage(cgImage: imageReference)
    }
    
}
