//
//  Xferro-Bridging-Header.h
//  Xferro
//
//  Created by Taha Bebek on 1/9/25.
//

#ifndef Xferro_Bridging_Header_h
#define Xferro_Bridging_Header_h


#endif /* Xferro_Bridging_Header_h */
#import <git2.h>
#import "XTQueueUtils.h"

int create_memory_refdb(git_repository *repo, git_refdb_backend **backend_out);
