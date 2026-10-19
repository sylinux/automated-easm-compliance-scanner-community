#!/usr/bin/env bash
# ============================================================
#  Recon-Tool — Automated Reconnaissance & Vulnerability Framework
#  Author  : st4ns3c
#  Version : 1.0.0
#  Usage   : chmod +x recon-tool.sh && ./recon-tool.sh
# ============================================================

SCRIPT_START=$(date +%s)
VERSION="1.0.0"
AUTHOR="st4ns3c"
TARGET=""
OUTDIR=""
OPEN_PORTS=""

RED='\e[1;31m'
YELLOW='\e[1;33m'
GREEN='\e[1;32m'
CYAN='\e[1;36m'
BLUE='\e[1;34m'
MAGENTA='\e[1;35m'
WHITE='\e[1;37m'
DIM='\e[2m'
ITALIC='\e[3m'
BOLD='\e[1m'
RESET='\e[0m'

info()    { echo -e "${CYAN}[*]${RESET} $*"; }
success() { echo -e "${GREEN}[+]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[-]${RESET} $*"; }
phase()   { echo -e "\n${MAGENTA}${BOLD}[>>]════════════════════════════════════════${RESET}"; \
            echo -e "${MAGENTA}${BOLD}[>>]  $*${RESET}"; \
            echo -e "${MAGENTA}${BOLD}[>>]════════════════════════════════════════${RESET}\n"; }
finding() { echo -e "${RED}${BOLD}[FOUND]${RESET} ${RED}$*${RESET}"; }

log_to_file() {
  local file="$1"; shift
  echo "$*" | sed 's/\x1b\[[0-9;]*m//g' >> "$file"
}

elapsed() {
  local now; now=$(date +%s)
  echo $(( now - SCRIPT_START ))
}

trap_handler() {
  echo -e "\n\n${RED}${BOLD}[!] Interrupted by user (SIGINT).${RESET}"
  [[ -n "$OUTDIR" ]] && echo -e "${YELLOW}[!] Partial results saved to: ${OUTDIR}${RESET}"
  echo -e "${DIM}    Exiting cleanly...${RESET}\n"
  exit 1
}
trap trap_handler SIGINT SIGTERM

spinner() {
  local pid="$1"; local msg="$2"
  local chars="◐◓◑◒"
  local spin_colors=("${RED}" "${YELLOW}" "${GREEN}" "${CYAN}")
  local i=0
  while kill -0 "$pid" 2>/dev/null; do
    local ci=$(( i % 4 ))
    printf "\r${spin_colors[$ci]}[${chars:$ci:1}]${RESET} ${DIM}%s${RESET}" "$msg"
    sleep 0.15
    (( i++ )) || true
  done
  printf "\r${GREEN}[✓]${RESET} ${msg}\n"
}

show_banner() {
  clear
  echo ""
  echo -e "${RED}██████╗ ███████╗ ██████╗ ██████╗ ███╗   ██╗    ████████╗ ██████╗  ██████╗ ██╗     ${RESET}"
  echo -e "${YELLOW}██╔══██╗██╔════╝██╔════╝██╔═══██╗████╗  ██║    ╚══██╔══╝██╔═══██╗██╔═══██╗██║     ${RESET}"
  echo -e "${GREEN}██████╔╝█████╗  ██║     ██║   ██║██╔██╗ ██║       ██║   ██║   ██║██║   ██║██║     ${RESET}"
  echo -e "${CYAN}██╔══██╗██╔══╝  ██║     ██║   ██║██║╚██╗██║       ██║   ██║   ██║██║   ██║██║     ${RESET}"
  echo -e "${BLUE}██║  ██║███████╗╚██████╗╚██████╔╝██║ ╚████║       ██║   ╚██████╔╝╚██████╔╝███████╗${RESET}"
  echo -e "${MAGENTA}╚═╝  ╚═╝╚══════╝ ╚═════╝ ╚═════╝ ╚═╝  ╚═══╝       ╚═╝    ╚═════╝  ╚═════╝ ╚══════╝${RESET}"
  echo ""
  echo -e "         ${CYAN}──────────────────────────────────────────────────────${RESET}"
  echo -e "         ${ITALIC}${DIM}          scripted by ${AUTHOR}${RESET}"
  echo -e "         ${DIM}       From reconnaissance to exploitation — automated.${RESET}"
  echo -e "         ${DIM}                    Version ${VERSION}${RESET}"
  echo -e "         ${CYAN}──────────────────────────────────────────────────────${RESET}"
  echo ""
}

REQUIRED_TOOLS=(whois whatweb dig nslookup curl subfinder httpx nmap nuclei nikto dalfox sqlmap)
OPTIONAL_TOOLS=(findomain amass assetfinder ffuf masscan gobuster waybackurls gau katana)
declare -A TOOL_STATUS

check_tools() {
  phase "TOOL AVAILABILITY CHECK"
  for tool in "${REQUIRED_TOOLS[@]}"; do
    command -v "$tool" &>/dev/null \
      && TOOL_STATUS["$tool"]="${GREEN}✓ Found${RESET}" \
      || TOOL_STATUS["$tool"]="${RED}✗ Missing${RESET}"
  done
  for tool in "${OPTIONAL_TOOLS[@]}"; do
    command -v "$tool" &>/dev/null \
      && TOOL_STATUS["$tool"]="${GREEN}✓ Found${RESET}" \
      || TOOL_STATUS["$tool"]="${YELLOW}- Optional${RESET}"
  done

  echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${BOLD}        REQUIRED TOOLS                    ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╠═══════════════════╦══════════════════════╣${RESET}"
  for tool in "${REQUIRED_TOOLS[@]}"; do
    printf "${CYAN}║${RESET} %-17s ${CYAN}║${RESET} %-30b${RESET}${CYAN}║${RESET}\n" "$tool" "${TOOL_STATUS[$tool]}"
  done
  echo -e "${CYAN}╠═══════════════════╩══════════════════════╣${RESET}"
  echo -e "${CYAN}║${BOLD}        OPTIONAL TOOLS                    ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╠═══════════════════╦══════════════════════╣${RESET}"
  for tool in "${OPTIONAL_TOOLS[@]}"; do
    printf "${CYAN}║${RESET} %-17s ${CYAN}║${RESET} %-30b${RESET}${CYAN}║${RESET}\n" "$tool" "${TOOL_STATUS[$tool]}"
  done
  echo -e "${CYAN}╚═══════════════════╩══════════════════════╝${RESET}"
  echo ""

  local core_recon=(subfinder httpx nmap nuclei)
  local any_core=false
  for tool in "${core_recon[@]}"; do
    command -v "$tool" &>/dev/null && { any_core=true; break; }
  done
  if [[ "$any_core" == "false" ]]; then
    error "None of the core scanning tools are installed. Cannot proceed."
    exit 1
  fi
  success "Tool check complete. Missing tools will be skipped gracefully."
  echo ""
}

get_target() {
  echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${BOLD}           TARGET SELECTION               ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
  echo ""
  echo -e "  ${DIM}Single domain  :  ${WHITE}vulnbank.org${RESET}"
  echo -e "  ${DIM}Wordlist file  :  ${WHITE}targets.txt${RESET}"
  echo ""
  read -rp "$(echo -e "  ${CYAN}[>]${RESET} Target or file: ")" USER_INPUT

  USER_INPUT="${USER_INPUT#http://}"
  USER_INPUT="${USER_INPUT#https://}"
  USER_INPUT="${USER_INPUT%/}"
  USER_INPUT="${USER_INPUT// /}"

  if [[ -z "$USER_INPUT" ]]; then
    error "No input provided. Exiting."
    exit 1
  fi

  if [[ -f "$USER_INPUT" ]]; then
    info "Wordlist detected: ${USER_INPUT}"
    TARGETS_FILE="$USER_INPUT"
    MULTI_TARGET=true
  else
    [[ ! "$USER_INPUT" =~ \. ]] && { error "Invalid domain: '${USER_INPUT}'"; exit 1; }
    TARGETS_FILE=""
    MULTI_TARGET=false
    TARGET="$USER_INPUT"
  fi
}

extract_dirname() {
  local input="$1"
  if [[ -f "$input" ]]; then
    basename "$input" .txt
  else
    echo "$input" | awk -F'.' '{if(NF>=2){print $(NF-1)}else{print $1}}'
  fi
}

setup_dirs() {
  local target="$1"
  local dirname; dirname=$(extract_dirname "$target")
  OUTDIR="$HOME/${dirname}"
  info "Creating output directory: ${OUTDIR}"
  mkdir -p "${OUTDIR}"/{recon,subdomains,portscan,vulnscan,report}
  cat > "${OUTDIR}/report/summary.txt" <<EOF
==============================================
         RECON-TOOL REPORT SUMMARY
         Target : ${target}
         Date   : $(date '+%Y-%m-%d %H:%M:%S')
         Author : ${AUTHOR}
         Version: ${VERSION}
==============================================

EOF
  success "Output structure created at: ${OUTDIR}"
  echo ""
  if command -v tree &>/dev/null; then
    tree -L 2 "$OUTDIR"
  else
    echo -e "${DIM}  ${OUTDIR}/\n  ├── recon/\n  ├── subdomains/\n  ├── portscan/\n  ├── vulnscan/\n  └── report/${RESET}"
  fi
  echo ""
}

phase1_passive_recon() {
  local target="$1"; local outdir="$2"
  local p_start; p_start=$(date +%s)
  phase "PHASE 1: PASSIVE RECONNAISSANCE → ${target}"
  { echo "[PASSIVE RECON] — ${target}"; echo "────────────────────────────────────"; } >> "${outdir}/report/summary.txt"

  if command -v whois &>/dev/null; then
    info "Running WHOIS lookup..."
    whois "$target" 2>/dev/null > "${outdir}/recon/whois.txt"
    local registrar creation expiry nameservers
    registrar=$(grep -i "Registrar:" "${outdir}/recon/whois.txt" | head -1 | cut -d':' -f2- | xargs 2>/dev/null)
    creation=$(grep -i "Creation Date\|Created On\|created:" "${outdir}/recon/whois.txt" | head -1 | cut -d':' -f2- | xargs 2>/dev/null)
    expiry=$(grep -i "Expiry Date\|Expiration Date\|expires:" "${outdir}/recon/whois.txt" | head -1 | cut -d':' -f2- | xargs 2>/dev/null)
    nameservers=$(grep -i "Name Server:" "${outdir}/recon/whois.txt" | cut -d':' -f2- | xargs 2>/dev/null | tr '\n' ' ')
    success "WHOIS complete"
    [[ -n "$registrar" ]]   && { echo -e "   ${DIM}Registrar   :${RESET} ${registrar}";   echo "  Registrar   : ${registrar}"   >> "${outdir}/report/summary.txt"; }
    [[ -n "$creation" ]]    && { echo -e "   ${DIM}Created     :${RESET} ${creation}";    echo "  Created     : ${creation}"    >> "${outdir}/report/summary.txt"; }
    [[ -n "$expiry" ]]      && { echo -e "   ${DIM}Expires     :${RESET} ${expiry}";      echo "  Expires     : ${expiry}"      >> "${outdir}/report/summary.txt"; }
    [[ -n "$nameservers" ]] && { echo -e "   ${DIM}Name Servers:${RESET} ${nameservers}"; echo "  Name Servers: ${nameservers}" >> "${outdir}/report/summary.txt"; }
  else
    warn "whois not found — skipping"
  fi
  echo ""; sleep 1

  if command -v whatweb &>/dev/null; then
    info "Running WhatWeb fingerprinting..."
    whatweb -v --color=never "https://${target}" 2>/dev/null > "${outdir}/recon/whatweb.txt"
    success "WhatWeb complete → ${outdir}/recon/whatweb.txt"
    local cms server
    cms=$(grep -i "WordPress\|Drupal\|Joomla\|Laravel\|Django\|Rails" "${outdir}/recon/whatweb.txt" | head -1 | xargs 2>/dev/null)
    server=$(grep -i "Apache\|Nginx\|IIS\|LiteSpeed\|Caddy" "${outdir}/recon/whatweb.txt" | head -1 | xargs 2>/dev/null)
    [[ -n "$cms" ]]    && { finding "CMS detected: ${cms}";        echo "  [FINDING] CMS: ${cms}"    >> "${outdir}/report/summary.txt"; }
    [[ -n "$server" ]] && { finding "Server detected: ${server}";  echo "  [FINDING] Server: ${server}" >> "${outdir}/report/summary.txt"; }
  else
    warn "whatweb not found — skipping"
  fi
  echo ""; sleep 1

  if command -v dig &>/dev/null; then
    info "Running DNS enumeration with dig..."
    {
      echo "=== ANY ==="
      dig ANY "$target" +noall +answer 2>/dev/null
      echo "=== MX ==="
      dig MX "$target" +short 2>/dev/null
      echo "=== TXT ==="
      dig TXT "$target" +short 2>/dev/null
      echo "=== DMARC ==="
      dig TXT "_dmarc.${target}" +short 2>/dev/null
    } > "${outdir}/recon/dig.txt"
    success "dig DNS records saved"
    grep -qi "v=spf1" "${outdir}/recon/dig.txt" 2>/dev/null \
      || { finding "SPF record MISSING — email spoofing may be possible"; echo "  [FINDING] SPF MISSING" >> "${outdir}/report/summary.txt"; }
    grep -qi "v=DMARC1" "${outdir}/recon/dig.txt" 2>/dev/null \
      || { finding "DMARC record MISSING"; echo "  [FINDING] DMARC MISSING" >> "${outdir}/report/summary.txt"; }
  else
    warn "dig not found — skipping"
  fi
  echo ""; sleep 1

  if command -v nslookup &>/dev/null; then
    info "Running nslookup..."
    nslookup "$target" 2>/dev/null > "${outdir}/recon/nslookup.txt"
    success "nslookup complete"
  else
    warn "nslookup not found — skipping"
  fi
  echo ""; sleep 1

  if command -v curl &>/dev/null; then
    info "Fetching HTTP response headers..."
    curl -sk -I --max-time 10 "https://${target}" 2>/dev/null > "${outdir}/recon/headers.txt"
    [[ ! -s "${outdir}/recon/headers.txt" ]] && {
      warn "HTTPS failed, trying HTTP..."
      curl -sk -I --max-time 10 "http://${target}" 2>/dev/null > "${outdir}/recon/headers.txt"
    }
    success "Headers saved"
    echo ""
    echo -e "  ${BOLD}Security Header Analysis:${RESET}"
    { echo ""; echo "  [HTTP SECURITY HEADERS]"; } >> "${outdir}/report/summary.txt"
    declare -A HEADER_CHECK=(
      ["X-Frame-Options"]="Clickjacking protection"
      ["Content-Security-Policy"]="XSS/injection policy"
      ["X-Content-Type-Options"]="MIME-sniffing protection"
      ["Strict-Transport-Security"]="HSTS — forces HTTPS"
      ["Referrer-Policy"]="Referrer leakage"
      ["Permissions-Policy"]="Browser feature permissions"
    )
    for header in "${!HEADER_CHECK[@]}"; do
      if grep -qi "^${header}:" "${outdir}/recon/headers.txt" 2>/dev/null; then
        echo -e "   ${GREEN}[✓]${RESET} ${header}"
      else
        echo -e "   ${RED}[✗]${RESET} ${header} ${DIM}(${HEADER_CHECK[$header]})${RESET}"
        finding "Missing header: ${header}"
        echo "    [MISSING] ${header} — ${HEADER_CHECK[$header]}" >> "${outdir}/report/summary.txt"
      fi
    done
  else
    warn "curl not found — skipping header analysis"
  fi
  echo ""
  success "Phase 1 complete in $(( $(date +%s) - p_start ))s"
  echo "" >> "${outdir}/report/summary.txt"
}

phase2_subdomain_enum() {
  local target="$1"; local outdir="$2"
  local p_start; p_start=$(date +%s)
  phase "PHASE 2: SUBDOMAIN ENUMERATION → ${target}"
  { echo "[SUBDOMAIN ENUMERATION] — ${target}"; echo "────────────────────────────────────"; } >> "${outdir}/report/summary.txt"
  local any_ran=false

  if command -v subfinder &>/dev/null; then
    info "Launching subfinder..."
    subfinder -d "$target" -silent -o "${outdir}/subdomains/subfinder.txt" 2>/dev/null &
    spinner $! "subfinder — passive subdomain discovery"
    success "subfinder: $(wc -l < "${outdir}/subdomains/subfinder.txt" 2>/dev/null || echo 0) subdomains"
    any_ran=true
  else
    warn "subfinder not found — skipping"
  fi

  if command -v findomain &>/dev/null; then
    info "Launching findomain..."
    findomain -t "$target" -q -u "${outdir}/subdomains/findomain.txt" 2>/dev/null &
    spinner $! "findomain — certificate transparency search"
    success "findomain: $(wc -l < "${outdir}/subdomains/findomain.txt" 2>/dev/null || echo 0) subdomains"
    any_ran=true
  else
    warn "findomain not found — skipping"
  fi

  if command -v amass &>/dev/null; then
    info "Launching amass (passive)..."
    amass enum -passive -d "$target" -o "${outdir}/subdomains/amass.txt" 2>/dev/null &
    spinner $! "amass — OSINT subdomain enumeration"
    success "amass: $(wc -l < "${outdir}/subdomains/amass.txt" 2>/dev/null || echo 0) subdomains"
    any_ran=true
  else
    warn "amass not found — skipping"
  fi

  if command -v assetfinder &>/dev/null; then
    info "Launching assetfinder..."
    assetfinder --subs-only "$target" > "${outdir}/subdomains/assetfinder.txt" 2>/dev/null &
    spinner $! "assetfinder — asset subdomain discovery"
    success "assetfinder: $(wc -l < "${outdir}/subdomains/assetfinder.txt" 2>/dev/null || echo 0) subdomains"
    any_ran=true
  else
    warn "assetfinder not found — skipping"
  fi

  if [[ "$any_ran" == "false" ]]; then
    error "No subdomain tools available. Skipping phase 2."
    echo "  [SKIPPED] No subdomain tools found" >> "${outdir}/report/summary.txt"
    return
  fi

  info "Merging and deduplicating results..."
  cat "${outdir}/subdomains/"*.txt 2>/dev/null | grep -v "^$" | sort -u > "${outdir}/subdomains/all_subdomains.txt"
  local total; total=$(wc -l < "${outdir}/subdomains/all_subdomains.txt")
  success "Total unique subdomains: ${total}"
  echo "  Total unique subdomains: ${total}" >> "${outdir}/report/summary.txt"

  if command -v httpx &>/dev/null; then
    info "Probing live hosts with httpx..."
    cat "${outdir}/subdomains/all_subdomains.txt" \
      | httpx -silent -status-code -title -tech-detect -follow-redirects -timeout 10 2>/dev/null \
      > "${outdir}/subdomains/live_subdomains.txt" &
    spinner $! "httpx — probing ${total} subdomains"
    local live; live=$(wc -l < "${outdir}/subdomains/live_subdomains.txt" 2>/dev/null || echo 0)
    success "Live subdomains: ${live}"
    echo "  Live subdomains: ${live}" >> "${outdir}/report/summary.txt"
    local ok; ok=$(grep -c "\[200\]" "${outdir}/subdomains/live_subdomains.txt" 2>/dev/null || echo 0)
    [[ "$ok" -gt 0 ]] && finding "${ok} subdomains returned HTTP 200"
  else
    warn "httpx not found — skipping live probe"
    cp "${outdir}/subdomains/all_subdomains.txt" "${outdir}/subdomains/live_subdomains.txt"
  fi

  echo "" >> "${outdir}/report/summary.txt"
  success "Phase 2 complete in $(( $(date +%s) - p_start ))s"
  echo ""
}

phase3_port_scan() {
  local target="$1"; local outdir="$2"
  local p_start; p_start=$(date +%s)
  phase "PHASE 3: PORT SCANNING & SERVICE DETECTION → ${target}"
  { echo "[PORT SCAN] — ${target}"; echo "────────────────────────────────────"; } >> "${outdir}/report/summary.txt"

  if ! command -v nmap &>/dev/null; then
    warn "nmap not found — skipping port scanning"
    echo "  [SKIPPED] nmap not found" >> "${outdir}/report/summary.txt"
    return
  fi

  info "Step 1/3 — Quick top-1000 port scan..."
  nmap -T4 --top-ports 1000 --open -oN "${outdir}/portscan/nmap_quick.txt" "$target" 2>/dev/null &
  spinner $! "nmap — scanning top 1000 ports on ${target}"

  OPEN_PORTS=$(grep "^[0-9]" "${outdir}/portscan/nmap_quick.txt" 2>/dev/null \
    | grep "open" | cut -d'/' -f1 | paste -sd',' 2>/dev/null)

  if [[ -z "$OPEN_PORTS" ]]; then
    warn "No open ports detected. Target may be down or firewalled."
    echo "  No open ports found" >> "${outdir}/report/summary.txt"
    return
  fi

  success "Open ports: ${OPEN_PORTS}"
  echo "  Open ports: ${OPEN_PORTS}" >> "${outdir}/report/summary.txt"
  echo ""

  info "Step 2/3 — Service & version detection on [${OPEN_PORTS}]..."
  nmap -sV -sC -p "${OPEN_PORTS}" -oN "${outdir}/portscan/nmap_services.txt" "$target" 2>/dev/null &
  spinner $! "nmap -sV -sC — service fingerprinting"
  success "Service detection complete"

  { echo ""; echo "  [SERVICES]"; } >> "${outdir}/report/summary.txt"
  for svc in ftp telnet smtp smb rdp vnc rsh rlogin; do
    grep -qi "$svc" "${outdir}/portscan/nmap_services.txt" 2>/dev/null && {
      finding "Dangerous service detected: ${svc}"
      echo "    [FINDING] Dangerous service: ${svc}" >> "${outdir}/report/summary.txt"
    }
  done

  local apache_ver; apache_ver=$(grep -i "Apache httpd" "${outdir}/portscan/nmap_services.txt" 2>/dev/null | grep -oP "Apache httpd [\d\.]+" | head -1)
  [[ -n "$apache_ver" ]] && { finding "${apache_ver} — verify not EOL"; echo "    [FINDING] ${apache_ver}" >> "${outdir}/report/summary.txt"; }
  local nginx_ver; nginx_ver=$(grep -i "nginx" "${outdir}/portscan/nmap_services.txt" 2>/dev/null | grep -oP "nginx/[\d\.]+" | head -1)
  [[ -n "$nginx_ver" ]] && { finding "Nginx: ${nginx_ver}"; echo "    [FINDING] ${nginx_ver}" >> "${outdir}/report/summary.txt"; }

  echo ""; sleep 1

  info "Step 3/3 — Running nmap vuln scripts on [${OPEN_PORTS}]..."
  nmap --script vuln -p "${OPEN_PORTS}" -oN "${outdir}/portscan/nmap_vuln_scripts.txt" "$target" 2>/dev/null &
  spinner $! "nmap --script vuln — CVE detection"
  success "Vuln script scan complete"

  { echo ""; echo "  [NMAP VULN SCRIPTS]"; } >> "${outdir}/report/summary.txt"
  local vuln_lines; vuln_lines=$(grep -A2 "VULNERABLE\|State: VULNERABLE" "${outdir}/portscan/nmap_vuln_scripts.txt" 2>/dev/null)
  if [[ -n "$vuln_lines" ]]; then
    finding "nmap vuln scripts found vulnerabilities!"
    echo "$vuln_lines" | sed 's/^/    /' >> "${outdir}/report/summary.txt"
  else
    info "No critical vulns from nmap scripts (manual review recommended)"
    echo "    No critical vulns from nmap scripts" >> "${outdir}/report/summary.txt"
  fi

  echo "" >> "${outdir}/report/summary.txt"
  success "Phase 3 complete in $(( $(date +%s) - p_start ))s"
  echo ""
}

phase4_vuln_scan() {
  local target="$1"; local outdir="$2"
  local p_start; p_start=$(date +%s)
  phase "PHASE 4: VULNERABILITY SCANNING (OWASP TOP 10) → ${target}"
  { echo "[VULNERABILITY SCAN] — ${target}"; echo "────────────────────────────────────"; } >> "${outdir}/report/summary.txt"

  if command -v nuclei &>/dev/null; then
    info "Running nuclei — CVE & misconfiguration templates..."
    nuclei -u "https://${target}" \
      -t cves/ -t exposures/ -t misconfiguration/ -t vulnerabilities/ -t technologies/ \
      -severity medium,high,critical -silent \
      -o "${outdir}/vulnscan/nuclei.txt" 2>/dev/null &
    spinner $! "nuclei — CVE/exposure/misconfiguration scan"
    success "Nuclei complete → ${outdir}/vulnscan/nuclei.txt"
    if [[ -s "${outdir}/vulnscan/nuclei.txt" ]]; then
      local critical high medium
      critical=$(grep -ci "\[critical\]" "${outdir}/vulnscan/nuclei.txt" 2>/dev/null || echo 0)
      high=$(grep -ci "\[high\]"     "${outdir}/vulnscan/nuclei.txt" 2>/dev/null || echo 0)
      medium=$(grep -ci "\[medium\]"  "${outdir}/vulnscan/nuclei.txt" 2>/dev/null || echo 0)
      echo -e "\n   ${RED}${BOLD}CRITICAL: ${critical}${RESET}  ${RED}HIGH: ${high}${RESET}  ${YELLOW}MEDIUM: ${medium}${RESET}\n"
      { echo "  [NUCLEI] CRITICAL:${critical} HIGH:${high} MEDIUM:${medium}"; echo ""; } >> "${outdir}/report/summary.txt"
      while IFS= read -r line; do
        local sev url tmpl
        sev=$(echo "$line" | grep -oP '\[(critical|high|medium|low|info)\]' | tr -d '[]' | tr '[:lower:]' '[:upper:]')
        url=$(echo "$line" | grep -oP 'https?://[^ ]+' | head -1)
        tmpl=$(echo "$line" | grep -oP '\[[a-z0-9:_-]+\]' | head -1 | tr -d '[]')
        finding "[nuclei] ${sev} — ${tmpl} @ ${url}"
        { echo "  [${sev}] ${tmpl}"; echo "         URL: ${url}"; echo "         Verify: curl -sk '${url}' | head -50"; echo ""; } >> "${outdir}/report/summary.txt"
      done < "${outdir}/vulnscan/nuclei.txt"
    else
      info "Nuclei: no medium+ findings"
      echo "  Nuclei: No medium+ findings" >> "${outdir}/report/summary.txt"
    fi
  else
    warn "nuclei not found — skipping"
  fi
  echo ""; sleep 1

  if command -v nikto &>/dev/null; then
    info "Running Nikto web server scan..."
    nikto -h "https://${target}" -output "${outdir}/vulnscan/nikto.txt" -Format txt -nointeractive 2>/dev/null &
    spinner $! "nikto — web server misconfiguration scan"
    success "Nikto complete"
    { echo "  [NIKTO]"; grep -i "OSVDB\|+ " "${outdir}/vulnscan/nikto.txt" 2>/dev/null | head -20 | sed 's/^/    /'; echo ""; } >> "${outdir}/report/summary.txt"
  else
    warn "nikto not found — skipping"
  fi
  echo ""; sleep 1

  if command -v dalfox &>/dev/null; then
    info "Collecting URLs for XSS testing..."
    local xss_urls="/tmp/recon_xss_$$.txt"
    if command -v gau &>/dev/null; then
      echo "$target" | gau --subs 2>/dev/null | grep "=" | grep -v "\.\(jpg\|png\|gif\|css\|js\|svg\|ico\)$" > "$xss_urls" &
      spinner $! "gau — harvesting parameterized URLs"
    elif command -v waybackurls &>/dev/null; then
      echo "$target" | waybackurls 2>/dev/null | grep "=" > "$xss_urls" &
      spinner $! "waybackurls — fetching from Wayback Machine"
    else
      echo "https://${target}" > "$xss_urls"
    fi
    local url_count; url_count=$(wc -l < "$xss_urls" 2>/dev/null || echo 1)
    info "Testing ${url_count} URL(s) with dalfox..."
    if [[ "$url_count" -gt 1 ]]; then
      dalfox file "$xss_urls" --silence -o "${outdir}/vulnscan/xss_dalfox.txt" 2>/dev/null &
    else
      dalfox url "https://${target}" --silence -o "${outdir}/vulnscan/xss_dalfox.txt" 2>/dev/null &
    fi
    spinner $! "dalfox — XSS scanning ${url_count} endpoints"
    rm -f "$xss_urls"
    if [[ -s "${outdir}/vulnscan/xss_dalfox.txt" ]]; then
      local xss_count; xss_count=$(wc -l < "${outdir}/vulnscan/xss_dalfox.txt")
      finding "dalfox found ${xss_count} XSS vector(s)!"
      { echo "  [XSS — DALFOX] ${xss_count} finding(s)"; cat "${outdir}/vulnscan/xss_dalfox.txt" | sed 's/^/    /'; echo "  Fix: Sanitize input. Implement Content-Security-Policy."; echo ""; } >> "${outdir}/report/summary.txt"
    else
      info "dalfox: no confirmed XSS"
      echo "  [XSS] No confirmed XSS by dalfox" >> "${outdir}/report/summary.txt"
    fi
  else
    warn "dalfox not found — skipping XSS"
  fi
  echo ""; sleep 1

  if command -v sqlmap &>/dev/null; then
    info "Running sqlmap SQL injection scan (crawl mode)..."
    warn "sqlmap will crawl ${target} — this may trigger WAF alerts"
    sqlmap -u "https://${target}/" --crawl=2 --batch --level=2 --risk=2 \
      --random-agent --output-dir="${outdir}/vulnscan/sqlmap_output/" \
      2>&1 > "${outdir}/vulnscan/sqli_sqlmap.txt" &
    spinner $! "sqlmap — crawling and testing for SQL injection"
    success "sqlmap complete"
    if grep -qi "is vulnerable\|Parameter.*injectable" "${outdir}/vulnscan/sqli_sqlmap.txt" 2>/dev/null; then
      finding "sqlmap found SQL INJECTION!"
      { echo "  [SQLi — SQLMAP] VULNERABLE"; grep -i "is vulnerable\|Parameter.*injectable\|Type:" "${outdir}/vulnscan/sqli_sqlmap.txt" 2>/dev/null | head -10 | sed 's/^/    /'; echo "  Exploit: re-run sqlmap with --dump on the vulnerable param"; echo "  Fix: Use parameterized queries / prepared statements."; echo ""; } >> "${outdir}/report/summary.txt"
    else
      info "sqlmap: no injectable parameters in crawl scope"
      echo "  [SQLi] No injectable parameters found in crawl scope" >> "${outdir}/report/summary.txt"
    fi
  else
    warn "sqlmap not found — skipping"
  fi
  echo ""
  success "Phase 4 complete in $(( $(date +%s) - p_start ))s"
  echo ""
}

generate_report() {
  local target="$1"; local outdir="$2"
  phase "GENERATING FINAL REPORT"
  local total_elapsed; total_elapsed=$(elapsed)
  {
    echo ""
    echo "=============================================="
    echo "  Duration : ${total_elapsed}s"
    echo "  Finished : $(date '+%Y-%m-%d %H:%M:%S')"
    echo "  Output   : ${outdir}/"
    echo "=============================================="
    echo "  Stay ethical. Stay legal."
    echo "  ${AUTHOR} — Recon-Tool v${VERSION}"
    echo "=============================================="
  } >> "${outdir}/report/summary.txt"

  success "Report saved: ${outdir}/report/summary.txt"
  echo ""

  local total_findings; total_findings=$(grep -c "\[FINDING\]\|\[CRITICAL\]\|\[HIGH\]\|MISSING\|XSS\|SQLi" "${outdir}/report/summary.txt" 2>/dev/null || echo 0)
  echo -e "${CYAN}╔══════════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${BOLD}            SCAN SUMMARY                  ${RESET}${CYAN}║${RESET}"
  echo -e "${CYAN}╠══════════════════════════════════════════╣${RESET}"
  printf "${CYAN}║${RESET} %-40s ${CYAN}║${RESET}\n" "Target   : ${target}"
  printf "${CYAN}║${RESET} %-40s ${CYAN}║${RESET}\n" "Output   : ${outdir}/"
  printf "${CYAN}║${RESET} %-40s ${CYAN}║${RESET}\n" "Duration : ${total_elapsed}s"
  printf "${CYAN}║${RESET} %-40s ${CYAN}║${RESET}\n" "Findings : ${total_findings}"
  echo -e "${CYAN}╚══════════════════════════════════════════╝${RESET}"
  echo ""
}

show_ending() {
  local outdir="$1"
  echo ""
  local chars="◐◓◑◒"
  local spin_colors=("${RED}" "${YELLOW}" "${GREEN}" "${CYAN}" "${BLUE}" "${MAGENTA}")
  for i in $(seq 1 40); do
    local ci=$(( i % 6 )); local chi=$(( i % 4 ))
    printf "\r${spin_colors[$ci]}  [${chars:$chi:1}]  Finalizing engagement...${RESET}"
    sleep 0.1
  done
  printf "\r%-60s\r" " "
  echo ""

  local word1="  H A P P Y"
  local word2="  H A C K I N G ! ! !"
  local colors=("${RED}" "${YELLOW}" "${GREEN}" "${CYAN}" "${BLUE}" "${MAGENTA}" "${WHITE}")
  local ci=0
  for (( i=0; i<${#word1}; i++ )); do
    printf "${colors[$((ci % 7))]}%s${RESET}" "${word1:$i:1}"; sleep 0.04; (( ci++ )) || true
  done
  echo ""
  for (( i=0; i<${#word2}; i++ )); do
    printf "${colors[$((ci % 7))]}%s${RESET}" "${word2:$i:1}"; sleep 0.04; (( ci++ )) || true
  done
  echo ""; echo ""
  echo -e "${GREEN}  ██╗  ██╗ █████╗ ██████╗ ██████╗ ██╗   ██╗${RESET}"
  echo -e "${CYAN}  ██║  ██║██╔══██╗██╔══██╗██╔══██╗╚██╗ ██╔╝${RESET}"
  echo -e "${BLUE}  ███████║███████║██████╔╝██████╔╝ ╚████╔╝ ${RESET}"
  echo -e "${MAGENTA}  ██╔══██║██╔══██║██╔═══╝ ██╔═══╝   ╚██╔╝  ${RESET}"
  echo -e "${YELLOW}  ██║  ██║██║  ██║██║      ██║        ██║   ${RESET}"
  echo -e "${RED}  ╚═╝  ╚═╝╚═╝  ╚═╝╚═╝      ╚═╝        ╚═╝   ${RESET}"
  echo ""
  echo -e "${GREEN}  ██╗  ██╗ █████╗  ██████╗██╗  ██╗██╗███╗   ██╗ ██████╗ ${RESET}"
  echo -e "${CYAN}  ██║  ██║██╔══██╗██╔════╝██║ ██╔╝██║████╗  ██║██╔════╝ ${RESET}"
  echo -e "${BLUE}  ███████║███████║██║     █████╔╝ ██║██╔██╗ ██║██║  ███╗${RESET}"
  echo -e "${MAGENTA}  ██╔══██║██╔══██║██║     ██╔═██╗ ██║██║╚██╗██║██║   ██║${RESET}"
  echo -e "${YELLOW}  ██║  ██║██║  ██║╚██████╗██║  ██╗██║██║ ╚████║╚██████╔╝${RESET}"
  echo -e "${RED}  ╚═╝  ╚═╝╚═╝  ╚═╝ ╚═════╝╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝ ${RESET}"
  echo ""
  echo -e "  ${GREEN}[+]${RESET} Report  : ${BOLD}${outdir}/report/summary.txt${RESET}"
  echo -e "  ${GREEN}[+]${RESET} Output  : ${BOLD}${outdir}/${RESET}"
  echo -e "  ${CYAN}[*]${RESET} Stay ethical. Stay legal. Hack responsibly."
  echo -e "  ${DIM}      ${AUTHOR} — Recon-Tool v${VERSION}${RESET}"
  echo ""
}

process_target() {
  local raw="$1"
  raw="${raw#http://}"; raw="${raw#https://}"; raw="${raw%/}"; raw="${raw// /}"
  TARGET="$raw"
  echo ""
  echo -e "${CYAN}╔══════════════════════════════════════╗${RESET}"
  echo -e "${CYAN}║${BOLD}  TARGET: ${TARGET}${RESET}"
  echo -e "${CYAN}╚══════════════════════════════════════╝${RESET}"
  echo ""
  setup_dirs "$TARGET"
  phase1_passive_recon "$TARGET" "$OUTDIR"
  phase2_subdomain_enum "$TARGET" "$OUTDIR"
  phase3_port_scan "$TARGET" "$OUTDIR"
  phase4_vuln_scan "$TARGET" "$OUTDIR"
  generate_report "$TARGET" "$OUTDIR"
}

main() {
  show_banner
  get_target
  check_tools
  if [[ "$MULTI_TARGET" == "true" ]]; then
    local n=0
    local total; total=$(grep -c "." "$TARGETS_FILE" 2>/dev/null || echo 0)
    info "Wordlist mode: ${total} targets in ${TARGETS_FILE}"
    echo ""
    while IFS= read -r line || [[ -n "$line" ]]; do
      [[ -z "$line" || "$line" == \#* ]] && continue
      (( n++ )) || true
      echo -e "\n${MAGENTA}${BOLD}[>>] ─── Target ${n}/${total}: ${line} ───${RESET}"
      process_target "$line"
    done < "$TARGETS_FILE"
    success "All ${n} targets processed."
    show_ending "$HOME"
  else
    process_target "$TARGET"
    show_ending "$OUTDIR"
  fi
}

main "$@"
