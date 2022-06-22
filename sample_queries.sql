set define off;

select
   apex_web_service.make_rest_request(
      p_url => 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/suggest?f=json&text=Gaylord+Texan'
    , p_http_method => 'GET')
from dual;







select 
   jt.*
from
   json_table(
      apex_web_service.make_rest_request(
         p_url => 'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/suggest?f=json&text='||utl_url.escape('Gaylord Texan')
       , p_http_method => 'GET'
   ) format json, '$.suggestions[*]'
      columns(
         text           varchar2(500 char)
       , magicKey       varchar2(100 char)
       , isCollection   varchar2(5 char)
      )
   ) jt;
   
   
with request as (
   select
      arcgis_util.suggest(
         p_text => 'hotel'
       , p_location => '-97.478256,35.657295'
       , p_max_suggestions => 15
      ) as response
   from dual
)
select 
   suggestions.*
from
   request,
   arcgis_util.parse_suggestions(p_json =>request.response) suggestions
;

--address candidates simple
select
   *
from
   insum_arcgis_util.parse_address_candidates(
      insum_arcgis_util.find_address_candidates(
         p_singleline => 'Oracle'
      )
   )
;

--address candidates, more filters
select
   *
from
   insum_arcgis_util.parse_address_candidates(
      insum_arcgis_util.find_address_candidates(
         p_address => '1501 Gaylord T'
       , p_city => 'Grapevine'
       , p_region => 'Texas'
      )
   )
;

--usps xml request
select 
   usps_util.get_address_xml(
      p_userid => 'XXXXX',
      p_revision => 1,
      p_firmname => 'Insum',
      p_address1 => null,
      p_address2 => '46 beekman',
      p_city => 'Plattsburgh',
      p_state => 'NY',
      p_zip5 => null,
      p_zip4 => null
   ) xml_request
from dual;


select
   usps_util.build_url(
      p_api => 'Verify',
      p_xml => usps_util.get_address_xml(
                  p_userid => 'XXXXX',
                  p_revision => 1,
                  p_firmname => 'Insum',
                  p_address1 => null,
                  p_address2 => '46 beekman',
                  p_city => 'Plattsburgh',
                  p_state => 'NY',
                  p_zip5 => null,
                  p_zip4 => null)
      ) as request_url
from dual;

with request as (
   select
      apex_web_service.make_rest_request(
         p_url => usps_util.build_url(
            p_api => 'Verify',
            p_xml => usps_util.get_address_xml(
                        p_userid => :USPS_USERID,
                        p_revision => 1,
                        p_firmname => 'Insum',
                        p_address1 => null,
                        p_address2 => '46 beekman',
                        p_city => 'Plattsburgh',
                        p_state => 'NY',
                        p_zip5 => null,
                        p_zip4 => null)
            ),
         p_http_method => 'GET'
      ) as response
   from dual
)
select
   usps_response.*
from
   request,
   usps_util.parse_address_xml(request.response) usps_response
;




select
   usps_util.get_address_xml(
      null, 1, 'Insum', '46 beekman st', null, 'Plattsburgh', 'NY')
from dual;

--usps address label
   select
      usps_address_util.format_usps_address(
           p_name => 'John Doe'
         , p_company => 'Johnson Manufacturing'
         , p_street_address1 => '500 E MAIN ST'
         , p_street_address2 => 'STE 222'
         , p_city => 'Kansas City'
         , p_state => 'MO'
         , p_zip5 => '64100'
         , p_zip4 => '1234'
      ) as usps_compatible_address
   from
      dual;
   
