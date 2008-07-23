;
;
; BIND 9 Zone file for example.com
; This is written automatically from domain_list.xsl and contains any special
; mappings that do not fit into normal host entries (very rare occasion)
;
;
$TTL	604800
@ IN SOA ns1.example.com. dns_admin.example.com. (
	20050523	  ; Serial
	360	  ; Refresh
	1800	  ; Retry
	604800	  ; Expire
	86400	) ; Negative Cache TTL
; Any entries here have been specified by hand in the domain_list.xml file
;
; All other entries are updated via the host_list.xml file
$include "/etc/bind/views/example-internal/zones/db-example.com"
