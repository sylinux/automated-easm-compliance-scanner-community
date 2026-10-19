#!/usr/bin/env bash

# Définition des fichiers et sources
FICHIER_HTML="rapport_bounties.html"
URL_DATA="https://githubusercontent.com"

echo "📡 Extraction des cibles indépendantes en cours..."
TARGETS=$(curl -s "$URL_DATA")

if [ -z "$TARGETS" ]; then
    echo "❌ Erreur : Impossible de récupérer les données du flux."
    exit 1
fi

# 1. Écriture de l'en-tête HTML et du style CSS (Design épuré pour Brave)
cat << EOF > "$FICHIER_HTML"
<!DOCTYPE html>
<html lang="fr">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Recon-Tools - Programmes Autonomes</title>
    <style>
        body {
            font-family: 'Segoe UI', Arial, sans-serif;
            background-color: #1e1e24;
            color: #f4f4f6;
            margin: 0;
            padding: 30px;
        }
        .container {
            max-width: 850px;
            margin: auto;
        }
        h1 {
            color: #ff6600; /* Orange signature de Brave */
            border-bottom: 2px solid #3a3a42;
            padding-bottom: 12px;
            margin-bottom: 5px;
        }
        .meta {
            color: #a0a0aa;
            font-size: 0.9em;
            margin-bottom: 30px;
        }
        .card {
            background-color: #2a2a35;
            border-radius: 6px;
            padding: 18px;
            margin-bottom: 15px;
            border-left: 4px solid #ff6600;
            box-shadow: 0 4px 6px rgba(0, 0, 0, 0.2);
            display: flex;
            justify-content: space-between;
            align-items: center;
        }
        .company-name {
            font-size: 1.15em;
            font-weight: 600;
            color: #ffffff;
        }
        .btn-link {
            background-color: #ff6600;
            color: white;
            text-decoration: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-size: 0.9em;
            font-weight: bold;
            transition: background 0.2s;
        }
        .btn-link:hover {
            background-color: #e05500;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🎯 Liste des Cibles Autonomes (VRP)</h1>
        <div class="meta">Rapport généré automatiquement le : $(date '+%d/%m/%Y à %H:%M')</div>
EOF

# 2. Injection des données JSON transformées en composants HTML lisibles
echo "⚡ Conversion au format lisible par l'humain..."
echo "$TARGETS" | jq -r '.programs[] | select(.bounty == true) | "\(.name)|\(.url)"' | head -n 30 | while IFS="|" read -r NOM URL; do
    cat << EOF >> "$FICHIER_HTML"
        <div class="card">
            <div class="company-name">🏢 $NOM</div>
            <a class="btn-link" href="$URL" target="_blank">Ouvrir le Scope 🔗</a>
        </div>
EOF
done

# 3. Fermeture des balises HTML
cat << EOF >> "$FICHIER_HTML"
    </div>
</body>
</html>
EOF

echo "✅ Rapport créé avec succès : $FICHIER_HTML"
