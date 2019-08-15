# Endpoint responses

### Always
* 200 Ok
* 400 Bad Request
* 403 Forbidden
* 500 Internal Server Error

### Levels

#### GET
* 404 NotFound
#### POST
* 403 Forbidden
    - Not your blueprint

### Solutions
#### GET
* 403 Forbidden
    - Not your solution
* 404 NotFound
#### POST
* 409 ConflictingId
    - Exists solution with same id
* 409 Duplicate
    - You have another solution with same solution

### Drafts
#### GET
* 403 Forbidden
    - Not your draft
* 404 NotFound
#### PUT
* 409 Forbidden
    - Exists draft with same id
#### DELETE
* 403 Forbidden
    - Not your draft
