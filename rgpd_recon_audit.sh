#!/bin/bash

# Configuration des couleurs pour la console
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [ -z "$1" ]; then
    echo -e "${RED}Usage: $0 <domaine_entreprise.com>${NC}"
    exit 1
fi

DOMAIN=$1
URL="https://$DOMAIN"
TMP_HTML="tmp_report.html"
OUTPUT_PDF="Rapport_Audit_RGPD_${DOMAIN}.pdf"

echo -e "${YELLOW}[*] Lancement de l'audit pour $DOMAIN...${NC}"

# ==========================================
# 1. COLLECTE DES DONNÉES TECHNIQUES
# ==========================================
IP_ADDR=$(host "$DOMAIN" | grep "has address" | head -n 1 | awk '{print $4}')
[ -z "$IP_ADDR" ] && IP_ADDR="Inconnue"

SERVER_WEB=$(curl -sI --connect-timeout 5 "$URL" | grep -i "server:" | awk '{print $2}' | tr -d '\r')
[ -z "$SERVER_WEB" ] && SERVER_WEB="Masqué / Inconnu"

END_DATE_RAW=$(echo | openssl s_client -connect "${DOMAIN}:443" -servername "${DOMAIN}" 2>/dev/null | openssl x509 -noout -enddate 2>/dev/null)
if [ -n "$END_DATE_RAW" ]; then
    END_DATE=$(echo "$END_DATE_RAW" | cut -d= -f2)
    END_EPOCH=$(date -d "$END_DATE" +%s 2>/dev/null)
    NOW_EPOCH=$(date +%s)
    DAYS_LEFT=$(( (END_EPOCH - NOW_EPOCH) / 86400 ))
    SSL_TXT="$DAYS_LEFT jours restants (Échéance : $(date -d "$END_DATE" "+%d/%m/%Y"))"
    [ "$DAYS_LEFT" -le 30 ] && SSL_STATUS="ALERTE" || SSL_STATUS="VALIDE"
else
    SSL_TXT="Échec de récupération"
    SSL_STATUS="ERREUR"
fi

DMARC_RECORD=$(host -t TXT _dmarc."$DOMAIN" 2>/dev/null)
if echo "$DMARC_RECORD" | grep -q "v=DMARC1"; then
    DMARC_STATUS="CONFORME"
    DMARC_CLASS="badge-success"
else
    DMARC_STATUS="MANQUANT (MISSING)"
    DMARC_CLASS="badge-danger"
fi

HEADERS=$(curl -sI --connect-timeout 5 "$URL")
SOURCE_CODE=$(curl -s --connect-timeout 5 "$URL")

check_header() {
    if echo "$HEADERS" | grep -iq "$1"; then echo "<td class='text-success'>Présent</td>"; else echo "<td class='text-danger'>MANQUANT (VULNÉRABLE)</td>"; fi
}

# ==========================================
# 2. GÉNÉRATION DU CODE HTML CORPORATIF + CADRE RGPD
# ==========================================
echo -e "${YELLOW}[*] Génération de la mise en page et du cadre juridique...${NC}"

cat <<EOF > "$TMP_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <style>
        @page { size: A4; margin: 20mm; @bottom-right { content: "Page " counter(page) " sur " counter(pages); font-size: 8pt; font-family: Arial; color: #718096; } }
        body { font-family: 'Helvetica Neue', Helvetica, Arial, sans-serif; color: #2d3748; line-height: 1.6; font-size: 11pt; }
        .header { border-bottom: 3px solid #1a365d; padding-bottom: 10px; margin-bottom: 25px; }
        .title { color: #1a365d; font-size: 22pt; margin: 0; font-weight: bold; }
        .subtitle { color: #4a5568; font-size: 11pt; margin-top: 5px; text-transform: uppercase; letter-spacing: 1px; }
        .meta-box { background: #f7fafc; border-left: 4px solid #3182ce; padding: 15px; margin-bottom: 25px; border-radius: 4px; }
        .meta-table { width: 100%; border-collapse: collapse; }
        .meta-table td { padding: 4px 8px; font-size: 10pt; }
        .meta-table td.label { font-weight: bold; color: #4a5568; width: 25%; }
        h2 { color: #2b6cb0; border-bottom: 1px solid #e2e8f0; padding-bottom: 5px; margin-top: 25px; font-size: 14pt; }
        table.data-table { width: 100%; border-collapse: collapse; margin-top: 15px; margin-bottom: 20px; }
        table.data-table th { background-color: #2d3748; color: white; text-align: left; padding: 10px; font-size: 9pt; text-transform: uppercase; }
        table.data-table td { padding: 10px; border-bottom: 1px solid #e2e8f0; font-size: 9.5pt; }
        .text-success { color: #38a169; font-weight: bold; }
        .text-danger { color: #e53e3e; font-weight: bold; }
        .badge-danger { background: #fed7d7; color: #9b2c2c; padding: 4px 8px; border-radius: 4px; font-weight: bold; }
        .badge-success { background: #c6f6d5; color: #22543d; padding: 4px 8px; border-radius: 4px; font-weight: bold; }
        
        /* NOUVEAU STYLE : CADRE JURIDIQUE RGPD EN RUPTURE DE PAGE SEPARÉE */
        .page-break { page-break-before: always; }
        .legal-framework-box { background-color: #fffaf0; border: 1px solid #feebc8; border-left: 4px solid #dd6b20; padding: 20px; border-radius: 6px; margin-top: 15px; }
        .legal-title { color: #c05621; font-size: 13pt; margin-top: 0; font-weight: bold; text-transform: uppercase; letter-spacing: 0.5px; }
        .legal-text { font-size: 8.5pt; color: #4a5568; text-align: justify; }
        .footer-offer { background: #ebf8ff; border: 1px solid #bee3f8; padding: 15px; border-radius: 6px; margin-top: 30px; }
    </style>
</head>
<body>

    <div class="header">
        <div class="title">Rapport d'Audit d'Exposition Numérique</div>
        <div class="subtitle">Conformité RGPD & Sécurité Périmétrique</div>
    </div>

    <div class="meta-box">
        <table class="meta-table">
            <tr>
                <td class="label">Cible Auditée :</td><td><strong>$DOMAIN</strong></td>
                <td class="label">Adresse IP :</td><td>$IP_ADDR</td>
            </tr>
            <tr>
                <td class="label">Date Analyse :</td><td>$(date "+%d/%m/%Y à %H:%M")</td>
                <td class="label">Serveur Web :</td><td>$SERVER_WEB</td>
            </tr>
            <tr>
                <td class="label">Statut SSL :</td>
                <td><span class="$( [ "$SSL_STATUS" = "VALIDE" ] && echo "text-success" || echo "text-danger" )">$SSL_TXT</span></td>
                <td class="label">Classification :</td><td>Confidentiel / Usage Privé</td>
            </tr>
        </table>
    </div>

    <h2>1. Sécurité de l'Infrastructure & Messagerie (Art. 32 du RGPD)</h2>
    <p>L'Article 32 du RGPD impose au responsable de traitement de mettre en œuvre les mesures techniques requises pour garantir la confidentialité des flux.</p>
    
    <table class="data-table">
        <thead>
            <tr>
                <th style="width: 30%;">Contrôle Éléments</th>
                <th style="width: 25%;">Statut Évalué</th>
                <th>Impact & Risques Potentiels</th>
            </tr>
        </thead>
        <tbody>
            <tr>
                <td><strong>Enregistrement DMARC</strong></td>
                <td><span class="$DMARC_CLASS">$DMARC_STATUS</span></td>
                <td>$( [ "$DMARC_STATUS" != "CONFORME" ] && echo "Risque critique d'usurpation d'identité de vos courriels (Phishing)." || echo "Protection active." )</td>
            </tr>
            <tr>
                <td>Strict-Transport-Security (HSTS)</td>
                $(check_header "Strict-Transport-Security")
                <td>Vulnérabilité aux attaques d'interception de type Man-in-the-Middle si manquant.</td>
            </tr>
            <tr>
                <td>X-Frame-Options</td>
                $(check_header "X-Frame-Options")
                <td>Facilite le détournement de clics (Clickjacking) sur vos formulaires.</td>
            </tr>
            <tr>
                <td>X-Content-Type-Options</td>
                $(check_header "X-Content-Type-Options")
                <td>Protège contre l'exécution détournée de fichiers de scripts injectés.</td>
            </tr>
        </tbody>
    </table>

    <h2>2. Conformité Vie Privée & Traceurs (Directives CNIL)</h2>
    <table class="data-table">
        <thead>
            <tr>
                <th>Traceurs identifiés au chargement brut</th>
                <th>Type / Catégorie</th>
                <th>Diagnostic Réglementaire</th>
            </tr>
        </thead>
        <tbody>
EOF

# Injection dynamique des traceurs
TRACKERS=("google-analytics.com" "googletagmanager.com" "connect.facebook.net" "hotjar")
ANY_TRACKER=0
for t in "${TRACKERS[@]}"; do
    if echo "$SOURCE_CODE" | grep -iq "$t"; then
        echo "<tr><td><code>$t</code></td><td>Marketing / Suivi tiers</td><td class='text-danger'>NON-CONFORME (Absence de consentement préalable)</td></tr>" >> "$TMP_HTML"
        ANY_TRACKER=1
    fi
done
if [ "$ANY_TRACKER" -eq 0 ]; then
    echo "<tr><td colspan='3' class='text-success'>Aucun traceur tiers détecté au chargement initial.</td></tr>" >> "$TMP_HTML"
fi

cat <<EOF >> "$TMP_HTML"
        </tbody>
    </table>

    <div class="footer-offer">
        <h3 style="margin-top:0; color:#2b6cb0; font-size:11pt;">🎯 Plan d'action & Offre de Remédiation</h3>
        <p style="margin:0; font-size:9.5pt;">Pour corriger ces écarts techniques et prémunir votre entité contre d'éventuelles sanctions administratives, nous proposons deux modalités d'intervention :<br>
        • <strong>Mise en conformité des en-têtes et protocoles de messagerie (DMARC/HSTS) :</strong> Forfait Unique — <strong>249 \$</strong><br>
        • <strong>Audit d'Exposition complet & Déploiement CMP (Bandeau Cookies conforme) :</strong> Forfait Expert — <strong>349 \$</strong></p>
    </div>

    <!-- ============================================================================== -->
    # 3. SAUT DE PAGE ET BLOC JURIDIQUE CADRE CONFORMITÉ RGPD
    <!-- ============================================================================== -->
    <div class="page-break"></div>
    
    <div class="legal-framework-box">
        <div class="legal-title">Annexe Juridique : Cadre d'Analyse et Conformité RGPD</div>
        <div class="legal-text">
            <p><strong>1. Périmètre de l'analyse :</strong> Le présent rapport constitue un audit d'exposition externe passif basé exclusivement sur le Renseignement d'Origine Source Ouverte (OSINT). Aucune tentative d'intrusion, test d'ingénierie sociale, ou scan vulnérant n'a été réalisé sur l'infrastructure de la cible auditée. Les données collectées correspondent aux métadonnées techniques et structures applicatives publiquement accessibles sur le réseau mondial Internet.</p>
            
