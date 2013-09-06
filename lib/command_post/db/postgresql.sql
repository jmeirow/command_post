--   DROP TABLE AGGREGATE_EVENTS;
--   DROP TABLE AGGREGATES;
--   DROP TABLE AGGREGATE_INDEXES;


CREATE TABLE aggregate_events (

    transaction_id      BIGINT PRIMARY KEY,  
    aggregate_id        BIGINT,  
    aggregate_type      VARCHAR(100),
    event_description   TEXT,
    content             TEXT,
    user_id         	VARCHAR(100) NOT NULL,
    transacted          TIMESTAMP
)  ;

CREATE INDEX aggregate_events_idx ON aggregate_events(aggregate_id,aggregate_type);




  
CREATE TABLE aggregates (

aggregate_id    		BIGINT NOT NULL PRIMARY KEY,
aggregate_type    		VARCHAR(100) NOT NULL,
content         		TEXT NOT NULL

)  ; 


CREATE TABLE aggregate_index_strings (
aggregate_id    		BIGINT NOT NULL,
index_field             VARCHAR(100) NOT NULL,
index_value             VARCHAR(100) NOT NULL,
PRIMARY KEY             (aggregate_id,index_field)
)  ; 


CREATE TABLE aggregate_index_integers (
aggregate_id    		BIGINT NOT NULL,
index_field             VARCHAR(100) NOT NULL,
index_value             INTEGER NOT NULL,
PRIMARY KEY             (aggregate_id,index_field)
)  ; 


CREATE TABLE aggregate_index_decimals (
aggregate_id    		BIGINT NOT NULL,
index_field             VARCHAR(100) NOT NULL,
index_value             DECIMAL(12,2) NOT NULL,
PRIMARY KEY             (aggregate_id,index_field)
)  ; 


  
CREATE SEQUENCE aggregate START 1;


CREATE SEQUENCE transaction START 1;

CREATE SEQUENCE misc START 1;

