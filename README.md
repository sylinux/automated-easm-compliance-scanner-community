# Automated EASM Compliance Scanner

## 1. Systemic Scope & Core Value Proposition
Modern public and sovereign digital registries rely on rigid, automated ingestion pipelines. These architectures frequently introduce severe operational silos, resulting in data friction, unexpected compliance failures, and the unintended sequestration of cross-border corporate or private assets.

This repository hosts a production-grade, passive **External Attack Surface Management (EASM)** compliance engine designed to continuously audit network interactions with legacy institutional gateways without triggering active SOC firewall alarms.

## 2. Technical Capabilities & Passive Recon Telemetry
Instead of deploying hostile active port probing, the scanning engine executes a 100% compliant, passive metadata harvesting loop. By utilizing legal administrative/regulatory request vectors, it maps the target network’s behavior and exposes operational security (OPSEC) blind spots:
- **Internal Domain Leakage:** Extracts nested corporate/state intranet sub-domains (e.g., internal `.local` structures).
- **Edge Security Fingerprinting:** Captures specific Mail Transfer Agent (MTA) headers, custom firewall configurations, and Proofpoint GUID tags.
- **Inter-Ministerial Handoff Routing:** Tracks live SMTP hops and cross-department network transfers in real-time.

## 3. Commercial Support & Enterprise Integration

This community edition provides the open-source passive scanning core under the MIT license. For custom enterprise deployment, integration with internal SIEM platforms, or advanced network topology mapping, please contact our team via the security advisory channel.

## 4. How To Use & Production Examples

### 📋 Prerequisites
Ensure your scanning environment has the necessary passive logging and networking utilities installed before executing the engine:
```bash
sudo apt update && sudo apt install -y curl dnsutils tor torsocks
```

### 🚀 Quick Start
To execute a fully compliant, passive attack surface audit against a target infrastructure topology without active packet injection or port probing, run the core engine:

```bash
# Standard local validation mode
bash rgpd_recon_audit.sh --domain target-example.com

# Stealth compliance mode (Enforces Tor proxy routing via Torsocks)
torsocks bash rgpd_recon_audit.sh --domain target-example.com --stealth
```

### 📊 Understanding the Output Telemetry (JSON Payload)
The architecture generates a standardized compliance audit file named `compliance_report.json`. Security operation teams can ingest this structured data directly into SIEM pipelines or monitoring dashboards:

```json
{
  "target": "target-example.com",
  "timestamp": "2026-10-20T05:35:00Z",
  "easm_compliance": {
    "clickjacking_vulnerable": true,
    "mime_sniffing_vulnerable": true,
    "missing_headers": [
      "X-Frame-Options", 
      "X-Content-Type-Options"
    ]
  },
  "telemetry_metadata": {
    "passive_scan_duration_seconds": 1.15,
    "routing_protocol": "Tor Network (Torsocks)"
  }
}
```

### 🕒 Automated Continuous Monitoring (Cron Integration)
To continuously track external network exposure and check for compliance drift over time, you can schedule the passive scanner to execute daily:

```bash
# Append this task to your system crontab to execute a quiet check every midnight
0 0 * * * /bin/bash /path/to/rgpd_recon_audit.sh --domain target-example.com --silent >> /var/log/easm_compliance.log
```

## 5. Legal & Licensing
This software is officially deployed under the **MIT License**. 
Copyright (c) 2026 sylinux. Personal target endpoints and structural network variables remain strictly confidential and uncommitted to the public repository structure.

## 🔹 Commercial Licensing & Inbound Engagement Fees
This framework is monetized under a three-tiered commercial model tailored for threat intelligence analysts, legal compliance firms, and corporate recovery agents:

*   **Tier 1: Core EASM Engine Ingestion — $499 USD (Base Price)**
    - Full access to the automated open-source passive scanning core.
    - Standard metadata processing modules.
    - Intended for individual developers and small-scale asset hunters.
*   **Tier 2: Corporate Integration & Target Fingerprinting — From $2,500 USD (Fixed Setup)**
    - Custom configuration of the passive proxy rotation matrix.
    - Enterprise-level setup on private dedicated servers.
    - Full architectural mapping of target state and institutional network nodes.
*   **Tier 3: High-Value Sovereign Recovery Arbitrage — Hybrid Model**
    - For major historical asset déshérence cases (> $100,000 USD value).
    - Requires a **$1,000 USD upfront technical retaining fee** to deploy dedicated passive monitoring nodes.
    - Operates on a **15% to 35% contingency fee model** upon successful manual administrative extraction.

## 🔹 Legal & Licensing
This software is officially deployed under the **MIT License**.  
Copyright (c) 2026 sylinux. Personal target endpoints and structural network variables remain strictly confidential and uncommitted to the public repository structure.
