#!/usr/bin/env node

/**
 * Health check script for CRM Probolsas
 * 
 * This script performs a simple health check by making an HTTP request to the application.
 * It can be used as a Docker health check or for external monitoring.
 * 
 * Usage:
 *   node health-check.js [url]
 * 
 * If no URL is provided, it defaults to http://localhost:3000
 */

import http from 'http';
import https from 'https';

const url = process.argv[2] || 'http://localhost:3000';
const parsedUrl = new URL(url);
const protocol = parsedUrl.protocol === 'https:' ? https : http;
const timeout = 5000; // 5 seconds timeout

console.log(`Performing health check on ${url}`);

const req = protocol.get(url, { timeout }, (res) => {
  const { statusCode } = res;
  
  // Consume response data to free up memory
  res.resume();
  
  if (statusCode >= 200 && statusCode < 300) {
    console.log(`Health check passed with status code: ${statusCode}`);
    process.exit(0); // Success
  } else {
    console.error(`Health check failed with status code: ${statusCode}`);
    process.exit(1); // Failure
  }
});

req.on('error', (err) => {
  console.error(`Health check failed: ${err.message}`);
  process.exit(1); // Failure
});

req.on('timeout', () => {
  console.error(`Health check timed out after ${timeout}ms`);
  req.destroy();
  process.exit(1); // Failure
});
