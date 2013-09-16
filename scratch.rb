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

  class Employer  < CommandPost::Persistence 
    include CommandPost::Identity

    def initialize
      super
    end

    def self.schema 
      {
        title: "Employer",
        required: ["employer_name", "address", "employer_number" ],
        type:  "object",
        properties: 
        {
          employer_number:  { type:  "integer"},
          employer_name:    { type:  "string" },
          address:          { type:  "string" }
        }
      }
    end

    def self.indexes
      [:employer_number]
    end

  end

  data3333 =  { :employer_number => 3333, :employer_name =>'ABC Co', :address => '2700 Trumbull, Detroit, MI' }
  data4444 =  { :employer_number => 4444, :employer_name =>'Sherman Foods', :address => '867 Main Street, Royal Oak, MI' }
  
  Employer.put Employer.load_from_hash(data3333), 'added new employer to system', 'joe'
  Employer.put Employer.load_from_hash(data4444), 'added new employer to system', 'joe'

  class ParticipationAgreement  < CommandPost::Persistence 
    include CommandPost::Identity


    def self.indexes

      [:employer_aggregate_id] 
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
            items: 
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
                  items:  
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

    def initialize

      super
    end


    def self.plan_for_employer_as_of_date   employer , date
      max_expiration_date = self.get_max_agreement_expiration_date_for_employer employer 
      query_date = (date > max_expiration_date) ? max_expiration_date : date 
      ParticipationAgreement.employer_aggregate_id_eq(employer.aggregate_id).first{ |x| x[:effective_date] <= query_date && x[:expiration_date] >= query_date }
    end 


    def self.rate_for_employer_and_type_as_of_date  employer, type, date

      self.plan_for_employer_as_of_date(employer, date)[:rates].select{ |x| x[:rate_type] ==  type }.first[:rate_amount]
    end
    

    def self.get_max_agreement_expiration_date_for_employer employer 

      self.employer_aggregate_id_eq(employer.aggregate_id).sort{|x,y| y.expiration_date <=> x.expiration_date}.first.expiration_date
    end

  end







  Employer.new 
  ParticipationAgreement.new 


  emp3333 = Employer.employer_number_eq(3333).first 
  #  emp4444 = Employer.employer_number_eq(4444).first 

  #pp emp3333

  pa_data_01 = 
    {   employer_aggregate_id: emp3333.aggregate_id,  effective_date: Date.new(2009,4,1),    expiration_date: Date.new(2010,3,31), 
       plans: 
       [

               {    id:  SecureRandom.uuid, effective_date:  Date.new(2009,4,1), expiration_date: Date.new(2010,3,31), tier_type: 'composite', plan: '100', 
                    rates: 
                    [
                      { published_rate?: true, rate_type: 'composite', rate_amount: Money.new(15000).to_f },  
                    ]
               },
               



               {    id: SecureRandom.uuid, effective_date: Date.new(2010,4,1), expiration_date:  Date.new(2011,3,31), tier_type: 'three_tier', plan: '100',
                    rates:
                    [
                      { published_rate?:  true, rate_type: 'single', rate_amount: Money.new(13000).to_f },  
                      { published_rate?:  true, rate_type: 'middle', rate_amount: Money.new(14000).to_f },  
                      { published_rate?:  true, rate_type: 'family', rate_amount: Money.new(18000).to_f } 
                    ]
               },



               {    id: SecureRandom.uuid,    effective_date: Date.new(2011,4,1),  expiration_date:  Date.new(2012,3,31), tier_type: 'three_tier', plan: '100', 
                    rates:
                    [
                      { published_rate?:  true, rate_type: 'single', rate_amount: Money.new(13100).to_f },  
                      { published_rate?:  true, rate_type: 'middle', rate_amount: Money.new(17100).to_f },  
                      { published_rate?:  true, rate_type: 'family', rate_amount: Money.new(18100).to_f } 
                    ]
               }
        ]
    }

  pa_data_02 = 
    {   employer_aggregate_id: emp3333.aggregate_id,  effective_date: Date.new(2012,4,1),    expiration_date: Date.new(2015,3,31), 
       plans: 
       [

               {    id:  SecureRandom.uuid, effective_date:  Date.new(2012,4,1), expiration_date: Date.new(2013,3,31), tier_type: 'three_tier', plan: '100', 
                    rates: 
                    [
                      { published_rate?:  true , rate_type: 'single', rate_amount: Money.new(13200).to_f },  
                      { published_rate?:  true , rate_type: 'middle', rate_amount: Money.new(17200).to_f },  
                      { published_rate?:  true , rate_type: 'family', rate_amount: Money.new(18200).to_f } 
                    ]
               },
               



               {    id: SecureRandom.uuid, effective_date: Date.new(2013,4,1), expiration_date:  Date.new(2014,3,31), tier_type: 'three_tier', plan: '110',
                    rates:
                    [
                      { published_rate?:  true , rate_type: 'single', rate_amount: Money.new(13300).to_f },  
                      { published_rate?:  true , rate_type: 'middle', rate_amount: Money.new(17300).to_f },  
                      { published_rate?:  true , rate_type: 'family', rate_amount: Money.new(18300).to_f } 
                    ]
               },



               {    id: SecureRandom.uuid,    effective_date: Date.new(2014,4,1),  expiration_date:  Date.new(2015,3,31), tier_type: 'four_tier', plan: '110', 
                    rates:
                    [
                      { published_rate?:  true, rate_type: 'single', rate_amount: Money.new(13400).to_f },  
                      { published_rate?:  true, rate_type: 'participant_plus_spouse', rate_amount: Money.new(15400).to_f },  
                      { published_rate?:  true, rate_type: 'participant_plus_children', rate_amount: Money.new(17400).to_f },  
                      { published_rate?:  true, rate_type: 'family', rate_amount: Money.new(18400).to_f } 
                    ]
               }
        ]
    }

  ParticipationAgreement.put  ParticipationAgreement.load_from_hash(pa_data_01), 'entered historical PA into system', 'joe'  
  ParticipationAgreement.put  ParticipationAgreement.load_from_hash(pa_data_02), 'entered historical PA into system', 'joe'  

  ParticipationAgreement.rate_for_employer_and_type_as_of_date emp3333, 'family', Date.new(2020,1,1)  














  
=begin
  
  # class ParticipationAgreementPlan <  CommandPost::Persistence 

  #   def self.schema
  #     {
  #       title: "ParticipationAgreementPlans",
  #       type:  "object",
  #       required: ["id", "effective_date", "expiration_date", "tier_type", "plan", "rates" ],
  #       properties:
  #       {   
  #         id:              { type:  "string",  class: "UUID"  },
  #         effective_date:  { type:  "string",  class: "Date"  },
  #         expiration_date: { type:  "string",  class: "Date"  },
  #         tier_type:       { type:  "string" },
  #         plan:            { type:  "string" },
  #         rates:           { type:  "array",   class: "ParticipationAgreementRate" }
  #       }
  #     }
  #   end
  # end


  # class ParticipationAgreementRate <  CommandPost::Persistence 
  #   def self.schema 
  #     {
  #       title: "ParticipationAgreementRate",
  #       type:  "object",
  #       required: ["published_rate?", "rate_type", "rate_amount"],
  #       properties:   
  #       {
  #         published_rate?:    { type:  "boolean"},
  #         rate_type:          { type:  "string"},
  #         rate_amount:        { type:  "number", class: "Money" }
  #       }
  #     }
  #   end

  #   def self.indexes 
  #     [:employer_aggregate_id]
  #   end


  #   def plan_in_effect date
  #     HashWrapper.new plans.select{|x| date >= x[:effective_date] and date <= x[:expiration_date]}.first
  #   end
  # end 
=end
