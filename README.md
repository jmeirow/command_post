CommandPost
===

CommandPost – the Command Pattern, Object Storage and Event Sourcing 




CommandPost is a library that facilitates the retrieval and storage of objects. The objects are nothing more than Hashes, stored as JSON in a relational database. CommandPost has the following features to facillitate this:

*  A base class (Persistence) which encapsulates a Hash so as to allow dot notation access ( myobject.myproperty instead of myobject['myproperty']) as well as computational methods on the class.
*  A schema declaration syntax which insures only valid objects are saved to the database 
*  A module (Identity) the provides an identity to the object so that it may be persisted and retrieved later by its 'aggregate_id'.
*  A fully-integrated 'at the core' event-sourcing mechanism. Objects are not saved to the database until their 'change events' are first recorded to an event store. A single table (aggregate_events) holds every event 
   that ever occurred to every object. It is relatively easy to picture the entire system as it appeared at a point in time. This will be even easier in future versions of CommandPost.
*  Say goodbye to database migrations. Three tables store all your objects. Development cycles become more nimble without the "friction" of keeping changes consistent between the code and a database. Simply add a new
   'field' to your class and it's done.
*  Retrieves fully populated domain objects from the database. Application code does not own the step of wrangling hash-data into a business object. CommandPost does it for you. In fact, it's through your domain object declaration
   that CommandPost even knows how to populate the hashes that eventually stored as JSON.


A word about Persitence vs Identity.

* In CommandPost, Persistence (a base-class) is what allows an "object" to be saved to the database. An object that inherits from Persistence and includes the Identity module can always be saved to the database.
* A class that ONLY inherits from Persistence, but does not include the Identity module *CAN* be saved to the database but ONLY as the property of another object which must also be an Identity object (includes the Identity module) or eventually reaches up to an Identity object


EXAMPLE: An example of Identity as contrasted against Persistence.

Consider a purchase order. It "header" information about the P.O. itself and it has many P.O. "lines".

In a traditional RDBMS, this scenario is almost always modeled as two tables:  A po_header table and a po_lines table.  In this case, both parts of the PO become unqiuely identifiable, individually retrievable entities by virtue of being rows on a table with po_lines most likely having a surrogate key that is an IDENTITY column.

In reality though, as Domain Driven Design points out, a purchase order line typically has no meaning, no value, unless viewed in the context of the P.O. as a whole. One *possible* way of modelling that is more in keeping with DDD is to model the P.O. as a whole (for now we'll leave out discussions of SubDomains and BoundedContexts). Why model it as a whole? Because being able to retrieve the ENTIRE po with a single read operation preserves the natural 
transactional boundary of the object. For instance, suppose that we want to maintain a field on the P.O. header that is essentially derived from sort of status of the lines. For convenience we just want to compute it has storeit on the P.O. header. In an RDBMS, you would HAVE TO use a transaction if the state of a line changed in such a way that this stored field on the header. With CommandPost (which I can admit stands for  Domain Driven Design Database, get it?),
with CommandPost, when the P.O. is modeled as a single object, there is only ONE write to the database, so the transaction is implicit, around the natual transactional boundaries of the object itself.

With CommandPost, you certainly COULD model our example "the RDBMS way".  Let's take a look at how to model the PO in each of the two approaches.



First, the Domain-Driven-Design-inspired approach

<pre><code>

class PurachaseOrderHeader < Persistence
  
  include Identity

  def initialize
    super
    fields = Hash.new
    fields[ 'order_date'   ] = { :required => true,       :type => Date,                              :location => :local                       } 
    fields[ 'order_number  ] = { :required => true,       :type => String                             :location => :local                       } 
    fields[ 'customer'     ] = { :required => true,       :type => Customer,                          :location => :remote, :auto_load => true  } 
    fields[ 'order_total'  ] = { :required => true,       :type => Money,                             :location => :local                       } 
    fields[ 'order_status' ] = { :required => true,       :type => String,                            :location => :local                       } 
    fields[ 'order_lines  '] = { :required => true,       :type => Array,  :of => PurchaseOrderLine,  :location => :local                       } 
    Address.init_schema fields 
  end

  def set_aggregate_lookup_value 
    @data['aggregate_lookup_value'] =  order_number
  end

end

class PurachaseOrderLine < Persistence
  def initialize
    super
    fields = Hash.new
    fields[ 'header '          ] = { :required => true,       :type => PurachaseOrderHeader,              :location => :remote, :auto_load => true  }  
    fields[ 'product'          ] = { :required => true,       :type => Product,                           :location => :remote, :auto_load => true   }  
    fields[ 'finalized_price'  ] = { :required => true,       :type => Money,                             :location => :local                        } 
    fields[ 'quantity'         ] = { :required => true,       :type => Fixnum,                            :location => :local                        } 
    Address.init_schema fields 
  end

  def extended_price
    
    # assumes Fixnum and Money play nice :)
    
    if header.status == 'open'
      quantity * product.price
    else 
      finalized_price
    end
  end

end

</code></pre>

Before getting into some code that uses this objects, let's examine this schema declaration 'syntax' in more detail.

Starting with intializer of PurchaseOrderHeader, you can see we call 'super' right off the bat. That's because 'initialize' in Persistence sets up things we'll need.
Next comes the schema declaration. Why talk about a "schema" for an object?  Well, I am the first to admit I am no fan of RDBMS for anything other than reporting and when I need aggregate functions that
only RDBMSs can provide. I am also no fan of the "friction" RDBMS introduces into the development process. BUT... that doesn't mean I like to have some controls and order around things. There several SIGNIFICANT 
advanatges that CommandPost storage provides over RDBMS storage. We'll cover them as they come up while discussing the mechanics of the schema declaration syntax.

First, a schema is nothing more than a list of fields, each of which has some properties. What better way, what more 'Ruby way' of accomplishing this than with a Hash? So then, a 'schema' is a Hash. Each key is a field name
and the value of each field is another hash containing a varying number of keys (properties) and values (settings) for the field.

Field names are declared AS STRINGS and NOT symbols. Personally, I like the look of symbols more, but JSON stores and returns keys as strings and so life is easier if we make our field names strings as well.

So then, the first field is 'order_date' is a 'required' field. Hopefully that requires no further explanation. They type is 'Date'. That means that the value assigned to the order_date field MUST be an object whose class is Date.
I've not yet given much thought about values that objects that descend from date or Strings that can cleanly be coerced into a Date. However, this segues into another point: unlike an RDBMS whose datatypes are fairly unintelligent
(integers, decimals, strings, dates, etc), CommandPost can have types of ANY object... well, any JSON-friendly object such Hashes, Arrays or classes that inherit from them (1) . For example, consider that most venerable of all database
fields, the Social Security Number. It turns out that not all 9-digit numbers issued by Uncle Sam are Social Security Numbers. 
Some are called ITINs (Individual Taxpayer Identification Number) and are often issued to people arriving in the U.S. before they are issued an actual SSN. They may have an ITIN for years before receving an SSN.

An SSN has a variety of validations that distinguish them from issued SSNs versus random, nine-digit numbers. The same applies to ITINs. Some business cases might need to know which people in their database have 
ITINs and which have SSNs. So you could, for example, create a class such as this:

<pre><code>

class GovernmentId < Hash

  attr_accessible :type, :value

  def initialize type, value
    raise "Invalid government ID" unless validate(type,value)
    ['type'] = @type = type
    ['value'] = @value = value
  end
  def validate
    return false if # validations failed..
    true
  end
end
</code></pre>

You could now declare a schema field as follows:

<pre><code>
    fields[ 'government_id' ] = { :required => true,       :type => GovernmentId,     :location => :local }
</code></pre>

Returning to our purchase order example, we left off the :location keyword of 'order_date'.  order_date's location is :local. This is the default for all fields but we've spelled it out here. The only other acceptable
value for :location is :remote. If :location is :remote, then :type must be set to the name of a class that includes Identity. Or, alternatively, the :type can be set to Array and the :of keyword must be set to 
a class that includes Identity.  It's worth noting that if a field is set to an Identity object and :location is :remote, the entire content of that object is NOT stored in the database. Rather a small Hash structure called
an 'AggregatePointer' is stored that. It is just a bit of data that says where to find the actual object in the database. However, you can easily tell CommandPost to return your object to you with all remote identity objects already
retrieved and populated. This is simply done by including the :autoload => true   otpion in your schema declaration.

Moving on to the order_lines field, you can see that its type is 'Array' and the :of keyword has PurchaseOrderLines as its value. So then, this field is an Array of PurchaseOrderLine objects. The :location is set to :local.
This means that P.O. lines are NOT stored as Identity objects, but merely Persitent objects. There's no way at all to retrieve a line without going through the P.O. header itself. In this case, the content of the PurchaseOrder
object and all of its PurchaseOrderLines are stored in single object and retrieved with a single read operation.


Moving on to PurchaseOrderLine, as mentioned earlier, there are two fields whose type are Identity classes, header and product. product is a pointer to a remote Customer object. Again, when we fetch the Purchas Order object with
our single read, not only does it retrieve the 'embedded' P.O. lines, but each P.O. line will have retieved and populated the product field. Though we've not shown what a Product object looks like, it might have  remote, auto_loaded
Supplier property. You get ALL of this data with a single read. Of course, you could go a little crazy with this. You don't want to retieve the entire database with every read. You can also declare the remote field to be
:auto_load => false. In this case, the cascading retrievals will not happen. Instead your object will return ONLY the data that is actually stored for remote fields... the AggregtePointer, which you can then use to manually
retrieve ONLY those elements you need at the time.

Lastly, notice the method, extended_price. First, it uses the 'status' property from the P.O. header which it gains access to by declaring a field, 'header' which is auto_loaded for each line (not 'stored', just populated within
the object).  The major point illustrated here is the value of using persistent objects (< Persistence) over plain old hashes... we can declare computational methods over the data.



Now to persist this thing we would say something like this:


<pre><code>

  hdr = PurchaseOrderHeader.new
  hdr.order_number = OrderNumberService.next_order_number  # a made up service we did not cover...
  hdr.order_date = Date.today
  hdr.customer = some_customer_variable # we already had this ...
  hdr.order_status = 'open'  # please ignore cheesy string as status

  lines = Array.new
  
  # first line...
  lines << PurchaseOrderLine.new
  lines.last.product = some_product_variable 
  lines.last.quantity = 12

  # second line...
  lines << PurchaseOrderLine.new
  lines.last.product = some_other_product_variable 
  lines.last.quantity = 144

  # more lines as necessary....

  # add the lines to the header.

  hdr.order_lines = lines

</code></pre>

  Now, if this were Rails/Active Record, you might exepct to see something like:

<pre><code>
  hdr.save
</code></pre>

  We don't do that here. Mutating data without capturing WHY it changed is the root of all evil.

  Here, we used the 'Command Pattern'. In some ways, it is a bit more code (at first), but, it's makes almost impossible to write an application without understanding each business case where data is created or changed,
  and then creating a "command" to carry it out.

  At this point, CommandPost does not use messaging software to transport commands to command handlers. You may or may not wish to ever use messaging software. 

  Omitting for now the code inside of the the command, here's how we'd persist this purchase order to the CommandPost database:
  
<pre><code>

  cmd = CommandCreateNewPurchaseOrder.new hdr
  cmd.execute

</code></pre>

  Now to retrieve the order number in its entirety, we can use a variety of methods:

  TO RETRIEVE WHEN WE KNOW THE 'AGGREGATE_ID' (essentialy an identity column, though not contiguously sequential because the same sequence is used for ALL aggregates (Identity objects) within our system)

<pre><code>

  po = PurchaseOrder.find(id)

</code></pre>


  The above is just a shortcut to the longer form:

<pre><code>
  po = Aggregate.get_by_aggregate_id PurchaseOrder, id 
</code></pre>

  Reflecting back for a minute to the PurchaseOrder class, you'll see a method after the initalizer called set_aggregate_lookup_value. This allows us to look up an aggregate by its 'real world unique identifier'.

  In this case, it's the order_number.  Assuming we have this value in an order_number variable:

  po = Aggregate.get_aggregate_by_lookup_value PurchaseOrder, order_number



Download the gem from RubyGems at: https://rubygems.org/gems/command_post




































































