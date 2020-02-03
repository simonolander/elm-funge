#### Setters like getters
Something like `=field` End up writing `\ value record -> { record | field = value }` a lot.

#### Support for cyclic import dependencies
You end up separating files unnecessarily

#### Nested assignment in records
Something like 
`{ (expression that produces record) | field.subfield = value }` would be super nice. 

#### Extend record with new field
```elm
record1 =
    { field1 = 1 }

record2 =
    { record1 | field2 = 2} -- Error: Record does not have field 'field2' 
```
