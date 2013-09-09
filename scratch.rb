  require_relative 'lib/command_post.rb'

  require 'securerandom'
  require 'json-schema'
  require 'pp'
  require 'json'
  require 'date'
  require 'money'     


  $DB['delete from aggregates'].delete
  $DB['delete from aggregate_events'].delete
  $DB['delete from aggregate_index_decimals'].delete
  $DB['delete from aggregate_index_integers'].delete
  $DB['delete from aggregate_index_strings'].delete

  # class Employer  < CommandPost::Persistence 
  #   include CommandPost::Identity

  #   def initialize
  #     super
  #   end

  #   def self.schema 
  #     {
  #       title: "Employer",
  #       required: ["employer_name", "address", "employer_number" ],
  #       type:  "object",
  #       properties: 
  #       {
  #         employer_number:  { type:  "integer"},
  #         employer_name:    { type:  "string" },
  #         address:          { type:  "string" }
  #       }
  #     }
  #   end

  #   def self.indexes
  #     [:employer_number]
  #   end
  # end

    class ParticipationAgreement  < CommandPost::Persistence 
      include CommandPost::Identity

      def initialize
        super
      end

      def self.schema 
        {
          title: "ParticipationAgreement",
          type:  "object",
          required: ["employer_aggregate_id", "effective_date", "expiration_date", "plans" ],
          properties: 
          {
            employer_aggregate_id:  { type:  "integer"  },
            effective_date:         { type:  "string",  class: "Date"  },
            expiration_date:        { type:  "string",  class: "Date"  },
            plans:                  
            { 
              type:  "array",   
              class: "ParticipationAgreementPlan", 
              properties: 
              {
                type:  "object",
                required: ["id", "effective_date", "expiration_date", "tier_type", "plan", "rates" ],
                properties:
                {   
                  id:              { type:  "string",  class: "UUID"  },
                  effective_date:  { type:  "string",  class: "Date"  },
                  expiration_date: { type:  "string",  class: "Date"  },
                  tier_type:       { type:  "string" },
                  plan:            { type:  "string" },
                  rates:           
                  { 
                    type:         "array",   
                    class:        "ParticipationAgreementRate",
                    properties:  
                    {
                      type:  "object",
                      required: ["published_rate?", "rate_type", "rate_amount"],
                      properties:   
                      {
                        published_rate?:    { type:  "boolean"},
                        rate_type:          { type:  "string"},
                        rate_amount:        { type:  "number", class: "Money" }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      end

      def self.indexes 
        [:employer_aggregate_id]
      end


      def plan_in_effect date
        HashWrapper.new plans.select{|x| date >= x[:effective_date] and date <= x[:expiration_date]}.first
      end

 

    end 
  
    data = 
     {
      employer_aggregate_id:    900,
      effective_date:    Date.new(2012-4-1),
      expiration_date:   Date.new(2014-3-31),
      expiration_date:   Date.new(2015-3-31),
      plans:             
      [
         { 
          id: SecureRandom.uuid,
          effective_date: Date.new(2012-4-1), 
          expiration_date: Date.new(2013-3-31),
          tier_type: :three_tier, 
          plan: '100', 
          rates:
          [
            { published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(13000).to_f },  
            { published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(17000).to_f },  
            { published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(21000).to_f }, 
          ]
         },
         { 
          id: SecureRandom.uuid,
          effective_date: Date.new(2013-4-1), 
          expiration_date: Date.new(2014-3-31),
          tier_type: :three_tier, 
          plan: '100', 
          rates:
          [
            { published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(13000).to_f },  
            { published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(17000).to_f },  
            { published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(21000).to_f } 
          ]
         },
         { 
          id: SecureRandom.uuid,
          effective_date: Date.new(2013-4-1), 
          expiration_date: Date.new(2014-3-31),
          tier_type: :three_tier, 
          plan: '100', 
          rates:
          [
            { published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(13000).to_f },  
            { published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(17000).to_f },  
            { published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(21000).to_f } 
          ]
         }
      ]
     }


   #  puts " valid? #{JSON::Validator.validate(JSON.generate(ParticipationAgreement.schema), JSON.generate(data))}   "
   #  pa = ParticipationAgreement.load_from_hash data 

   #  pp pa.to_h

   #  ParticipationAgreement.put pa, 'new agreement', 'joe'
   #  load './scratch.rb'






  # class EmployerParticipationAgreements

  #   def initialize employer_aggregate_id
  #     @agreements = ParticipationAgreement.employer_aggregate_id_eq(employer_aggregate_id)
  #   end

  #   def current_agreement
  #     @agreements.select {|x| (Date.today >= x.effective_date) && (Date.today <= x.expiration_date) }.first
  #   end

  #   def current_plan 
  #     current_agreement.plans.each {|x| (Date.today >= x.effective_date) && (Date.today <= x.expiration_date ) }.first
  #   end
  # end




  # employer = Employer.load_from_hash({ :employer_number => 3000, :employer_name => 'abc co', :address => '2700 Trumbull'})
  # Employer.put employer, 'added new employer to system', 'user_id'
              


  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(11000).to_f })
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(15000).to_f })
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(19000).to_f })
  # plan1 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date: Date.new(2008,4,1), expiration_date:  Date.new(2009,3,31), tier_type: 'three_tier', plan:  "274", rates:   [rate1,rate2,rate3] })


  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(12000).to_f } )
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(16000).to_f } )
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(22000).to_f } )
  # plan2 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date:   Date.new(2009,4,1), expiration_date:  Date.new(2010,3,31), tier_type:  'three_tier', plan:   "274", rates: [rate1,rate2,rate3] })


  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(13000).to_f }   )
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(17000).to_f }   )
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(21000).to_f }   )
  # plan3 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date:  Date.new(2010,4,1), expiration_date:  Date.new(2011,9,30), tier_type:  'three_tier', plan:   "171", rates: [rate1,rate2,rate3] })


  # pa1 = ParticipationAgreement.load_from_hash({ employer_aggregate_id: employer.aggregate_id, effective_date:  Date.new(2008,4,1), expiration_date: Date.new(2011,9,30), plans: [plan1,plan2,plan3]})




  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(21000).to_f })
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(25000).to_f })
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(29000).to_f })
  # plan1 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date: Date.new(2008,4,1), expiration_date:  Date.new(2009,3,31), tier_type: 'three_tier', plan:  "100", rates:   [rate1,rate2,rate3] })


  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(22000).to_f } )
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(26000).to_f } )
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(30000).to_f } )
  # plan2 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date:   Date.new(2009,4,1), expiration_date:  Date.new(2010,3,31), tier_type:  'three_tier', plan:   "100", rates: [rate1,rate2,rate3] })


  # rate1 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'single', rate_amount: Money.new(23000).to_f }   )
  # rate2 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'middle', rate_amount: Money.new(26000).to_f }   )
  # rate3 = ParticipationAgreementRate.load_from_hash({ published_rate?: 'true', rate_type: 'family', rate_amount: Money.new(31000).to_f }   )
  # plan3 = ParticipationAgreementPlan.load_from_hash({id: SecureRandom.uuid, effective_date:  Date.new(2010,4,1), expiration_date:  Date.new(2011,9,30), tier_type:  'three_tier', plan:   "100", rates: [rate1,rate2,rate3] })


  # pa2 = ParticipationAgreement.load_from_hash({ employer_aggregate_id: employer.aggregate_id, effective_date:  Date.new(2008,4,1), expiration_date: Date.new(2011,9,30), plans: [plan1,plan2,plan3] } )


  # ParticipationAgreement.put pa1, 'Added new PA', 'smithmr'
  # ParticipationAgreement.put pa2, 'Added new PA', 'smithmr'
    



  # employer = Employer.employer_number_eq(3000).first
  

  # pa = ParticipationAgreement.find(63444167)

  # puts pa.plans.first.plan 
  
  # employer_agreements = EmployerParticipationAgreements.new employer.aggregate_id




  



    








      