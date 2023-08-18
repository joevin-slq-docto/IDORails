# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# Examples:
#
#   movies = Movie.create([{ name: "Star Wars" }, { name: "Lord of the Rings" }])
#   Character.create(name: "Luke", movie: movies.first)
user = User.create! :email => 'first@user.fr', :password => 'secret', :password_confirmation => 'secret'
user = User.create! :email => 'second@user.fr', :password => 'secret', :password_confirmation => 'secret'

10.times do |i|
  Article.create({title: "Post #{i + 1}", body: 'test body', user_id: i < 5 ? 1 : 2})
end
