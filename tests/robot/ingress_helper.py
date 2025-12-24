"""
Robot Framework library for discovering and testing Kubernetes ingresses.
"""
import subprocess
import json
import os
from typing import List, Dict, Optional

class ingress_helper:
    """Helper library for Kubernetes ingress discovery and testing."""

    ROBOT_LIBRARY_SCOPE = 'SUITE'

    def __init__(self):
        self._ingresses: List[Dict] = []
        self._discovered = False

    def _run_kubectl(self, args: List[str]) -> str:
        """Execute kubectl command and return output."""
        cmd = ['kubectl'] + args
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=60
            )
            if result.returncode != 0:
                raise RuntimeError(f"kubectl failed: {result.stderr}")
            return result.stdout
        except subprocess.TimeoutExpired:
            raise RuntimeError("kubectl command timed out")
        except FileNotFoundError:
            raise RuntimeError("kubectl not found in PATH")

    def discover_ingresses(self) -> List[Dict]:
        """Discover all ingresses in the cluster."""
        output = self._run_kubectl([
            'get', 'ingress', '-A', '-o', 'json'
        ])

        data = json.loads(output)
        ingresses = []

        for item in data.get('items', []):
            metadata = item.get('metadata', {})
            spec = item.get('spec', {})
            namespace = metadata.get('namespace', 'default')
            name = metadata.get('name', 'unknown')

            # Check if TLS is configured
            tls_hosts = set()
            for tls in spec.get('tls', []):
                for host in tls.get('hosts', []):
                    tls_hosts.add(host)

            # Process each rule
            for rule in spec.get('rules', []):
                host = rule.get('host')
                if not host:
                    continue

                # Determine protocol based on TLS configuration
                protocol = 'https' if host in tls_hosts else 'http'

                # Get paths from the rule
                http = rule.get('http', {})
                paths = http.get('paths', [])

                if paths:
                    for path_config in paths:
                        path = path_config.get('path', '/')
                        # Clean up path for regex/prefix types
                        if path.endswith('(/|$)'):
                            path = path.replace('(/|$)', '')
                        ingresses.append({
                            'name': name,
                            'namespace': namespace,
                            'host': host,
                            'path': path if path else '/',
                            'protocol': protocol
                        })
                else:
                    ingresses.append({
                        'name': name,
                        'namespace': namespace,
                        'host': host,
                        'path': '/',
                        'protocol': protocol
                    })

        # Remove duplicates based on host+path
        seen = set()
        unique_ingresses = []
        for ing in ingresses:
            key = f"{ing['host']}{ing['path']}"
            if key not in seen:
                seen.add(key)
                unique_ingresses.append(ing)

        self._ingresses = unique_ingresses
        self._discovered = True
        return self._ingresses

    def get_ingress_list(self) -> List[Dict]:
        """Get the list of discovered ingresses."""
        if not self._discovered:
            self.discover_ingresses()
        return self._ingresses

    def get_ingress_count(self) -> int:
        """Get the count of discovered ingresses."""
        if not self._discovered:
            self.discover_ingresses()
        return len(self._ingresses)

    def get_ingress_hosts(self) -> List[str]:
        """Get list of all ingress hostnames."""
        if not self._discovered:
            self.discover_ingresses()
        return [ing['host'] for ing in self._ingresses]
