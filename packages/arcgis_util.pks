create or replace package arcgis_util authid definer as
--
-- This is the base URL used in all API requests
--
   k_base_url constant varchar2(100 char) := 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/';

--
-- Type declaration and nested table used by the parse_suggestions table function
--
   type r_suggestion_type is record (
      text             varchar2(500 char)
    , magic_key        varchar2(100 char)
    , is_collection    varchar2(5 char)
   );
   
   type t_suggestion_type is table of r_suggestion_type;
   
--==========================================================================================================
-- Parses JSON output from the suggest API and returns rows of suggestions
--
-- Parameters:
-- * p_json               JSON output from suggest function as a CLOB
--                        
--==========================================================================================================
   function parse_suggestions(
      p_json in clob
   ) return t_suggestion_type pipelined deterministic;
   
--==========================================================================================================
-- Calls the suggest API to retrieve a list of suggestions
-- API Docs: https://developers.arcgis.com/rest/geocode/api-reference/geocoding-suggest.htm
--
-- Parameters:
-- * p_text               Input text used by the suggest API to generate a list of possible matches
--                        
-- * p_location           Defines an origin point that is used to prefer or boost geocoding candidates based
--                        on their proximity to the location. The location can be represented with a simple
--                        comma-separated syntax (x,y), or as a JSON point object. If the comma-separated
--                        syntax is used, the spatial reference of the coordinates must be WGS84; otherwise,
--                        the spatial reference of the point coordinates can be defined in the JSON object.
--                        Example using simple syntax(WGS84): p_location => '-117.196,34.056'
--==========================================================================================================
   function suggest(
      p_text                   in varchar2
    , p_location               in varchar2 default null --Can be WGS84 x,y pair (-117.196,34.056) or JSON point object to limit area
    , p_category               in varchar2 default null
    , p_search_extent          in varchar2 default null
    , p_max_suggestions        in number default 5 --max 15
    , p_country_code           in varchar2 default null --2 or 3 digit ISO country code, i.e. 'USA'
    , p_preferred_label_values in varchar2 default null --Either 'postalCity' or 'localCity'
    , p_format                 in varchar2 default 'json'  --Formats: json,pjson
   ) return clob;

--
-- Type declaration and nested table used by the parse_address_candidates table function
--
   type r_address_candidate_type is record (
      address          varchar2(500 char)
    , location         varchar2(4000)
    , loc_name         varchar2(20 char)
    , status           varchar2(1 char)
    , score            number
    , match_addr       varchar2(500 char)
    , longlabel        varchar2(500 char)
    , shortlabel       varchar2(500 char)
    , addr_type        varchar2(20 char)
    , type             varchar2(50 char)
    , placename        varchar2(200 char)
    , place_addr       varchar2(500 char)
    , phone            varchar2(25 char)
    , url              varchar2(250 char)
    , rank             number
    , buildingname     varchar2(125 char)
    , addressnumber    varchar2(50 char)
    , addnumfrom       varchar2(50 char)
    , addnumto         varchar2(50 char)
    , addressrange     varchar2(100 char)
    , side             varchar2(1 char)
    , stpredir         varchar2(5 char)
    , stpretype        varchar2(50 char)
    , stname           varchar2(125 char)
    , sttype           varchar2(30 char)
    , stdir            varchar2(20 char)
    , bldgtype         varchar2(20 char)
    , bldgname         varchar2(50 char)
    , leveltype        varchar2(20 char)
    , levelname        varchar2(50 char)
    , unittype         varchar2(20 char)
    , unitname         varchar2(50 char)
    , subaddress       varchar2(250 char)
    , staddr           varchar2(300 char)
    , block            varchar2(120 char)
    , sector           varchar2(120 char)
    , neighborhood     varchar2(120 char)
    , district         varchar2(120 char)
    , city             varchar2(120 char)
    , metroarea        varchar2(120 char)
    , subregion        varchar2(120 char)
    , region           varchar2(120 char)
    , regionabbr       varchar2(50 char)
    , territory        varchar2(120 char)
    , zone             varchar2(100 char)
    , postal           varchar2(20 char)
    , postalext        varchar2(10 char)
    , country          varchar2(30 char)
    , countryname      varchar2(100 char)
    , langcode         varchar2(5 char)
    , distance         number
    , x                number
    , y                number
    , displayx         number
    , displayy         number
    , xmin             number
    , xmax             number
    , ymin             number
    , ymax             number
    , extrainfo        varchar2(500 char)  
   );
   
   type t_address_candidate_type is table of r_address_candidate_type;

--==========================================================================================================
-- Parses JSON output from the findAddressCandidates API and returns rows of address candidates
--
-- Parameters:
-- * p_json               JSON output from find_address_candidates function as a CLOB
--                        
--==========================================================================================================
   function parse_address_candidates(
      p_json in clob
   ) return t_address_candidate_type pipelined deterministic;
   
   --https://developers.arcgis.com/rest/geocode/api-reference/geocoding-find-address-candidates.htm
   function find_address_candidates (
      p_singleline     in  varchar2 default null --max length 200
    , p_magic_key      in  varchar2 default null
    -- address params, ignored if p_singleline was used
    , p_address        in  varchar2 default null --Address or Place (100 char) i.e. Beetham Tower
    , p_address2       in  varchar2 default null --Address 2        (100 char) i.e. 301 Deensgate
    , p_address3       in  varchar2 default null --Address 3        (100 char) i.e. Suite 4208
    , p_neighborhood   in  varchar2 default null --(50 char)
    , p_city           in  varchar2 default null --(50 char)
    , p_subregion      in  varchar2 default null --U.S. County (50 char)
    , p_region         in  varchar2 default null --U.S. State  (50 char)
    , p_postal         in  varchar2 default null --U.S. Zip    (20 char)
    , p_postal_ext     in  varchar2 default null --U.S. Zip+4  (20 char)
    -- request params
    , p_country_code   in  varchar2 default null --2 or 3 digit ISO country code, i.e. 'USA'
    , p_langCode       in  varchar2 default 'en'
    , p_out_fields     in  varchar2 default '*'
    , p_max_locations  in  varchar2 default null
    , p_outsr          in  varchar2 default '4326'
    , p_format         in  varchar2 default 'json' --json,pjson
   ) return clob;
   

end arcgis_util;
/
