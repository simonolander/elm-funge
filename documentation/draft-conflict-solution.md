local : Result Json.Decode.Error Draft
expected : Maybe (Result Json.Decode.Error Draft)
actual : RemoteData DetailedHttpError Draft

```elm
case actual of 
    Success actualDraft -> 
        case expected
```
