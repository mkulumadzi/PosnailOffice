module SnailMail

	class MailService

		def self.create_mail person_id, data
			person = SnailMail::Person.find(person_id)

		    mail = SnailMail::Mail.create!({
		      from: person.username,
		      to: data["to"],
		      content: data["content"]
		    })
		end

		def self.get_mail params = {}
			mails = []
			SnailMail::Mail.where(params).each do |mail|
				mails << mail.as_document
			end
			mails
		end

		def self.mailbox params
			username = SnailMail::Person.find(params[:id]).username
			mails = []

			SnailMail::Mail.where({to: username, scheduled_to_arrive: { "$lte" => Time.now } }).each do |mail|
				mails << mail.as_document
			end

			mails
		end

	end

end