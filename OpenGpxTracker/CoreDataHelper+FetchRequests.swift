//
//  CoreDataHelper+FetchRequests.swift
//  OpenGpxTracker
//
//  Created by Vincent Neo on 1/8/20.
//

import CoreData
import CoreGPX

extension CoreDataHelper {
    
    // 查询数据中root信息
    func rootFetchRequest() -> NSAsynchronousFetchRequest<CDRoot> {
        let rootFetchRequest = NSFetchRequest<CDRoot>(entityName: "CDRoot")
        let asyncRootFetchRequest = NSAsynchronousFetchRequest(fetchRequest: rootFetchRequest) { asynchronousFetchResult in
            guard let rootResults = asynchronousFetchResult.finalResult else { return }
            
            DispatchQueue.main.async {
                print("Core Data Helper: fetching recoverable CDRoot")
                
                /** NSManagedObject instances are not intended to be passed between queues. Doing so can result in corruption of the data and termination of the application. When it is necessary to hand off a managed object reference from one queue to another, it must be done through NSManagedObjectID instances.
                 
                 You retrieve the managed object ID of a managed object by calling the objectID method on the NSManagedObject instance.
                 */
                guard let objectID = rootResults.last?.objectID else { self.lastFileName = ""; return }
                guard let safeRoot =  self.appDelegate.managedObjectContext.object(with: objectID) as? CDRoot else { self.lastFileName = ""; return }
                self.lastFileName = safeRoot.lastFileName ?? ""
                self.lastTracksegmentId = safeRoot.lastTrackSegmentId
                self.isContinued = safeRoot.continuedAfterSave
                // swiftlint:disable:next line_length
                print("Core Data Helper: fetched CDRoot  lastFileName:\(self.lastFileName) lastTracksegmentId: \(self.lastTracksegmentId) isContinued: \(self.isContinued)")
            }
        }
        return asyncRootFetchRequest
    }

    func trackPointFetchRequest() -> NSAsynchronousFetchRequest<CDTrackpoint> {
        // Creates a fetch request
        let trkptFetchRequest = NSFetchRequest<CDTrackpoint>(entityName: "CDTrackpoint")
        // Ensure that fetched data is ordered
        let sortTrkpt = NSSortDescriptor(key: "trackpointId", ascending: true)
        trkptFetchRequest.sortDescriptors = [sortTrkpt]
        
        // Creates `asynchronousFetchRequest` with the fetch request and the completion closure
        let asynchronousTrackPointFetchRequest = NSAsynchronousFetchRequest(fetchRequest: trkptFetchRequest) { asynchronousFetchResult in
            
            print("Core Data Helper: fetching recoverable CDTrackpoints")
            
            guard let trackPointResults = asynchronousFetchResult.finalResult else { return }
            // Dispatches to use the data in the main queue
            DispatchQueue.main.async {
                self.tracksegmentId = trackPointResults.first?.trackSegmentId ?? 0
                
                for result in trackPointResults {
                    let objectID = result.objectID
                    
                    // thread safe
                    guard let safePoint = self.appDelegate.managedObjectContext.object(with: objectID) as? CDTrackpoint else { continue }
                    
                    // 遍历到下一段 segment 的点了
                    if self.tracksegmentId != safePoint.trackSegmentId {
                        if self.currentSegment.points.count > 0 {
                            self.tracksegments.append(self.currentSegment)
                            
                            // 重置 currentSegment
                            self.currentSegment = GPXTrackSegment()
                        }
                        
                        self.tracksegmentId = safePoint.trackSegmentId
                    }
                    
                    let pt = GPXTrackPoint(latitude: safePoint.latitude, longitude: safePoint.longitude)
                    
                    pt.time = safePoint.time
                    pt.elevation = safePoint.elevation
                    
                    self.currentSegment.points.append(pt)
                }
                
                // 添加最后一段 Segment；上面循环在执行到最后一段Segment时，只是创建了Segment对象并添加了对应点，还没有加到数组里。
                self.trackpointId = trackPointResults.last?.trackpointId ?? Int64()
                self.tracksegments.append(self.currentSegment)
                
                // siftlint:disable:next line_length
                print("Core Data Helper: fetched CDTrackpoints. # of tracksegments: \(self.tracksegments.count). trackPointId: \(self.trackpointId) trackSegmentId: \(self.tracksegmentId)")
            }
        }
        return asynchronousTrackPointFetchRequest
    }
    
    func waypointFetchRequest() -> NSAsynchronousFetchRequest<CDWaypoint> {
        let wptFetchRequest = NSFetchRequest<CDWaypoint>(entityName: "CDWaypoint")
        let sortWpt = NSSortDescriptor(key: "waypointId", ascending: true)
        wptFetchRequest.sortDescriptors = [sortWpt]
        
        let asynchronousWaypointFetchRequest = NSAsynchronousFetchRequest(fetchRequest: wptFetchRequest) { asynchronousFetchResult in
            
            print("Core Data Helper: fetching recoverable CDWaypoints")
            
            // Retrieves an array of points from Core Data
            guard let waypointResults = asynchronousFetchResult.finalResult else { return }
            
            // Dispatches to use the data in the main queue
            DispatchQueue.main.async {
                for result in waypointResults {
                    let objectID = result.objectID
                    
                    // thread safe
                    guard let safePoint = self.appDelegate.managedObjectContext.object(with: objectID) as? CDWaypoint else { continue }
                    
                    let pt = GPXWaypoint(latitude: safePoint.latitude, longitude: safePoint.longitude)
                    
                    pt.time = safePoint.time
                    pt.desc = safePoint.desc
                    pt.name = safePoint.name
                    if safePoint.elevation != .greatestFiniteMagnitude {
                        pt.elevation = safePoint.elevation
                    }

                    self.waypoints.append(pt)
                }
                self.waypointId = waypointResults.last?.waypointId ?? Int64()
                
                // trackpoint request first, followed by waypoint request
                // hence, crashFileRecovery method is ran in this.
                self.crashFileRecovery() // should always be in the LAST fetch request!
                print("Core Data Helper: fetched \(self.waypoints.count) CDWaypoints ")
                print("Core Data Helper: async fetches complete.")
            }
        }
        return asynchronousWaypointFetchRequest
    }
    
}
