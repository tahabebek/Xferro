//
//  ThreadSafeRepository.swift
//  Xferro
//
//  Created by Taha Bebek on 2/11/25.
//

import Foundation
/*
 Prints:
 sync: before
 sync: inside
 sync: after

 func performSync() {
     print("sync: before")
     DispatchQueue.global().sync {
         print("sync: inside")
     }
     print("sync: after")
 }

 Prints:
 async: before
 async: after
 async: inside

 func performAsync() {
     print("async: before")
     DispatchQueue.global().async {
         print("async: inside")
     }
     print("async: after")
 }

 DispatchGroup:
 func fetchWebsites() {
     let group = DispatchGroup()
     var results = [Data]()
     let urls = [
         "https://practicalcoredata.com",
         "https://practicalcombine.com",
         "https://practicalswiftconcurrency.com"
     ].compactMap(URL.init)
     for url in urls {
         group.enter()
         URLSession.shared.dataTask(with: url) { data, response, error in
             if let data = data {
                 results.append(data)
             }
             group.leave()
         }.resume()
     }

     group.notify(queue: DispatchQueue.main) {
         print(results)
     }
 }

 class SimpleCache<Key: Hashable, T> {
     private var cache: [Key: T] = [:]
     private let queue = DispatchQueue(label: "SimpleCache.\(UUID().uuidString)")

     func getValue(forKey key: Key) -> T? {
         return queue.sync {
             return cache[key]
         }
     }

     func setValue(_ value: T, forKey key: Key) {
         queue.sync {
             cache[key] = value
         }
     }
 }

 class SimpleCache2<Key: Hashable, T> {
     private var cache: [Key: T] = [:]
     private let semaphore = DispatchSemaphore(value: 1)

     func getValue(forKey key: Key) -> T? {
         semaphore.wait()
         let value = cache[key]
         semaphore.signal()
         return value
     }

     func setValue(_ value: T, forKey key: Key) {
         semaphore.wait()
         cache[key] = value
         semaphore.signal()
     }
 }

 class SimpleCache3<Key: Hashable, T> {
     private var cache: [Key: T] = [:]
     private let lock = NSLock()

     func getValue(forKey key: Key) -> T? {
         lock.lock()
         let value = cache[key]
         lock.unlock()
         return value
     }

     func setValue(_ value: T, forKey key: Key) {
         lock.lock()
         cache[key] = value
         lock.unlock()
     }
 }

 Prints:
 one
 three
 two

 func viewDidLoad() {
     print("one")
     Task {
         // ...
         print("two")
     }
     print("three")
 }

 Tasks have an implicit self capture which means
 that you can freely use and access members of self inside of a task. This is a huge gotcha for
 many developers because there are no compiler errors or warnings surrounding the behavior
 so it’s easy to accidentally capture self strongly through the implicit capture.
 Another behavior that can be slightly surprising when using Task is that a task created with
 the Task or Task.detached initializer will swallow any errors thrown from inside of the
 task’s body.

 Compiles:
 Task {
     let userInfo = try await fetchUserInfo()
 }

 */

actor DateFormatters {
    private var formatters: [String: DateFormatter] = [:]
    func formatter(using dateFormat: String) -> DateFormatter {
        if let formatter = formatters[dateFormat] {
            return formatter
        }
        let newFormatter = DateFormatter()
        newFormatter.dateFormat = dateFormat
        formatters[dateFormat] = newFormatter
        return newFormatter
    }
}
