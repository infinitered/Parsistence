module Parsistence
  class Relation
    attr_accessor :PFRelation, :belongs_to, :klass
    
    def initialize(pf_relation)
      self.PFRelation = pf_relation

    end

    def fetch(&block)
      if self.belongs_to
        self.PFRelation.fetchIfNeededInBackgroundWithBlock do |result, error|
          if result
            result = self.klass.new(result)
          end

          block.call(result, error)
        end
      else

      end
    end

    def fetchAll(&block)
      self.fetch(block)
    end
  end
end