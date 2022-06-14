# apex-geocoding-and-address-validation
Sample application demonstrating 3 options for geocoding and address validation in Oracle APEX. 

- APEX Geocoded Address Item
- ArcGIS Geocoding Service
- US Postal Services Web Tools API

### Requirements

- APEX 21.2+
- Oracle DB 12c+ (*The USPS_UTIL package does work on 11*g)
- Network ACL allowing access to secure.shippingapis.com and geocode.arcgis.com
- Oracle Wallet containing root certificates for secure.shippingapis.com and geocode.arcgis.com
- Registration required to use the USPS Web Tools API. Register here: https://www.usps.com/business/web-tools-apis/

Includes two PL/SQL packages used to interact with the US Postal Services Web Tools API and ArcGIS Geocoding Service.

## APEX Geocoded Address Item
Introduced in APEX 21.2, the Geocoded Address Item lets you geocode and validate addresses or places without writing any code.

## ArcGIS Geocoding Service
API Docs: https://developers.arcgis.com/rest/geocode/api-reference/overview-world-geocoding-service.htm

## United States Postal Services Web Tools API
API Docs: https://www.usps.com/business/web-tools-apis/documentation-updates.htm
