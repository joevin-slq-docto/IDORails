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
    true # IDOR here
    # @article.user_id == @user.id
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