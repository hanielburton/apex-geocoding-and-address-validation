create or replace package usps_util as

--Production base_url used for secure data transfer
k_base_url constant varchar2(100) := 'https://secure.shippingapis.com/ShippingAPI.dll';

--Returns AddressValidateRequest XML
function get_address_xml(
   p_userid in varchar2,
   p_revision in varchar default '0', --'1' to return additional fields
   p_firmname in varchar2 default null, --optional
   p_address1 in varchar2 default null, --optional
   p_address2 in varchar2, --required
   p_city in varchar2, --required
   p_state in varchar2, --required
   p_zip5 in varchar2 default null, --optional
   p_zip4 in varchar2 default null --optional
) return clob deterministic;

--Record object type for an address
--Lenght limits from here: https://www.serviceobjects.com/blog/character-limits-in-address-lines-for-usps-ups-and-fedex/
--and here: https://www.usps.com/business/web-tools-apis/address-information-api.htm#_Toc39492053
type r_usps_address_type is record
(
     firmname varchar2(46 CHAR)
   , address1 varchar2(46 CHAR)
   , address2 varchar2(46 CHAR)
   , city varchar2(15 CHAR)
   , state varchar2(2 CHAR)
   , zip5 varchar2(5 CHAR)
   , zip4 varchar2(4 CHAR)
   , returntext varchar2(4000 CHAR)
   , deliverypoint varchar2(4000 CHAR)
   , carrierroute varchar2(5 CHAR)
   , footnotes varchar2(50 CHAR)
   , dpvconfirmation varchar2(1 CHAR)
   , dpvcmra varchar2(1 CHAR)
   , dpvfootnotes varchar2(8 CHAR)
   , business varchar2(1 CHAR)
   , centraldeliverypoint varchar2(1 CHAR)
   , vacant varchar2(1 CHAR)
   , error_number varchar2(4000)
   , error_source varchar2(4000)
   , error_description varchar2(4000)
   , error_helpfile varchar2(4000)
);

--Table of r_usps_address_type 
type t_usps_address_type is table of r_usps_address_type;

--Parses XML with address nodes from either a request or response
--and returns pipelined table of r_usps_address_type
function parse_address_xml(
   p_xml in clob
) return t_usps_address_type pipelined deterministic;

--Returns CityStateLookupRequest XML
function get_city_state_lookup_xml(
   p_userid in varchar2,
   p_zip5 in varchar2 --5-digit zip
) return clob deterministic;

--Returns TrackRequest XML
function get_track_request_xml(
    p_userid in varchar2,
    p_trackid in varchar2
) return clob deterministic;

--Builds full URL including URL-escaped XML request
function build_url(
   p_api in varchar2, --i.e. 'Verify', 'TrackV2', 'ZipCodeLookup', 'CityStateLookup'
   p_xml in clob,--XML request from one of the functions, will be automatically wrapped with utl_url.escape
   p_override_base_url in varchar2 default k_base_url --i.e. https://production.shippingapis.com/ShippingAPI.dll
) return varchar2 deterministic;

--Combines multiple parts of an address to return a single value with newlines and spaces according to USPS guidelines.
--Name is optional, but useful for shipping labels
--Shipping Guidelines: https://pe.usps.com/businessmail101?ViewName=DeliveryAddress
--Postal Addressing Guidelines: https://pe.usps.com/text/pub28/28c2_001.htm#ep526236
--All capital letters, no punctuation, one space between city and state, two spaces between state and ZIP
/*  
   Sample Query
   
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
   
   Sample Output
   
   JOHN DOE                    --Recipient Line
   JOHNSON MANUFACTURING       --Optional Company Line
   500 E MAIN ST STE 222       --Delivery Address Line
   KANSAS CITY MO  64100-1234  --Last Line
*/
function format_address_label(
     p_name in varchar2 default null --i.e. John Doe or ATTN:
   , p_company in varchar default null --i.e. Some Company
   , p_street_address1 in varchar2 --House number and Street address
   , p_street_address2 in varchar2 default null --Optional apt/suite/other
   , p_city in varchar2
   , p_state in varchar2
   , p_zip5 in varchar2
   , p_zip4 in varchar2 default null --Optional, if included will be appended to zip5 as "zip5-zip4"
) return varchar2 deterministic;

end usps_util;