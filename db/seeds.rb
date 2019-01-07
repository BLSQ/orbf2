# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: 'Star Wars' }, { name: 'Lord of the Rings' }])
#   Character.create(name: 'Luke', movie: movies.first)

if Scorpio.is_dev?
  program = Program.find_or_create_by(code: "Sierra Leone")
  email = ENV.fetch("DEFAULT_USER_EMAIL", "admin@example.com")
  password = ENV.fetch("DEFAULT_USER_PASSWORD", "12345678")
  program.users.find_or_create_by(email: email) do |user|
    user.password = user.password_confirmation = password
  end
end
