# README

This README will you make able to rebuild this application by taking this tutorial.

One IDOR has been left on `articles#show`.

## Create a basic application

```
rails new idorails
cd idorails

bin/rails generate controller Articles index --skip-routes
bin/rails generate model Article title:string body:text

bin/rails db:migrate

# append in config/routes.rb
Rails.application.routes.draw do
  root "articles#index"

  resources :articles
end

# append in app/controllers/articles_controller.rb
class ArticlesController < ApplicationController
  def index
    @articles = Article.all
  end

  def show
    @article = Article.find(params[:id])
  end

  def new
    @article = Article.new
  end

  def create
    @article = Article.new(article_params)

    if @article.save
      redirect_to @article
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    @article = Article.find(params[:id])
  end

  def update
    @article = Article.find(params[:id])

    if @article.update(article_params)
      redirect_to @article
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @article = Article.find(params[:id])
    @article.destroy

    redirect_to root_path, status: :see_other
  end

  private
    def article_params
      params.require(:article).permit(:title, :body)
    end
end

# append in app/models/article.rb
class Article < ApplicationRecord
  validates :title, presence: true
  validates :body, presence: true, length: { minimum: 5 }
end

# append in app/views/articles/index.html.erb
<h1>Articles</h1>

<ul>
  <% @articles.each do |article| %>
    <li>
      <%= link_to article.title, article %>
    </li>
  <% end %>
</ul>

<%= link_to "New Article", new_article_path %>

# create file and append in app/views/articles/show.html.erb
<h1><%= @article.title %></h1>

<p><%= @article.body %></p>

<ul>
  <li><%= link_to "Edit", edit_article_path(@article) %></li>
  <li><%= link_to "Destroy", article_path(@article), data: {
                    turbo_method: :delete,
                    turbo_confirm: "Are you sure?"
                  } %></li>
</ul>

# create file and append in app/views/articles/new.html.erb
<h1>New Article</h1>

<%= render "form", article: @article %>

# create file and append in app/views/articles/edit.html.erb
<h1>Edit Article</h1>

<%= render "form", article: @article %>

# create and append in app/views/articles/_form.html.erb
<%= form_with model: article do |form| %>
  <div>
    <%= form.label :title %><br>
    <%= form.text_field :title %>
    <% article.errors.full_messages_for(:title).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.label :body %><br>
    <%= form.text_area :body %><br>
    <% article.errors.full_messages_for(:body).each do |message| %>
      <div><%= message %></div>
    <% end %>
  </div>

  <div>
    <%= form.submit %>
  </div>
<% end %>
```
Execute `bin/rails server` and check that everything works.

## Installing Devise

```
# More info -> https://github.com/heartcombo/devise
bundle add devise

rails generate devise:install
rails generate devise user

bin/rails db:migrate

# append this in app/controllers/articles_controller.rb
before_action :authenticate_user!

# set this in config/initializers/devise.rb
config.sign_out_via = :get

# append this body of app/views/layouts/application.html.erb
  <body>
    <p style="color: green"><%= notice %></p>
    <p style="color: red"><%= alert %></p>
    <hr />
    <div>
      <%= link_to "Home", root_path, :class => 'navbar-link'  %> |
      <% if user_signed_in? %>
        Logged in as <strong><%= current_user.email %></strong>.
        <%= link_to "Logout", destroy_user_session_path, :class => 'navbar-link'  %>
      <% else %>
        <%= link_to "Sign up", new_user_registration_path, :class => 'navbar-link'  %> |
        <%= link_to "Sign in", new_user_session_path, :class => 'navbar-link'  %>
      <% end %>
    </div>
    <hr />
    <%= yield %>
  </body>

# add one-to-many relation between articles and users
rails g migration AddUserRefToArticles user:references
bin/rails db:reset ; bin/rails db:migrate

# modify models/article.rb
belongs_to :user

# modify models/user.rb
has_many :articles

# add in app/controllers/articles_controller.rb#create, after `@article = Article.new(article_params)`:
@article.user = current_user

# add in app/controllers/articles_controller.rb#update, after `@article = Article.find(params[:id])`:
@article.user = current_user
```
Execute `bin/rails server` and check that everything works.

## Installing Pundit

```
# More info -> https://github.com/varvet/pundit
bundle add pundit

# replace app/controllers/application_controller.rb content with this
class ApplicationController < ActionController::Base
  include Pundit::Authorization
  after_action :verify_authorized, except: :index, unless: :devise_controller?
  after_action :verify_policy_scoped, only: :index
  
  rescue_from Pundit::NotAuthorizedError, with: :pundishing_user

  private

  def pundishing_user
    flash[:alert] = "You are not authorized to perform this action."
    redirect_to articles_path
  end
end

# run thoses commands
rails g pundit:install
rails g pundit:policy article

# replace app/policies/application_policy.rb content with this
class ApplicationPolicy
  class Scope
    attr_reader :user, :scope

    def initialize(user, scope)
      @user = user
      @scope = scope
    end
  end
end

# replace app/policies/article_policy.rb content with this
class ArticlePolicy < ApplicationPolicy
  attr_reader :user, :article

  def initialize(user, article)
    @user = user
    @article = article
  end

  def index?
    true
  end

  def show?
    true # @article.user_id == @user.id
  end

  def create?
    true
  end

  def new?
    create?
  end

  def update?
    @article.user_id == @user.id
  end

  def edit?
    update?
  end

  def destroy?
    @article.user_id == @user.id
  end

  class Scope < Scope
    def resolve
      scope.where(articles: {user_id: user.id})
    end
  end
end

# inside app/controllers/articles_controller.rb#index, replace '@articles = Article.all' by:
@articles = policy_scope(Article)
# inside app/controllers/articles_controller.rb, for show, new, create, edit, update and destroy methods, append:
authorize @article


# append this in db/seeds.rb
user = User.create! :email => 'first@user.fr', :password => 'secret', :password_confirmation => 'secret'
user = User.create! :email => 'second@user.fr', :password => 'secret', :password_confirmation => 'secret'

10.times do |i|
  Article.create({title: "Post #{i + 1}", body: 'test body', user_id: i < 5 ? 1 : 2})
end

# run this
bin/rails db:reset
```
Execute `bin/rails server` and check that everything works.
