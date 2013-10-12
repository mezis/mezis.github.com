---
layout: post
title: Service layer 101, a Rails example
published: true
tags: good_pratice ruby rails
summary:  |
  OO in Rails doesn't have to suck.

  Whenever your model and controllers start doing more than persistence,
  associations and validations, or (respectively) acting directly on models,
  it's time to trim the proverbial fat.

  Here's a concret example on thining a model and a controller with a few
  additional "service" classes.
---




Brian Helmkamp of Code Climate fame
[blogged](http://blog.codeclimate.com/blog/2012/10/17/7-ways-to-decompose-
fat-activerecord-models/) brilliantly about a few ways to thin down your fat
model & controller code.

This is a slightly more detailed use case of the second point in his
article, _Extract service objects_, encountered in a real application:
[Appfab.io](http://appfab.io).

Appfab intro

# initial situation

EA diagram: login/user/account

<figure class="dm-schematic">
  <img src="/public/entities.svg"/>
  <figcaption></figcaption>
</figure>

code from authentication + signup controller

{% highlight ruby %}
class OmniauthCallbacksController < ApplicationController
  def google_oauth2
    auth_hash = request.env['omniauth.auth']
    login = Login.find_or_create_from_auth_hash!(auth_hash)
    sign_in login
    flash[:success] = "Welcome, #{user}!"
    redirect_to dashboard_path
  end
end
{% endhighlight %}

code from user.rb for adoptions
  uses callbacks

{% highlight ruby %}
class Login < ActiveRecord::Base
  devise :database_authenticatable, :omniauthable

  has_many :users
  has_many :accounts, through: :users

  after_save :adopt_account

  def self.find_or_create_from_auth_hash!(auth_hash)
    user = self.where(
      email:    auth_hash[:email],
      provider: auth_hash[:provider]
    ).first
    return user if user.present?

    new.tap do |user|
      user.email    = auth_hash[:info][:email]
      user.provider = auth_hash[:provider]
      user.save!
    end
  end

  private

  def adopt_account
    domain = /@(?<domain>.*)$/.match(self.email).andand[:domain]
    
    account = Account.where(domain:domain, auto_adopt:true).first
    return if account.nil? || accounts.include?(account)

    self.users.create! account:account
  end
end
{% endhighlight %}


# problem : invitations

code for invitations

`InvitationController#create`

{% highlight ruby %}
def create
  authorize! :invite, nil

  login = Login.where(email:@login.email).first
  invitee = Login.new params[:login].slice(:email, :first_name, :last_name)

  login = Login.create!(...) if login.nil?

  if login.accounts.include?(@inviter.account)
    @already_invited = true
    return
  end

  new_user = login.users.create!(account: current_user.account)
  InvitationMailer.invitation(inviter:current_user, user:new_user).deliver
end  
{% endhighlight %}


and have it create a `Login` if necessary, create a `User` if necessary, 

may create logins
new logins get automatically adopted by accounts, on the fly

failed cannot detect if they're actually new logins, and should be sent an email

# solution: introduce a login service

code outline from login service

new code in auth controller
code removed from user.rb

# follow-up: invitation service

slim down the `InvitationController`

i want to be able to write

{% highlight ruby %}
UserInvitationService.new(inviter, "alice@example.com").run
{% endhighlight %}
