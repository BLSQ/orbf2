# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

states = [
  { name: "Claimed", configurable: false },
  { name: "Verified", configurable: false },
  { name: "Validated", configurable: false },
  { name: "Tarif", configurable: true },
  { name: "Max. Score", configurable: true },
  { name: "Budget", configurable: true }
]

states.each do |state|
  state_record = State.find_or_create_by(name: state[:name])
  state_record.update_attributes(state)
end
