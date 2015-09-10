module Postoffice
	class Mail
		include Mongoid::Document
		include Mongoid::Timestamps

		extend Dragonfly::Model
		dragonfly_accessor :image
		dragonfly_accessor :thumbnail

		belongs_to :person, foreign_key: :from_person_id
		embeds_many :recipients


		# These fields are going to be migrated, then deleted
		field :from, type: String
		field :to, type: String
		field :content, type: String
		field :image_uid, type: String
		field :thumbnail_uid

		field :type, type: String, default: "STANDARD"
		field :scheduled_to_arrive, type: DateTime

		# Options include DRAFT, SENT, DELIVERED
		field :status, type: String, default: "DRAFT"
		field :date_sent, type: DateTime
		field :date_delivered, type: DateTime

		# field :delivery_options, type: Array, default: ["SLOWPOST"]

		# attachments: [
		# 	{
		# 		id: objectId,
		# 		type: "TEXT",
		# 		content: "blah"
		# 	}
		# 	{
		# 		id: objectId,
		# 		type: "IMAGE",
		# 		image_uid: "xxxx"
		# 	}
		# ]

		def days_to_arrive
			(1..2).to_a.sample
		end

		def arrive_when
			Time.now + days_to_arrive * 86400
		end

		def mail_it
			raise ArgumentError, "Mail must be in DRAFT state to send" unless self.status == "DRAFT"
			self.status = "SENT"
			self.date_sent = Time.now
			unless self.scheduled_to_arrive?
				self.scheduled_to_arrive = arrive_when
			end
			self.save
		end

		def deliver
			raise ArgumentError, "Mail must be in SENT state to deliver" unless self.status == "SENT"
			self.status = "DELIVERED"
			self.date_delivered = Time.now
			self.save
		end

		# def update_delivery_status
		# 	if self.scheduled_to_arrive && self.scheduled_to_arrive <= Time.now && self.status == "SENT"
		# 		self.status = "DELIVERED"
		# 		self.save
		# 	end
		# end

		# def read
		# 	raise ArgumentError, "Mail must be in DELIVERED state to read" unless self.status == "DELIVERED"
		# 	self.status = "READ"
		# 	self.save
		# end

	end

end
