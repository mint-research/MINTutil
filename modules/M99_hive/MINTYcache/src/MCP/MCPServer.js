// MINTYcache MCP Server
// Implements the Model Context Protocol server for the MINTYcache agent

import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import {
    CallToolRequestSchema,
    ErrorCode,
    ListResourcesRequestSchema,
    ListResourceTemplatesRequestSchema,
    ListToolsRequestSchema,
    McpError,
    ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';

/**
 * MINTYcache MCP Server
 * Exposes MINTYcache functionality as MCP tools and resources
 */
class MINTYcacheServer {
    /**
     * The MCP server instance
     */
    server;

    /**
     * Reference to the CacheManager
     */
    cacheManager;

    /**
     * Constructor
     */
    constructor() {
        this.server = new Server(
            {
                name: 'minty-cache-server',
                version: '1.0.0',
            },
            {
                capabilities: {
                    resources: {},
                    tools: {},
                },
            }
        );

        // Initialize the CacheManager
        // In a real implementation, this would be properly imported and instantiated
        this.cacheManager = {
            GetProjectStructure: (path, refresh) => ({ path, refresh, mock: true }),
            GetCodeSemantics: (path, refresh) => ({ path, refresh, mock: true }),
            OptimizeContext: (context, targetSize) => ({ context, targetSize, mock: true }),
            RotateContext: (context, strategy) => ({ context, strategy, mock: true }),
            GetContextWindowStatus: (usedTokens, totalTokens) => ({ usedTokens, totalTokens, mock: true }),
        };

        // Set up tool and resource handlers
        this.setupToolHandlers();
        this.setupResourceHandlers();

        // Set up error handling
        this.server.onerror = (error) => console.error('[MCP Error]', error);
        process.on('SIGINT', async () => {
            await this.server.close();
            process.exit(0);
        });
    }

    /**
     * Set up MCP tool handlers
     */
    setupToolHandlers() {
        // List available tools
        this.server.setRequestHandler(ListToolsRequestSchema, async () => ({
            tools: [
                {
                    name: 'get_project_structure',
                    description: 'Get the structure of a project',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            path: {
                                type: 'string',
                                description: 'Project path',
                            },
                            refresh: {
                                type: 'boolean',
                                description: 'Whether to refresh the cache',
                                default: false,
                            },
                        },
                        required: ['path'],
                    },
                },
                {
                    name: 'get_code_semantics',
                    description: 'Get semantic information about code',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            path: {
                                type: 'string',
                                description: 'File or directory path',
                            },
                            refresh: {
                                type: 'boolean',
                                description: 'Whether to refresh the cache',
                                default: false,
                            },
                        },
                        required: ['path'],
                    },
                },
                {
                    name: 'optimize_context',
                    description: 'Optimize context window usage',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            context: {
                                type: 'object',
                                description: 'Current context',
                            },
                            targetSize: {
                                type: 'number',
                                description: 'Target size in tokens',
                            },
                        },
                        required: ['context', 'targetSize'],
                    },
                },
                {
                    name: 'rotate_context',
                    description: 'Rotate context information',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            context: {
                                type: 'object',
                                description: 'Current context',
                            },
                            strategy: {
                                type: 'string',
                                description: 'Rotation strategy',
                                enum: ['aggressive', 'balanced', 'conservative'],
                                default: 'balanced',
                            },
                        },
                        required: ['context'],
                    },
                },
                {
                    name: 'get_context_status',
                    description: 'Get context window status',
                    inputSchema: {
                        type: 'object',
                        properties: {
                            usedTokens: {
                                type: 'number',
                                description: 'Number of tokens used',
                            },
                            totalTokens: {
                                type: 'number',
                                description: 'Total number of tokens available',
                            },
                        },
                        required: ['usedTokens', 'totalTokens'],
                    },
                },
            ],
        }));

        // Handle tool calls
        this.server.setRequestHandler(CallToolRequestSchema, async (request) => {
            try {
                switch (request.params.name) {
                    case 'get_project_structure': {
                        const { path, refresh = false } = request.params.arguments;
                        const structure = this.cacheManager.GetProjectStructure(path, refresh);
                        return {
                            content: [
                                {
                                    type: 'text',
                                    text: JSON.stringify(structure, null, 2),
                                },
                            ],
                        };
                    }

                    case 'get_code_semantics': {
                        const { path, refresh = false } = request.params.arguments;
                        const semantics = this.cacheManager.GetCodeSemantics(path, refresh);
                        return {
                            content: [
                                {
                                    type: 'text',
                                    text: JSON.stringify(semantics, null, 2),
                                },
                            ],
                        };
                    }

                    case 'optimize_context': {
                        const { context, targetSize } = request.params.arguments;
                        const optimizedContext = this.cacheManager.OptimizeContext(context, targetSize);
                        return {
                            content: [
                                {
                                    type: 'text',
                                    text: JSON.stringify(optimizedContext, null, 2),
                                },
                            ],
                        };
                    }

                    case 'rotate_context': {
                        const { context, strategy = 'balanced' } = request.params.arguments;
                        const rotationResult = this.cacheManager.RotateContext(context, strategy);
                        return {
                            content: [
                                {
                                    type: 'text',
                                    text: JSON.stringify(rotationResult, null, 2),
                                },
                            ],
                        };
                    }

                    case 'get_context_status': {
                        const { usedTokens, totalTokens } = request.params.arguments;
                        const status = this.cacheManager.GetContextWindowStatus(usedTokens, totalTokens);
                        return {
                            content: [
                                {
                                    type: 'text',
                                    text: JSON.stringify(status, null, 2),
                                },
                            ],
                        };
                    }

                    default:
                        throw new McpError(
                            ErrorCode.MethodNotFound,
                            `Unknown tool: ${request.params.name}`
                        );
                }
            } catch (error) {
                console.error(`Error executing tool ${request.params.name}:`, error);
                return {
                    content: [
                        {
                            type: 'text',
                            text: `Error: ${error.message}`,
                        },
                    ],
                    isError: true,
                };
            }
        });
    }

    /**
     * Set up MCP resource handlers
     */
    setupResourceHandlers() {
        // List available resources
        this.server.setRequestHandler(ListResourcesRequestSchema, async () => ({
            resources: [
                {
                    uri: 'cache://project_structure/current',
                    name: 'Current project structure',
                    mimeType: 'application/json',
                    description: 'Structure of the current project',
                },
                {
                    uri: 'cache://code_semantics/current',
                    name: 'Current code semantics',
                    mimeType: 'application/json',
                    description: 'Semantic information about the current code',
                },
                {
                    uri: 'cache://context_status/current',
                    name: 'Current context status',
                    mimeType: 'application/json',
                    description: 'Status of the current context window',
                },
            ],
        }));

        // List available resource templates
        this.server.setRequestHandler(ListResourceTemplatesRequestSchema, async () => ({
            resourceTemplates: [
                {
                    uriTemplate: 'cache://project_structure/{path}',
                    name: 'Project structure for a specific path',
                    mimeType: 'application/json',
                    description: 'Structure of a project at the specified path',
                },
                {
                    uriTemplate: 'cache://code_semantics/{path}',
                    name: 'Code semantics for a specific path',
                    mimeType: 'application/json',
                    description: 'Semantic information about code at the specified path',
                },
            ],
        }));

        // Handle resource reads
        this.server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
            try {
                const uri = request.params.uri;

                // Handle static resources
                if (uri === 'cache://project_structure/current') {
                    const structure = this.cacheManager.GetProjectStructure('./');
                    return {
                        contents: [
                            {
                                uri,
                                mimeType: 'application/json',
                                text: JSON.stringify(structure, null, 2),
                            },
                        ],
                    };
                }

                if (uri === 'cache://code_semantics/current') {
                    const semantics = this.cacheManager.GetCodeSemantics('./');
                    return {
                        contents: [
                            {
                                uri,
                                mimeType: 'application/json',
                                text: JSON.stringify(semantics, null, 2),
                            },
                        ],
                    };
                }

                if (uri === 'cache://context_status/current') {
                    const status = this.cacheManager.GetContextWindowStatus(8000, 16000); // Example values
                    return {
                        contents: [
                            {
                                uri,
                                mimeType: 'application/json',
                                text: JSON.stringify(status, null, 2),
                            },
                        ],
                    };
                }

                // Handle dynamic resources
                const projectStructureMatch = uri.match(/^cache:\/\/project_structure\/(.+)$/);
                if (projectStructureMatch) {
                    const path = decodeURIComponent(projectStructureMatch[1]);
                    const structure = this.cacheManager.GetProjectStructure(path);
                    return {
                        contents: [
                            {
                                uri,
                                mimeType: 'application/json',
                                text: JSON.stringify(structure, null, 2),
                            },
                        ],
                    };
                }

                const codeSemanticMatch = uri.match(/^cache:\/\/code_semantics\/(.+)$/);
                if (codeSemanticMatch) {
                    const path = decodeURIComponent(codeSemanticMatch[1]);
                    const semantics = this.cacheManager.GetCodeSemantics(path);
                    return {
                        contents: [
                            {
                                uri,
                                mimeType: 'application/json',
                                text: JSON.stringify(semantics, null, 2),
                            },
                        ],
                    };
                }

                throw new McpError(
                    ErrorCode.ResourceNotFound,
                    `Resource not found: ${uri}`
                );
            } catch (error) {
                console.error(`Error reading resource ${request.params.uri}:`, error);
                throw new McpError(
                    ErrorCode.InternalError,
                    `Error reading resource: ${error.message}`
                );
            }
        });
    }

    /**
     * Run the MCP server
     */
    async run() {
        const transport = new StdioServerTransport();
        await this.server.connect(transport);
        console.error('MINTYcache MCP server running on stdio');
    }
}

// Create and run the server
const server = new MINTYcacheServer();
server.run().catch(console.error);
