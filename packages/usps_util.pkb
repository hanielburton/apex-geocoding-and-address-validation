create or replace package body usps_util as

function get_address_xml(
   p_userid in varchar2,
   p_revision in varchar default '0', --'1' to return additional fields
   p_firmname in varchar2 default null, --optional
   p_address1 in varchar2 default null, --optional
   p_address2 in varchar2, --required
   p_city in varchar2, --required
   p_state in varchar2, --required
   p_zip5 in varchar2, --optional
   p_zip4 in varchar2 default null --optional
) return clob deterministic
is
   l_return clob;
begin
   --Assertions
   --@TODO: Add assertions to ensure limits and other requirements
   --assert(length(p_city) =2, 'Value of p_city is not 2 characters');
   
   --docs: https://www.usps.com/business/web-tools-apis/address-information-api.htm#_Toc39492052
   --Builds XML for <AddressValidateRequest>
   select
      xmlserialize(document
         xmlelement("AddressValidateRequest", xmlattributes (p_userid as "USERID"),
            xmlelement("Revision", p_revision), --use 1 to return all available fields
            xmlagg(
               xmlelement("Address",
                  xmlelement("FirmName", p_firmname), --Optional
                  xmlelement("Address1", p_address1), --Optional
                  xmlelement("Address2", p_address2), --Required
                  xmlelement("City", p_city ), --Required
                  xmlelement("State", p_state), --Required
                  xmlelement("Zip5", p_zip5), --Optional
                  xmlelement("Zip4", p_zip4) --Optional
               )
            )
         )
         as clob
         indent size=2
      )
   into
      l_return
   from 
      dual;

   return l_return;

end get_address_xml;

--Parses XML from address verify response and returns pipelined table of r_usps_address_type
function parse_address_xml(
   p_xml in clob
) return t_usps_address_type pipelined deterministic
is
begin
   for rec in (
      select
         firmname              as firmname
       , address1              as address1
       , address2              as address2
       , city                  as city
       , state                 as state
       , zip5                  as zip5
       , zip4                  as zip4
       , returntext            as returntext
       , deliverypoint         as deliverypoint
       , carrierroute          as carrierroute
       , footnotes             as footnotes
       , dpvconfirmation       as dpvconfirmation
       , dpvcmra               as dpvcmra
       , dpvfootnotes          as dpvfootnotes
       , business              as business
       , centraldeliverypoint  as centraldeliverypoint
       , vacant                as vacant
       , error_number          as error_number
       , error_source          as error_source
       , error_description     as error_description
       , error_helpfile        as error_helpfile
      from
         xmltable ( '/*/Address'
             passing sys.xmltype(p_xml)
             columns
                firmname varchar2(46 CHAR) path 'FirmName[1]'
              , address1 varchar2(46 CHAR) path 'Address1[1]'
              , address2 varchar2(46 CHAR) path 'Address2[1]'
              , city varchar2(15 CHAR) path 'City[1]'
              , state varchar2(2 CHAR) path 'State[1]'
              , zip5 varchar2(5 CHAR) path 'Zip5[1]'
              , zip4 varchar2(4 CHAR) path 'Zip4[1]'
              , returntext varchar2(4000 CHAR) path 'ReturnText[1]'
              , deliverypoint varchar2(4000 CHAR) path 'DeliveryPoint[1]'
              , carrierroute varchar2(5 CHAR) path 'CarrierRoute[1]'
              , footnotes varchar2(50 CHAR) path 'Footnotes[1]'
              , dpvconfirmation varchar2(1 CHAR) path 'DPVConfirmation[1]'
              , dpvcmra varchar2(1 CHAR) path 'DPVCMRA[1]'
              , dpvfootnotes varchar2(8 CHAR) path 'DPVFootnotes[1]'
              , business varchar2(1 CHAR) path 'Business[1]'
              , centraldeliverypoint varchar2(1 CHAR) path 'CentralDeliveryPoint[1]'
              , vacant varchar2(1 CHAR) path 'Vacant[1]'
              , error_number VARCHAR2(4000 CHAR) path 'Error/Number[1]'
              , error_source VARCHAR2(4000 CHAR) path 'Error/Source[1]'
              , error_description VARCHAR2(4000 CHAR) path 'Error/Description[1]'
              , error_helpfile VARCHAR2(4000 CHAR) path 'Error/HelpFile'
         )
   )
   loop
     pipe row(rec);
   end loop;
   --Empty return
   return;
end parse_address_xml;

function get_city_state_lookup_xml(
   p_userid in varchar2,
   p_zip5 in varchar2 --5-digit zip
) return clob deterministic
is
   l_return clob;
begin
   select
      xmlserialize(document
         xmlelement("CityStateLookupRequest", xmlattributes (p_userid as "USERID"),
            xmlelement("ZipCode", xmlattributes ('0' as ID), 
                  xmlelement("Zip5", p_zip5)
            )
         )
      as clob
      indent size=2
      )
   into
      l_return
   from 
      dual;

   return l_return;
end get_city_state_lookup_xml;

--Returns TrackRequest XML
function get_track_request_xml(
   p_userid in varchar2,
   p_trackid in varchar2
) return clob deterministic
is
   l_return clob;
begin
   --docs: https://www.usps.com/business/web-tools-apis/track-and-confirm-api.htm#_Toc41911505
   select
      xmlserialize(document
         xmlelement("TrackRequest", xmlattributes (p_userid as "USERID"),
               xmlelement("TrackID", xmlattributes (p_trackid as ID)
               )
         )
         as clob
         indent size=2
      )
   into
      l_return
   from 
      dual;
   
   return l_return;
end get_track_request_xml;

--Builds full URL including URL-escaped XML request
function build_url(
   p_api in varchar2, --i.e. 'Verify', 'TrackV2', 'ZipCodeLookup', 'CityStateLookup'
   p_xml in clob,--XML request from one of the functions, will be automatically wrapped with utl_url.escape
   p_override_base_url in varchar2 default k_base_url --i.e. https://production.shippingapis.com/ShippingAPI.dll
) return varchar2 deterministic
is
   l_return varchar2(32767);
begin
   l_return := p_override_base_url||'?API='||p_api||'&XML='||utl_url.escape(p_xml);
   return l_return;
end build_url;

--Purpose is to format address parts according to USPS guidelines.
--Name and company are optional, but useful for shipping labels.
--Shipping Guidelines: https://pe.usps.com/businessmail101?ViewName=DeliveryAddress
--Postal Addressing Guidelines: https://pe.usps.com/text/pub28/28c2_001.htm#ep526236
--All capital letters, no punctuation, one space between city and state, two spaces between state and ZIP
/* 
   Sample Return:

   JOHN DOE
   JOHNSON MANUFACTURING
   500 E MAIN ST STE 222
   KANSAS CITY MO  64100-1234
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
) return varchar2 deterministic
is
   l_return varchar2(32767);
   --carriage return and line feed (new line)
   l_crlf varchar2(4 CHAR) := chr(13)||chr(10);
begin
   --@TODO: Remove special characters per these guidelines: https://pe.usps.com/text/pub28/28c3_019.htm
   --@TODO: Add assertions to ensure limits and other requirements
   
   --Add name if not null     
   case 
      when p_name is not null then
         l_return := p_name ||l_crlf;
      else
         l_return := null;
   end case;
   
   --Add company if not null
   case
      when p_company is not null then
         l_return := l_return||p_company ||l_crlf;
      else
         l_return := l_return || null;
   end case;

   --Add address line1 and append line2 if not null
   case
      when p_street_address2 is not null then
         l_return := l_return||p_street_address1||' '||p_street_address2 ||l_crlf;
      else
         l_return := l_return||p_street_address1 ||l_crlf;
   end case;
   
   --Add City State (One space between city and state, two spaces between state and zip)
   l_return := l_return||p_city||' '||p_state||'  ';

   --Build full zip and add 

   --Add zip5-zip4, or just zip5 if zip is null
   case
      when p_zip4 is not null then
         l_return := l_return||p_zip5||'-'||p_zip4;
      else
         l_return := l_return||p_zip5;
   end case;

   --Capitalize everything
   l_return := upper(l_return);

   return l_return;

end format_address_label;

end usps_util;