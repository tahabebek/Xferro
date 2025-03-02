//
//  GitEnum.h
//  Xferro
//
//  Created by Taha Bebek on 3/1/25.
//

#import <git2/status.h>
#import <git2/types.h>
#import <Cocoa/Cocoa.h>

typedef NS_ENUM(unsigned int, DeltaStatus)
{
    DeltaStatusUnmodified = GIT_DELTA_UNMODIFIED,
    DeltaStatusAdded = GIT_DELTA_ADDED,
    DeltaStatusDeleted = GIT_DELTA_DELETED,
    DeltaStatusModified = GIT_DELTA_MODIFIED,
    DeltaStatusRenamed = GIT_DELTA_RENAMED,
    DeltaStatusCopied = GIT_DELTA_COPIED,
    DeltaStatusIgnored = GIT_DELTA_IGNORED,
    DeltaStatusUntracked = GIT_DELTA_UNTRACKED,
    DeltaStatusTypeChange = GIT_DELTA_TYPECHANGE,
    DeltaStatusConflict = GIT_DELTA_CONFLICTED,
    DeltaStatusMixed,  // For folders containing a mix of changes
} __attribute__((enum_extensibility(closed)));
