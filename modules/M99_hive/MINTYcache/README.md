# MINTYcache

MINTYcache ist der Cache-Agent des MINTYhive-Systems. Er ist verantwortlich für die Zwischenspeicherung von Daten, die Analyse von Codestrukturen und die Optimierung der Kontextfenster.

## Funktionen

- **Projektscannen**: Analysiert die Struktur von Projekten und speichert Metadaten
- **Codesemantik**: Analysiert die Semantik von Code und extrahiert wichtige Informationen
- **Kontextfenster-Management**: Optimiert die Größe und den Inhalt von Kontextfenstern
- **MCP-Integration**: Stellt Cache-Funktionen über das Model Context Protocol bereit

## Komponenten

- **ProjectScanner**: Scannt Projekte und extrahiert Metadaten
- **CodeParser**: Analysiert Code und extrahiert semantische Informationen
- **ContextManager**: Verwaltet Kontextfenster und optimiert deren Inhalt
- **MCPServer**: Stellt Cache-Funktionen über das MCP-Protokoll bereit

## Konfiguration

Die Konfiguration erfolgt über die Datei `config/cache_config.json`. Folgende Einstellungen können angepasst werden:

- **ScanSettings**: Konfiguration des Projektscanners
- **ParserSettings**: Konfiguration des Codeparsers
- **ContextSettings**: Konfiguration des Kontextmanagers
- **MCPSettings**: Konfiguration des MCP-Servers

## Verwendung

```javascript
// Beispiel für die Verwendung des MCP-Servers
const { MCPServer } = require('./src/MCP/MCPServer');

// Server erstellen
const server = new MCPServer({
  port: 8080,
  host: 'localhost'
});

// Server starten
server.start();

// Cache-Funktionen nutzen
server.cacheProject('/path/to/project');
server.getProjectStructure('/path/to/project');
server.getCodeSemantics('/path/to/file.js');
server.optimizeContext(context, maxTokens);
```

Weitere Beispiele finden Sie in der Datei `examples/use_mcp_server.js`.

## Integration mit anderen Agenten

MINTYcache integriert sich mit anderen Agenten des MINTYhive-Systems, um eine optimale Nutzung des Kontextfensters zu ermöglichen. Andere Agenten können die Cache-Funktionen über das MCP-Protokoll nutzen.

## Dokumentation

Weitere Informationen zur Implementierung und Verwendung von MINTYcache finden Sie in den Dokumenten im `docs`-Ordner:

- `docs/cache_system_plan.md`: Ursprünglicher Plan für das Cache-System
- `docs/cache_system_plan_v2.md`: Überarbeiteter Plan für das Cache-System
- `docs/cache_system_plan_final.md`: Finaler Plan für das Cache-System
- `docs/implementation_plan_phase1.md`: Implementierungsplan für Phase 1
- `docs/agent_hive_setup.md`: Einrichtung des Agents im Hive-System
