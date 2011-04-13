require "rubygems"
gem "actionpack"
gem "actionmailer"
gem "activesupport"
require "active_support"
require "action_pack"
require "action_mailer"
require 'smtp_tls'
require 'action_mailer_tls'

class Emailer < ActionMailer::Base
	def email(h)
		recipients   h[:recipients]
		subject      h[:subject]
		from         h[:from]
		body         h[:body]
		content_type "text/html"
	end
	

end

