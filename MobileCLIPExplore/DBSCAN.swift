//
//  DBSCAN.swift
//  MobileCLIPExplore
//
//  Created by SSUM on 7/24/25.
//
import Foundation

class DBSCAN<T:Hashable> {
    
    var db:[T]
    var label:[T:String]
    
    init(aDB:[T])  {
        
        db = aDB
        label = [T:String]()
        for P in db {
            self.label[P] = "undefined"
        }
    }
    
    func DBSCAN(distFunc:(T,T)->Double, eps:Double, minPts:Int) {
        
        var C = 0
        for P in self.db {
            
            if self.label[P] != "undefined" {
                continue
            }
            
            var N = self.rangeQuery(distFunc: distFunc, Q: P, eps: eps)
            
            if N.count < minPts  {
                
                self.label[P] = "Noise"
                continue
            }
            
            C = C + 1
            self.label[P] = "\(C)"
            
            var seedSet = N // Use a separate set for exploration
            
            var index = 0
            while index < seedSet.count {
                let Q = seedSet[index]
                index += 1
                
                if self.label[Q] == "Noise" {
                    self.label[Q] = "\(C)"
                }
                
                if self.label[Q] != "undefined" {
                    continue
                }
                
                label[Q] = "\(C)"
                let N1 = self.rangeQuery(distFunc: distFunc, Q: Q, eps: eps)
                if N1.count >= minPts  {
                    // Add only new points to the seed set to avoid redundant checks
                    for point in N1 {
                        if self.label[point] == "undefined" || self.label[point] == "Noise" {
                            if !seedSet.contains(where: { $0 == point }) {
                                seedSet.append(point)
                            }
                        }
                    }
                }
            }
        }
    }
    
    func rangeQuery(distFunc:(T,T)->Double, Q:T, eps:Double)->[T] {
        
        var Neighbors = [T]()
        for P in self.db {
            if distFunc(Q, P) <= eps {
                Neighbors.append(P)
            }
        }
        return Neighbors
    }
}
