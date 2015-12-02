
_gen = (attr, name) ->
  return [
    {lang: 'cz', value: "CZ_#{attr}_#{name}"}
    {lang: 'en', value: "EN_#{attr}_#{name}"}
  ]

module.exports = [
  birth_year: 1983
  town: 'Tabor'
  age: 32
  parent_id: 1
  name: _gen('name', 'person1')
  descr: _gen('descr', 'person1')
,
  birth_year: 1991
  town: 'Praha'
  age: 22
  parent_id: 2
  name: _gen('name', 'person2')
  descr: _gen('descr', 'person2')
,
  birth_year: 1988
  town: 'Praha'
  age: 26
  parent_id: 1
  name: _gen('name', 'person3')
  descr: _gen('descr', 'person3')
]
