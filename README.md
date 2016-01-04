# polymorphic-crud-resource

[![Codeship Status for digitalairwaystv/da-web-backend](https://codeship.com/projects/9d947f10-5ca1-0132-ef81-1a777663c9d2/status?branch=master)](https://codeship.com/projects/50902)

Express resource that is able to handle polymorphic One2Many assotiations with sequelize.

For example we have a model person, that we want to perform CRUD on.
And we want to internationalize its attribute description to retrieve this:

```
...
"description": [
  {"lang": "cz", "value": "CZTrolol"}
  {"lang": "en", "value": "ENTrolol"}
]
```

So we have to have model translats with joining attributes.
Then we create CRUD like this:

```
app = express()
personsCRUD = CRUD sequelize.models.person, [
  name: 'description'
  model: sequelize.models.translats
  fk: 'entity_id'
  defaults: entity_type: 0  # polymorphic ID
]
# mount it to express app
personsCRUD.initApp(app)
```

# app middlewares

You can specify for each operation an array of middlewares when doing initApp:

```
authMWare = expressJwt(secret: process.env.SERVER_SECRET)

personsCRUD.initApp app,
  'create': [authMWare]
  'update': [authMWare]
  'delete': [authMWare]
```
