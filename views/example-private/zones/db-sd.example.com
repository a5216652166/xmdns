;
; SRV helper records for the kerberos realm SD.EXAMPLE.COM (_kerberos._udp)
_kerberos._udp.sd.example.com.	IN SRV	0 1 88 puppy.sd.example.com.
_kerberos._udp.sd.example.com.	IN SRV	1 1 88 dog.sd.example.com.

;
; Example kerberos server (puppy)
puppy.sd.example.com.	IN A	192.0.2.5
puppy.sd.example.com.	IN AAAA	2001:0db8:0000:0000:0000:0000:0000:0005

; -- special case hostname == @
; Example Sub-Domain
sd.example.com.	IN NS	ns1.sd.example.com.
sd.example.com.	IN NS	ns2.sd.example.com.

