module Environment exposing (Environment(..), environment)


type Environment
    = Local
    | Production


environment : Environment
environment =
    Production
