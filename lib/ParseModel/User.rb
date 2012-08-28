module ParseModel
  module User
    include ParseModel::Model

    attr_accessor :PFUser
    
    RESERVED_KEYS = ['username', 'password', 'email']
    
    def initialize
      @PFUser = PFUser.user
      @PFObject = @PFUser # For compatibility with Model
    end
    
    module ClassMethods    
      def get_fields
        @fields ||= []
        @fields
      end
      
      def all
        query = PFQuery.queryForUser
        users = query.findObjects
        users
      end
    end
  end
end
