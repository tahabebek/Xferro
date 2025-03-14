//
//  GitTransferProgress.swift
//  Xferro
//
//  Created by Taha Bebek on 3/14/25.
//

struct GitTransferProgress: TransferProgress
{
  let gitProgress: git_transfer_progress
  
  var totalObjects: UInt32    { gitProgress.total_objects }
  var indexedObjects: UInt32  { gitProgress.indexed_objects }
  var receivedObjects: UInt32 { gitProgress.received_objects }
  var localObjects: UInt32    { gitProgress.local_objects }
  var totalDeltas: UInt32     { gitProgress.total_deltas }
  var indexedDeltas: UInt32   { gitProgress.indexed_deltas }
  var receivedBytes: Int      { gitProgress.received_bytes }
}
