//
//  MemoryRefDB.c
//  SwiftSpace
//
//  Created by Taha Bebek on 1/7/25.
//

#include <git2.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>   // For fprintf()

#ifndef GIT_ENOMEM
#define GIT_ENOMEM -1
#define GIT_ENOTFOUND -3
#define GIT_EEXISTS -4
#define GIT_ENOTIMPLEMENTED -2
#define GIT_REFDB_BACKEND_VERSION 1
#endif

/*
 Some good prime numbers for different sizes:

 Small: 61, 127, 251
 Medium: 1223, 2459, 4919
 Large: 9973, 20011, 40009
 */
#define HASH_TABLE_SIZE 1223  // Size of hash table, can adjust as needed

typedef struct memory_ref {
    char *name;         // ref name (e.g. "refs/heads/main")
    git_oid target;     // commit ID
    char *symbolic_target; // Target name for symbolic references (e.g., HEAD)
    git_reference_t type; // Reference type (GIT_REFERENCE_DIRECT or GIT_REFERENCE_SYMBOLIC)
    struct memory_ref *next;  // for hash collision handling
} memory_ref;

typedef struct {
    git_refdb_backend parent;
    git_repository *repo;
    memory_ref *refs[HASH_TABLE_SIZE];  // hash table of refs
} memory_refdb_backend;

// Simple hash function for strings
static unsigned int hash(const char *str) {
    unsigned int hash = 0;
    while (*str) {
        hash = (hash * 31) + *str++;
    }
    return hash % HASH_TABLE_SIZE;
}

static int memory_ref_exists(int *exists, git_refdb_backend *backend, const char *ref_name) {
    memory_refdb_backend *b = (memory_refdb_backend *)backend;
    unsigned int h = hash(ref_name);
    memory_ref *ref = b->refs[h];

    *exists = 0;
    while (ref) {
        if (strcmp(ref->name, ref_name) == 0) {
            *exists = 1;
            break;
        }
        ref = ref->next;
    }
    return 0;  // success
}

static int memory_ref_lookup(git_reference **out, git_refdb_backend *backend, const char *ref_name) {
    memory_refdb_backend *b = (memory_refdb_backend *)backend;
    unsigned int h = hash(ref_name);
    memory_ref *ref = b->refs[h];

    while (ref) {
        if (strcmp(ref->name, ref_name) == 0) {
            if (ref->type == GIT_REFERENCE_DIRECT) {
                *out = git_reference__alloc(ref_name, &ref->target, NULL);
            } else if (ref->type == GIT_REFERENCE_SYMBOLIC) {
                *out = git_reference__alloc_symbolic(ref_name, ref->symbolic_target);
            }
            return (*out != NULL) ? 0 : GIT_ENOMEM;
        }
        ref = ref->next;
    }
    return GIT_ENOTFOUND; // Reference not found
}

static int memory_ref_write(git_refdb_backend *backend, const git_reference *ref, int force,
                            const git_signature *who, const char *message,
                            const git_oid *old_id, const char *old_target) {
    // Validate input parameters
    if (!backend || !ref) {
        return GIT_EINVALIDSPEC;
    }

    memory_refdb_backend *b = (memory_refdb_backend *)backend;
    const char *ref_name = git_reference_name(ref);

    // Validate reference name
    if (ref_name == NULL) {
        return GIT_EINVALIDSPEC;
    }

    // Determine reference type
    git_reference_t ref_type = git_reference_type(ref);

    if (ref_type == GIT_REFERENCE_DIRECT) {
        const git_oid *target = git_reference_target(ref);

        // Explicitly check for NULL target
        if (target == NULL) {
            // Use stderr for error logging
            fprintf(stderr, "Error: Null target for direct reference %s\n", ref_name);
            return GIT_EINVALIDSPEC;
        }

        unsigned int h = hash(ref_name);

        // Check if ref exists
        memory_ref *current = b->refs[h];
        while (current) {
            if (strcmp(current->name, ref_name) == 0) {
                if (!force) return GIT_EEXISTS;
                // Update existing ref
                git_oid_cpy(&current->target, target);
                return 0;
            }
            current = current->next;
        }

        // Create new ref
        memory_ref *new_ref = calloc(1, sizeof(memory_ref));
        if (!new_ref) return GIT_ENOMEM;

        new_ref->name = strdup(ref_name);
        if (!new_ref->name) {
            free(new_ref);
            return GIT_ENOMEM;
        }

        // Safely copy the target OID
        git_oid_cpy(&new_ref->target, target);
        new_ref->type = GIT_REFERENCE_DIRECT;
        
        // Add to hash table (front of the bucket)
        new_ref->next = b->refs[h];
        b->refs[h] = new_ref;

        return 0;
    }
    else if (ref_type == GIT_REFERENCE_SYMBOLIC) {
        const char *symbolic_target = git_reference_symbolic_target(ref);

        if (!symbolic_target) {
            fprintf(stderr, "Error: Null target for symbolic reference %s\n", ref_name);
            return GIT_EINVALIDSPEC;
        }

        unsigned int h = hash(ref_name);

        // Check if the reference already exists
        memory_ref *current = b->refs[h];
        while (current) {
            if (strcmp(current->name, ref_name) == 0) {
                if (!force) return GIT_EEXISTS;
                // Update existing symbolic ref
                free(current->symbolic_target);
                current->symbolic_target = strdup(symbolic_target);
                current->type = GIT_REFERENCE_SYMBOLIC;
                return 0;
            }
            current = current->next;
        }

        // Create a new symbolic reference
        memory_ref *new_ref = calloc(1, sizeof(memory_ref));
        if (!new_ref) return GIT_ENOMEM;

        new_ref->name = strdup(ref_name);
        new_ref->symbolic_target = strdup(symbolic_target);
        if (!new_ref->name || !new_ref->symbolic_target) {
            free(new_ref->name);
            free(new_ref->symbolic_target);
            free(new_ref);
            return GIT_ENOMEM;
        }

        new_ref->type = GIT_REFERENCE_SYMBOLIC;

        // Add to hash table
        new_ref->next = b->refs[h];
        b->refs[h] = new_ref;

        return 0;
    }
    else {
        fprintf(stderr, "Unknown reference type for %s\n", ref_name);
        return GIT_EINVALIDSPEC;
    }
}

typedef struct {
    git_reference_iterator parent;
    memory_refdb_backend *backend;
    size_t current_bucket;
    memory_ref *current_ref;
} memory_ref_iterator_t;

static int memory_ref_iterator_next(git_reference **ref, git_reference_iterator *_iter) {
    memory_ref_iterator_t *iter = (memory_ref_iterator_t *)_iter;

    // If we have a current ref, try next in linked list
    if (iter->current_ref && iter->current_ref->next) {
        iter->current_ref = iter->current_ref->next;
        return git_reference_create(ref, iter->backend->repo, iter->current_ref->name,
                                    &iter->current_ref->target, 0, NULL);
    }

    // Otherwise, find next non-empty bucket
    while (++iter->current_bucket < HASH_TABLE_SIZE) {
        if (iter->backend->refs[iter->current_bucket]) {
            iter->current_ref = iter->backend->refs[iter->current_bucket];
            return git_reference_create(ref, iter->backend->repo, iter->current_ref->name,
                                        &iter->current_ref->target, 0, NULL);
        }
    }

    // No more refs
    *ref = NULL;
    return GIT_ERROR;
}

static int memory_ref_iterator_next_name(const char **ref_name, git_reference_iterator *_iter) {
    memory_ref_iterator_t *iter = (memory_ref_iterator_t *)_iter;

    // If we have a current ref, try next in linked list
    if (iter->current_ref && iter->current_ref->next) {
        iter->current_ref = iter->current_ref->next;
        *ref_name = iter->current_ref->name;
        return 0;
    }

    // Otherwise, find next non-empty bucket
    while (++iter->current_bucket < HASH_TABLE_SIZE) {
        if (iter->backend->refs[iter->current_bucket]) {
            iter->current_ref = iter->backend->refs[iter->current_bucket];
            *ref_name = iter->current_ref->name;
            return 0;
        }
    }

    // No more refs
    *ref_name = NULL;
    return GIT_ERROR;
}

static void memory_ref_iterator_free(git_reference_iterator *_iter) {
    memory_ref_iterator_t *iter = (memory_ref_iterator_t *)_iter;
    free(iter);
}

// Now implement the iterator creation function
static int memory_ref_iterator(git_reference_iterator **iter,
                               git_refdb_backend *backend,
                               const char *glob) {
    memory_refdb_backend *b = (memory_refdb_backend *)backend;
    memory_ref_iterator_t *it = calloc(1, sizeof(memory_ref_iterator_t));
    if (!it) return GIT_ERROR;

    it->backend = b;
    it->current_bucket = -1;
    it->current_ref = NULL;

    it->parent.next = &memory_ref_iterator_next;
    it->parent.next_name = &memory_ref_iterator_next_name;
    it->parent.free = &memory_ref_iterator_free;

    *iter = (git_reference_iterator *)it;
    return 0;
}

static void memory_ref_free(git_refdb_backend *backend) {
    memory_refdb_backend *b = (memory_refdb_backend *)backend;

    // Free all refs in all buckets
    for (int i = 0; i < HASH_TABLE_SIZE; i++) {
        memory_ref *ref = b->refs[i];
        while (ref) {
            memory_ref *next = ref->next;
            free(ref->name);
            free(ref);
            ref = next;
        }
    }
    free(b);
}

static int memory_ref_rename(git_reference **out, git_refdb_backend *backend,
                             const char *old_name, const char *new_name,
                             int force, const git_signature *who,
                             const char *message) {
    memory_refdb_backend *b = (memory_refdb_backend *)backend;
    unsigned int old_h = hash(old_name);
    unsigned int new_h = hash(new_name);
    memory_ref *ref = b->refs[old_h];
    memory_ref *prev = NULL;

    // First check if new name already exists
    if (!force) {
        memory_ref *existing = b->refs[new_h];
        while (existing) {
            if (strcmp(existing->name, new_name) == 0) {
                return GIT_EEXISTS;
            }
            existing = existing->next;
        }
    }

    // Find the old reference
    while (ref) {
        if (strcmp(ref->name, old_name) == 0) {
            // Remove from old bucket
            if (prev)
                prev->next = ref->next;
            else
                b->refs[old_h] = ref->next;

            // Update name
            free(ref->name);
            ref->name = strdup(new_name);
            if (!ref->name) {
                free(ref);
                return GIT_ENOMEM;
            }

            // Add to new bucket
            ref->next = b->refs[new_h];
            b->refs[new_h] = ref;

            // Create new reference object for output
            return git_reference_create(out, NULL, new_name, &ref->target, 0, NULL);
        }
        prev = ref;
        ref = ref->next;
    }

    return GIT_ENOTFOUND;
}

static int memory_ref_delete(git_refdb_backend *_backend, const char *ref_name,
                             const git_oid *old_id, const char *old_target) {
    memory_refdb_backend *b = (memory_refdb_backend *)_backend;
    unsigned int h = hash(ref_name);
    memory_ref *ref = b->refs[h];
    memory_ref *prev = NULL;

    while (ref) {
        if (strcmp(ref->name, ref_name) == 0) {
            // Validate `old_id` for direct references
            if (ref->type == GIT_REFERENCE_DIRECT && old_id &&
                !git_oid_equal(&ref->target, old_id)) {
                return GIT_EMODIFIED;
            }

            // Validate `old_target` for symbolic references
            if (ref->type == GIT_REFERENCE_SYMBOLIC && old_target &&
                strcmp(ref->symbolic_target, old_target) != 0) {
                return GIT_EMODIFIED;
            }

            // Remove the reference from the hash table
            if (prev) {
                prev->next = ref->next;
            } else {
                b->refs[h] = ref->next;
            }

            // Free memory for the deleted reference
            free(ref->name);
            if (ref->type == GIT_REFERENCE_SYMBOLIC) {
                free(ref->symbolic_target);
            }
            free(ref);

            return 0; // Success
        }
        prev = ref;
        ref = ref->next;
    }

    return GIT_ENOTFOUND; // Reference not found
}


static int memory_ref_compress(git_refdb_backend *_backend) {
    // No real need to compress in-memory structures
    return 0;
}

static int memory_ref_has_log(git_refdb_backend *_backend, const char *refname) {
    // We don't support reflogs, so always return 0 (no log exists)
    return 0;
}

static int memory_ref_ensure_log(git_refdb_backend *_backend, const char *refname) {
    // We don't support reflogs, but return success since no log is "ensured"
    return 0;
}

static int memory_ref_del(git_refdb_backend *backend,
                          const char *ref_name,
                          const git_oid *old_id,
                          const char *old_target) {
    // This is just an alias for delete
    return memory_ref_delete(backend, ref_name, old_id, old_target);
}

static int reflog_read(git_reflog **out, git_refdb_backend *backend, const char *name) {
    // Since this is memory-only, we don't maintain reflogs
    return GIT_ENOTFOUND;
}

static int reflog_write(git_refdb_backend *backend, git_reflog *reflog) {
    // Memory-only implementation doesn't persist reflogs
    return 0;  // Return success but don't actually write
}

static int reflog_rename(git_refdb_backend *_backend, const char *old_name, const char *new_name) {
    // Memory-only implementation doesn't maintain reflogs
    return 0;  // Return success but don't actually rename
}

static int reflog_delete(git_refdb_backend *backend, const char *name) {
    // Memory-only implementation doesn't maintain reflogs
    return 0;  // Return success but don't actually delete
}

int create_memory_refdb(git_repository *repo, git_refdb_backend **backend_out) {
    memory_refdb_backend *backend = calloc(1, sizeof(memory_refdb_backend));
    if (!backend) return -1;

    backend->parent.version = GIT_REFDB_BACKEND_VERSION;
    backend->parent.exists = &memory_ref_exists;
    backend->parent.lookup = &memory_ref_lookup;
    backend->parent.iterator = &memory_ref_iterator;
    backend->parent.write = &memory_ref_write;
    backend->parent.free = &memory_ref_free;
    backend->parent.rename = &memory_ref_rename;
    backend->parent.del = &memory_ref_delete;
    backend->parent.compress = &memory_ref_compress;
    backend->parent.has_log = &memory_ref_has_log;
    backend->parent.ensure_log = &memory_ref_ensure_log;
    backend->parent.del = &memory_ref_del;
    backend->parent.reflog_read = &reflog_read;
    backend->parent.reflog_write = &reflog_write;
    backend->parent.reflog_rename = &reflog_rename;
    backend->parent.reflog_delete = &reflog_delete;
    backend->repo = repo;

    *backend_out = (git_refdb_backend *)backend;
    return 0;
}
