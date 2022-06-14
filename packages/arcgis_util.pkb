create or replace package body arcgis_util as

   function parse_suggestions(
      p_json in clob
   ) return t_suggestion_type pipelined deterministic
   is
   begin
      for suggestion in (
         select 
            jt.*
         from
            json_table(p_json format json, '$.suggestions[*]'
               columns(
                  text           varchar2(500 char)
                , magicKey       varchar2(100 char)
                , isCollection   varchar2(5 char)
               )
            ) jt
      )
      loop
         pipe row(suggestion);
      end loop;
      
      return;
   end parse_suggestions;
   
   --https://developers.arcgis.com/rest/geocode/api-reference/geocoding-suggest.htm
   function suggest(
      p_text                   in varchar2
    , p_location               in varchar2 default null --Can be WGS84 x,y pair (-117.196,34.056) or JSON point object to limit area
    , p_category               in varchar2 default null
    , p_search_extent          in varchar2 default null
    , p_max_suggestions        in number default 5 --max 15
    , p_country_code           in varchar2 default null --2 or 3 digit ISO country code, i.e. 'USA'
    , p_preferred_label_values in varchar2 default null --Either 'postalCity' or 'localCity'
    , p_format                 in varchar2 default 'json'  --Formats: json,pjson
   ) return clob
   is
      l_url_params varchar2(200);
      l_return clob;
   begin
   
      --Build URL query string from parameters

      --Start with f=json, which is required to return JSON formatted result
      l_url_params := '?f='||utl_url.escape(p_format);
      
      l_url_params := l_url_params||'&text='||utl_url.escape(p_text);
      l_url_params := l_url_params||'&location='||utl_url.escape(p_location);
      l_url_params := l_url_params||'&category='||utl_url.escape(p_category);
      l_url_params := l_url_params||'&searchExtent='||utl_url.escape(p_search_extent);
      l_url_params := l_url_params||'&maxSuggestions='||p_max_suggestions;
      l_url_params := l_url_params||'&countryCode='||utl_url.escape(p_country_code);
      l_url_params := l_url_params||'&preferredLabelValues='||utl_url.escape(p_preferred_label_values);

      --Make REST request and return output
      l_return := apex_web_service.make_rest_request(
         p_url => k_base_url||'suggest'||l_url_params
       , p_http_method => 'GET'
      );
      
      return l_return;
   end;
   
   function parse_address_candidates(
      p_json in clob
   ) return t_address_candidate_type pipelined deterministic
   is
   begin
      for address_candidate in (
         select
            jt.*
         from
            json_table(p_json format json, '$.candidates[*]'
               columns(
                  address          varchar2(500 char)
                , location         varchar2(4000) format json    path '$.location'
                , loc_name         varchar2(20 char)             path '$.attributes.Loc_name'
                , status           varchar2(1 char)              path '$.attributes.Status'
                , score            number                        path '$.attributes.Score'
                , match_addr       varchar2(500 char)            path '$.attributes.Match_addr'
                , longlabel        varchar2(500 char)            path '$.attributes.LongLabel'
                , shortlabel       varchar2(500 char)            path '$.attributes.ShortLabel'
                , addr_type        varchar2(20 char)             path '$.attributes.Addr_type'
                , type             varchar2(50 char)             path '$.attributes.Type'
                , placename        varchar2(200 char)            path '$.attributes.PlaceName'
                , place_addr       varchar2(500 char)            path '$.attributes.Place_addr'
                , phone            varchar2(25 char)             path '$.attributes.Phone'
                , url              varchar2(250 char)            path '$.attributes.URL'
                , rank             number                        path '$.attributes.Rank'
                , buildingname     varchar2(125 char)            path '$.attributes.AddBldg'
                , addressnumber    varchar2(50 char)             path '$.attributes.AddNum'
                , addnumfrom       varchar2(50 char)             path '$.attributes.AddNumFrom'
                , addnumto         varchar2(50 char)             path '$.attributes.AddNumTo'
                , addressrange     varchar2(100 char)            path '$.attributes.AddRange'
                , side             varchar2(1 char)              path '$.attributes.Side'
                , stpredir         varchar2(5 char)              path '$.attributes.StPreDir'
                , stpretype        varchar2(50 char)             path '$.attributes.StPreType'
                , stname           varchar2(125 char)            path '$.attributes.StName'
                , sttype           varchar2(30 char)             path '$.attributes.StType'
                , stdir            varchar2(20 char)             path '$.attributes.StDir'
                , bldgtype         varchar2(20 char)             path '$.attributes.BldgType'
                , bldgname         varchar2(50 char)             path '$.attributes.BldgName'
                , leveltype        varchar2(20 char)             path '$.attributes.LevelType'
                , levelname        varchar2(50 char)             path '$.attributes.LevelName'
                , unittype         varchar2(20 char)             path '$.attributes.UnitType'
                , unitname         varchar2(50 char)             path '$.attributes.UnitName'
                , subaddress       varchar2(250 char)            path '$.attributes.SubAddr'
                , staddr           varchar2(300 char)            path '$.attributes.StAddr'
                , block            varchar2(120 char)            path '$.attributes.Block'
                , sector           varchar2(120 char)            path '$.attributes.Sector'
                , neighborhood     varchar2(120 char)            path '$.attributes.Nbrhd'
                , district         varchar2(120 char)            path '$.attributes.District'
                , city             varchar2(120 char)            path '$.attributes.City'
                , metroarea        varchar2(120 char)            path '$.attributes.MetroArea'
                , subregion        varchar2(120 char)            path '$.attributes.Subregion'
                , region           varchar2(120 char)            path '$.attributes.Region'
                , regionabbr       varchar2(50 char)             path '$.attributes.RegionAbbr'
                , territory        varchar2(120 char)            path '$.attributes.Territory'
                , zone             varchar2(100 char)            path '$.attributes.Zone'
                , postal           varchar2(20 char)             path '$.attributes.Postal'
                , postalext        varchar2(10 char)             path '$.attributes.PostalExt'
                , country          varchar2(30 char)             path '$.attributes.Country'
                , countryname      varchar2(100 char)            path '$.attributes.CntryName'
                , langcode         varchar2(5 char)              path '$.attributes.LangCode'
                , distance         number                        path '$.attributes.Distance'
                , x                number                        path '$.attributes.X'
                , y                number                        path '$.attributes.Y'
                , displayx         number                        path '$.attributes.DisplayX'
                , displayy         number                        path '$.attributes.DisplayY'
                , xmin             number                        path '$.attributes.Xmin'
                , xmax             number                        path '$.attributes.Xmax'
                , ymin             number                        path '$.attributes.Ymin'
                , ymax             number                        path '$.attributes.Ymax'
                , extrainfo        varchar2(500 char)            path '$.attributes.ExInfo'
               )
            ) jt
      )
      loop
         pipe row (address_candidate);
      end loop;
      return;
   end parse_address_candidates;
   
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
   ) return clob
   is
      l_url_params varchar2(200);
      l_return clob;
   begin
      
      --Build URL query string from parameters

      --Start with f=json, which is required to return JSON formatted result
      l_url_params := '?f='||utl_url.escape(p_format);

      --Note: The singleLine parameter can be combined with the sourceCountry parameter, but not with any other
      --multi-field params (city, state, etc)
      --Add single line address if not null, otherwise concatenate p_street, p_city, p_state, etc
      case
         when p_singleline is not null then
            l_url_params := l_url_params || '&SingleLine='||utl_url.escape(p_singleline);
            --magic key comes from sugggest api
            if p_magic_key is not null then 
               l_url_params := l_url_params || '&magicKey='||utl_url.escape(p_magic_key);
            end if;
         else
            --p_address
            l_url_params := l_url_params || '&address='||utl_url.escape(p_address);
            --p_address2
            l_url_params := l_url_params || '&address2='||utl_url.escape(p_address2);
            --p_address3
            l_url_params := l_url_params || '&address3='||utl_url.escape(p_address3);
            
            --p_street Note: World Geocode service doesn't use street param, but other locators do
            --l_url_params := l_url_params || '&Street='||utl_url.escape(p_street);
            --p_city
            l_url_params := l_url_params || '&City='||utl_url.escape(p_city);
            --p_state
            --l_url_params := l_url_params || '&State='||utl_url.escape(p_state);
            --p_zip
            --l_url_params := l_url_params || '&ZIP='||utl_url.escape(p_zip);
      end case;

      --Add the rest, p_out_fields, p_max_locations, p_outsr
      l_url_params := l_url_params || '&countryCode='||utl_url.escape(p_country_code);
      l_url_params := l_url_params || '&outFields='||utl_url.escape(p_out_fields);
      l_url_params := l_url_params || '&maxLocations='||utl_url.escape(p_max_locations);
      l_url_params := l_url_params || '&outSR='||utl_url.escape(p_outsr);
      
      --Make REST Request and return output
      l_return := apex_web_service.make_rest_request(
         p_url => k_base_url||'findAddressCandidates'||l_url_params
       , p_http_method => 'GET'
      );
      
      return l_return;
   end;
   

end arcgis_util;