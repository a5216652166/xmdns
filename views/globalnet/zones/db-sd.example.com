; -- special case hostname == @
; Example Sub-Domain
sd.example.com.	IN NS	ns1.sd.example.com.
sd.example.com.	IN NS	ns2.sd.example.com.

