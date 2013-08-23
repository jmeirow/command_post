--DROP TABLE AGGREGATE_EVENTS;
--DROP TABLE AGGREGATES;



CREATE TABLE aggregate_events (

    transaction_id      BIGINT PRIMARY KEY,  
    aggregate_id        BIGINT,  
    aggregate_type      VARCHAR(100),
    event_description   TEXT,
    content             TEXT,
    call_stack          TEXT, 
    user_id         	VARCHAR(100) NOT NULL,
    transacted          TIMESTAMP

   )  ;

CREATE INDEX aggregate_id_idx ON aggregate_events(aggregate_id,aggregate_type);




  
CREATE TABLE aggregates (

aggregate_id    		BIGINT NOT NULL PRIMARY KEY,
aggregate_lookup_value  VARCHAR(100) NOT NULL,
aggregate_type    		VARCHAR(100) NOT NULL,
content         		TEXT NOT NULL

)  ; 

CREATE INDEX aggregate_lookup_idx ON aggregates(aggregate_lookup_value);



  
CREATE TABLE aggregate_indexes (
aggregate_id    		BIGINT NOT NULL,
index_field             VARCHAR(100) NOT NULL,
index_value      		VARCHAR(100) NOT NULL,
PRIMARY KEY             (aggregate_id,index_field)
)  ; 


  
CREATE SEQUENCE aggregate START 1;


CREATE SEQUENCE transaction START 1;

CREATE SEQUENCE misc START 1;

