# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

states = [
  { name: "Claimed",    configurable: false,  level: "activity" },
  { name: "Verified",   configurable: false,  level: "activity" },
  { name: "Validated",  configurable: false,  level: "activity" },
  { name: "Max. Score", configurable: true,   level: "activity" },
  { name: "Tarif",      configurable: true,   level: "activity" },
  { name: "Budget",     configurable: true,   level: "package"  },
  { name: "Remoteness Bonus", configurable: false,   level: "package"  },
  { name: "Applicable Points", configurable: false,   level: "activity" },
]

states.each do |state|
  state_record = State.find_or_create_by(name: state[:name])
  state_record.update_attributes(state)
end
