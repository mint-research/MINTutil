// Example script to demonstrate using the MINTYcache MCP server
// This script shows how to connect to the MCP server and use its tools and resources

import { spawn } from 'child_process';
import { Client } from '@modelcontextprotocol/sdk/client/index.js';
import { StdioClientTransport } from '@modelcontextprotocol/sdk/client/stdio.js';

/**
 * Main function to demonstrate MCP client usage
 */
async function main() {
    console.log('Starting MINTYcache MCP client example...');

    // Start the MCP server as a child process
    const serverProcess = spawn('node', ['../src/MCP/MCPServer.js'], {
        stdio: ['pipe', 'pipe', 'pipe'],
    });

    // Create a transport that communicates with the server via stdio
    const transport = new StdioClientTransport({
        stdin: serverProcess.stdin,
        stdout: serverProcess.stdout,
    });

    // Create the MCP client
    const client = new Client();

    try {
        // Connect to the server
        await client.connect(transport);
        console.log('Connected to MINTYcache MCP server');

        // List available tools
        const tools = await client.listTools();
        console.log('Available tools:');
        for (const tool of tools) {
            console.log(`- ${tool.name}: ${tool.description}`);
        }
        console.log();

        // List available resources
        const resources = await client.listResources();
        console.log('Available resources:');
        for (const resource of resources) {
            console.log(`- ${resource.uri}: ${resource.name}`);
        }
        console.log();

        // Example 1: Get project structure
        console.log('Example 1: Getting project structure...');
        const projectStructureResult = await client.callTool('get_project_structure', {
            path: './',
            refresh: true,
        });
        console.log('Project structure result:');
        console.log(projectStructureResult);
        console.log();

        // Example 2: Get code semantics
        console.log('Example 2: Getting code semantics...');
        const codeSemanticResult = await client.callTool('get_code_semantics', {
            path: './src/CacheManager.ps1',
        });
        console.log('Code semantics result:');
        console.log(codeSemanticResult);
        console.log();

        // Example 3: Optimize context
        console.log('Example 3: Optimizing context...');
        const optimizeResult = await client.callTool('optimize_context', {
            context: {
                task: 'Implement a new feature',
                codebase: 'Large codebase with many files',
                requirements: 'The feature should do X, Y, and Z',
            },
            targetSize: 1000,
        });
        console.log('Optimize context result:');
        console.log(optimizeResult);
        console.log();

        // Example 4: Read a resource
        console.log('Example 4: Reading a resource...');
        const resourceResult = await client.readResource('cache://project_structure/current');
        console.log('Resource content:');
        console.log(resourceResult);
        console.log();

        console.log('All examples completed successfully!');
    } catch (error) {
        console.error('Error:', error);
    } finally {
        // Close the connection and terminate the server process
        await client.close();
        serverProcess.kill();
        console.log('Connection closed and server terminated');
    }
}

// Run the main function
main().catch(console.error);
