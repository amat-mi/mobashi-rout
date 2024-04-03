/**
    For performances' sake, it's important that tables used by pgRouting have at least the following CONSTRAINTS and INDEXES.
*/

-- bike ways
ALTER TABLE public.bike_ways ADD
CONSTRAINT bike_ways_pkey PRIMARY KEY (gid);

CREATE INDEX IF NOT EXISTS bike_ways_the_geom_idx
    ON public.bike_ways USING gist
    (the_geom)
    TABLESPACE pg_default;

-- bike vertices
ALTER TABLE public.bike_ways_vertices_pgr ADD
CONSTRAINT bike_ways_vertices_pgr_pkey PRIMARY KEY (id);

ALTER TABLE public.bike_ways_vertices_pgr ADD
CONSTRAINT bike_ways_vertices_pgr_osm_id_key UNIQUE (osm_id);

CREATE INDEX IF NOT EXISTS bike_ways_vertices_pgr_the_geom_idx
    ON public.bike_ways_vertices_pgr USING gist
    (the_geom)
    TABLESPACE pg_default;

-- car ways
ALTER TABLE public.car_ways ADD
CONSTRAINT car_ways_pkey PRIMARY KEY (gid);

CREATE INDEX IF NOT EXISTS car_ways_the_geom_idx
    ON public.car_ways USING gist
    (the_geom)
    TABLESPACE pg_default;

-- car vertices
ALTER TABLE public.car_ways_vertices_pgr ADD
CONSTRAINT car_ways_vertices_pgr_pkey PRIMARY KEY (id);

ALTER TABLE public.car_ways_vertices_pgr ADD
CONSTRAINT car_ways_vertices_pgr_osm_id_key UNIQUE (osm_id);

CREATE INDEX IF NOT EXISTS car_ways_vertices_pgr_the_geom_idx
    ON public.car_ways_vertices_pgr USING gist
    (the_geom)
    TABLESPACE pg_default;

-- foot ways
ALTER TABLE public.foot_ways ADD
CONSTRAINT foot_ways_pkey PRIMARY KEY (gid);

CREATE INDEX IF NOT EXISTS foot_ways_the_geom_idx
    ON public.foot_ways USING gist
    (the_geom)
    TABLESPACE pg_default;

-- foot vertices
ALTER TABLE public.foot_ways_vertices_pgr ADD
CONSTRAINT foot_ways_vertices_pgr_pkey PRIMARY KEY (id);

ALTER TABLE public.foot_ways_vertices_pgr ADD
CONSTRAINT foot_ways_vertices_pgr_osm_id_key UNIQUE (osm_id);

CREATE INDEX IF NOT EXISTS foot_ways_vertices_pgr_the_geom_idx
    ON public.foot_ways_vertices_pgr USING gist
    (the_geom)
    TABLESPACE pg_default;

-- tpl ways
ALTER TABLE tpl_ways ADD
CONSTRAINT tpl_ways_pkey PRIMARY KEY (gid);

CREATE INDEX IF NOT EXISTS tpl_ways_the_geom_idx
    ON public.tpl_ways USING gist
    (the_geom)
    TABLESPACE pg_default;

-- tpl vertices
ALTER TABLE tpl_ways_vertices_pgr ADD
CONSTRAINT tpl_ways_vertices_pgr_pkey PRIMARY KEY (id);

CREATE INDEX IF NOT EXISTS tpl_ways_vertices_pgr_the_geom_idx
    ON public.tpl_ways_vertices_pgr USING gist
    (the_geom)
    TABLESPACE pg_default;

CREATE INDEX IF NOT EXISTS idx_tpl_transfer
    ON public.tpl_ways_vertices_pgr USING btree
    (transfer ASC NULLS LAST)
    INCLUDE(transfer)
    TABLESPACE pg_default;


/**
    Schema for routing functions.
*/

CREATE SCHEMA IF NOT EXISTS elab
    AUTHORIZATION django;

GRANT ALL ON SCHEMA elab TO django;


/**
    Return type of routing functions.
*/

CREATE TYPE elab.rout AS
(
	ord integer,
	submode text,
	agency text,
	route_id text,
	network text,
	netid text,
	graphid text,
	trav_dist integer,
	trav_time integer,
	flow integer,
	geom geometry(LineString,4326)
);

ALTER TYPE elab.rout
    OWNER TO django;

GRANT USAGE ON TYPE elab.rout TO django;


/**
    Routing function for bike.
*/

-- FUNCTION: elab.routing_bike(double precision, double precision, double precision, double precision, integer)

-- DROP FUNCTION IF EXISTS elab.routing_bike(double precision, double precision, double precision, double precision, integer);

CREATE OR REPLACE FUNCTION elab.routing_bike(
	i_source_lat double precision,
	i_source_lon double precision,
	i_target_lat double precision,
	i_target_lon double precision,
	i_k integer)
    RETURNS SETOF elab.rout 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN

RETURN QUERY
with 

------------------ finding source e target from input lat and lon -------------------------
t2 as (
	SELECT id as source	
	FROM public.bike_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_source_lon,i_source_lat),4326)
	LIMIT 1
),

t4 as (
	SELECT id as target	
	FROM public.bike_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_target_lon,i_target_lat),4326)
	LIMIT 1
),

-------------------- performing routing from source to target ---------------------------

a as (
select  *
FROM pgr_KSP(
    'SELECT gid as id, source, target, cost_s cost, reverse_cost_s reverse_cost FROM public.bike_ways', 
(select source from t2), (select target from t4),i_k, directed => true, heap_paths => false)
   ),

b as (
select path_id, path_seq, edge, agg_cost, 
case when source is null then null when node=source then 1 else -1 end as direction
from a left join public.bike_ways on edge=gid
),

c as (
select path_id, agg_cost
from a where edge=-1
),

d as (
select path_id, agg_cost, exp(-agg_cost*0.0015)/(sum(exp(-agg_cost*0.0015)) over ()) as p
from c
),

e as (
select edge, direction, p
from b left join d using(path_id) where edge is not null
),

f as (
select edge, direction, sum(p) as flow
from e
where edge<>-1
group by edge, direction
),

g as (
select 'bike' as mode, null as submode, null as agency, null as route_id, 
0 as net_id, source_osm||'-'||target_osm||'-'||osm_id as edge_id, edge*direction as link_id,
length_m as trav_dist, length_m/4 as trav_time, flow, the_geom
from f join 
public.bike_ways on edge=gid
)

select 
0 as ord,
'' || submode, 
'' || agency, 
'' || route_id,  
'osm' as network,
'' || edge_id as graphid,
'' || link_id as netid,
(round(trav_dist::numeric, 2) * 100)::integer as trav_dist,
(round(trav_time::numeric, 2) * 100)::integer as trav_time, 
(round(flow::numeric, 2) * 100)::integer as flow,  
the_geom as geom
from g;

END;
$BODY$;

ALTER FUNCTION elab.routing_bike(double precision, double precision, double precision, double precision, integer)
    OWNER TO django;


/**
    Routing function for car.
*/

-- FUNCTION: elab.routing_car(double precision, double precision, double precision, double precision, integer)

-- DROP FUNCTION IF EXISTS elab.routing_car(double precision, double precision, double precision, double precision, integer);

CREATE OR REPLACE FUNCTION elab.routing_car(
	i_source_lat double precision,
	i_source_lon double precision,
	i_target_lat double precision,
	i_target_lon double precision,
	i_k integer)
    RETURNS SETOF elab.rout 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN

RETURN QUERY
with 

------------------ finding source e target from input lat and lon -------------------------
t2 as (
	SELECT id as source	
	FROM public.car_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_source_lon,i_source_lat),4326)
	LIMIT 1
),

t4 as (
	SELECT id as target	
	FROM public.car_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_target_lon,i_target_lat),4326)
	LIMIT 1
),

-------------------- performing routing from source to target ---------------------------

a as (
select  *
--, reverse_cost_s reverse_cost 
FROM pgr_KSP(
    'SELECT gid as id, source, target, cost_s cost, reverse_cost_s reverse_cost FROM public.car_ways', 
(select source from t2), (select target from t4),i_k, directed => true, heap_paths => false)
    order by 2 ),

b as (
select path_id, path_seq, edge, agg_cost, 
case when source is null then null when node=source then 1 else -1 end as direction
from a left join public.car_ways on edge=gid
),

c as (
select path_id, agg_cost
from a where edge=-1
),

d as (
select path_id, agg_cost, exp(-agg_cost*0.0015)/(sum(exp(-agg_cost*0.0015)) over ()) as p
from c
),

e as (
select edge, direction, p
from b left join d using(path_id) where edge is not null
),

f as (
select edge, direction, sum(p) as flow
from e
where edge<>-1
group by edge, direction
),

g as (
select 'car' as mode, null as submode, null as agency, null as route_id, 
0 as net_id, source_osm||'-'||target_osm||'-'||osm_id as edge_id, edge*direction as link_id,
length_m as trav_dist, cost_s*3 as trav_time, flow, the_geom
from f join 
public.car_ways on edge=gid
)

select 
0 as ord,
'' || submode, 
'' || agency, 
'' || route_id,  
'osm' as network,
'' || edge_id as graphid,
'' || link_id as netid,
(round(trav_dist::numeric, 2) * 100)::integer as trav_dist,
(round(trav_time::numeric, 2) * 100)::integer as trav_time, 
(round(flow::numeric, 2) * 100)::integer as flow,  
the_geom as geom
from g;

END;
$BODY$;

ALTER FUNCTION elab.routing_car(double precision, double precision, double precision, double precision, integer)
    OWNER TO django;


/**
    Routing function for foot.
*/

-- FUNCTION: elab.routing_foot(double precision, double precision, double precision, double precision, integer)

-- DROP FUNCTION IF EXISTS elab.routing_foot(double precision, double precision, double precision, double precision, integer);

CREATE OR REPLACE FUNCTION elab.routing_foot(
	i_source_lat double precision,
	i_source_lon double precision,
	i_target_lat double precision,
	i_target_lon double precision,
	i_k integer)
    RETURNS SETOF elab.rout 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN

RETURN QUERY
with 

------------------ finding source e target from input lat and lon -------------------------
t2 as (
	SELECT id as source	
	FROM public.foot_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_source_lon,i_source_lat),4326)
	LIMIT 1
),

t4 as (
	SELECT id as target	
	FROM public.foot_ways_vertices_pgr
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_target_lon,i_target_lat),4326)
	LIMIT 1
),

-------------------- performing routing from source to target ---------------------------

a as (
select  *
FROM pgr_KSP(
    'SELECT gid as id, source, target, cost_s cost, reverse_cost_s reverse_cost FROM public.foot_ways', 
(select source from t2), (select target from t4),i_k, directed => false, heap_paths => false)
  ),

b as (
select path_id, path_seq, edge, agg_cost, 
case when source is null then null when node=source then 1 else -1 end as direction
from a left join public.foot_ways on edge=gid
),

c as (
select path_id, agg_cost
from a where edge=-1
),

d as (
select path_id, agg_cost, exp(-agg_cost*0.0015)/(sum(exp(-agg_cost*0.0015)) over ()) as p
from c
),

e as (
select edge, direction, p
from b left join d using(path_id) where edge is not null
),

f as (
select edge, direction, sum(p) as flow
from e
where edge<>-1
group by edge, direction
),

g as (
select 'foot' as mode, null as submode, null as agency, null as route_id, 
    0 as net_id, source_osm||'-'||target_osm||'-'||osm_id as edge_id, edge*direction as link_id,
length_m as trav_dist, length_m/80*60 as trav_time, flow, the_geom
from f join 
public.foot_ways on edge=gid
)

select 
0 as ord,
'' || submode, 
'' || agency, 
'' || route_id,  
'osm' as network,
'' || edge_id as graphid,
'' || link_id as netid,
(round(trav_dist::numeric, 2) * 100)::integer as trav_dist,
(round(trav_time::numeric, 2) * 100)::integer as trav_time, 
(round(flow::numeric, 2) * 100)::integer as flow,  
the_geom as geom
from g;

END;
$BODY$;

ALTER FUNCTION elab.routing_foot(double precision, double precision, double precision, double precision, integer)
    OWNER TO django;


/**
    Routing function for tpl.
*/

-- FUNCTION: elab.routing_tpl(double precision, double precision, double precision, double precision, integer)

-- DROP FUNCTION IF EXISTS elab.routing_tpl(double precision, double precision, double precision, double precision, integer);

CREATE OR REPLACE FUNCTION elab.routing_tpl(
	i_source_lat double precision,
	i_source_lon double precision,
	i_target_lat double precision,
	i_target_lon double precision,
	i_k integer)
    RETURNS SETOF elab.rout 
    LANGUAGE 'plpgsql'
    COST 100
    VOLATILE PARALLEL UNSAFE
    ROWS 1000

AS $BODY$
BEGIN

RETURN QUERY
with 

------------------ finding source e target from input lat and lon -------------------------
t2 as (
	SELECT id as source	
	FROM (SELECT id, the_geom FROM public.tpl_ways_vertices_pgr where transfer=1) q
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_source_lon,i_source_lat),4326)
	LIMIT 1
),

t4 as (
	SELECT id as target	
	FROM (SELECT id, the_geom FROM public.tpl_ways_vertices_pgr where transfer=1) q
	ORDER BY the_geom <-> st_setsrid(st_makepoint(i_target_lon,i_target_lat),4326)
	LIMIT 1
),

-------------------- performing routing from source to target ---------------------------

a as (
select  *
FROM pgr_KSP(
    'SELECT gid as id, source, target, cost FROM public.tpl_ways', 
(select source from t2), (select target from t4),i_k, directed => true, heap_paths => false)
   ),

c as (
select path_id, agg_cost
from a where edge=-1
),

d as (
select path_id, agg_cost, exp(-agg_cost*0.0015)/(sum(exp(-agg_cost*0.0015)) over ()) as p
from c
),

e as (
select edge, p
from a left join d using(path_id) where edge is not null
),

f as (
select edge, sum(p) as flow
from e
where edge<>-1
group by edge
),

g as (
select 1 as id_od, 'tpl' as mode, submode, agency, route_id,  1 as net_id, edge_id, edge as link_id,
length_m as trav_dist, trav_time, flow, the_geom
from f join 
public.tpl_ways on edge=gid
)

select 
0 as ord,
'' || submode, 
'' || agency, 
'' || route_id,  
'tpl' as network,
'' || edge_id as graphid,
'' || link_id as netid,
(round(trav_dist::numeric, 2) * 100)::integer as trav_dist,
(round(trav_time::numeric, 2) * 100)::integer as trav_time, 
(round(flow::numeric, 2) * 100)::integer as flow,  
the_geom as geom
from g;

END;
$BODY$;

ALTER FUNCTION elab.routing_tpl(double precision, double precision, double precision, double precision, integer)
    OWNER TO django;


/**
    Example calling routing functions:
        (
            source_latitude, source_longitude,
            target_latitude, target_longitude,
            k
        )

    Where "k" specifies how many alternative routes to generate, before aggregating them by graph edge.
    A value of 1 only generates the very best route and the "flow" field of every graph edge will always be 1.
    Greater values generates more alternatives and "flow" values will be more dispersed.
    Increasing the value of "k" considerably increases computing time.
*/

select * from elab.routing_bike(45.4518875, 9.13167305, 45.476168, 9.203714, 1);
select * from elab.routing_car(45.4518875, 9.13167305, 45.476168, 9.203714, 1);
select * from elab.routing_foot(45.4518875, 9.13167305, 45.476168, 9.203714, 1);
select * from elab.routing_tpl(45.4518875, 9.13167305, 45.476168, 9.203714, 1);
