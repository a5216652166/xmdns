; -- special case hostname == @
; Example Domain
example.com.	IN MX	10 mx.example.com.
example.com.	IN MX	20 mx2.example.com.

; -- special case hostname == @
; Example Domain
example.com.	IN NS	ns1.example.com.
example.com.	IN NS	ns2.example.com.

;
; Example Sub-Domain (sd)
sd.example.com.	IN NS	internal-ns1.sd.example.com.
sd.example.com.	IN NS	internal-ns2.sd.example.com.

