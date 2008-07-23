; -- special case hostname == @
; Example Sub-Domain
sd.example.com.	IN NS	internal-ns1.sd.example.com.
sd.example.com.	IN NS	internal-ns2.sd.example.com.

