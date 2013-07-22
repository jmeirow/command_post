
--drop table aggregate_events;

--drop table aggregates;



create table aggregate_events (
    transaction_id      bigint primary key,  
    aggregate_id        bigint,  
    aggregate_type      varchar(100),
    event_description   text,
    content             text,
    call_stack          text, 
    user_id         varchar(100) not null,
    transacted          timestamp
   )  ;
  
create table aggregates (
aggregate_id    bigint not null primary key,
aggregate_lookup_value  varchar(100) not null,
aggregate_type    varchar(100) not null,
content         text not null
)  ; 



create index aggregate_lookup_idx on aggregates(aggregate_lookup_value);

create index aggregate_id_idx on aggregate_events(aggregate_id,aggregate_type);
  

CREATE SEQUENCE aggregate START 1;

CREATE SEQUENCE transaction START 1;

CREATE SEQUENCE misc START 1;