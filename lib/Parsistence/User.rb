module Parsistence
  module User
    include ::Parsistence::Model

    attr_accessor :PFUser
    
    RESERVED_KEYS = [:objectId, :username, :password, :email]

    def PFObject=(value)
      @PFObject = value
      @PFUser = @PFObject
    end
    
    def PFUser=(value)
      self.PFObject = value
    end

    module ClassMethods    
      def all
        query = PFQuery.queryForUser
        users = query.findObjects
        users
      end
    end

    def self.included(base)
      base.extend(ClassMethods)
    end
  end
end
