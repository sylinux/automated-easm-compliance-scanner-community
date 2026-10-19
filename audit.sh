#!/bin/bash
D=$1
[ -z "$D" ] && echo "Usage: $0 domaine.com" && exit 1

echo "--- INFRASTRUCTURE & CERTIFICAT ---"
E=$(echo | openssl s_client -connect "$D":443 -servername "$D" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null | cut -d= -f2)
if [ -n "$E" ]; then
    J=$(( ($(date -d "$E" +%s) - $(date +%s)) / 86400 ))
    echo "SSL Expiration : $J jours restants (Échéance : $E)"
else
    echo "SSL : Erreur de connexion"
fi

echo "--- MESSAGERIE (DMARC) ---"
host -t TXT _dmarc."$D" 2>/dev/null | grep -q "v=DMARC1" && echo "DMARC : Présent" || echo "DMARC : MISSING"

echo "--- EN-TÊTES DE SÉCURITÉ ---"
H=$(curl -sI --connect-timeout 4 "https://$D")
for h in "Strict-Transport-Security" "X-Frame-Options" "X-Content-Type-Options"; do
    echo "$H" | grep -iq "$h" && echo "$h : OK" || echo "$h : MANQUANT"
done

echo "--- TRACEURS MARKETING TIERS ---"
S=$(curl -s --connect-timeout 4 "https://$D")
for t in "google-analytics" "googletagmanager" "facebook.net" "hotjar"; do
    echo "$S" | grep -iq "$t" && echo "Traceur détecté : $t"
done
